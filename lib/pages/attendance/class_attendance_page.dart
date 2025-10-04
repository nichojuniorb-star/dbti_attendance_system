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

  String _activeField = "student"; // student or lecturer
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
      setState(() => _statusMessage = "⚠ Please enter a Student ID.");
      return;
    }
    if (_lecturerController.text.isEmpty && _substituteId == null) {
      setState(() => _statusMessage = "⚠ Lecturer or Substitute ID is required.");
      return;
    }

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 20));
    String status = now.isAfter(cutoff) ? "Late" : "Present";

    final studentId = _studentController.text.trim();
    final lecturerId = _lecturerController.text.trim().isNotEmpty
        ? _lecturerController.text.trim()
        : _substituteId;

    try {
      // 🔹 Fetch student info
      final student = await supabase
          .from('students')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (!mounted) return;

      if (student == null) {
        setState(() => _statusMessage = "⚠ Student not found.\nID: $studentId");
        return;
      }

      final studentName = student['full_name'] ?? "Unknown";

      // 🔹 Validate lecturer or substitute
      if (lecturerId != null && lecturerId.isNotEmpty) {
        final lecturer = await supabase
            .from('lecturers')
            .select()
            .eq('lecturer_id', lecturerId)
            .maybeSingle();

        if (!mounted) return;

        if (lecturer == null) {
          setState(() => _statusMessage = "⚠ Lecturer not found.\nID: $lecturerId");
          return;
        }
      }

      // 🔹 Save attendance record
      await supabase.from('class_attendance').insert({
        'student_id': studentId,
        'lecturer_id': lecturerId,
        'status': status,
        'timestamp': now.toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _statusMessage = """
✅ Attendance Recorded

Student: $studentName ($studentId)
Lecturer: ${lecturerId ?? "N/A"}
Status: $status
Time: $now
""";
        _lecturerLocked = true;
        _studentController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = "❌ Error: $e");
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
        _statusMessage = "Lecturer cleared. Please re-enter.";
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
          _statusMessage = "Substitute set: $subId";
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
            Navigator.pop(dialogContext); // ✅ close immediately (no async context use)

            // Now safely perform async Supabase work *after* the dialog closes
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

  return completer.future; // ✅ returns the async result safely
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25), // ✅ updated
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 28)
              : Text(label,
                  style: const TextStyle(
                      fontSize: 22,
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
                  child: isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildKeypad(),
                            const SizedBox(height: 20),
                            _buildInfoPanel(),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildKeypad(),
                            const SizedBox(width: 20),
                            _buildInfoPanel(),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _unlockAndExit,
          backgroundColor: Colors.redAccent,
          child: const Icon(Icons.lock_open),
        ),
      ),
    );
  }

  /// Keypad + Input fields
  Widget _buildKeypad() => SizedBox(
        width: 280,
        child: Column(
          children: [
            const Text("Class Attendance",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),

            // Lecturer ID
            TextField(
              controller: _lecturerController,
              readOnly: true,
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
                suffixIcon: _lecturerLocked
                    ? const Icon(Icons.lock, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 15),

            // Student ID
            TextField(
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
            const SizedBox(height: 20),

            // Keypad
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 1; i <= 9; i++) _buildKey("$i"),
                _buildKey("", icon: Icons.backspace, onTap: _onDelete),
                _buildKey("0"),
                _buildKey("", icon: Icons.check, onTap: _onSubmit),
              ],
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
        ),
      );

  /// Info Panel
  Widget _buildInfoPanel() => Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30)),
        child: Text(_statusMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      );
}

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
