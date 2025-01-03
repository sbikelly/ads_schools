import 'package:ads_schools/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

class CreateClassDialog extends StatefulWidget {
  final SchoolClass? classToEdit;

  const CreateClassDialog({super.key, this.classToEdit});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class CreateSubjectDialog extends StatefulWidget {
  final String classId;
  final String sessionId;
  final String termId;

  const CreateSubjectDialog({
    super.key,
    required this.classId,
    required this.sessionId,
    required this.termId,
  });

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _className = TextEditingController();
  final List<TextEditingController> _sessionControllers = [
    TextEditingController()
  ];
  final Map<String, List<TextEditingController>> _termSubjectsControllers = {
    '1st Term': [TextEditingController()],
    '2nd Term': [TextEditingController()],
    '3rd Term': [TextEditingController()],
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.classToEdit != null ? 'Edit Class' : 'Create New Class'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _className,
                  decoration: const InputDecoration(labelText: 'Class Name'),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a class name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildSessionsSection(),
                const SizedBox(height: 16),
                _buildTermsSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.classToEdit != null ? 'Save Changes' : 'Create Class'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _className.dispose();
    for (var controller in _sessionControllers) {
      controller.dispose();
    }
    _termSubjectsControllers.forEach((_, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.classToEdit != null) {
      _className.text = widget.classToEdit!.name;
    }
  }

  void _addSessionField() {
    setState(() {
      _sessionControllers.add(TextEditingController());
    });
  }

  void _addSubjectField(String term) {
    setState(() {
      _termSubjectsControllers[term]?.add(TextEditingController());
    });
  }

  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(
          _sessionControllers.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sessionControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Session',
                      hintText: 'e.g., 2023/2024',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSessionField,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Terms and Subjects',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ..._termSubjectsControllers.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key),
              ...List.generate(
                entry.value.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value[index],
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            hintText: 'e.g., Mathematics',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addSubjectField(entry.key),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sessions = _sessionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final termsAndSubjects = Map<String, List<String>>.fromEntries(
        _termSubjectsControllers.entries.map((entry) {
          final subjects = entry.value
              .map((controller) => controller.text.trim())
              .where((text) => text.isNotEmpty)
              .toList();
          return MapEntry(entry.key, subjects);
        }),
      );

      final firebaseService = FirebaseService();

      if (widget.classToEdit != null) {
        // Handle edit class
        await firebaseService.updateClass(
          widget.classToEdit!.id,
          _className.text.trim(),
          sessions: sessions,
          termsAndSubjects: termsAndSubjects,
        );
      } else {
        // Create new class
        final classId =
            await firebaseService.createClass(_className.text.trim());
        await firebaseService.setupClassStructure(
          classId: classId,
          sessions: sessions,
          termsAndSubjects: termsAndSubjects,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _subjectControllers = [
    TextEditingController(),
  ];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Subjects'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(
                  _subjectControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _subjectControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Subject Name',
                              hintText: 'e.g., Mathematics',
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter a subject name'
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addSubjectField,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Subjects'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _subjectControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubjectField() {
    setState(() {
      _subjectControllers.add(TextEditingController());
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final subjects = _subjectControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (subjects.isNotEmpty) {
        final subjectCollection = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('sessions')
            .doc(widget.sessionId)
            .collection('terms')
            .doc(widget.termId)
            .collection('subjects');

        for (var subject in subjects) {
          await subjectCollection.add({'name': subject});
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
