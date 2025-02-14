import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/helpers/firebase_helper.dart';
import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/screens/attendance/generate_qr_screen.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/services/template_service.dart';
import 'package:ads_schools/widgets/import_review.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:ads_schools/widgets/report_dialog.dart';
import 'package:ads_schools/widgets/student_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
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
  String? currentClassId;
  // Add these to the existing variables
  bool get isDesktop => MediaQuery.of(context).size.width >= 1100;
  bool get isMobile => MediaQuery.of(context).size.width < 650;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(isLoading: isLoading, title: 'Students'),
      body: _buildDataTable(),
    );
  }

  Future<void> errorDialog({message, errorCode}) {
    return ErrorDialog.show(
      context: context,
      message: message!,
      errorCode: errorCode!,
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

  Future<void> loadingDialog(String? subtitle) {
    return LoadingDialog.show(
      context: context,
      subtitle: subtitle!,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showStudentDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Add green background color
            foregroundColor: Colors.white, // Add white text/icon color
          ),
          label: Text(Responsive.isMobile(context) ? '' : 'New'),
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                if (currentClassId == null) {
                  ErrorWidget('Please select a class to generate QR codes');
                  errorDialog(
                    message: 'Please select a class to import students',
                    errorCode: 'sstd003',
                  );
                  return;
                }

                try {
                  // Show loading dialog
                  LoadingDialog.show(
                      context: context, subtitle: 'Importing students');

                  // Parse Excel file
                  final importedStudents =
                      await StudentTemplate.parseStudentExcelFile(
                    classId: currentClassId!,
                  );

                  // Close loading dialog
                  if (mounted) Navigator.pop(context);

                  // Show review dialog
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => ImportReviewDialog(
                        students: importedStudents,
                        currentClassId: currentClassId!,
                        onSaveComplete: _loadStudents,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  errorDialog(message: 'Import failed: ${e.toString()}');
                }
              },
              child: Responsive.isMobile(context)
                  ? const Icon(Icons.download)
                  : const Row(
                      children: [
                        Text('Import'),
                        Icon(Icons.download),
                      ],
                    ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                // Show loading dialog
                try {
                  LoadingDialog.show(
                      context: context, subtitle: 'Importing students');
                  StudentTemplate.generateStudentTemplate();
                  if (mounted) Navigator.pop(context);
                  _successDialog(
                    msg: 'Template Successfully Downloaded',
                  );
                } catch (e) {
                  errorDialog(
                    message: 'Error downloading template',
                    errorCode: 'dlt001',
                  );
                }
              },
              child: Responsive.isMobile(context)
                  ? const Icon(Icons.upload)
                  : const Row(
                      children: [
                        Text('Template'),
                        Icon(Icons.upload),
                      ],
                    ),
            ),
          ],
        )
      ],
    );
  }

  List<DataColumn> _buildDataColumns() {
    final columns = [
      const DataColumn(label: Text('S/N')),
      const DataColumn(label: Text('I.D No.')),
      const DataColumn(label: Text('Name')),
    ];

    // Add optional columns for larger screens
    if (isDesktop || isTablet) {
      columns.addAll([
        const DataColumn(label: Text('Gender')),
        const DataColumn(label: Text('Department')),
        const DataColumn(label: Text('DOB')),
      ]);
    }

    columns.add(const DataColumn(label: Text('Actions')));
    return columns;
  }

  DataRow _buildDataRow(Student student, int index) {
    final schoolClass =
        classes.firstWhere((cls) => cls.id == student.currentClass);
    String className = schoolClass.name;
    return DataRow(
      cells: [
        DataCell(Text('$index')),
        DataCell(Text(student.regNo)),
        DataCell(Text(student.name)),
        DataCell(Text(student.gender ?? 'N/A')),
        DataCell(Text(className)),
        DataCell(Text(
          student.dob != null
              ? '${student.dob!.day}/${student.dob!.month}/${student.dob!.year}'
              : 'N/A',
        )),
        DataCell(Row(
          children: [
            IconButton(
              color: Colors.blue,
              tooltip: 'Edit',
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showStudentDialog(student: student),
            ),
            IconButton(
              color: Colors.green,
              tooltip: 'View Report Card',
              icon: const Icon(Icons.assessment, size: 20),
              onPressed: () => _viewReportCardDialog(student),
            ),
            IconButton(
                icon: const Icon(Icons.qr_code, size: 20),
                tooltip: 'generate ID card',
                onPressed: () async {
                  try {
                    loadingDialog('generate the ID card');
                    student.currentClass = className;

                    await StudentIdCardGenerator(
                            student: student, context: context)
                        .generateAndPrint();

                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      _successDialog(msg: 'ID Card Generated Successfully');
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      errorDialog(
                          message: e.toString().replaceFirst('Exception: ', ''),
                          errorCode: 'idc001');
                    }
                    debugPrint("Error: $e");
                  }
                }),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              onPressed: () {},
            ),
            IconButton(
              color: Colors.red,
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete,
                size: 20,
              ),
              onPressed: () => _deleteStudent(student),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildDataTable() {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
          child: Column(
            children: [
              // Responsive header
              if (isDesktop)
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildViewToggle()),
                    const Spacer(),
                    Expanded(
                        flex: 2,
                        child: MySearchBar(controller: _searchController)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildViewToggle(),
                    const SizedBox(height: 8),
                    MySearchBar(controller: _searchController),
                  ],
                ),

              // Responsive action buttons
              if (isDesktop)
                _buildActionButtons()
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildActionButtons(),
                ),

              const Divider(thickness: 2.0),

              // Responsive table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      horizontalMargin: isDesktop ? 24 : 12,
                      columnSpacing: isDesktop ? 24 : 16,
                      columns: _buildDataColumns(),
                      rows: filteredStudents
                          .asMap()
                          .entries
                          .map((entry) =>
                              _buildDataRow(entry.value, entry.key + 1))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        loadingDialog("delete the record");
        await FirebaseService.deleteDocument('students', student.studentId!);

        if (mounted) Navigator.pop(context);
        _loadStudents();
        _successDialog(
          msg: 'Student deleted successfully',
        );
      } catch (e) {
        debugPrint('Error deleting student: $e');
        errorDialog(message: e.toString().replaceFirst(' ', ''));
      }
    }
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
      debugPrint('Error fetching classes: $e');
      errorDialog(
        message: 'Error fetching classes',
        errorCode: 'ld002',
      );
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
      debugPrint('Error loading initial data: $e');
      errorDialog(
        message: 'Error loading initial data',
        errorCode: 'ld001',
      );
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
        studentId: student.regNo,
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
      debugPrint('Error loading report card: $error');
      errorDialog(
        message: 'Error loading report card',
        errorCode: 'ld003',
      );
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
            message: 'Please select a class to add a student',
            errorCode: 'sstd002',
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
      debugPrint('Error opening student dialog: $e');
      errorDialog(
        message: 'Error opening student dialog',
        errorCode: 'sstd001',
      );
      throw Exception('error opening student dialog: $e');
    }
  }

  void _successDialog({msg, additionalContent}) {
    SuccessDialog.show(
        context: context, message: msg, additionalContent: additionalContent);
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
                  errorDialog(
                    message: 'Please select class, session, and term',
                    errorCode: 'vrc001',
                  );
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
