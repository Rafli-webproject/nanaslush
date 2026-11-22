import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const NanaSlushApp());
}

class NanaSlushApp extends StatelessWidget {
  const NanaSlushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nana Slush',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
          child: Text(
            'Nana Slush\nUI Ready',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}