import 'dart:math';
import 'package:flutter/material.dart';

/// افکت سبک و بدون وابستگی برای لحظه پیدا شدن کلمه.
class WordSuccessEffect extends StatefulWidget {
  final String word;
  final int combo;

  const WordSuccessEffect({
    super.key,
    required this.word,
    required this.combo,
  });

  @override
  State<WordSuccessEffect> createState() => _WordSuccessEffectState();
}

class _WordSuccessEffectState extends State<WordSuccessEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = List.generate(
    18,
    (index) => _Particle(index),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_controller.value);
          return Stack(
            children: [
              ..._particles.map((particle) {
                final angle = particle.angle;
                final distance = 18 + particle.distance * t;
                final x = cos(angle) * distance;
                final y = sin(angle) * distance;
                final opacity = 1 - t;
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(x, y),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: particle.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Center(
                child: Transform.scale(
                  scale: 0.72 + (0.28 * Curves.elasticOut.transform(
                    min(1, _controller.value * 1.35),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('آفرین!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        if (widget.combo > 1) ...[
                          const SizedBox(height: 2),
                          Text('🔥 زنجیره ${widget.combo}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _Particle(int index)
      : angle = (index / 18) * pi * 2,
        distance = 55 + ((index * 17) % 70),
        size = 5 + ((index * 3) % 6),
        color = Colors.primaries[index % Colors.primaries.length];
}
