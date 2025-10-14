import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/password_helper.dart'; 

// Developer Email for Notifications and Contact
const String _developerEmail = "automatedattendancesystem0@gmail.com";

class ManagementPage extends StatefulWidget {
  const ManagementPage({super.key});

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final supabase = Supabase.instance.client;

  // UPDATED: Default to the first main tab
  String _activeTab = "View All Attendance"; 
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
  
  // Controllers for Admin Auth / Password Change
  final _adminPinController = TextEditingController(); 
  final _newPasswordController = TextEditingController(); 
  final _confirmPasswordController = TextEditingController(); 

  // Controllers for Contact Developer form
  final _queryController = TextEditingController();
  final _queryEmailController = TextEditingController();
  bool _isSendingContact = false;
  
  // Toggles for Password & Security tab
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  List<Map<String, dynamic>> attendanceRecords = []; 

  @override
  void initState() {
    super.initState();
    _loadAttendance(); 
  }
  
  @override
  void dispose() {
    _adminPinController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _queryController.dispose();
    _queryEmailController.dispose();
    super.dispose();
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
  
  Future<void> _forgotPassword() async {
    final adminEmail = "admin@dbti.edu"; 
    
    try {
      await supabase.auth.resetPasswordForEmail(
        adminEmail,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔑 Password reset email sent to Admin.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("X Error sending reset email: $e")),
      );
    }
  }

  Future<void> _sendContactQuery() async {
    if (_queryEmailController.text.isEmpty || _queryController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in your email and query.")),
        );
      }
      return;
    }
    
    setState(() => _isSendingContact = true);
    
    try {
      // Simulation of a backend function call to send email
      await Future.delayed(const Duration(seconds: 2)); 

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✔ Email sent successfully, you'll be notified in the next 24-48hrs."),
        ),
      );
      _queryController.clear();
      _queryEmailController.clear();
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("X Failed to send message: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSendingContact = false);
    }
  }


  Future<Uint8List> _generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Attendance Report ($_selectedFilter)", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
            children: [
              // Header Row
              pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue200), children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Full Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Program", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Technology", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Year", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Status", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Timestamp", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ]),
              // Data Rows
              ...data.map((rec) {
                final s = rec['students'];
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["full_name"] ?? "")),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["program"] ?? "")),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["technology"] ?? "")),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s["year"] ?? "")),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rec["status"] ?? "")),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(rec["timestamp"] ?? "")),
                ]);
              }),
            ],
          ),
        ],
      );
    }));
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

    // Simulate sending email notification to developer 
    await Future.delayed(const Duration(milliseconds: 500)); 
    
    _newPasswordController.clear(); 
    _confirmPasswordController.clear(); 

    if (!mounted) return; 
    ScaffoldMessenger.of(context).showSnackBar( 
        SnackBar(content: Text("✔ $role password updated successfully. Developer has been notified."))); 
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

  // ✅ LEFT PANEL - Consolidated Menu
  Widget _leftPanel() {
    // Consolidated Tabs: Removed PDF/CSV export tabs
    final tabs = [ 
      {"label": "View All Attendance", "icon": Icons.view_list},
      // ADDED: New tab
      {"label": "Schedule Management", "icon": Icons.schedule},
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

  // ✅ MIDDLE PANEL – Retained for Filter
  Widget _middlePanel() { 
    return LayoutBuilder(
      builder: (context, constraints) { 
        final isMobile = constraints.maxWidth < 700; 

        // Hide filter panel if not on the attendance tab
        if (_activeTab != "View All Attendance") {
          return const SizedBox.shrink();
        }

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

                      // Limit dropdown height for all screens
                      menuMaxHeight:
                          MediaQuery.of(context).size.height * 0.45, 
                      style: const TextStyle( 
                        color: Colors.white, 
                        fontFamily: 'Times New Roman', 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                      ),
                      // Items section
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

  // ✅ RIGHT PANEL - Consolidated View/Security/Contact/Schedule
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
        return Column(
          children: [
            // 1. Attendance List
            Expanded(
              child: attendanceRecords.isEmpty
                  ? const Center(
                      child: Text("No records found", style: TextStyle(color: Colors.white70)),
                    )
                  : ListView.builder(
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
                    ),
            ),
            const SizedBox(height: 15),
            // 2. Export Options (Moved from main menu)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final pdf = await _generatePdf(attendanceRecords);
                    await Printing.layoutPdf(onLayout: (format) async => pdf);
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportCSV,
                  icon: const Icon(Icons.table_chart),
                  label: const Text("Export CSV"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ],
        );

      case "Schedule Management":
        return _scheduleManagementWidget();

      case "Password & Security":
        return _passwordSecurityWidget();

      case "Contact Developer":
        return _contactDeveloperWidget();

      default:
        return const Center(
            child: Text("Select a menu on the left",
                style: TextStyle(color: Colors.white70)));
    }
  }

  // 🆕 NEW WIDGET: Schedule Management UI
  Widget _scheduleManagementWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Schedule Management",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(color: Colors.white38, height: 30),
        const Text(
          "Upload Timetable CSV",
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Format required: Day, StartTime (HH:MM), EndTime (HH:MM), LecturerID, UnitCode, ClassName/Program",
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              // 💡 Placeholder for actual file picker logic
              // In a real app, this would open a file picker and process the CSV contents into Supabase.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File Picker placeholder activated. CSV upload needed.")),
                );
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Timetable CSV"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Database Status:",
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(color: Colors.white38),
        // Display status of current schedule table (Conceptual)
        Expanded(
          child: Center(
            child: Text(
              "Timetable must be loaded into a new 'class_schedule' table to activate the class validation logic.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.yellow.shade200, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ PASSWORD PANEL WIDGET (Previous logic)
  Widget _passwordSecurityWidget() {
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
          const SizedBox(height: 20),
          // Forgot Password Option
          TextButton(
            onPressed: _forgotPassword,
            child: const Text("Forgot Admin Password?", 
              style: TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline)),
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
          // Password Display
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
                // New Password Field
                TextField(
                  controller: _newPasswordController, 
                  obscureText: !_isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "New Password", 
                    prefixIcon: const Icon(Icons.lock_outline), 
                    suffixIcon: IconButton(
                        icon: Icon(_isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible)),
                    filled: true, 
                    fillColor: Colors.white, 
                  ),
                ),
                const SizedBox(height: 10), 
                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController, 
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Confirm Password", 
                    prefixIcon: const Icon(Icons.lock), 
                    suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
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

  // ✅ CONTACT DEVELOPER WIDGET (Previous logic)
  Widget _contactDeveloperWidget() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Contact Developer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white38, height: 30),
          const Text(
            "Share your issues or queries below. We will respond to your provided email within 24-48 hours.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _queryEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: "Your Email Address",
              hintText: "Enter email for follow-up",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _queryController,
            maxLines: 5,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: "Issue/Query Details",
              hintText: "Describe your issue or query",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          
          Center(
            child: ElevatedButton.icon(
              onPressed: _isSendingContact ? null : _sendContactQuery,
              icon: _isSendingContact 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.send, color: Colors.white),
              label: Text(_isSendingContact ? "Sending..." : "Send Query"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white38),
          const SizedBox(height: 10),

          // Developer Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Developer Contact: $_developerEmail",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}