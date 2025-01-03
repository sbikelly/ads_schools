import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/screens/classes_screen.dart';
import 'package:ads_schools/screens/report.dart';
import 'package:ads_schools/services/data_upload.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/services/subject_template.dart';
import 'package:ads_schools/util/constants.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _uploadService = DataUploadService();
  final String _selectedClass = 'All Classes';
  final String _selectedTerm = '1st Term';
  final String _selectedSession = '2024/2025';
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: _buildMainContent(),
          ),
          Expanded(
            flex: 2,
            child: _buildSidebar(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStudent(),
        label: const Text('Add Student'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addStudent() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final regNoController = TextEditingController();
    String selectedClass = 'Primary 1';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: regNoController,
                decoration:
                    const InputDecoration(labelText: 'Registration Number'),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Registration Number is required'
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: const InputDecoration(labelText: 'Class'),
                items: ['Primary 1', 'Primary 2', 'Primary 3']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => selectedClass = value!,
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'regNo': regNoController.text,
                  'class': selectedClass,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final student = Student(
          regNo: result['regNo']!,
          name: result['name']!,
          currentClass: result['class']!,
          personalInfo: {},
        );

        await FirebaseService.addDocument(
          collection: 'students',
          document: student,
          toJsonOrMap: (s) => s.toMap(),
        );

        _showSnackBar('Student added successfully');
      } catch (e) {
        _showSnackBar('Error adding student: $e');
      }
    }
  }

  Future<void> _batchPrintReports() async {
    setState(() => _isLoading = true);
    try {
      final students = await FirebaseService.getWhere(
        collection: 'students',
        queryFields: _selectedClass == 'All Classes'
            ? {}
            : {'currentClass': _selectedClass},
      );

      if (students.docs.isEmpty) {
        _showSnackBar('No students found for printing reports');
        return;
      }

      // Show progress dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Generating Reports'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while reports are being generated...'),
            ],
          ),
        ),
      );

      _showSnackBar('Reports generated successfully');
    } catch (e) {
      _showSnackBar('Error generating reports: $e');
    } finally {
      setState(() => _isLoading = false);
      Navigator.of(context).pop(); // Close progress dialog
    }
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('ADS_School'),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: mainColor,
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedClass,
      decoration: const InputDecoration(labelText: 'Class'),
      items: ['All Classes', 'Primary 1', 'Primary 2', 'Primary 3']
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) => setState(() {}),
    );
  }

  DataRow _buildDataRow(Student student) {
    return DataRow(
      cells: [
        DataCell(Text(student.regNo)),
        DataCell(Text(student.name)),
        DataCell(Text(student.currentClass)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editStudent(student),
            ),
            IconButton(
              icon: const Icon(Icons.assessment, size: 20),
              onPressed: () => _viewReportCard(student),
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
    return Expanded(
      child: Card(
        elevation: 4,
        child: StreamBuilder<List<Student>>(
          stream: FirebaseService.getDataStream<Student>(
            collection: 'students',
            fromMap: (data) => Student.fromMap(data),
            queryFields: _selectedClass == 'All Classes'
                ? null
                : {'currentClass': _selectedClass},
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Reg No')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: students
                      .map((student) => _buildDataRow(student))
                      .toList(),
                ),
              ),
            );
          },
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

  Widget _buildFilters() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildClassDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildTermDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildSessionDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search students...',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildSessionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSession,
      decoration: const InputDecoration(labelText: 'Session'),
      items: ['2024/2025', '2023/2024']
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildSidebar() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickAction(
            icon: Icons.add,
            title: 'Add Student',
            onTap: _addStudent,
          ),
          _buildQuickAction(
            icon: Icons.upload_file,
            title: 'Upload Data',
            onTap: _uploadData,
          ),
          _buildQuickAction(
            icon: Icons.download,
            title: 'Download Template',
            onTap: _downloadTemplate,
          ),
          _buildQuickAction(
            icon: Icons.print,
            title: 'Print Reports',
            onTap: _batchPrintReports,
          ),
          const Divider(),
          _buildQuickAction(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: _showAnalytics,
          ),
          _buildQuickAction(
            icon: Icons.settings,
            title: 'Settings',
            onTap: _showSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTermDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTerm,
      decoration: const InputDecoration(labelText: 'Term'),
      items: ['1st Term', '2nd Term', '3rd Term']
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (value) => setState(() {}),
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
    try {
      setState(() => _isLoading = true);

      // Show options to the user
      final selectedTemplate = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Template'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Subject Template'),
                  onTap: () => Navigator.of(context).pop('subject'),
                ),
                ListTile(
                  title: Text('Traits and Skills Template'),
                  onTap: () => Navigator.of(context).pop('traitsAndSkills'),
                ),
              ],
            ),
          );
        },
      );

      // Proceed based on user selection
      if (selectedTemplate == 'subject') {
        final filePath = await SubjectTemplate.generateSubjectTemplate();
        _showSnackBar('Subject template downloaded to: $filePath');
      } else if (selectedTemplate == 'traitsAndSkills') {
        final filePath = await TraitsTemplate.generateTraitsTemplate();
        _showSnackBar('Traits and Skills template downloaded to: $filePath');
      } else {
        _showSnackBar('No template selected.');
      }
    } catch (e) {
      _showSnackBar('Error downloading template: $e');
      debugPrint('Error downloading template: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editStudent(Student student) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student.name);
    final regNoController = TextEditingController(text: student.regNo);
    String selectedClass = student.currentClass;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: regNoController,
                decoration:
                    const InputDecoration(labelText: 'Registration Number'),
                enabled: false,
              ),
              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: const InputDecoration(labelText: 'Class'),
                items: ['Primary 1', 'Primary 2', 'Primary 3']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => selectedClass = value!,
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'class': selectedClass,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedStudent = Student(
          studentId: student.studentId,
          regNo: student.regNo,
          name: result['name']!,
          currentClass: result['class']!,
          photoUrl: student.photoUrl,
          personalInfo: student.personalInfo,
        );

        await FirebaseService.updateOrAddDocument(
          collection: 'students',
          document: updatedStudent,
          queryFields: {'regNo': student.regNo},
          toJsonOrMap: (s) => s.toMap(),
        );

        _showSnackBar('Student updated successfully');
      } catch (e) {
        _showSnackBar('Error updating student: $e');
      }
    }
  }

  Future<void> _showAnalytics() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Class Analytics'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsCard('Total Students', '120'),
              _buildAnalyticsCard('Class Average', '72.5%'),
              _buildAnalyticsCard('Highest Score', '98%'),
              _buildAnalyticsCard('Lowest Score', '45%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('School Information'),
              onTap: () => _showSnackBar('School Information settings'),
            ),
            ListTile(
              leading: const Icon(Icons.grade),
              title: const Text('Grading System'),
              onTap: () => _showSnackBar('Grading System settings'),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup & Restore'),
              onTap: () => _showSnackBar('Backup & Restore settings'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

// Helper Methods
  Future<void> _uploadData() async {
    try {
      setState(() => _isLoading = true);

      await _uploadService.uploadReportCardData();
      _showSnackBar('Data uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading data: $e');
      _showSnackBar('Error uploading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewReportCard(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportCardScreen1(
          studentId: student.studentId!,
          classId: student.currentClass,
          sessionId: 'Kf5LOZaxaqlAoKzMSO9R',
          termId: 'DHujiDF53AOGKiLMLfKh',
        ),
      ),
    );
  }
}
