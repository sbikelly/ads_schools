/*
import 'package:ads_schools/models/student_model.dart';
import 'package:flutter/material.dart';

Future<Student?> showMultiStepDialog(
  BuildContext context, {
  Student? existingStudent,
}) {
  return showDialog<Student>(
    context: context,
    barrierDismissible: false, // Prevent dismissing without confirmation
    builder: (context) => MultiStepDialog(student: existingStudent),
  );
}

class AttendanceStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final StudentFormData data;
  final Function(StudentFormData) onUpdate;

  const AttendanceStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Attendance form fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Days Present'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Must be a number';
                    }
                    return null;
                  },
                  /*
                  onChanged: (value) {
                    data.attendance = [AttendanceRecord(
                      daysPresent: int.tryParse(value) ?? 0,
                      totalDays: data.attendance?.first.totalDays ?? 0,
                    )];
                    onUpdate(data);
                  },
                 */
                  initialValue: data.attendance?.first.daysPresent.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Total Days'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Must be a number';
                    }
                    return null;
                  },
                  /*
                  onChanged: (value) {
                    data.attendance = [AttendanceRecord(
                      daysPresent: data.attendance?.first.daysPresent ?? 0,
                      totalDays: int.parse(value)?? 0,
                    )];
                    onUpdate(data);
                  },
                  */
                  initialValue:
                      (data.attendance?.first.totalDays ?? 0).toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BasicInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final StudentFormData data;
  final Function(StudentFormData) onUpdate;

  const BasicInfoStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: data.name,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (value) {
              data.name = value;
              onUpdate(data);
            },
            validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
          ),
          TextFormField(
            initialValue: data.studentClass,
            decoration: const InputDecoration(labelText: 'Class'),
            onChanged: (value) {
              data.studentClass = value;
              onUpdate(data);
            },
            validator: (value) =>
                value?.isEmpty ?? true ? 'Class is required' : null,
          ),
          TextFormField(
            initialValue: data.regNo,
            decoration: const InputDecoration(labelText: 'Registration Number'),
            onChanged: (value) {
              data.regNo = value;
              onUpdate(data);
            },
            validator: (value) => value?.isEmpty ?? true
                ? 'Registration Number is required'
                : null,
          ),
        ],
      ),
    );
  }
}

class CognitiveStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final StudentFormData data;
  final Function(StudentFormData) onUpdate;

  const CognitiveStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Add cognitive domain form fields here
          const Text('Cognitive Domain Assessment'),
        ],
      ),
    );
  }
}

class MultiStepDialog extends StatefulWidget {
  final Student? student;

  const MultiStepDialog({super.key, this.student});

  @override
  _MultiStepDialogState createState() => _MultiStepDialogState();
}

class RemarksStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final StudentFormData data;
  final Function(StudentFormData) onUpdate;

  const RemarksStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            decoration:
                const InputDecoration(labelText: 'Class Teacher Remarks'),
            maxLines: 3,
            initialValue: data.remarks?.classTeacher,
            onChanged: (value) {
              data.remarks = Remarks(
                classTeacher: value,
                principal: data.remarks?.principal ?? '',
              );
              onUpdate(data);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Principal Remarks'),
            maxLines: 3,
            initialValue: data.remarks?.principal,
            onChanged: (value) {
              data.remarks = Remarks(
                classTeacher: data.remarks?.classTeacher ?? '',
                principal: value,
              );
              onUpdate(data);
            },
          ),
        ],
      ),
    );
  }
}

class SkillsTraitsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final StudentFormData data;
  final Function(StudentFormData) onUpdate;

  const SkillsTraitsStep({
    super.key,
    required this.formKey,
    required this.data,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Skills and traits form fields
          const Text('Skills and Traits Assessment'),
        ],
      ),
    );
  }
}

class StepData {
  final String title;
  final Widget Function(
      GlobalKey<FormState>, StudentFormData, Function(StudentFormData)) content;

  StepData({
    required this.title,
    required this.content,
  });
}

// Step Indicator Widget
class StepIndicator extends StatelessWidget {
  final List<StepData> steps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final isActive = entry.key == currentStep;
        final isCompleted = entry.key < currentStep;

        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).primaryColor
                  : isActive
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Data Models and Step Widgets would follow...

class StudentFormData {
  String? name;
  String? studentClass;
  String? regNo;
  List<AttendanceRecord>? attendance;
  List<CognitiveScore>? cognitiveDomain;
  List<SkillRating>? psychomotorDomain;
  List<TraitRating>? affectiveDomain;
  Remarks? remarks;

  StudentFormData();

  factory StudentFormData.fromStudent(Student? student) {
    final data = StudentFormData();
    if (student != null) {
      data.name = student.name;
      data.studentClass = student.currentClass;
      data.regNo = student.regNo;
      data.attendance = student.attendance;
      data.cognitiveDomain = student.cognitiveDomain;
      data.psychomotorDomain = student.psychomotorDomain;
      data.affectiveDomain = student.affectiveDomain;
      data.remarks = student.remarks;
    }
    return data;
  }

  Student toStudent() {
    return Student(
      name: name ?? '',
      id: '',
      currentClass: studentClass ?? '',
      regNo: regNo ?? '',
      attendance: attendance ?? [],
      cognitiveDomain: cognitiveDomain ?? [],
      psychomotorDomain: psychomotorDomain ?? [],
      affectiveDomain: affectiveDomain ?? [],
      remarks: remarks ?? Remarks(classTeacher: '', principal: ''),
    );
  }
}

class _MultiStepDialogState extends State<MultiStepDialog> {
  int _currentStep = 0;
  final _formKeys = List.generate(5, (_) => GlobalKey<FormState>());
  late StudentFormData _formData;

  final List<StepData> _steps = [
    StepData(
      title: 'Basic Info',
      content: (formKey, data, onUpdate) => BasicInfoStep(
        formKey: formKey,
        data: data,
        onUpdate: onUpdate,
      ),
    ),
    StepData(
      title: 'Cognitive',
      content: (formKey, data, onUpdate) => CognitiveStep(
        formKey: formKey,
        data: data,
        onUpdate: onUpdate,
      ),
    ),
    StepData(
      title: 'Attendance',
      content: (formKey, data, onUpdate) => AttendanceStep(
        formKey: formKey,
        data: data,
        onUpdate: onUpdate,
      ),
    ),
    StepData(
      title: 'Skills & Traits',
      content: (formKey, data, onUpdate) => SkillsTraitsStep(
        formKey: formKey,
        data: data,
        onUpdate: onUpdate,
      ),
    ),
    StepData(
      title: 'Remarks',
      content: (formKey, data, onUpdate) => RemarksStep(
        formKey: formKey,
        data: data,
        onUpdate: onUpdate,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Step Indicator
            StepIndicator(
              steps: _steps,
              currentStep: _currentStep,
            ),
            const SizedBox(height: 24),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                child: _steps[_currentStep].content(
                  _formKeys[_currentStep],
                  _formData,
                  (newData) => setState(() => _formData = newData),
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton(
                      onPressed: _previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                      child: const Text('Previous'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(
                        _currentStep == _steps.length - 1 ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _formData = StudentFormData.fromStudent(widget.student);
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submitForm() {
    if (_formKeys.every((key) => key.currentState?.validate() ?? false)) {
      final student = _formData.toStudent();
      Navigator.pop(context, student);
    }
  }
}
*/