import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import pages
import 'pages/splash_screen.dart';
import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';

// 🔹 Your Supabase credentials
const supabaseUrl = 'https://rvhsxbrbwwhnykhxzdqu.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2aHN4YnJid3dobnlraHh6ZHF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5MTk2NzEsImV4cCI6MjA3MDQ5NTY3MX0.L19TWg8OpGShhy_3fDnoDhCXkC28fbjOWxEKrNl1h2g';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const DBTIAttendanceSystem());
}

class DBTIAttendanceSystem extends StatelessWidget {
  const DBTIAttendanceSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBTI Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),

      // 👇 Always start with SplashScreen
      home: const SplashScreen(),

      // 👇 Define all available routes
      routes: {
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
