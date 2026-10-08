import 'package:flutter/material.dart';
import 'core/storage/game_progress_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/game/data/local_stage_repository.dart';
import 'features/home/presentation/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final stageRepository = LocalStageRepository();
  await stageRepository.load();
  final progressController = await GameProgressController.create();

  runApp(FlutterWordGameApp(
    stageRepository: stageRepository,
    progressController: progressController,
  ));
}

class FlutterWordGameApp extends StatelessWidget {
  final LocalStageRepository stageRepository;
  final GameProgressController progressController;

  const FlutterWordGameApp({
    super.key,
    required this.stageRepository,
    required this.progressController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بازی کلمات',
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(
          stageRepository: stageRepository,
          progressController: progressController,
        ),
      ),
    );
  }
}
