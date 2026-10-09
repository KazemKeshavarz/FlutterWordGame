import 'package:flutter/material.dart';
import '../../../core/storage/game_progress_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/data/local_stage_repository.dart';
import '../../game/presentation/game_page.dart';
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
        final totalStages = stageRepository.stages.length;
        final completedCount = progress.completedStages.length;
        final unlockedStage = totalStages == 0 ? 1 : progress.unlockedStage.clamp(1, totalStages).toInt();
        final totalStars = progress.stageStars.values.fold<int>(0, (sum, stars) => sum + stars);

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
                      Text(progress.coins.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppTheme.primary, AppTheme.dark],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 62),
                        const SizedBox(height: 16),
                        const Text('آماده‌ای قهرمان؟', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('مرحله $unlockedStage از $totalStages منتظر توست', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.dark, padding: const EdgeInsets.symmetric(vertical: 15)),
                            onPressed: totalStages == 0 ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(stageId: unlockedStage, repository: stageRepository, progressController: progressController))),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('ادامه بازی', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.flag_rounded, label: 'مرحله‌ها', value: '$completedCount / $totalStages', color: AppTheme.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.star_rounded, label: 'ستاره‌ها', value: '$totalStars', color: Colors.amber.shade800)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(icon: Icons.monetization_on_rounded, label: 'سکه‌ها', value: '${progress.coins}', color: Colors.orange.shade800)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StageMapPage(repository: stageRepository, progressController: progressController))),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('مشاهده نقشه مراحل'),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('هر کلمه، یک قدم به قهرمانی نزدیک‌ترت می‌کند ✨', style: TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.black.withOpacity(0.05)), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}
