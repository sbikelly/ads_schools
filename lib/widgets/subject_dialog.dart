import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:flutter/material.dart';

class CreateEditSubjectsDialog extends StatefulWidget {
  final List<Subject>? initialSubjects;

  const CreateEditSubjectsDialog({
    super.key,
    this.initialSubjects,
  });

  @override
  State<CreateEditSubjectsDialog> createState() =>
      _CreateEditSubjectsDialogState();
}

class _CreateEditSubjectsDialogState extends State<CreateEditSubjectsDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _nameControllers = [];
  final List<String?> _selectedFileUrls = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add/Edit Subjects'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(
                  _nameControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Subject Name',
                              hintText: 'e.g., Mathematics',
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter a subject name'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _selectFile(index),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Material'),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedFileUrls[index] != null)
                          Expanded(
                            flex: 2,
                            child: Text(
                              'File Uploaded',
                              style: const TextStyle(color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: _nameControllers.length > 1
                              ? () => _removeSubjectField(index)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addSubjectField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Subject'),
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
              : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSubjects != null) {
      for (var subject in widget.initialSubjects!) {
        _nameControllers.add(TextEditingController(text: subject.name));
        _selectedFileUrls.add(subject.materialUrl);
      }
    } else {
      _addSubjectField();
    }
  }

  void _addSubjectField() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _selectedFileUrls.add(null);
    });
  }

  void _removeSubjectField(int index) {
    setState(() {
      _nameControllers.removeAt(index);
      _selectedFileUrls.removeAt(index);
    });
  }

  void _selectFile(int index) async {}

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      for (int i = 0; i < _nameControllers.length; i++) {
        final name = _nameControllers[i].text.trim();
        final fileUrl = _selectedFileUrls[i];

        final subject = Subject(
          id: widget.initialSubjects != null &&
                  i < widget.initialSubjects!.length
              ? widget.initialSubjects![i].id
              : null,
          name: name,
          materialUrl: fileUrl,
        );

        await FirebaseService.updateOrAddDocument(
          collection: 'subjects',
          document: subject,
          queryFields: {'name': subject.name},
          toJsonOrMap: (subject) => subject.toMap(),
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
