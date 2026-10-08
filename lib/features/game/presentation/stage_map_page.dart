import 'dart:math' as math;
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
            title: const Text('نقشه ماجراجویی'),
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background,
                  AppTheme.background.withOpacity(0.72),
                ],
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
              itemCount: repository.stages.length,
              itemBuilder: (context, index) {
                final stage = repository.stages[index];
                final locked = stage.id > progress.unlockedStage;
                final completed = progress.completedStages.contains(stage.id);
                final stars = progress.starsFor(stage.id);
                final side = index.isEven ? Alignment.centerRight : Alignment.centerLeft;

                return _MapStage(
                  stageId: stage.id,
                  stars: stars,
                  locked: locked,
                  completed: completed,
                  side: side,
                  showConnector: index < repository.stages.length - 1,
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
          ),
        );
      },
    );
  }
}

class _MapStage extends StatelessWidget {
  final int stageId;
  final int stars;
  final bool locked;
  final bool completed;
  final Alignment side;
  final bool showConnector;
  final VoidCallback? onTap;

  const _MapStage({
    required this.stageId,
    required this.stars,
    required this.locked,
    required this.completed,
    required this.side,
    required this.showConnector,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = completed ? Colors.green : AppTheme.primary;
    final center = side == Alignment.centerRight
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return SizedBox(
      height: 142,
      child: Stack(
        children: [
          if (showConnector)
            Positioned(
              top: 76,
              bottom: 0,
              left: side == Alignment.centerRight ? 54 : null,
              right: side == Alignment.centerLeft ? 54 : null,
              child: CustomPaint(
                size: const Size(90, 80),
                painter: _PathPainter(
                  reverse: side == Alignment.centerLeft,
                  active: !locked,
                ),
              ),
            ),
          Align(
            alignment: center,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(42),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked ? Colors.grey.shade200 : Colors.white,
                    border: Border.all(
                      color: locked ? Colors.grey.shade400 : activeColor,
                      width: 4,
                    ),
                    boxShadow: locked
                        ? const []
                        : [
                            BoxShadow(
                              color: activeColor.withOpacity(0.20),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        locked
                            ? Icons.lock_rounded
                            : completed
                                ? Icons.check_rounded
                                : Icons.play_arrow_rounded,
                        size: 34,
                        color: locked ? Colors.grey : activeColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$stageId',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: locked ? Colors.grey : AppTheme.dark,
                        ),
                      ),
                      if (!locked)
                        Text(
                          stars == 0 ? 'شروع' : '⭐' * stars,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final bool reverse;
  final bool active;

  const _PathPainter({
    required this.reverse,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = active ? AppTheme.primary.withOpacity(0.35) : Colors.black12;

    final path = Path();
    if (reverse) {
      path.moveTo(size.width * 0.85, 0);
      path.cubicTo(
        size.width * 0.15,
        size.height * 0.20,
        size.width * 0.15,
        size.height * 0.80,
        size.width * 0.85,
        size.height,
      );
    } else {
      path.moveTo(size.width * 0.15, 0);
      path.cubicTo(
        size.width * 0.85,
        size.height * 0.20,
        size.width * 0.85,
        size.height * 0.80,
        size.width * 0.15,
        size.height,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.reverse != reverse || oldDelegate.active != active;
}
