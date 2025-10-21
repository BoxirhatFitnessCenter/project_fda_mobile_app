import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'services/background_location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using google-services.json on Android.
  // Set up credentials: Place your google-services.json in android/app (see README).
  // For web, we pass FirebaseOptions directly.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDsvgfLJ_D-jCDF0M2ST61C5lq7kWVu9ZI",
      appId: "1:691497497614:web:9b11183b11c27ea4deb85f",
      messagingSenderId: "691497497614",
      projectId: "projectfda-59d48",
      authDomain: "projectfda-59d48.firebaseapp.com",
      databaseURL: "https://projectfda-59d48-default-rtdb.asia-southeast1.firebasedatabase.app/",
      storageBucket: "projectfda-59d48.firebasestorage.app",
    ),
  );
  
  // Initialize background service
  await BackgroundLocationService.initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FDA Location App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (_) => const LoginPage(),
      },
      home: const SplashPage(),
    );
  }
}
