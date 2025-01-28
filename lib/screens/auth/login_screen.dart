import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/screens/home.dart';
import 'package:ads_schools/services/auth_service.dart';
import 'package:ads_schools/services/navigator_service.dart';
import 'package:ads_schools/services/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userService = Services().userService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSigning = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  late Future<void> _initializeFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('backgrounds/milky_way.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: FutureBuilder(
          future: _initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Responsive.isMobile(context)
                      ? _buildRightPanel()
                      : Row(
                          children: [
                            _buildLeftPanel(),
                            _buildRightPanel(),
                          ],
                        );
                },
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeFuture = _initialize();
  }

  Widget _buildAnonymousSignInButton() {
    return GestureDetector(
      onTap: _signInAnonymously,
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            "Sign In Anonymously",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Provider.of<NavigatorService>(context, listen: false)
          //     .navigateTo(Routes.resetPasswordScreen);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.transparent,
            ),
            child: const Text(
              "I forgot my password",
              style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: mainColor.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50.0),
            bottomLeft: Radius.circular(50.0),
          ),
          image: const DecorationImage(
            image: AssetImage('backgrounds/app-banner.png'),
            fit: BoxFit.cover,
            opacity: 0.7,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          //Provider.of<NavigatorService>(context, listen: false).navigateTo(Routes.signupScreen);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account?"),
            const SizedBox(width: 5),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: Responsive.isMobile(context)
              ? const BorderRadius.all(Radius.circular(50.0))
              : const BorderRadius.only(
                  topRight: Radius.circular(50.0),
                  bottomRight: Radius.circular(50.0),
                ),
        ),
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('app-logo.png'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please enter your credentials below to Login',
                      style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: mainColor),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Enter your Email/Username",
                        hintText: 'e.g., someone@something.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Email/Username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: 'password',
                          hintText: 'enter your password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter Password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(value: false, onChanged: (bool? value) {}),
                        const Text('Remember me'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 5),
                    _buildSignInButton(),
                    SizedBox(height: 5),
                    _buildAnonymousSignInButton(),
                    const SizedBox(height: 20),
                    _buildRegisterLink(),
                    const SizedBox(height: 10),
                    _buildForgotPasswordLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return GestureDetector(
      onTap: () {
        if (_formKey.currentState!.validate()) {
          _signInWithEmailAndPassword();
        }
      },
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _isSigning
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Sign In",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  /*
  Widget _buildSignInButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (_formKey.currentState!.validate()) {
            _signIn();
          }
        },
        child: Container(
          width: double.infinity,
          height: 45,
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isSigning
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
*/

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isSigning = false;
    });
    Provider.of<NavigatorService>(context, listen: false)
        .navigateTo(Routes.loginScreen);
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 1));
  }

/*
  void _signIn() async {
    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      User? user = await Provider.of<AuthService>(context, listen: false)
          .signIn(email, password);

      // Fetch the user document from Firestore
      final userInfo = await _userService.getById(user!.uid);

      if (userInfo != null) {
        String? role = userInfo.role;
        String? firstName = userInfo.firstName;
        String? otherNames = userInfo.otherNames;
        String? userEmail = userInfo.email;
        String? photo = userInfo.photo;

        // Save the role, userID, firstName, otherNames, email, and photo to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role!);
        await prefs.setString('userID', user.uid);
        await prefs.setString('firstName', firstName!);
        await prefs.setString(
            'otherNames', otherNames ?? ''); // In case otherNames is null
        await prefs.setString('email', userEmail!);
        await prefs.setString('photo', photo ?? ''); // In case photoUrl is null

        // Navigate to the appropriate dashboard based on the role
        switch (role) {
          case 'Admin':
            Provider.of<NavigatorService>(context, listen: false)
                .navigateTo(Routes.adminDashboard);
            break;
          case 'Student':
            Provider.of<NavigatorService>(context, listen: false)
                .navigateTo(Routes.studentDashboard);
            break;
          default:
            _handleError("User's Role not found");
            break;
        }
      } else {
        _handleError("User data not found");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not found'),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    } catch (e) {
      _handleError("Invalid Username/Password");
      if (kDebugMode) {
        print("Sign in Error: $e");
      }
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }
*/
  void _signInAnonymously() async {
    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      User? user = await authService.signInAnonymously();
      // Fetch the user document from Firestore
      //final userInfo = await _userService.getById(user!.uid);
      // Handle successful anonymous sign-in
      if (user != null) {
        /*
        String? role = userInfo.role;
        String? firstName = userInfo.firstName;
        String? otherNames = userInfo.otherNames;
        String? userEmail = userInfo.email;
        String? photo = userInfo.photo;

        // Save the role, userID, firstName, otherNames, email, and photo to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role!);
        await prefs.setString('userID', user.uid);
        await prefs.setString('firstName', firstName!);
        await prefs.setString(
            'otherNames', otherNames ?? ''); // In case otherNames is null
        await prefs.setString('email', userEmail!);
        await prefs.setString('photo', photo ?? ''); // In case photoUrl is null

        // Navigate to the appropriate dashboard based on the role
        switch (role) {
          case 'Admin':
            Provider.of<NavigatorService>(context, listen: false)
                .navigateTo(Routes.adminDashboard);
            break;
          case 'Student':
            Provider.of<NavigatorService>(context, listen: false)
                .navigateTo(Routes.studentDashboard);
            break;
          default:
            _handleError("User's Role not found");
            break;
        }
        */
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        _handleError("User data not found");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not found'),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    } catch (e) {
      _handleError("Invalid Username/Password");
      setState(() {
        _errorMessage = "Failed to sign in anonymously.";
      });
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }

  void _signInWithEmailAndPassword() async {
    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn(_emailController.text, _passwordController.text);
      // Handle successful sign-in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to sign in. Please try again.";
      });
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }
}
