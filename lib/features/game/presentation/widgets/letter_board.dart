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
  final Map<int, Offset> _centers = {};
  int? _activeIndex;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _start(details.localPosition),
          onPanUpdate: (details) => _move(details.localPosition),
          onPanEnd: (_) => _end(),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(widget.letters.length, (index) {
              return _buildLetter(index);
            }),
          ),
        );
      },
    );
  }

  Widget _buildLetter(int index) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: 72,
          height: 72,
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final position = box.localToGlobal(
                  Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                );

                final boardBox =
                    context.findAncestorRenderObjectOfType<RenderBox>();
                if (boardBox != null) {
                  _centers[index] = boardBox.globalToLocal(position);
                }
              });

              final selected = widget.selectedIndexes.contains(index);

              return AnimatedScale(
                scale: selected ? 0.9 : 1,
                duration: const Duration(milliseconds: 100),
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
              );
            },
          ),
        );
      },
    );
  }
}
