import 'package:flutter/material.dart';

import 'screens/categories_screen.dart';
import 'theme/app_theme.dart';

// Dart starts here. runApp attaches our root widget to the screen.
void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const CategoriesScreen(),
    );
  }
}
