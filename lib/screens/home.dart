import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/screens/classes_screen.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/util/functions.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:ads_schools/widgets/report_dialog.dart';
import 'package:ads_schools/widgets/student_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool isLoading = true; // Track loading state
  List<SchoolClass> classes = [];
  List<Student> allStudents = [];
  List<Student> filteredStudents = [];
  List<Session> sessions = [];
  List<Term> terms = [];
  String? _selectedClassForReport;
  String? _selectedSessionForReport;
  String? _selectedTerm;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? currentClassId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: MyAppBar(isLoading: isLoading),
      drawer: !kIsWeb ? _buildDrawer() : null,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSidebar(),
          ),
          Expanded(
            flex: 6,
            child: _buildDataTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentDialog(),
        label: const Text('Add Student'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<dynamic> errorDialog(
      {required String errorCode, required String message}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text('Error!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                'Error Code: $errorCode',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  Future<dynamic> loadingDialog(String? subtitle) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing dialog by tapping outside
      builder: (context) {
        return AlertDialog(
          //title: Text('$title ...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Please wait while we $subtitle ...'),
            ],
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Student student, int index) {
    return DataRow(
      cells: [
        DataCell(Text('$index')),
        DataCell(Text(student.regNo)),
        DataCell(Text(student.name)),
        DataCell(Text(student.gender ?? 'N/A')),
        DataCell(Text(student.currentClass)),
        DataCell(Text(student.dob.toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showStudentDialog(student: student),
            ),
            IconButton(
              icon: const Icon(Icons.assessment, size: 20),
              onPressed: () => _viewReportCardDialog(student),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteStudent(student),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDataTable() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildViewToggle(),
                  ),
                  const Spacer(),
                  Expanded(
                      flex: 2,
                      child: MySearchBar(controller: _searchController)),
                ],
              ),
              const Divider(
                thickness: 5.0,
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Text('S/N')),
                  DataColumn(label: Text('Reg No')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('DOB')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredStudents
                    .asMap()
                    .entries
                    .map((entry) => _buildDataRow(
                          entry.value,
                          entry.key + 1,
                        ))
                    .toList(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('ADS_School',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Classes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClassesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: _showSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QuickActionBtn(
              icon: Icons.add,
              title: 'Add Student',
              onTap: () => _showStudentDialog()),
          QuickActionBtn(
              icon: Icons.download,
              title: 'Classes',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClassesScreen()),
                );
              }),
          QuickActionBtn(
              icon: Icons.download,
              title: 'Templates',
              onTap: _downloadTemplate),
          // QuickActionBtn(icon: Icons.print, title: 'Print Reports', onTap: _batchPrintReports),
          const Divider(),
          QuickActionBtn(
              icon: Icons.analytics, title: 'Analytics', onTap: _showAnalytics),
          QuickActionBtn(
              icon: Icons.settings, title: 'Settings', onTap: _showSettings),
        ],
      ),
    );
  }

  // Toggle between viewing all students or filtering by class
  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Filter by Class: '),
          Expanded(
            child: classes.isEmpty
                ? const Text('Loading classes...')
                : DropdownButtonFormField<String>(
                    disabledHint: Text('Select Class to View Students'),
                    items: [
                      DropdownMenuItem(
                          value: null, child: const Text('All Students')),
                      ...classes.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        currentClassId = value; // Update currentClassId here
                        filteredStudents = value == null
                            ? List.from(allStudents)
                            : allStudents
                                .where(
                                    (student) => student.currentClass == value)
                                .toList();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.deleteDocument('students', student.regNo);
        _showSnackBar('Student deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting student: $e');
      }
    }
  }

  Future<void> _downloadTemplate() async {
    //TODO: Implement this method
    _showSnackBar('Template download feature coming soon');
  }

  // Filter students by search query
  void _filterStudents(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredStudents = allStudents
          .where((student) =>
              student.name.toLowerCase().contains(lowercaseQuery) ||
              student.regNo.toLowerCase().contains(lowercaseQuery) ||
              student.currentClass.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  // Fetch classes
  Future<void> _loadClasses() async {
    try {
      final fetchedClasses = await FirebaseHelper.fetchClasses();
      setState(() {
        classes = fetchedClasses;
      });
    } catch (e) {
      _showSnackBar('Error fetching classes: $e');
    }
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      await Future.wait([
        _loadClasses(),
        _loadStudents(),
      ]);
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _loadReportCard({required Student student}) async {
    try {
      // Show progress dialog with initial message
      loadingDialog('prepare the report');
      Navigator.pop(context);
      loadingDialog("fetch the student's Information");
      Navigator.pop(context);

      loadingDialog('fetch class info');
// Fetch class name
      final classDoc = await FirebaseService.getDocumentById(
          'classes', _selectedClassForReport!);
      final schoolClass = SchoolClass.fromFirestore(classDoc);
      final className = schoolClass.name;

      student.currentClass = className;
      Navigator.pop(context);
      loadingDialog("calculate the subjects scores");

      // Fetch subject scores
      final subjectScores = await FirebaseHelper.fetchStudentScores(
        classId: _selectedClassForReport!,
        sessionId: _selectedSessionForReport!,
        termId: _selectedTerm!,
        regNo: student.regNo,
      );
      Navigator.pop(context);
      loadingDialog('fetching traits and skills grades');
      // Fetch traits and skills scores
      final traitsAndSkillsDoc = await FirebaseService.getDocumentById(
        'classes/$_selectedClassForReport/sessions/$_selectedSessionForReport/terms/$_selectedTerm/skillsAndTraits',
        student.regNo,
      );

      final traitsAndSkills = TraitsAndSkills.fromFirestore(
        traitsAndSkillsDoc.data() as Map<String, dynamic>,
      );
      Navigator.pop(context);
      loadingDialog("calculate the student's overall performance");
      // Fetch overall performance data
      final performanceDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(_selectedClassForReport)
          .collection('sessions')
          .doc(_selectedSessionForReport)
          .collection('terms')
          .doc(_selectedTerm)
          .collection('studentPerformance')
          .doc(student.regNo)
          .get();

      PerformanceData? performanceData;
      if (performanceDoc.exists) {
        performanceData = PerformanceData.fromMap(performanceDoc.data()!);
      }
      Navigator.pop(context);
      loadingDialog('finish up');
      // Organize data for report card screen
      final reportCardData = {
        'student': student,
        'performanceData': performanceData,
        'subjectScores': subjectScores,
        'traitsAndSkills': traitsAndSkills,
      };

      // Close progress dialog once the data is fetched
      Navigator.pop(context);

      // open the report dialog and pass the fetched data

      showDialog<bool>(
        barrierDismissible: true,
        context: context,
        builder: (context) => ReportDialog(
          reportCardData: reportCardData,
        ),
      );
    } catch (error) {
      // Close the last dialog in case of error
      Navigator.pop(context);
      errorDialog(message: 'Result not available', errorCode: 'str001');
    }
  }

  // Fetch students
  Future<void> _loadStudents() async {
    try {
      final fetchedStudents = await FirebaseHelper.fetchStudents();
      setState(() {
        allStudents = fetchedStudents;
        filteredStudents = fetchedStudents;
      });
    } catch (e) {
      _showSnackBar('Error fetching students: $e');
    }
  }

  Future<String?> _selectClassDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? selectedClassId;
        return AlertDialog(
          title: const Text('Select a Class'),
          content: DropdownButtonFormField<String>(
            items: classes
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (value) {
              selectedClassId = value;
            },
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedClassId),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAnalytics() async {
    //TODO: Implement this method
    _showSnackBar('Analytics feature coming soon');
  }

  Future<void> _showSettings() async {
    //TODO: Implement this method
    _showSnackBar('Settings feature coming soon');
  }

// Show a snackbar with the provided message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

//show student dialog for either adding or editing students
  void _showStudentDialog({Student? student}) async {
    try {
      // If adding a new student
      if (student == null) {
        // Check if the current class is null (i.e., "All Students" is selected)
        if (currentClassId == null) {
          errorDialog(
            errorCode: '404',
            message: 'Please select a class before adding a student...',
          );
          return; // Exit the function if no class is selected
        }
      }

      String? cId = student == null ? currentClassId : student.currentClass;

      final success = await showDialog<bool>(
        barrierDismissible: false,
        context: context,
        builder: (context) => StudentDialog(
          student: student,
          currentClassId: cId!,
        ),
      );

      if (success == true) {
        _showSnackBar(student != null
            ? "${student.name}'s data updated successfully!"
            : 'New student added successfully!');
        // Reload students to reflect the changes
        await _loadStudents();
      }
    } catch (e) {
      errorDialog(errorCode: 'sstd001', message: 'showing student dialog');
      throw Exception('error opening student dialog: $e');
    }
  }

  // Handle report card viewing
  Future<void> _viewReportCardDialog(Student student) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Class, Session, and Term'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedClassForReport,
                    items: classes
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClassForReport = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Class'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSessionForReport,
                    items: [
                      DropdownMenuItem(
                          value: 'Kf5LOZaxaqlAoKzMSO9R',
                          child: Text('2023/2024')),
                      DropdownMenuItem(
                          value: 'n2D091pQfbGTd6AsoC1E',
                          child: Text('2024/2025')),
                      DropdownMenuItem(value: '', child: Text('2025/2026')),
                      DropdownMenuItem(value: '', child: Text('2026/2027')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSessionForReport = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Session'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTerm,
                    items: [
                      DropdownMenuItem(
                          value: 'DHujiDF53AOGKiLMLfKh', child: Text('First')),
                      DropdownMenuItem(
                          value: 'PYn6CJOPDHgsdUhBEpnU', child: Text('Second')),
                      DropdownMenuItem(
                          value: 'LS3aTdmRpHWQphg9Yhz1', child: Text('Third')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTerm = value;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Term'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (_selectedClassForReport != null &&
                    _selectedSessionForReport != null &&
                    _selectedTerm != null) {
                  _loadReportCard(
                    student: student,
                  );
                } else {
                  _showSnackBar('Please select all fields');
                }
              },
              child: const Text('View Report'),
            ),
          ],
        );
      },
    );
  }
}
