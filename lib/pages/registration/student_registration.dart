import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentRegistration extends StatefulWidget {
  const StudentRegistration({super.key});

  @override
  State<StudentRegistration> createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idController = TextEditingController();
  String? _technology;
  String? _program;
  String? _gender;
  String? _year;

  /// 🔹 Save student to Supabase
  Future<void> _saveStudent() async {
    try {
      await Supabase.instance.client.from('students').insert({
        'student_id': _idController.text.trim(),
        'full_name':
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        'technology': _technology,
        'program': _program,
        'sex': _gender,
        'year': _year,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Student registered successfully!")),
      );

      // Clear fields after save
      _firstNameController.clear();
      _lastNameController.clear();
      _idController.clear();
      setState(() {
        _technology = null;
        _program = null;
        _gender = null;
        _year = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
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
            color: Colors.white, // 🔹 Clean white box
            borderRadius: BorderRadius.circular(16),
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
                "Student Registration",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              /// 🔹 First Name
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("First Name"),
              ),
              const SizedBox(height: 15),

              /// 🔹 Last Name
              TextField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("Last Name"),
              ),
              const SizedBox(height: 15),

              /// 🔹 Student ID
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("Student ID"),
              ),
              const SizedBox(height: 15),

              /// 🔹 Dropdowns
              _dropdownField("Technology", _technology,
                  (val) => setState(() => _technology = val), [
                "Information Technology",
                "Electrical Technology",
                "Electronic Technology",
                "Instrumentation Technology",
                "Machine Fitting & Machinery",
                "Metal Fabrication & Welding",
              ]),
              const SizedBox(height: 15),

              _dropdownField("Program", _program,
                  (val) => setState(() => _program = val), [
                "Bachelor Degree",
                "Bachelor in Education",
                "Diploma in Technology",
              ]),
              const SizedBox(height: 15),

              _dropdownField("Gender", _gender,
                  (val) => setState(() => _gender = val), [
                "Male",
                "Female",
              ]),
              const SizedBox(height: 15),

              _dropdownField("Year", _year, (val) => setState(() => _year = val), [
                "First Year",
                "Second Year",
                "Third Year",
                "Fourth Year",
              ]),
              const SizedBox(height: 25),

              /// 🔹 Save Button
              ElevatedButton(
                onPressed: _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Student",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable Dropdown Field
  Widget _dropdownField(String label, String? value,
      Function(String?) onChanged, List<String> items) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: _inputDecoration(label),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.black)),
              ))
          .toList(),
    );
  }

  /// 🔹 Input Decoration
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
