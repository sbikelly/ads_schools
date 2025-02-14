import 'package:ads_schools/screens/attendance/attendance_dash.dart';
import 'package:ads_schools/screens/auth/login_screen.dart';
import 'package:ads_schools/screens/classes_screen.dart';
import 'package:ads_schools/screens/students.dart';
import 'package:ads_schools/screens/subjects.dart';
import 'package:ads_schools/services/auth_service.dart';
import 'package:ads_schools/widgets/my_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class MainHome extends StatelessWidget {
  const MainHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(builder: (context, authService, _) {
      if (authService.isAuthenticated) {
        return const LoginScreen();
      }

      return Scaffold(
        appBar: MyAppBar(isLoading: false, title: 'Home',),
        body: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 4;
            double crossAxisSpacing = 64;
            double mainAxisSpacing = 64;

            if (constraints.maxWidth < 1200) {
              crossAxisCount = 3;
              crossAxisSpacing = 32;
              mainAxisSpacing = 32;
            }
            if (constraints.maxWidth < 800) {
              crossAxisCount = 2;
              crossAxisSpacing = 16;
              mainAxisSpacing = 16;
            }
            if (constraints.maxWidth < 600) {
              crossAxisCount = 1;
              crossAxisSpacing = 8;
              mainAxisSpacing = 8;
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildCard(
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
                      );
                    case 1:
                      return _buildCard(
                        context,
                        icon: Icons.people,
                        title: "Students",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StudentsScreen()),
                          );
                        },
                      );
                    case 2:
                      return _buildCard(
                        context,
                        icon: Icons.book_online,
                        title: "Subjects",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SubjectScreen()),
                          );
                        },
                      );
                    case 3:
                      return _buildCard(
                        context,
                        icon: Icons.travel_explore,
                        title: "Attendance",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AttendanceAdminDashboard()),
                          );
                        },
                      );
                    case 4:
                      return _buildCard(
                        context,
                        icon: Icons.report,
                        title: "Reports",
                        onTap: () {},
                      );
                    case 5:
                      return _buildCard(
                        context,
                        icon: Icons.bookmark,
                        title: "Templates",
                        onTap: () {},
                      );
                    case 6:
                      return _buildCard(
                        context,
                        icon: Icons.bar_chart,
                        title: "Analytics",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AttendanceAdminDashboard()),
                          );
                        },
                      );
                    case 7:
                      return _buildCard(
                        context,
                        icon: Icons.settings,
                        title: "Settings",
                        onTap: () {},
                      );
                    default:
                      return Container();
                  }
                },
              ),
            );
          },
        ),
      );
    });
  }
}