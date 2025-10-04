import 'package:flutter/material.dart';
import 'lecturer_registration.dart';
import 'student_registration.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // rebuild when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            /// Background painter
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: BackgroundPainter(),
            ),

            /// Logo
            const AppLogo(size: 80),

            Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Registration",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                /// Tabs
                LayoutBuilder(
                  builder: (context, constraints) {
                    double fullWidth = constraints.maxWidth - 100; // horizontal margin
                    double halfWidth = fullWidth / 2;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6AA9E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                      child: Stack(
                        children: [
                          /// 🔹 Moving red rectangle background
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            left: _tabController.index == 0 ? 0 : halfWidth,
                            child: Container(
                              width: halfWidth,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 82, 95, 235), // red/orange active box
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          /// 🔹 TabBar (labels)
                          TabBar(
                            controller: _tabController,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.black,
                            indicatorColor: Colors.transparent, // disable default
                            tabs: const [
                              Tab(text: "Lecturer"),
                              Tab(text: "Students"),
                            ],
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                /// Tab contents
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      LecturerRegistration(),
                      StudentRegistration(),
                    ],
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

/// Logo widget
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

/// Background painter
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:0.2)
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
      ..color = Colors.white.withValues(alpha:0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2), 30, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.75), 40, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
