import 'package:flutter/material.dart';

class LetterBoard extends StatefulWidget {
  final List<String> letters;
  final Set<int> selectedIndexes;
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
    widget.onSelectionChanged([index]);
  }

  void _move(Offset position) {
    if (_activeIndex == null) return;

    final index = _hitTest(position);
    if (index == null || widget.selectedIndexes.contains(index)) return;

    widget.onSelectionChanged([
      ...widget.selectedIndexes,
      index,
    ]);
  }

  void _end() {
    if (_activeIndex == null) return;
    _activeIndex = null;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _boardKey,
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _start(details.localPosition),
        onPanUpdate: (details) => _move(details.localPosition),
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(
            widget.letters.length,
            (index) => _buildLetter(index),
          ),
        ),
      ),
    );
  }

  Widget _buildLetter(int index) {
    return Builder(
      builder: (context) {
        _cacheCenter(index, context);

        final selected = widget.selectedIndexes.contains(index);

        return AnimatedScale(
          scale: selected ? 0.9 : 1,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            width: 72,
            height: 72,
            child: ElevatedButton(
              onPressed: () {
                if (selected) return;
                widget.onSelectionChanged([
                  ...widget.selectedIndexes,
                  index,
                ]);
                widget.onSelectionCompleted();
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: selected ? 2 : 5,
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              child: Text(
                widget.letters[index],
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
