import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GateAttendancePage extends StatefulWidget {
  const GateAttendancePage({super.key});

  @override
  State<GateAttendancePage> createState() => GateAttendancePageState();
}

class GateAttendancePageState extends State<GateAttendancePage> {
  final _controller = TextEditingController();
  String _statusMessage = "Waiting for input...";

  /// Supabase instance
  final supabase = Supabase.instance.client;

  /// Handle keypad input
  void _onKeyTap(String value) {
    setState(() {
      _controller.text += value;
    });
  }

  /// Handle backspace
  void _onDelete() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text =
            _controller.text.substring(0, _controller.text.length - 1);
      });
    }
  }

  /// Handle submit
  Future<void> _onSubmit() async {
    if (_controller.text.isEmpty) {
      if (mounted) setState(() => _statusMessage = "X Please enter a Student ID.");
      return;
    }
    
    final now = DateTime.now();

    // Attendance status logic
    String status;
    if (now.hour >= 5 && (now.hour < 7 || (now.hour == 7 && now.minute <= 50))) {
      status = "Early Present";
    } else if ((now.hour == 7 && now.minute >= 51) ||
        (now.hour > 8 && now.hour <= 10)) {
      status = "Late Present";
    } else {
      status = "Outside Attendance Window";
    }

    final studentId = _controller.text.trim();
    try {
      // Fetch student details from 'students' table
      final response = await supabase
          .from('students')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (!mounted) return;
      if (response == null) {
        setState(() {
          _statusMessage =
              "X Student ID not found.\nEntered: $studentId\nTime: $now";
        });
        return;
      }
      
      final studentName = response['full_name'] ?? 'Unknown';

      // Save attendance record to 'gate_attendance'
      await supabase.from('gate_attendance').insert({
        'student_id': studentId,
        'status': status,
        'timestamp': now.toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _statusMessage =
            "✔ Attendance Recorded\nStudent: $studentName ($studentId)\nProgram: ${response['program'] ?? 'N/A'}\nTechnology: ${response['technology'] ?? 'N/A'}\nStatus: $status\nTime: ${now.toString().substring(11, 16)}";
        _controller.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "X Error: $e";
      });
      _controller.clear();
    }
  }

  /// Lock Exit with password
  Future<bool> _unlockAndExit() async {
    final result = await _showPasswordDialog("Exit Gate Attendance");
    
    // FIX APPLIED: Use context only after ensuring the widget is still mounted.
    if (!mounted) return false; 
    
    if (result == true) {
      Navigator.pop(context); // Line 138 is now safe.
      return true;
    }
    return false;
  }

  /// Password check dialog (Supabase-aware, supports admin & staff)
  Future<bool?> _showPasswordDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
                hintText: "Enter password",
                border: OutlineInputBorder(),
            ), 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final entered = controller.text.trim();
                // Check against staff_accounts table
                _validatePassword(entered).then((isValid) {
                  if (!mounted) return;
                  Navigator.pop(dialogContext, isValid);
                });
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Separate async function to validate password for admin/staff roles
  Future<bool> _validatePassword(String entered) async {
    final res = await supabase
        .from('staff_accounts')
        .select('password')
        .inFilter('role', ['admin', 'staff'])
        .maybeSingle();
    final dbPass = res?['password'] ?? "1234";
    return entered == dbPass;
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
          // FIX APPLIED: Reverted to withValues()
          color: Colors.white.withValues(alpha: 0.25), 
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 32)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Prevent accidental exit/refresh without password
        if (!didPop) {
          await _unlockAndExit();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            // Existing gradient background
            gradient: LinearGradient(
              colors: [Color(0xFF00ACC1), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: BackgroundPainter(), // Decorative background painter
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 700;
                
                // NEW LAYOUT IMPLEMENTATION
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      // FIX APPLIED: Reverted to withValues()
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
                              _buildKeypadAndInput(), // Keypad + ID input
                              const SizedBox(height: 30),
                              _buildInfoPanel(), // Info status
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
        "Gate Attendance",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      );

  /// Keypad and Student ID Input Field
  Widget _buildKeypadAndInput() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Student ID Display Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _controller,
              readOnly: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Enter Student ID#",
                hintStyle:
                    TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 3),
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ),
          const SizedBox(height: 30),
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
                _buildKey("", icon: Icons.backspace, onTap: _onDelete), // Backspace
                _buildKey("0"), // Zero
                _buildKey("", icon: Icons.check, onTap: _onSubmit), // Submit
              ],
            ),
          ),
        ],
      );


  /// Build info panel (Preview)
  Widget _buildInfoPanel() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          // FIX APPLIED: Reverted to withValues()
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
              "STATUS / PREVIEW",
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
                  _statusMessage, // The core status message
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
      // FIX APPLIED: Reverted to withValues()
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
      // FIX APPLIED: Reverted to withValues()
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