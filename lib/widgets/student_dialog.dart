import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentDialog extends StatefulWidget {
  final Student? student;
  final String currentClassId;

  const StudentDialog({
    super.key,
    this.student,
    required this.currentClassId,
  });

  @override
  _StudentDialogState createState() => _StudentDialogState();
}

class _StudentDialogState extends State<StudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<TextEditingController, String> _controllers;
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  DateTime? _dateJoined;
  String? _photo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhotoSelector(
                          photo: _photo,
                          onPhotoSelected: (photoUrl) {
                            setState(() {
                              _photo = photoUrl;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildFormContent(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.keys) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveStudent,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
                widget.student == null ? 'Create Student' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupSelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Blood Group',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _bloodGroup,
          isExpanded: true,
          items: _bloodGroups.map((group) {
            return DropdownMenuItem(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: (value) => setState(() => _bloodGroup = value),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      controller: TextEditingController(
        text: date != null ? DateFormat.yMMMd().format(date) : '',
      ),
      validator: (value) => date == null ? 'Please select $label' : null,
      onTap: () => _selectDate(context, date, onDateSelected),
    );
  }

  Widget _buildDatePickers() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
                child: _buildDatePicker(
              label: 'Date of Birth',
              date: _dob,
              onDateSelected: (date) => setState(() => _dob = date),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: _buildDatePicker(
              label: 'Date Joined',
              date: _dateJoined,
              onDateSelected: (date) => setState(() => _dateJoined = date),
            )),
          ],
        );
      },
    );
  }

  Widget _buildDropdownSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(child: _buildGenderSelector()),
            const SizedBox(width: 8),
            Expanded(child: _buildBloodGroupSelector()),
          ],
        );
      },
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputGrid(),
        const SizedBox(height: 8),
        _buildDropdownSection(),
        const SizedBox(height: 8),
        _buildDatePickers(),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          items: _genders.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (value) => setState(() => _gender = value),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.student == null ? 'Add New Student' : 'Edit Student',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildInputGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3,
      children: _controllers.entries.map((entry) {
        return TextFormField(
          controller: entry.key,
          decoration: InputDecoration(
            labelText: entry.value,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (value) => _validateField(value, entry.value),
        );
      }).toList(),
    );
  }

  void _initializeFields() {
    final student = widget.student;
    _gender = student?.gender ?? _genders.first;
    _bloodGroup = student?.bloodGroup ?? _bloodGroups.first;
    _dob = student?.dob;
    _photo = student?.photo;
    _dateJoined = student?.dateJoined ?? DateTime.now();

    _controllers = {
      TextEditingController(text: student?.name ?? ''): 'Name',
      TextEditingController(text: student?.regNo ?? ''): 'Registration Number',
      TextEditingController(text: student?.parentName ?? ''): 'Parent Name',
      TextEditingController(text: student?.parentPhone ?? ''): 'Parent Phone',
      TextEditingController(text: student?.address ?? ''): 'Address',
    };
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null || _dateJoined == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    final isEditing = widget.student != null;
    final studentId = widget.student?.studentId;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Check for duplicate registration number when adding new student
      if (!isEditing) {
        final existing = await FirebaseFirestore.instance
            .collection('students')
            .where('regNo',
                isEqualTo: _controllers.keys.elementAt(1).text.trim())
            .get();

        if (existing.docs.isNotEmpty) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration number already exists')),
          );
          return;
        }
      }

      // Prepare student data
      final studentData = Student(
        studentId: studentId,
        regNo: _controllers.keys.elementAt(1).text.trim(),
        name: _controllers.keys.elementAt(0).text.trim(),
        currentClass: widget.currentClassId,
        gender: _gender!,
        dob: _dob!,
        dateJoined: _dateJoined!,
        parentName: _controllers.keys.elementAt(2).text.trim(),
        parentPhone: _controllers.keys.elementAt(3).text.trim(),
        address: _controllers.keys.elementAt(4).text.trim(),
        bloodGroup: _bloodGroup!,
        photo: _photo,
        personInfo: widget.student?.personInfo ?? {},
      );

      // Firestore operations
      if (isEditing) {
        // Update existing student
        await FirebaseService.updateOrAddDocument<Student>(
          collection: 'students',
          document: studentData,
          queryFields: {'regNo': studentData.regNo},
          toJsonOrMap: (s) => s.toMap(),
        );
      } else {
        // Add new student
        final docRef = await FirebaseService.addDocument<Student>(
          collection: 'students',
          document: studentData,
          toJsonOrMap: (s) => s.toMap(),
        );

        // Initialize attendance record
        await _setupNewStudent(docRef!.id);
      }

      // Close dialogs and show success
      Navigator.pop(context); // Close loading
      Navigator.pop(context, true); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Student updated' : 'Student created'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Save error: $e');
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  Future<void> _setupNewStudent(String studentId) async {
    try {
      // Create initial attendance record
      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': studentId,
        'status': 'New',
        'date': Timestamp.now(),
        'currentClass': widget.currentClassId,
        'timestamp': Timestamp.now(),
      });
/*
      // Add to class roster
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.currentClassId)
          .update({
        'students': FieldValue.arrayUnion([studentId])
      });
      */
    } catch (e) {
      debugPrint('Error setting up new student: $e');
      rethrow;
    }
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (fieldName == 'Parent Phone' &&
        !RegExp(r'^[0-9]{14}$').hasMatch(value)) {
      return 'Enter valid 14-digit phone number';
    }
    return null;
  }
}
