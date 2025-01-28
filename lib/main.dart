import 'package:ads_schools/error_screen.dart';
import 'package:ads_schools/helpers/constants.dart';
import 'package:ads_schools/screens/auth/login_screen.dart';
import 'package:ads_schools/screens/dashboard/dashboard_home.dart';
import 'package:ads_schools/services/auth_service.dart';
import 'package:ads_schools/services/navigator_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load();

    // Initialize Firebase for web
    await _initializeFirebase();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log errors and show a fallback widget

    runApp(ErrorScreen());
    debugPrint("Error initializing Firebase: $e");
    debugPrint("StackTrace: $stackTrace");
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['API_KEY']!,
          authDomain: dotenv.env['AUTH_DOMAIN']!,
          projectId: dotenv.env['PROJECT_ID']!,
          storageBucket: dotenv.env['STORAGE_BUCKET']!,
          messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
          appId: dotenv.env['APP_ID']!,
          measurementId: dotenv.env['MEASUREMENT_ID']!,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GlobalDataProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthService()), // Provides authentication service
        Provider(
            create: (_) => NavigatorService()), // Provides navigation service
      ],
      child: MaterialApp(
        title: 'ADS Schools',
        theme: ThemeData(
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        home: MainHome(),
        // const LoginScreen(), // Change to AuthWrapper for conditional navigation
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

  @override
  Widget build(BuildContext context) {
    // Set the system UI overlay style to have a transparent status bar.
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GlobalDataProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthService()), // Provides authentication service
        Provider(
            create: (_) => NavigatorService()), // Provides navigation service
      ],
      child: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError) {
            debugPrint('Something went wrong! ');
            debugPrint('${snapshot.error}');
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Something went wrong!',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => const MyApp()),
                                );
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Consumer<NavigatorService>(
              builder: (context, navigatorService, child) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'ADS Schools',
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.deepPurple,
                        brightness: Brightness.light),
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    textTheme: const TextTheme(
                      headlineMedium:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      bodyLarge: TextStyle(fontSize: 14),
                    ),
                    useMaterial3: true,
                  ),
                  navigatorKey: navigatorService.navigatorKey,
                  // Navigate to the initial route based on the device type and auth state
                  initialRoute: Responsive.isMobile(context)
                      ? Routes.loginScreen
                      : Routes.loginScreen,
                  routes: {
                    Routes.loginScreen: (context) => const LoginScreen(),
                    //Routes.adminDashboard: (context) => const AdminDashboard(),
                    //Routes.studentDashboard: (context) =>const StudentDashboard()
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _initializeApp() async {
    // Simulate a delay for app initialization.
    await Future.delayed(const Duration(seconds: 1));
  }
}
