import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/material.dart';

class CreateClassDialog extends StatefulWidget {
  final SchoolClass? classToEdit;

  const CreateClassDialog({super.key, this.classToEdit});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _className = TextEditingController();
  final List<TextEditingController> _sessionControllers = [
    TextEditingController()
  ];
  final List<String> _terms = ['1st Term', '2nd Term', '3rd Term'];
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
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'e.g. Primary 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a class name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildSessionsSection(),
                const SizedBox(height: 16),
                const Text('Terms',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Card(
                  child: Column(
                    children: _terms
                        .map((term) => ListTile(
                              title: Text(term),
                              leading: const Icon(Icons.calendar_today),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a session'
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSessionField,
                  tooltip: 'Add another session',
                ),
              ],
            ),
          ),
        ),
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

      final firebaseService = FirebaseService();

      await LoadingDialog.show(
        context: context,
        subtitle: widget.classToEdit != null
            ? 'Update the class details...'
            : 'Create the new class...',
      );

      if (widget.classToEdit != null) {
        await firebaseService.updateClass(
          widget.classToEdit!.id,
          _className.text.trim(),
          sessions: sessions,
          termsAndSubjects: null, // No subjects needed
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(true); // Close create dialog
          SuccessDialog.show(
            context: context,
            message: 'Class updated successfully',
          );
        }
      } else {
        final classId =
            await firebaseService.createClass(_className.text.trim());
        await firebaseService.setupClassStructure(
          classId: classId,
          sessions: sessions,
          termsAndSubjects: null, // No subjects needed
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(true); // Close create dialog
          SuccessDialog.show(
            context: context,
            message: 'Class created successfully',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ErrorDialog.show(
          context: context,
          message: widget.classToEdit != null
              ? 'Failed to update class'
              : 'Failed to create class',
          errorCode: e.toString(),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
