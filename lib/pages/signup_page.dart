// 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ADDED: Focus nodes for keyboard navigation
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isEmailVisible = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _signUp() async {
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
      }
      return;
    }

    if (_usernameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All fields are required.")),
            );
        }
        return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(), // 👈 store username
        },
      );

      if (response.user != null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sign up successful, please check your email to verify."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign Up failed: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    // Automatically focus on the username field when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 Background painter + gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00ACC1), Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(
              painter: BackgroundPainter(),
              child: Container(),
            ),
          ),

          /// 🔹 Logo
          const AppLogo(size: 90),

          /// 🔹 Main Sign-up content
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double screenWidth = constraints.maxWidth;
                bool isMobile = screenWidth < 600;

                return Container(
                  width: isMobile ? screenWidth * 0.9 : 750,
                  height: isMobile ? null : 480,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 20 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildLeftPanel(isMobile: true),
                            const SizedBox(height: 20),
                            _buildRightPanel(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 1, child: _buildLeftPanel()),
                            Expanded(flex: 1, child: _buildRightPanel()),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Left panel (decorative + text)
  Widget _buildLeftPanel({bool isMobile = false}) {
    return Container(
      height: isMobile ? 200 : double.infinity,
      decoration: BoxDecoration(
        // REVERTED to original syntax to satisfy local SDK environment
        color: Colors.blueAccent.shade100.withValues(alpha: 0.2),
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : const BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 30,
            child: CircleAvatar(
              radius: 25,
              // REVERTED to original syntax to satisfy local SDK environment
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 40,
            child: CircleAvatar(
              radius: 40,
              // REVERTED to original syntax to satisfy local SDK environment
              backgroundColor: Colors.teal.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 50,
            child: CircleAvatar(
              radius: 12,
              // REVERTED to original syntax to satisfy local SDK environment
              backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            child: Container(
              width: 120,
              height: 2,
              color: Colors.black26,
            ),
          ),
          Positioned(
            top: 200,
            right: 30,
            child: Row(
              children: List.generate(
                5,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "WELCOME",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "DBTI Attendance System",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Right panel (Sign-up form)
  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Create Account",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Username - Autofocus and navigation to Email
          TextField(
            autofocus: true, // Auto-focus handled in initState, but kept here for clarity
            focusNode: _usernameFocusNode,
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_emailFocusNode);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              labelText: "Username",
              hintText: "Enter your full name or preferred username", // New placeholder
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Email with toggle - Navigation to Password
          TextField(
            focusNode: _emailFocusNode,
            controller: _emailController,
            obscureText: !_isEmailVisible,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: "Email",
              hintText: "Enter your official email address", // New placeholder
              suffixIcon: IconButton(
                icon: Icon(
                  _isEmailVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _isEmailVisible = !_isEmailVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Password - Navigation to Confirm Password
          TextField(
            focusNode: _passwordFocusNode,
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: "Password",
              hintText: "Create a secure password", // New placeholder
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Confirm Password - ENTER Submission
          TextField(
            focusNode: _confirmPasswordFocusNode,
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done, // ENTER triggers submission
            onSubmitted: (_) => _signUp(), // ENTER calls the sign-up function
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: "Confirm Password",
              hintText: "Repeat your password to confirm", // New placeholder
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _isConfirmPasswordVisible =
                      !_isConfirmPasswordVisible);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sign-up button
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isLoading ? "Signing up..." : "Sign Up",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Link back to sign in
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/signin');
            },
            child: const Text(
              "Already have an account? Sign In",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Reusable background painter
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // REVERTED to original syntax to satisfy local SDK environment
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
      // REVERTED to original syntax to satisfy local SDK environment
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
    double screenWidth = MediaQuery.of(context).size.width;
    double finalSize = screenWidth < 600 ? size * 0.6 : size;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Transform.rotate(
          angle: 0,
          child: Image.asset(
            "assets/images/dbti_logo.png",
            height: finalSize,
          ),
        ),
      ),
    );
  }
}