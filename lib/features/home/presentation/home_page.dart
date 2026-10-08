import 'package:flutter/material.dart';
import '../../game/presentation/game_page.dart';
import '../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازی کلمات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 80, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text(
                'به بازی کلمات خوش آمدید',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('اولین مرحله را شروع کن!'),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GamePage(stageId: 1)),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('شروع مرحله ۱'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
