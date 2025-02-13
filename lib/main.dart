import 'package:ads_schools/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: dotenv.env['apiKey'] ?? '',
          authDomain: dotenv.env['authDomain'] ?? '',
          projectId: dotenv.env['projectId'] ?? '',
          storageBucket: dotenv.env['storageBucket']??'',
          messagingSenderId: dotenv.env['messagingSenderId']??'',
          appId: dotenv.env['appId']??'',
          measurementId: dotenv.env['measurementId']  ??''       ),
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
