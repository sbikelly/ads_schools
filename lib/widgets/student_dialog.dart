import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentDialog extends StatefulWidget {
  final Student? student; // If null, we're adding a new student.
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
  late TextEditingController _nameController;
  late TextEditingController _regNoController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _addressController;

  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  DateTime? _dateJoined;

  String? _photo;

  @override
  Widget build(BuildContext context) {
    try {
      return Builder(builder: (context) {
        return _mainFields();
      });
    } on Exception catch (e) {
      debugPrint('error in student dialog: $e');
      return ErrorDialog(errorCode: 'ast001', message: 'adding student');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    try {
      _nameController = TextEditingController(text: widget.student?.name ?? '');
      _regNoController =
          TextEditingController(text: widget.student?.regNo ?? '');
      _parentNameController =
          TextEditingController(text: widget.student?.parentName ?? '');
      _parentPhoneController =
          TextEditingController(text: widget.student?.parentPhone ?? '');
      _addressController =
          TextEditingController(text: widget.student?.address ?? '');
      _gender = widget.student?.gender;
      _bloodGroup = widget.student?.bloodGroup;
      _dob = widget.student?.dob;
      _photo = widget.student?.photo;
      _dateJoined = widget.student?.dateJoined;
    } catch (e) {
      throw Exception(e);
    }
  }

  Widget _mainFields() {
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    return SizedBox(
      width: 800,
      child: AlertDialog(
        title: Text(
          widget.student == null ? 'Add Student' : 'Edit Student',
          //style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            label: const Text('Cancel'),
            icon: const Icon(Icons.cancel),
          ),
          SizedBox(
            width: 5,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            onPressed: _saveStudent,
            label: Text(widget.student == null ? 'Add' : 'Save'),
          ),
        ],
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                //mainAxisSize: MainAxisSize.mi,
                children: [
                  PhotoSelector(
                    photo: _photo,
                    onPhotoSelected: (photoUrl) {
                      setState(() {
                        _photo = photoUrl;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _regNoController,
                    decoration: const InputDecoration(labelText: 'Reg No'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter a reg no'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (value) =>
                        value == null ? 'Select a gender' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _parentNameController,
                    decoration: const InputDecoration(labelText: 'Parent Name'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _parentPhoneController,
                    decoration:
                        const InputDecoration(labelText: 'Parent Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _bloodGroup,
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    items: bloodGroups
                        .map((group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _bloodGroup = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'DOB'),
                          controller: TextEditingController(
                            text: _dob != null
                                ? DateFormat.yMMMd().format(_dob!)
                                : '',
                          ),
                          onTap: () => _pickDate(context, _dob, (date) {
                            setState(() => _dob = date);
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration:
                              const InputDecoration(labelText: 'Date Joined'),
                          controller: TextEditingController(
                            text: _dateJoined != null
                                ? DateFormat.yMMMd().format(_dateJoined!)
                                : '',
                          ),
                          onTap: () => _pickDate(context, _dateJoined, (date) {
                            setState(() => _dateJoined = date);
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate,
      ValueChanged<DateTime?> onDateSelected) async {
    try {
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        onDateSelected(selectedDate);
      }
    } catch (e) {
      throw Exception('error selecting date $e');
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final student = Student(
        studentId: widget.student?.studentId,
        regNo: _regNoController.text,
        name: _nameController.text,
        currentClass: widget.currentClassId,
        gender: _gender,
        dob: _dob,
        dateJoined: _dateJoined,
        parentName: _parentNameController.text,
        parentPhone: _parentPhoneController.text,
        address: _addressController.text,
        bloodGroup: _bloodGroup,
        personalInfo: widget.student?.personalInfo ?? {},
        photo: _photo);

    try {
      if (widget.student == null) {
        // Add new student
        await FirebaseService.addDocument<Student>(
          collection: 'students',
          document: student,
          toJsonOrMap: (s) => s.toMap(),
        );
      } else {
        // Edit existing student
        await FirebaseService.updateOrAddDocument<Student>(
          collection: 'students',
          document: student,
          queryFields: {'regNo': student.regNo},
          toJsonOrMap: (s) => s.toMap(),
        );
      }

      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: $e')),
      );
      throw Exception(e);
    }
  }
}
