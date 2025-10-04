import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final supabase = Supabase.instance.client;

  String _activeTab = "none";
  String _selectedFilter = "Today";
  final List<String> _filters = [
    "Today", "Weekly", "Monthly", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"
  ];

  bool _isAdminAuthorized = false;
  String _selectedRole = "admin";

  final _adminPinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final response = await supabase
        .from('class_attendance')
        .select('timestamp,status, students(full_name,program,technology,year)')
        .order('timestamp', ascending: false);

    if (!mounted) return;
    setState(() {
      attendanceRecords = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<Uint8List> _generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Attendance Report ($_selectedFilter)",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Full Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Program", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Technology", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Year", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Status", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Timestamp", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...data.map((rec) {
                    final s = rec['students'];
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["full_name"] ?? "")),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["program"] ?? "")),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["technology"] ?? "")),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["year"] ?? "")),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rec["status"] ?? "")),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rec["timestamp"] ?? "")),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  void _exportCSV() {
    List<List<dynamic>> rows = [
      ["Full Name", "Program", "Technology", "Year", "Status", "Timestamp"],
      ...attendanceRecords.map((rec) {
        final s = rec['students'];
        return [
          s['full_name'],
          s['program'],
          s['technology'],
          s['year'],
          rec['status'],
          rec['timestamp']
        ];
      }),
    ];
    String csvData = const ListToCsvConverter().convert(rows);
    debugPrint(csvData);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CSV Exported (check console/output)")));
  }

  Future<bool> _verifyAdminPassword(String password) async {
    final res = await supabase
        .from('staff_accounts')
        .select('password')
        .eq('role', 'admin')
        .maybeSingle();
    final dbPass = res?['password'] ?? "1234";
    return password == dbPass;
  }

  Future<void> _changePassword(String role) async {
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password cannot be empty")));
      return;
    }
    if (newPass != confirmPass) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    await supabase
        .from('staff_accounts')
        .update({'password': newPass})
        .eq('role', role);

    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$role password updated successfully")));
  }

  Widget _passwordSecurity() {
    if (!_isAdminAuthorized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter Admin Password to Access Security Panel",
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          SizedBox(
            width: 250,
            child: TextField(
              controller: _adminPinController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Admin Password",
                prefixIcon: Icon(Icons.lock),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final ok =
                  await _verifyAdminPassword(_adminPinController.text.trim());
              if (ok) {
                setState(() => _isAdminAuthorized = true);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Incorrect Admin Password!")));
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("Admin"),
              selected: _selectedRole == "admin",
              onSelected: (_) => setState(() => _selectedRole = "admin"),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text("Staff"),
              selected: _selectedRole == "staff",
              onSelected: (_) => setState(() => _selectedRole = "staff"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder(
          future: supabase
              .from('staff_accounts')
              .select('password')
              .eq('role', _selectedRole)
              .maybeSingle(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final pass = snapshot.data?['password'] ?? "N/A";
            return Card(
              color: Colors.white.withValues(alpha: 0.2),
              child: ListTile(
                leading: const Icon(Icons.visibility, color: Colors.white),
                title: Text("Current ${_selectedRole.toUpperCase()} Password",
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(pass,
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text("Change Password",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () => _changePassword(_selectedRole),
                icon: const Icon(Icons.save),
                label: const Text("Update Password"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00ACC1), Color(0xFF3F51B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text("MANAGEMENT",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),

              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 700;
                        if (isMobile) {
                          // Stack vertically on mobile
                          return Column(
                            children: [
                              Expanded(flex: 2, child: _leftPanel()),
                              Expanded(flex: 2, child: _middlePanel()),
                              Expanded(flex: 5, child: _rightPanel()),
                            ],
                          );
                        } else {
                          // Side by side on wide screens
                          return Row(
                            children: [
                              Expanded(flex: 2, child: _leftPanel()),
                              Expanded(flex: 2, child: _middlePanel()),
                              Expanded(flex: 5, child: _rightPanel()),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    "© 2025 DBTI Attendance System | Developed by Laim Han Solutions",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftPanel() {
    return ListView(
      children: [
        const Text("Reports & Exports",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white54),
        _tabButton("View All Attendance"),
        _tabButton("Generate PDF"),
        _tabButton("Generate CSV/Excel"),
        const SizedBox(height: 20),
        const Text("Users & Roles",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white54),
        _tabButton("Password & Security"),
        _tabButton("Contact Developer"),
      ],
    );
  }

  Widget _middlePanel() {
    return Column(
      children: [
        const Text("Filters",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white54),
        DropdownButton<String>(
          value: _selectedFilter,
          dropdownColor: Colors.black87,
          items: _filters
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) async {
            setState(() => _selectedFilter = v!);
            await _loadAttendance();
          },
        ),
      ],
    );
  }

  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildPreview(),
    );
  }

  Widget _tabButton(String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => setState(() => _activeTab = label),
    );
  }

  Widget _buildPreview() {
    switch (_activeTab) {
      case "View All Attendance":
        if (attendanceRecords.isEmpty) {
          return const Center(
              child: Text("No records found",
                  style: TextStyle(color: Colors.white70)));
        }
        return ListView(
          children: attendanceRecords.map((rec) {
            final s = rec['students'];
            return ListTile(
              title: Text("${s['full_name']} (${s['year']})",
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                  "${s['program']} - ${s['technology']} | ${rec['status']} @ ${rec['timestamp']}",
                  style: const TextStyle(color: Colors.white70)),
            );
          }).toList(),
        );

      case "Generate PDF":
        return Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              final pdf = await _generatePdf(attendanceRecords);
              await Printing.layoutPdf(onLayout: (format) async => pdf);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Download Attendance PDF"),
          ),
        );

      case "Generate CSV/Excel":
        return Center(
          child: ElevatedButton.icon(
            onPressed: _exportCSV,
            icon: const Icon(Icons.table_chart),
            label: const Text("Export CSV"),
          ),
        );

      case "Password & Security":
        return _passwordSecurity();

      case "Contact Developer":
        return const Center(
          child: Text(
            "📩 DBTI Attendance System was developed by Laim Han Solutions\nFor inquiries: support@dbti-attendance.com",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        );

      default:
        return const Center(
            child: Text("Select a menu on the left",
                style: TextStyle(color: Colors.white70)));
    }
  }
}
