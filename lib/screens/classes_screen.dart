import 'package:ads_schools/services/template_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/dialogs.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes Management'),
      ),
      body: Row(
        children: [
          // Classes List Panel
          Expanded(
            flex: 2,
            child: _buildClassesList(),
          ),
          // Class Details Panel
          if (_selectedClassId != null)
            Expanded(
              flex: 3,
              child: _buildClassDetails(_selectedClassId!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        label: const Text('New Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassDetails(String classId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final classData = SchoolClass.fromFirestore(snapshot.data!);

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  classData.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                subtitle: const Text('Class Structure'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editClass(classData),
                ),
              ),
              const Divider(),
              Expanded(child: _buildClassStructure(classId)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classDoc = classes[index];
            final classData = SchoolClass.fromFirestore(classDoc);

            return Card(
              color: _selectedClassId == classData.id
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
              child: ListTile(
                leading: const Icon(Icons.class_),
                title: Text(classData.name),
                subtitle: Text('Created: ${_formatDate(classData.createdAt)}'),
                selected: _selectedClassId == classData.id,
                onTap: () => setState(() => _selectedClassId = classData.id),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteClass(classData),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassStructure(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final sessionDoc = sessions[index];
            final session = Session.fromFirestore(sessionDoc);

            return ExpansionTile(
              title: Text(session.name),
              children: [_buildTerms(classId, sessionDoc.id)],
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectsList(String classId, String sessionId, String termId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .doc(termId)
          .collection('subjects')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: snapshot.data!.docs.map((subjectDoc) {
            final subject = Subject.fromFirestore(
                subjectDoc.data() as Map<String, dynamic>);
            return ListTile(
              leading: const Icon(Icons.subject),
              title: Text(subject.name),
              contentPadding: const EdgeInsets.only(left: 32),
              onTap: () => _showSubjectScores(
                classId,
                sessionId,
                termId,
                subjectDoc.id,
                subject.name,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTerms(String classId, String sessionId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .doc(sessionId)
          .collection('terms')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          shrinkWrap:
              true, // Ensures the ListView takes up only the required space
          children: snapshot.data!.docs.map((termDoc) {
            final term = Term.fromFirestore(termDoc);

            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ExpansionTile(
                title: Text(term.name),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _newSubject(
                    classId: classId,
                    sessionId: sessionId,
                    termId: termDoc.id,
                  ),
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('Performance Details'),
                    onTap: () =>
                        _showPerformanceDialog(classId, sessionId, termDoc.id),
                  ),
                  _buildSubjectsList(classId, sessionId, termDoc.id),
                  ListTile(
                    leading: const Icon(Icons.stars_outlined),
                    title: const Text('Traits and Skills'),
                    onTap: () =>
                        _showSkillsAndTraits(classId, sessionId, termDoc.id),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

//TODO: Implement a progress indicator for all the upload processes

  Future<void> _confirmDeleteClass(SchoolClass classData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete ${classData.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.deleteDocument('classes', classData.id);
    }
  }

  void _editClass(SchoolClass classData) {
    showDialog(
      context: context,
      builder: (context) => CreateClassDialog(classToEdit: classData),
    );
  }

// Helper Methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _newSubject({classId, sessionId, termId}) {
    showDialog(
      context: context,
      builder: (context) => CreateSubjectDialog(
        classId: classId,
        sessionId: sessionId,
        termId: termId,
      ),
    );
  }

  Future<void> _showCreateClassDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const CreateClassDialog(),
    );
  }

  Future<void> _showPerformanceDialog(
      String classId, String sessionId, String termId) async {
    showDialog(
      context: context,
      builder: (context) => PerformanceDialog(
          classId: classId, sessionId: sessionId, termId: termId),
    );
  }

  Future<void> _showSkillsAndTraits(
      String classId, String sessionId, String termId) async {
    showDialog(
        context: context,
        builder: (context) => SkillsAndTraitsDialog(
            classId: classId, sessionId: sessionId, termId: termId));
  }

  Future<void> _showSubjectScores(String classId, String sessionId,
      String termId, String subjectId, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name Scores'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .collection('sessions')
                .doc(sessionId)
                .collection('terms')
                .doc(termId)
                .collection('subjects')
                .doc(subjectId)
                .collection('scores')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final scores = snapshot.data!.docs
                  .map((doc) => SubjectScore(
                        regNo: doc.id,
                        ca1: (doc.data() as Map<String, dynamic>)['ca1'],
                        ca2: (doc.data() as Map<String, dynamic>)['ca2'],
                        exam: (doc.data() as Map<String, dynamic>)['exam'],
                        total: (doc.data() as Map<String, dynamic>)['total'],
                        average:
                            (doc.data() as Map<String, dynamic>)['average'],
                        position:
                            (doc.data() as Map<String, dynamic>)['position'],
                        grade: (doc.data() as Map<String, dynamic>)['grade'],
                        remark: (doc.data() as Map<String, dynamic>)['remark'],
                      ))
                  .toList();

              return Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            SubjectTemplate.generateSubjectTemplate(),
                        icon: const Icon(Icons.download),
                        label: const Text('Download Template'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _uploadSubjectScores(
                            classId, sessionId, termId, subjectId),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Scores'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Reg No')),
                            DataColumn(label: Text('CA1')),
                            DataColumn(label: Text('CA2')),
                            DataColumn(label: Text('Exam')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Average')),
                            DataColumn(label: Text('Position')),
                            DataColumn(label: Text('Grade')),
                            DataColumn(label: Text('Remark')),
                          ],
                          rows: scores.map((score) {
                            return DataRow(cells: [
                              DataCell(Text(score.regNo)),
                              DataCell(Text(score.ca1?.toString() ?? '-')),
                              DataCell(Text(score.ca2?.toString() ?? '-')),
                              DataCell(Text(score.exam?.toString() ?? '-')),
                              DataCell(Text(score.total?.toString() ?? '-')),
                              DataCell(Text(score.average?.toString() ?? '-')),
                              DataCell(Text(score.position?.toString() ?? '-')),
                              DataCell(Text(score.grade?.toString() ?? '-')),
                              DataCell(Text(score.remark?.toString() ?? '-')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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

  Future<void> _uploadSubjectScores(
      String classId, String sessionId, String termId, String subjectId) async {
    final scores = await SubjectTemplate.parseExcelFile();

    if (SubjectTemplate.validateScores(scores)) {
      await FirebaseService().uploadBatchSubjectScores(
        classId: classId,
        sessionId: sessionId,
        termId: termId,
        subjectId: subjectId,
        scores: scores,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores uploaded successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid scores in template')),
        );
      }
    }
  }
}
