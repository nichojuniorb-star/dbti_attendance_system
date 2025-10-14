import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LecturerRegistration extends StatefulWidget {
  const LecturerRegistration({super.key});

  @override
  State<LecturerRegistration> createState() => _LecturerRegistrationState();
}

class _LecturerRegistrationState extends State<LecturerRegistration> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  String? _gender;
  String? _title; // Correct variable name from source: 'title' [cite: 956]

  /// Save lecturer to Supabase
  Future<void> _saveLecturer() async {
    try {
      await Supabase.instance.client.from('lecturers').insert({
        'lecturer_id': _idController.text.trim(),
        'full_name': _nameController.text.trim(),
        'gender': _gender, 
        'title': _title,
      });

      // FIX APPLIED: Guarded context use (Line 27 in error report)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✔ Lecturer registered successfully!")),
      );

      // Clear fields after save
      _nameController.clear();
      _idController.clear();
      setState(() {
        _gender = null;
        _title = null;
      });
    } catch (e) {
      // FIX APPLIED: Guarded context use (Line 39 in error report)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("X Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, // White background box
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lecturer Registration",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              /// Full Name
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("Full Name"),
              ),
              const SizedBox(height: 15),
              /// Lecturer ID
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("Lecturer ID"),
              ),
              const SizedBox(height: 15),
              // Gender Dropdown
              DropdownButtonFormField<String>(
                // FIX APPLIED: Replaced 'value' with 'initialValue' (Line 110 in error report)
                initialValue: _gender,
                onChanged: (val) => setState(() => _gender = val),
                decoration: _inputDecoration("Gender"),
                items: ["Male", "Female"]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e,
                              style: const TextStyle(color: Colors.black)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 15),
              /// Title Dropdown
              DropdownButtonFormField<String>(
                // FIX APPLIED: Replaced 'value' with 'initialValue'
                initialValue: _title,
                onChanged: (val) => setState(() => _title = val),
                decoration: _inputDecoration("Title"),
                items: ["Mr.", "Mrs.", "Ms."]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e,
                              style: const TextStyle(color: Colors.black)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 25),
              /// Save Button
              ElevatedButton(
                onPressed: _saveLecturer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Lecturer",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Input decoration helper (renamed from source to prevent conflicts)
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}