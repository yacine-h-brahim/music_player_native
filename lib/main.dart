import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Clone',
      theme: ThemeData.dark().copyWith(
          tabBarTheme: const TabBarTheme(unselectedLabelColor: Colors.white),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            titleTextStyle: TextStyle(color: Colors.white),
            backgroundColor: Colors.black,
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[800]!),
          primaryColor: Colors.green[800]),
      home: const HomePage(),
    );
  }
}
