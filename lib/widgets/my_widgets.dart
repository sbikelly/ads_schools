import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/helpers/file_helper.dart';
import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String errorCode;
  final String message;

  const ErrorDialog({
    super.key,
    required this.errorCode,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Text('Error!'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'An error occurred',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              'Error Code: $errorCode',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Static method to show the error dialog without requiring a direct instance.
  static void show({
    required BuildContext context,
    required String errorCode,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        errorCode: errorCode,
        message: message,
      ),
    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;

  const MyAppBar({
    super.key,
    required this.isLoading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/app-logo.png',
            height: 50,
            width: 50,
          ),
          const SizedBox(width: 8),
          Text(
            'Adokweb Solutions',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Bree_Serif',
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: mainColor,
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Handle notifications
          },
        ), /*
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                setState(() {
                  _currentRoute = 'user';
                });
                break;
              case 'change_password':
                showDialog(
                  context: context,
                  builder: (context) => ChangePasswordDialog(),
                );
                break;
              case 'logout':
                Provider.of<AuthService>(context, listen: false).signOut();
                Provider.of<NavigatorService>(context, listen: false)
                    .navigateTo(Routes.loginScreen);
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
          child: Row(
            children: [
              Text(
                /*userModel?.firstName ?? */'No name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 5),/*
              CircleAvatar(
                backgroundImage: userModel?.photo != null
                    ? NetworkImage(userModel!.photo.toString())
                    : const AssetImage('images/avatar.png') as ImageProvider,
              ),*/
              const SizedBox(width: 8),
            ],
          ),
        ),
      */
      ],
      leading: Responsive.isMobile(context)
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // _scaffoldKey.currentState?.openDrawer();
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
