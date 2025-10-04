import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import sub-pages
import 'attendance/attendance_page.dart';
import 'registration/registration_page.dart';
import 'management_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return; // ✅ Safe context usage
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00ACC1), Color(0xFF3F51B5)], // teal → blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            /// 🔹 Background decoration
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: BackgroundPainter(),
            ),

            /// 🔹 Logo
            const AppLogo(size: 80),

            /// 🔹 Content
            Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "DBTI Attendance System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Times New Roman",
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),

                /// Main box
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double screenWidth = constraints.maxWidth;
                        bool isMobile = screenWidth < 600;

                        return Container(
                          width: isMobile ? screenWidth * 0.9 : 450,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 138, 156, 188),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.26),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HoverMenuButton(
                                title: "Attendance",
                                icon: Icons.qr_code,
                                page: const AttendancePage(),
                              ),
                              const SizedBox(height: 20),
                              HoverMenuButton(
                                title: "Registration",
                                icon: Icons.person_add,
                                page: const RegistrationPage(),
                              ),
                              const SizedBox(height: 20),
                              HoverMenuButton(
                                title: "Management",
                                icon: Icons.settings,
                                page: const ManagementPage(),
                              ),
                              const SizedBox(height: 30),

                              /// Logout button
                              ElevatedButton.icon(
                                onPressed: () => _signOut(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 24),
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                icon: const Icon(Icons.logout,
                                    color: Colors.white),
                                label: const Text(
                                  "Logout",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Hoverable Menu Button Widget
class HoverMenuButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget page;

  const HoverMenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.page,
  });

  @override
  State<HoverMenuButton> createState() => _HoverMenuButtonState();
}

class _HoverMenuButtonState extends State<HoverMenuButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => widget.page),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isHovered ? Colors.lightBlueAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: isHovered ? Colors.white : Colors.black87,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isHovered
                      ? Color.fromARGB(255, 225, 8, 8)
                      : Colors.black87,
                  fontFamily: "Times New Roman",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Background decoration
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

/// 🔹 Reusable Logo Widget
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Image.asset(
          "assets/images/dbti_logo.png",
          height: size,
        ),
      ),
    );
  }
}
