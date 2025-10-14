import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ClassAttendancePage extends StatefulWidget {
  const ClassAttendancePage({super.key});

  @override
  State<ClassAttendancePage> createState() => _ClassAttendancePageState();
}

class _ClassAttendancePageState extends State<ClassAttendancePage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _studentController = TextEditingController();
  final TextEditingController _lecturerController = TextEditingController();

  String _activeField = "lecturer"; // Start focused on lecturer
  String _statusMessage = "Waiting for input...";
  bool _lecturerLocked = false;
  String? _substituteId;

  /// Keypad input
  void _onKeyTap(String value) {
    setState(() {
      if (_activeField == "student") {
        _studentController.text += value;
      } else if (_activeField == "lecturer" && !_lecturerLocked) {
        _lecturerController.text += value;
      }
    });
  }

  /// Backspace
  void _onDelete() {
    setState(() {
      if (_activeField == "student" && _studentController.text.isNotEmpty) {
        _studentController.text =
            _studentController.text.substring(0, _studentController.text.length - 1);
      } else if (_activeField == "lecturer" &&
          !_lecturerLocked &&
          _lecturerController.text.isNotEmpty) {
        _lecturerController.text =
            _lecturerController.text.substring(0, _lecturerController.text.length - 1);
      }
    });
  }

  /// Submit attendance
  Future<void> _onSubmit() async {
    if (_studentController.text.isEmpty) {
      if (mounted) setState(() => _statusMessage = "⚠ Please enter a Student ID.");
      return;
    }
    if (_lecturerController.text.isEmpty && _substituteId == null) {
      if (mounted) setState(() => _statusMessage = "⚠ Lecturer or Substitute ID is required.");
      return;
    }
    
    // Check if Lecturer field is active AND unlocked (meaning they haven't submitted their ID yet)
    if (_activeField == "lecturer" && !_lecturerLocked) {
      // Treat this submission as the attempt to lock the lecturer ID
      if (_lecturerController.text.isNotEmpty) {
        // Attempt to validate and lock the lecturer
        await _validateAndLockLecturer();
        return; 
      }
    }
    
    // If lecturer is locked, proceed with class attendance logic
    if (_lecturerLocked || _substituteId != null) {
      await _processClassAttendance();
    } else {
      if (mounted) setState(() => _statusMessage = "⚠ Please enter and confirm Lecturer ID first.");
    }
  }

  // Helper function to handle lecturer validation and locking
  Future<void> _validateAndLockLecturer() async {
      final lecturerId = _lecturerController.text.trim();
      try {
          final lecturer = await supabase
              .from('lecturers')
              .select()
              .eq('lecturer_id', lecturerId)
              .maybeSingle(); 

          if (!mounted) return;
          if (lecturer == null) {
              setState(() => _statusMessage = "⚠ Lecturer ID not found.");
              return;
          }

          setState(() {
              _lecturerLocked = true;
              _activeField = "student";
              _statusMessage = "✅ Lecturer confirmed. Ready for student IDs.";
          });
      } catch (e) {
          if (mounted) setState(() => _statusMessage = "❌ Error validating lecturer: $e");
      }
  }
  
  // Helper function to process actual student attendance (Now includes Timetable Check)
  Future<void> _processClassAttendance() async {
    final now = DateTime.now();
    final studentId = _studentController.text.trim();
    final currentDay = _getDayOfWeek(now.weekday);

    final classStartTime = 9; 
    final lateTime = DateTime(now.year, now.month, now.day, classStartTime, 20); 

    String status = now.isAfter(lateTime) ? "Late" : "Present";
    
    final lecturerId = _lecturerController.text.trim().isNotEmpty
        ? _lecturerController.text.trim()
        : _substituteId;

    try {
      // 🔹 1. Fetch student info (including program details for timetable matching)
      final student = await supabase
          .from('students')
          .select('full_name, program, technology, year')
          .eq('student_id', studentId)
          .maybeSingle();

      if (!mounted) return;

      if (student == null) {
        setState(() => _statusMessage = "⚠ Student not found.\nID: $studentId");
        return;
      }
      
      final studentName = student['full_name'] ?? "Unknown";
      final studentProgram = student['program'] ?? "N/A";
      final studentTechnology = student['technology'] ?? "N/A";
      final studentYear = student['year'] ?? "N/A";


      // 🔹 2. Gate Check (Prevents Proxy Attendance)
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).toIso8601String();
      
      final gateCheck = await supabase
          .from('gate_attendance')
          .select('status')
          .eq('student_id', studentId)
          .inFilter('status', ['Early Present', 'Late Present'])
          .gte('timestamp', twentyFourHoursAgo)
          .maybeSingle();

      if (!mounted) return;
      
      if (gateCheck == null) {
        setState(() => _statusMessage = "❌ Gate check failed. Student must clock in at the gate first.");
        _studentController.clear();
        return;
      }

      // 🔹 3. Timetable Validation: Check if student and lecturer are scheduled NOW
      
      // NOTE: This assumes an uploaded 'class_schedule' table exists in Supabase
      // Format: Day, StartTime, EndTime, LecturerID, UnitCode, ClassName (Program + Technology + Year)
      
      final scheduleMatch = await supabase
          .from('class_schedule')
          .select('lecturer_id, unit_code, class_name')
          .eq('day', currentDay)
          .lte('start_time', '${now.hour}:${now.minute}') // Current time is after or equal to start
          .gte('end_time', '${now.hour}:${now.minute}')   // Current time is before or equal to end
          .eq('class_name', '$studentProgram - $studentTechnology - $studentYear')
          .maybeSingle();

      if (!mounted) return;

      if (scheduleMatch == null) {
        setState(() => _statusMessage = "❌ Timetable error. No class scheduled now for $studentProgram / $studentTechnology.");
        _studentController.clear();
        return;
      }

      final expectedLecturerId = scheduleMatch['lecturer_id'];

      // 🔹 4. Lecturer Match Check
      if (lecturerId != expectedLecturerId && _substituteId == null) {
        setState(() => _statusMessage = "❌ Wrong class! Lecturer ID $lecturerId is not scheduled for this unit (${scheduleMatch['unit_code']}). Expected: $expectedLecturerId");
        _studentController.clear();
        return;
      }

      // 🔹 Save attendance record
      await supabase.from('class_attendance').insert({
        'student_id': studentId,
        'lecturer_id': lecturerId,
        'status': status,
        'unit_code': scheduleMatch['unit_code'], // Save unit code from schedule
        'timestamp': now.toIso8601String(), 
      });

      if (!mounted) return;

      setState(() {
        _statusMessage = """
✅ Attendance Recorded

Student: $studentName ($studentId)
Class: ${scheduleMatch['class_name']}
Lecturer: ${lecturerId ?? "N/A"}
Unit: ${scheduleMatch['unit_code']}
Status: $status
Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}
""";
        _studentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = "❌ Error: $e");
    }
  }
  
  // Helper function to get the current day of the week as a string (e.g., Monday)
  String _getDayOfWeek(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }


  /// Clear Lecturer (password required)
  void _clearLecturer() async {
    final result = await _showPasswordDialog("Clear Lecturer");
    if (!mounted) return;
    if (result == true) {
      setState(() {
        _lecturerController.clear();
        _substituteId = null;
        _lecturerLocked = false;
        _statusMessage = "Lecturer cleared. Please enter Lecturer ID.";
        _activeField = "lecturer";
      });
    }
  }

  /// Set Substitute Lecturer
  void _setSubstitute() async {
    final result = await _showPasswordDialog("Substitute Lecturer");
    if (!mounted) return;
    if (result == true) {
      final subId = await _showInputDialog("Enter Substitute ID#");
      if (!mounted) return;
      if (subId != null && subId.isNotEmpty) {
        setState(() {
          _substituteId = subId;
          _lecturerLocked = true;
          _activeField = "student";
          _statusMessage = "Substitute set: $subId. Ready for student IDs.";
        });
      }
    }
  }

  /// Exit unlock (password required)
  Future<bool> _unlockAndExit() async {
    final result = await _showPasswordDialog("Exit Attendance Screen");
    if (!mounted) return false;
    if (result == true) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  /// 🔹 Password dialog (Admin OR Staff for unlocks)
  Future<bool?> _showPasswordDialog(String title) async {
    final controller = TextEditingController();
    final completer = Completer<bool?>();

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter password"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final entered = controller.text.trim();
              Navigator.pop(dialogContext); // Close immediately

              // Safely perform async Supabase work *after* the dialog closes
              final res = await supabase
                  .from('staff_accounts')
                  .select('password')
                  .inFilter('role', ['admin', 'staff'])
                  .maybeSingle();

              final dbPass = res?['password'] ?? "1234";
              completer.complete(entered == dbPass);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    return completer.future; // returns the async result safely
  }


  /// Substitute ID input
  Future<String?> _showInputDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter ID#")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text("OK")),
        ],
      ),
    );
  }

  /// Build keypad button
  Widget _buildKey(String label, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _onKeyTap(label),
      child: Container(
        width: 80, 
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25), 
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 32)
              : Text(label,
                  style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _unlockAndExit();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF00ACC1), Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: CustomPaint(
            painter: BackgroundPainter(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 700;
                return Center(
                  // New Container for the main content box (similar to GateAttendancePage)
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    width: isMobile ? constraints.maxWidth * 0.9 : 800,
                    height: isMobile ? null : 600,
                    child: isMobile
                        // Mobile Layout: Keypad over Info Panel
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildKeypadAndInput(),
                              const SizedBox(height: 30),
                              _buildInfoPanel(),
                            ],
                          )
                        // Desktop/Tablet Layout: Keypad side-by-side with Info Panel
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(flex: 1, child: _buildKeypadAndInput()),
                              const SizedBox(width: 30),
                              Expanded(flex: 1, child: _buildInfoPanel()),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        // RED LOCK ICON BUTTON: Triggers password-protected exit
        floatingActionButton: FloatingActionButton(
          onPressed: _unlockAndExit,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.lock_open, size: 30),
        ),
      ),
    );
  }

  /// New Header Widget
  Widget _buildHeader() => const Text(
        "Class Attendance",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      );

  /// Keypad and Input fields (Consolidated for the new layout)
  Widget _buildKeypadAndInput() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lecturer ID Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _lecturerController,
              readOnly: true,
              autofocus: true, 
              onTap: () => setState(() => _activeField = "lecturer"), 
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Enter Lecturer ID#", 
                hintStyle: const TextStyle(
                    color: Colors.white70, fontStyle: FontStyle.italic),
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)),
                // Show lock icon when set
                suffixIcon: _lecturerLocked 
                    ? const Icon(Icons.lock, color: Colors.white70) 
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Student ID Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _studentController,
              readOnly: true,
              onTap: () => setState(() => _activeField = "student"), 
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: "Enter Student ID#", 
                hintStyle:
                    TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Keypad Grid 
          SizedBox(
            width: 300,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 18, 
              crossAxisSpacing: 18, 
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (var i = 1; i <= 9; i++) _buildKey("$i"),
                _buildKey(""), // Spacer
                _buildKey("0"), 
                _buildKey("", icon: Icons.backspace, onTap: _onDelete), 
                _buildKey("", icon: Icons.check, onTap: _onSubmit), 
                _buildKey(""), // Spacer
              ].where((widget) => widget.runtimeType != SizedBox).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons 
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _clearLecturer, 
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent), 
                child: const Text("Clear Lecturer")), 
              const SizedBox(width: 10), 
              ElevatedButton(
                onPressed: _setSubstitute, 
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange), 
                child: const Text("Substitute")), 
            ],
          ),
        ],
      );

  /// Info Panel (Updated styling to match Gate Attendance)
  Widget _buildInfoPanel() => Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const Divider(color: Colors.white54, height: 40, thickness: 1.5),
            const Text(
              "STATUS / FEEDBACK",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _statusMessage, 
                  style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      );
}

// Reusable BackgroundPainter class
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.2, size.width, size.height * 0.4);
    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.8, size.width, size.height * 0.7);
    canvas.drawPath(path2, paint);

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2), 30, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.75), 40, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}