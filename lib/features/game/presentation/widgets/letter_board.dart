import 'package:flutter/material.dart';
import '../../../../core/audio/game_feedback.dart';

class LetterBoard extends StatefulWidget {
  final List<String> letters;
  final List<int> selectedIndexes;
  final ValueChanged<List<int>> onSelectionChanged;
  final VoidCallback onSelectionCompleted;

  const LetterBoard({
    super.key,
    required this.letters,
    required this.selectedIndexes,
    required this.onSelectionChanged,
    required this.onSelectionCompleted,
  });

  @override
  State<LetterBoard> createState() => _LetterBoardState();
}

class _LetterBoardState extends State<LetterBoard> {
  final GlobalKey _boardKey = GlobalKey();
  final Map<int, Offset> _centers = {};
  int? _activeIndex;
  Offset? _dragPosition;

  RenderBox? get _boardBox {
    final renderObject = _boardKey.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
  }

  int? _hitTest(Offset position) {
    for (final entry in _centers.entries) {
      if ((entry.value - position).distance <= 38) {
        return entry.key;
      }
    }
    return null;
  }

  void _start(Offset position) {
    final index = _hitTest(position);
    if (index == null) return;

    _activeIndex = index;
    _dragPosition = position;
    widget.onSelectionChanged([index]);
    GameFeedback.letterSelected();
    setState(() {});
  }

  void _move(Offset position) {
    if (_activeIndex == null) return;

    _dragPosition = position;

    final index = _hitTest(position);
    if (index != null &&
        widget.selectedIndexes.length > 1 &&
        index == widget.selectedIndexes[widget.selectedIndexes.length - 2]) {
      widget.onSelectionChanged(
        widget.selectedIndexes.sublist(0, widget.selectedIndexes.length - 1),
      );
      GameFeedback.letterSelected();
    } else if (index != null && !widget.selectedIndexes.contains(index)) {
      widget.onSelectionChanged([
        ...widget.selectedIndexes,
        index,
      ]);
      GameFeedback.letterSelected();
    }

    setState(() {});
  }

  void _end() {
    if (_activeIndex == null) return;

    _activeIndex = null;
    _dragPosition = null;
    setState(() {});
    widget.onSelectionCompleted();
  }

  void _cacheCenter(int index, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final box = context.findRenderObject();
      final board = _boardBox;

      if (box is! RenderBox || board == null) return;

      final globalCenter = box.localToGlobal(
        box.size.center(Offset.zero),
      );
      _centers[index] = board.globalToLocal(globalCenter);
    });
  }

  void _selectByTap(int index) {
    if (widget.selectedIndexes.contains(index)) return;

    widget.onSelectionChanged([
      ...widget.selectedIndexes,
      index,
    ]);
    GameFeedback.letterSelected();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      key: _boardKey,
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _start(details.localPosition),
        onPanUpdate: (details) => _move(details.localPosition),
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: _boardHeight(constraints.maxWidth),
            child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _SelectionPathPainter(
                  centers: _centers,
                  selectedIndexes: widget.selectedIndexes,
                  dragPosition: _activeIndex == null ? null : _dragPosition,
                  color: color,
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(
                  widget.letters.length,
                  (index) => _buildLetter(index),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  double _boardHeight(double width) {
    const itemSize = 72.0;
    const spacing = 16.0;
    final columns = ((width + spacing) / (itemSize + spacing)).floor().clamp(1, 5);
    final rows = (widget.letters.length / columns).ceil();
    return rows * itemSize + (rows - 1) * spacing + 16;
  }

  Widget _buildLetter(int index) {
    return Builder(
      builder: (context) {
        _cacheCenter(index, context);

        final selected = widget.selectedIndexes.contains(index);
        final color = Theme.of(context).colorScheme.primary;

        return SizedBox(
          width: 72,
          height: 72,
          child: AnimatedScale(
            scale: selected ? 0.88 : 1,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.20),
                          color.withOpacity(0.05),
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(selected ? 0.28 : 0.12),
                    blurRadius: selected ? 18 : 8,
                    spreadRadius: selected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
              onPressed: () => _selectByTap(index),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: selected ? 1 : 5,
                animationDuration: const Duration(milliseconds: 120),
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                  fontSize: selected ? 32 : 29,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  widget.letters[index],
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionPathPainter extends CustomPainter {
  final Map<int, Offset> centers;
  final List<int> selectedIndexes;
  final Offset? dragPosition;
  final Color color;

  const _SelectionPathPainter({
    required this.centers,
    required this.selectedIndexes,
    required this.dragPosition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndexes.isEmpty) return;

    final linePaint = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final points = selectedIndexes
        .map((index) => centers[index])
        .whereType<Offset>()
        .toList();

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (dragPosition != null) {
      path.lineTo(dragPosition!.dx, dragPosition!.dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPathPainter oldDelegate) {
    return oldDelegate.selectedIndexes != selectedIndexes ||
        oldDelegate.dragPosition != dragPosition ||
        oldDelegate.color != color;
  }
}
