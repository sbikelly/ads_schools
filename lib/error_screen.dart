import 'package:ads_schools/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  _ErrorScreenState createState() {
    return _ErrorScreenState();
  }
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _isLoading = false; // Tracks loading state
  String? _errorMessage =
      'please wait while we re-establish to Firebase'; // Displays any errors during retry

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 100,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Initialization Failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We were unable to initialize the app. Please check your connection and try again.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _retryInitialization,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => showContactSupportDialog(context),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'For assistance, please contact support at:\n\nEmail: support@adschools.com\nPhone: +1239031316499',
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

  Future<void> _retryInitialization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Attempt to initialize Firebase
      await Firebase.initializeApp();
      // Navigate to the main app if successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const MyApp()), // Replace with your actual app screen
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to initialize Firebase. Please try again.";
      });
    }
  }
}
