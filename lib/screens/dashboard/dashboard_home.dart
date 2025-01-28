import 'package:ads_schools/screens/attendance/attendance_dash.dart';
import 'package:ads_schools/screens/classes_screen.dart';
import 'package:ads_schools/screens/students.dart';
import 'package:ads_schools/screens/subjects.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/material.dart';

class MainHome extends StatelessWidget {
  const MainHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(isLoading: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 90),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 64,
          mainAxisSpacing: 64,
          children: [
            _buildCard(
              context,
              icon: Icons.room,
              title: "Classes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClassesScreen()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.people,
              title: "Students",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentsScreen()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.book_online,
              title: "Subjects",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubjectScreen()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.travel_explore,
              title: "Attendance",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AttendanceAdminDashboard()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.report,
              title: "Reports",
              onTap: () {},
            ),
            _buildCard(
              context,
              icon: Icons.bookmark,
              title: "Templates",
              onTap: () {},
            ),
            _buildCard(
              context,
              icon: Icons.bar_chart,
              title: "Analytics",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AttendanceAdminDashboard()),
                );
              },
            ),
            _buildCard(
              context,
              icon: Icons.settings,
              title: "Settings",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            SizedBox(height: 10),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
