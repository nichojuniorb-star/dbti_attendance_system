import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GateAttendancePage extends StatefulWidget {
  const GateAttendancePage({super.key});

  @override
  State<GateAttendancePage> createState() => _GateAttendancePageState();
}

class _GateAttendancePageState extends State<GateAttendancePage> {
  final TextEditingController _controller = TextEditingController();
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

  /// Handle submit (✔)
  Future<void> _onSubmit() async {
    if (_controller.text.isEmpty) return;

    final now = DateTime.now();

    // 🔹 Attendance status logic
    String status;
    if (now.hour >= 5 && (now.hour < 7 || (now.hour == 7 && now.minute <= 50))) {
      status = "Early - Present";
    } else if ((now.hour == 7 && now.minute >= 51) ||
        (now.hour >= 8 && now.hour <= 10)) {
      status = "Late - Present";
    } else {
      status = "Outside Attendance Window";
    }

    final studentId = _controller.text.trim();

    try {
      // 🔹 Fetch student details from "students" table
      final response = await supabase
          .from('students')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _statusMessage =
              "⚠ Student ID not found.\nEntered: $studentId\nTime: $now";
        });
        return;
      }

      // 🔹 Save attendance record
      await supabase.from('gate_attendance').insert({
        'student_id': studentId,
        'status': status,
        'timestamp': now.toIso8601String(),
      });

      setState(() {
        _statusMessage = """
✅ Attendance Recorded

Student ID: $studentId
Name: ${response['full_name']}
Program: ${response['program'] ?? 'N/A'}
Technology: ${response['technology'] ?? 'N/A'}

Status: $status
Time: $now
""";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Error: $e";
      });
    }

    _controller.clear(); // reset for next student
  }

  /// Lock Exit with password
  Future<bool> _unlockAndExit() async {
    final result = await _showPasswordDialog("Exit Gate Attendance");
    if (result == true) {
      if (!mounted) return false;
      Navigator.pop(context);
      return true;
    }
    return false;
  }

    /// 🔹 Password check dialog (Supabase-aware, supports admin & staff)
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
              decoration: const InputDecoration(hintText: "Enter password"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final entered = controller.text.trim();

                  // 🚀 Do Supabase check OUTSIDE the async gap
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

    /// Separate async function
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25), // ✅ updated
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 28)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
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
              end: Alignment.bottomRight,
            ),
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

  /// Build keypad section
  Widget _buildKeypad() => SizedBox(
        width: 280,
        child: Column(
          children: [
            const Text(
              "Gate Attendance",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
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
          ],
        ),
      );

  /// Build info panel
  Widget _buildInfoPanel() => Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), // ✅ updated
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(
          _statusMessage,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2) // ✅ updated
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
      ..color = Colors.white.withValues(alpha: 0.25) // ✅ updated
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2), 30, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.75), 40, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
