import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firestore_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ImportReviewDialog extends StatefulWidget {
  final List<Student> students;
  final String currentClassId;
  final VoidCallback onSaveComplete;

  const ImportReviewDialog({
    super.key,
    required this.students,
    required this.currentClassId,
    required this.onSaveComplete,
  });

  @override
  State<ImportReviewDialog> createState() => _ImportReviewDialogState();
}

class _ImportReviewDialogState extends State<ImportReviewDialog> {
  final _studentService = FirestoreService<Student>(
    collectionName: 'students',
    fromSnapshot: (doc) => Student.fromFirestore(doc),
    toJson: (student) => student.toMap(),
  );

  bool _isSaving = false;
  final List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Review Import',
        style: TextStyle(fontWeight: FontWeight.bold, color: mainColor),
      ),
      icon: const Icon(Icons.info, color: mainColor),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(),
              const SizedBox(height: 8),
              Text(
                'Found ${widget.students.length} students',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    return Card(
                      child: ListTile(
                        title: Text(student.name),
                        subtitle: Text('Reg: ${student.regNo}'),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
              if (_errors.isNotEmpty) ErrorWidget(_errors.join('\n')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: _isSaving
              ? const CircularProgressIndicator()
              : const Icon(Icons.cloud_upload),
          label: Text(_isSaving ? 'Saving...' : 'Save to Cloud'),
          onPressed: _isSaving ? null : _saveStudents,
        ),
      ],
    );
  }

  Future<void> _saveStudents() async {
    setState(() {
      _isSaving = true;
      _errors.clear();
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final studentsCollection =
          FirebaseFirestore.instance.collection('students');

      // Check for existing students and prepare batch operations
      for (final student in widget.students) {
        if (student.regNo.trim().isEmpty) {
          throw Exception('Registration number cannot be empty');
        }

        // Query for existing student by registration number (exact match)
        final existingStudentQuery = await studentsCollection
            .where('regNo',
                isEqualTo: student.regNo
                    .trim()) // this is to handle case sensitive regNo safely
            .limit(1)
            .get();

        final studentData = student.toMap()
          ..['currentClass'] = widget.currentClassId
          ..['dateJoined'] = Timestamp.now();

        if (existingStudentQuery.docs.isNotEmpty) {
          // Update existing student
          final existingDocRef = existingStudentQuery.docs.first.reference;
          batch.update(existingDocRef, studentData);
        } else {
          // Add new student
          final docRef = studentsCollection.doc();
          batch.set(docRef, studentData);
        }
      }

      // Update class document
      final classRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.currentClassId);

      batch.update(classRef, {
        'students':
            FieldValue.arrayUnion(widget.students.map((s) => s.regNo).toList())
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(
          msg: 'Successfully imported ${widget.students.length} students',
        );
        widget.onSaveComplete();
      }
    } catch (e) {
      setState(() {
        _errors.add('Save failed: ${e.toString()}');
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog({msg, additionalContent}) {
    SuccessDialog.show(
        context: context, message: msg, additionalContent: additionalContent);
  }
}
