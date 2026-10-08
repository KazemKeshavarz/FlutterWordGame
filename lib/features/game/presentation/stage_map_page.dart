import 'package:flutter/material.dart';
import '../../../core/storage/game_progress_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../data/local_stage_repository.dart';
import 'game_page.dart';

class StageMapPage extends StatelessWidget {
  final LocalStageRepository repository;
  final GameProgressController progressController;

  const StageMapPage({
    super.key,
    required this.repository,
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
            title: const Text('نقشه مراحل'),
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
          body: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 125,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: repository.stages.length,
            itemBuilder: (context, index) {
              final stage = repository.stages[index];
              final locked = stage.id > progress.unlockedStage;
              final completed = progress.completedStages.contains(stage.id);

              return _StageTile(
                key: ValueKey('stage-${stage.id}-$completed-$locked'),
                stageId: stage.id,
                locked: locked,
                completed: completed,
                onTap: locked
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GamePage(
                              stageId: stage.id,
                              repository: repository,
                              progressController: progressController,
                            ),
                          ),
                        ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StageTile extends StatelessWidget {
  final int stageId;
  final bool locked;
  final bool completed;
  final VoidCallback? onTap;

  const _StageTile({
    super.key,
    required this.stageId,
    required this.locked,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed ? Colors.green : AppTheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: locked
            ? const []
            : [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: locked ? Colors.black12 : color.withOpacity(0.35),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  locked
                      ? Icons.lock_outline
                      : completed
                          ? Icons.check_circle_outline
                          : Icons.play_circle_outline,
                  size: 42,
                  color: locked ? Colors.grey : color,
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحله $stageId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locked ? 'قفل' : completed ? 'تکمیل شد' : 'شروع',
                  style: TextStyle(
                    fontSize: 12,
                    color: locked ? Colors.grey : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
