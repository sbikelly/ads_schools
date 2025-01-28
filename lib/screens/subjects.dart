import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/firebase_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:ads_schools/widgets/subject_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final _subjectsCollection = FirebaseFirestore.instance.collection('subjects');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(isLoading: false),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => _openSubjectDialog(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _subjectsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No subjects found.'));
          }

          final subjects = snapshot.data!.docs
              .map((doc) => Subject.fromFirestore(doc))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return _buildSubjectCard(subjects[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Divider(),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                subject.materialUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _viewMaterial(subject.materialUrl),
                        tooltip: 'View Material',
                      )
                    : SizedBox.shrink(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _openSubjectDialog(subject: subject),
                      tooltip: 'edit subject',
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSubject(subject.id!),
                      tooltip: 'delete subject',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(String subjectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.deleteDocument('subjects', subjectId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting subject: $e')),
        );
      }
    }
  }

  Future<void> _openSubjectDialog({Subject? subject}) async {
    List<Subject>? initialSubjects = [];
    if (subject != null) {
      initialSubjects.add(subject);
    }
    final result = await showDialog(
      context: context,
      builder: (context) =>
          CreateEditSubjectsDialog(initialSubjects: initialSubjects),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(subject == null ? 'Subject added!' : 'Subject updated!'),
        ),
      );
    }
  }

  void _viewMaterial(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No material available for this subject.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open material.')),
      );
    }
  }
}
