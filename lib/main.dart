import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated configuration for emma-a3cbd
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully for emma-a3cbd');
  } catch (e) {
    debugPrint('Firebase initialization notice: $e (Falling back to in-memory simulator)');
  }

  runApp(
    const ProviderScope(
      child: EmmaApp(),
    ),
  );
}

class EmmaApp extends StatelessWidget {
  const EmmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emma - Waste Drive & Upcycling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
