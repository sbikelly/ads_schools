// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/helpers/file_helper.dart';
import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/screens/profile_screen.dart';
import 'package:ads_schools/services/auth_service.dart';
import 'package:ads_schools/services/navigator_service.dart';

/// A dialog widget to display error messages with a consistent style

class ErrorDialog extends StatelessWidget {
  final String errorCode;
  final String message;
  final VoidCallback? onClose;

  const ErrorDialog({
    super.key,
    required this.errorCode,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.dangerous, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          const Text('Error!', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Code: $errorCode',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onClose?.call();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String errorCode,
    required String message,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        errorCode: errorCode,
        message: message,
        onClose: onClose,
      ),
    );
  }
}

/// A dialog widget to display loading states with a consistent style
class LoadingDialog extends StatelessWidget {
  final String subtitle;
  final Color? progressColor;

  const LoadingDialog({
    super.key,
    required this.subtitle,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title:
            Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: progressColor ?? mainColor),
            const SizedBox(height: 24),
            Text(
              'Please wait while we $subtitle...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String subtitle,
    Color? progressColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        subtitle: subtitle,
        progressColor: progressColor,
      ),
    );
  }
}

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final bool isLoading;

  const MyAppBar({
    super.key, 
    required this.isLoading, this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  UserModel? userModel;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserInfo();
    if (mounted) {
      setState(() {
        userModel = userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: _scaffoldKey,
      title: Text(widget.title??'', style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              //fontFamily: 'Bree_Serif',
            ),),
      /*Row(
        children: [
          Image.asset(
            'assets/app-logo.png',
            height: 50,
            width: 50,
          ),
          const SizedBox(width: 8),
          const Text(
            'F.C.E, Pankshin',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Bree_Serif',
            ),
          ),
        ],
      ),*/
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: mainColor,
      actions: [
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Handle notifications
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'profile':
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                break;
              case 'change_password':
                // Implement password change dialog
                break;
              case 'logout':
                await Provider.of<AuthService>(context, listen: false).signOut();
                if (mounted) {
                  Provider.of<NavigatorService>(context, listen: false)
                      .navigateTo(Routes.loginScreen);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 8),
                  Text('Change Password'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  userModel?.firstName ?? 'Guest',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: userModel?.photo != null
                      ? NetworkImage(userModel!.photo!)
                      : const AssetImage('images/avatar.png') as ImageProvider,
                ),
              ],
            ),
          ),
        ),
      ],
      leading: Responsive.isMobile(context)
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
    );
  }
}

class MySearchBar extends StatelessWidget {
  final TextEditingController _searchController;

  const MySearchBar({
    super.key,
    required TextEditingController controller,
  }) : _searchController = controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search here',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}

class PhotoSelector extends StatelessWidget {
  final String? photo;
  final Function(String?) onPhotoSelected;

  const PhotoSelector(
      {super.key, required this.photo, required this.onPhotoSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await FileHelper.selectPhoto((selectedPhotoUrl) {
            if (selectedPhotoUrl != null) {
              onPhotoSelected(selectedPhotoUrl);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File size exceeds limit')),
              );
            }
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An error occurred while selecting the photo')),
          );
        }
      },
      child: Container(
        width: 150.0,
        height: 150.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: mainColor, width: 5.0),
        ),
        child: CircleAvatar(
          radius: 75,
          backgroundImage: photo == null
              ? const AssetImage('images/avatar.png') as ImageProvider
              : NetworkImage(photo!),
          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class QuickActionBtn extends StatelessWidget {
  final IconData icon;

  final String title;
  final VoidCallback onTap;
  const QuickActionBtn({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class SuccessDialog {
  static void show({
    required BuildContext context,
    required String message,
    Widget? additionalContent,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (additionalContent != null) ...[
              const SizedBox(height: 16),
              additionalContent,
            ],
          ],
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
}
