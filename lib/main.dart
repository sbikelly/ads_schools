import 'package:ads_schools/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCepN5IF9hpBPvtWMyQciBn4pL7TYmtJXE",
          authDomain: "school-b50fb.firebaseapp.com",
          projectId: "school-b50fb",
          storageBucket: "school-b50fb.firebasestorage.app",
          messagingSenderId: "760268818180",
          appId: "1:760268818180:web:3c2d81209b8ec285943251",
          measurementId: "G-391GHP51GH"),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADS Schools',
      theme: ThemeData(
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
