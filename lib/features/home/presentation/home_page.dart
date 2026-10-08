import 'package:flutter/material.dart';
import '../../../core/storage/game_progress_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/data/local_stage_repository.dart';
import '../../game/presentation/stage_map_page.dart';

class HomePage extends StatelessWidget {
  final LocalStageRepository stageRepository;
  final GameProgressController progressController;

  const HomePage({
    super.key,
    required this.stageRepository,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressController,
      builder: (context, _) {
        final progress = progressController.progress;

        return Scaffold(
          appBar: AppBar(
            title: const Text('بازی کلمات'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        progress.coins.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                  Text('مرحله ${progress.unlockedStage} آماده است'),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StageMapPage(
                            repository: stageRepository,
                            progressController: progressController,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('نقشه مراحل'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StageMapPage(
                          repository: stageRepository,
                          progressController: progressController,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('ادامه بازی'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
