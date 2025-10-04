import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordHelper {
  static final _supabase = Supabase.instance.client;

  /// Checks if the provided password matches the role ('admin' or 'staff')
  static Future<bool> verifyPassword(String role, String inputPassword) async {
    try {
      final res = await _supabase
          .from('staff_accounts')
          .select('password')
          .eq('role', role)
          .maybeSingle();

      if (res == null) return false;
      return res['password'] == inputPassword;
    } catch (e) {
      print("Error verifying password: $e");
      return false;
    }
  }
}
