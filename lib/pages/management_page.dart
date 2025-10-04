import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/password_helper.dart'; 


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
    "Today",
    "Weekly",
    "Monthly",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
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
        .select(
            'timestamp,status, students(full_name,program,technology,year)')
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
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blue200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Full Name",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Program",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Technology",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Year",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Status",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("Timestamp",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...data.map((rec) {
                    final s = rec['students'];
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(s["full_name"] ?? "")),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(s["program"] ?? "")),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(s["technology"] ?? "")),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(s["year"] ?? "")),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(rec["status"] ?? "")),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(rec["timestamp"] ?? "")),
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

  // ❌ REMOVED: This logic is now handled by PasswordHelper.verifyPassword
  /* Future<bool> _verifyAdminPassword(String password) async {
    final res = await supabase
        .from('staff_accounts')
        .select('password')
        .eq('role', 'admin')
        .maybeSingle();
    final dbPass = res?['password'] ?? "1234";
    return password == dbPass;
  }
  */

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
              const Text(
                "MANAGEMENT",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),

              // MAIN PANEL
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 700;
                      if (isMobile) {
                        return Column(
                          children: [
                            Expanded(flex: 2, child: _leftPanel()),
                            Expanded(flex: 2, child: _middlePanel()),
                            Expanded(flex: 5, child: _rightPanel()),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _leftPanel()),
                            Expanded(flex: 2, child: _middlePanel()),
                            Expanded(flex: 6, child: _rightPanel()),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "© 2025 DBTI Attendance System | Developed by Laim Han Solutions",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ LEFT PANEL - Dynamic Tabs
  Widget _leftPanel() {
    final tabs = [
      {"label": "View All Attendance", "icon": Icons.view_list},
      {"label": "Generate PDF", "icon": Icons.picture_as_pdf},
      {"label": "Generate CSV/Excel", "icon": Icons.table_chart},
      {"label": "Password & Security", "icon": Icons.lock},
      {"label": "Contact Developer", "icon": Icons.email_outlined},
    ];

    return ListView(
      children: [
        const Text(
          "Menu",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const Divider(color: Colors.white38),
        ...tabs.map((tab) {
          final isActive = _activeTab == tab['label'];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Colors.white70 : Colors.transparent,
                width: 1,
              ),
            ),
            child: ListTile(
              leading:
                  Icon(tab['icon'] as IconData, color: Colors.white, size: 22),
              title:
                  Text(tab['label'] as String, style: const TextStyle(color: Colors.white)),
              onTap: () => setState(() => _activeTab = tab['label'] as String),
            ),
          );
        }),
      ],
    );
  }

  // ✅ MIDDLE PANEL – FILTER FIX APPLIED (Removed 'offset')
  Widget _middlePanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                "Filters",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Times New Roman',
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Divider(
              color: Colors.white38,
              height: 0.5,
              thickness: 0.8,
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: isMobile ? double.infinity : 180,
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withValues(alpha: 0.18),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: DropdownButtonHideUnderline(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      canvasColor:
                          const Color(0xFF000000).withValues(alpha: 0.25),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      borderRadius: BorderRadius.circular(14),
                      dropdownColor:
                          const Color(0xFF000000).withValues(alpha: 0.25),
                      iconEnabledColor: Colors.white,
                      isExpanded: true,
                      itemHeight: 48.0,
                      isDense: true,

                      // The 'offset' parameter is correctly removed.
                      
                      // ✅ Limit dropdown height for all screens
                      menuMaxHeight:
                          MediaQuery.of(context).size.height * 0.45,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      // ✅ Items section
                      items: _filters.map((f) {
                        final isSelected = f == _selectedFilter;
                        return DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontWeight:
                                  isSelected ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFFFFEB3B)
                                  : Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        setState(() => _selectedFilter = v!);
                        await _loadAttendance();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // ✅ RIGHT PANEL - Preview Display
  Widget _rightPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_activeTab),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildPreview(),
      ),
    );
  }

  // ✅ PREVIEW CONTENT
  Widget _buildPreview() {
    switch (_activeTab) {
      case "View All Attendance":
        if (attendanceRecords.isEmpty) {
          return const Center(
              child: Text("No records found",
                  style: TextStyle(color: Colors.white70)));
        }
        return ListView.builder(
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            final rec = attendanceRecords[index];
            final s = rec['students'];
            return Card(
              color: Colors.white.withValues(alpha: 0.1),
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text("${s['full_name']} (${s['year']})",
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                    "${s['program']} - ${s['technology']} | ${rec['status']} @ ${rec['timestamp']}",
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          },
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: Colors.blue.shade800,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        );

      case "Generate CSV/Excel":
        return Center(
          child: ElevatedButton.icon(
            onPressed: _exportCSV,
            icon: const Icon(Icons.table_chart),
            label: const Text("Export CSV File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              foregroundColor: Colors.teal.shade800,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
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

  // ✅ PASSWORD PANEL
  Widget _passwordSecurity() {
    if (!_isAdminAuthorized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter Admin Password to Access Security Panel",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          SizedBox(
            width: 250,
            child: TextField(
              controller: _adminPinController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Admin Password",
                prefixIcon: Icon(Icons.lock, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              // 💡 FIX: Use the imported PasswordHelper.verifyPassword
              final ok = await PasswordHelper.verifyPassword(
                'admin', 
                _adminPinController.text.trim()
              );
              
              if (ok) {
                setState(() => _isAdminAuthorized = true);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Incorrect Admin Password!")));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: Colors.blue),
            child: const Text("Confirm"),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Change Passwords",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Admin"),
                selected: _selectedRole == "admin",
                onSelected: (_) => setState(() => _selectedRole = "admin"),
              ),
              const SizedBox(width: 10),
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
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: Colors.white);
              }
              final pass = snapshot.data?['password'] ?? "N/A";
              return Card(
                color: Colors.white.withValues(alpha: 0.2),
                child: ListTile(
                  leading:
                      const Icon(Icons.visibility, color: Colors.white70),
                  title: Text(
                      "Current ${_selectedRole.toUpperCase()} Password",
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(pass,
                      style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}