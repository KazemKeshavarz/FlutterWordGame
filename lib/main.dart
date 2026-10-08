import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterWordGameApp());
}

class FlutterWordGameApp extends StatelessWidget {
  const FlutterWordGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بازی کلمات',
      theme: AppTheme.light,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}
