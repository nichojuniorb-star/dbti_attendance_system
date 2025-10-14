import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class PasswordHelper {
  static final supabase = Supabase.instance.client;

  /// Checks if the provided password matches the role ('admin' or 'staff')
  static Future<bool> verifyPassword(String role, String inputPassword) async {
    try {
      final res = await supabase
          .from('staff_accounts')
          .select('password')
          .eq('role', role)
          .maybeSingle();
      if (res == null) return false;

      return res['password'] == inputPassword;
    } catch (e) {
      // FIX APPLIED: Changed print() to debugPrint() to avoid production warning (Line 18 in error report)
      debugPrint("Error verifying password: $e"); 
      return false;
    }
  }
}