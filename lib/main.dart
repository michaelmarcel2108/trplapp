import "package:flutter/material.dart";

import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart'; 
import 'screens/profile_screen.dart';
import 'screens/upload_foto_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Routing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      
      initialRoute: '/',

      routes: {
        '/': (context) => const MainNavigationScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/upload_foto':(context) => const UploadFoto(),
      },
    );
  }
}