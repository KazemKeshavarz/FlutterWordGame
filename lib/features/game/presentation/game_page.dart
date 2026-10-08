import 'package:flutter/material.dart';
import '../data/local_stage_repository.dart';
import '../domain/stage.dart';
import '../../../core/storage/game_progress_controller.dart';
import 'widgets/letter_board.dart';

class GamePage extends StatefulWidget {
  final int stageId;
  final LocalStageRepository repository;
  final GameProgressController progressController;

  const GamePage({
    super.key,
    required this.stageId,
    required this.repository,
    required this.progressController,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final Stage _stage;
  List<int> _selectedIndexes = [];
  final Set<String> _foundWords = {};
  bool _completionHandled = false;
  final Map<String, Set<int>> _revealedLetters = {};
  static const int _hintCost = 10;

  @override
  void initState() {
    super.initState();
    _stage = widget.repository.getStage(widget.stageId);
  }

  String get _currentWord =>
      _selectedIndexes.map((i) => _stage.letters[i]).join();

  void _onSelectionChanged(List<int> indexes) {
    setState(() => _selectedIndexes = indexes);
  }

  void _onSelectionCompleted() => _submitWord();

  void _removeLastLetter() {
    if (_selectedIndexes.isEmpty) return;
    setState(() {
      _selectedIndexes = List<int>.from(_selectedIndexes)..removeLast();
    });
  }

  void _clearSelection() {
    if (_selectedIndexes.isEmpty) return;
    setState(() => _selectedIndexes = []);
  }

  Future<void> _useHint() async {
    String? targetWord;
    int? targetIndex;

    for (final word in _stage.words) {
      if (_foundWords.contains(word)) continue;

      final revealed = _revealedLetters[word] ?? <int>{};
      for (var i = 0; i < word.length; i++) {
        if (!revealed.contains(i)) {
          targetWord = word;
          targetIndex = i;
          break;
        }
      }

      if (targetWord != null) break;
    }

    if (targetWord == null || targetIndex == null) {
      _showMessage('همه کلمه‌ها پیدا شده‌اند.');
      return;
    }

    final success = await widget.progressController.spendCoins(_hintCost);
    if (!success) {
      _showMessage('برای استفاده از راهنما حداقل $_hintCost سکه لازم است.');
      return;
    }

    setState(() {
      final revealed = Set<int>.from(_revealedLetters[targetWord!] ?? const {});
      revealed.add(targetIndex!);
      _revealedLetters[targetWord!] = revealed;
    });

    _showMessage('یک حرف از «$targetWord» با $_hintCost سکه نمایش داده شد.');
  }

  Future<void> _submitWord() async {
    final word = _currentWord;
    if (word.isEmpty) return;

    if (!_stage.words.contains(word)) {
      _showMessage('این کلمه در این مرحله وجود ندارد.');
      _clearSelection();
      return;
    }

    if (_foundWords.contains(word)) {
      _showMessage('این کلمه را قبلاً پیدا کرده‌ای.');
      _clearSelection();
      return;
    }

    setState(() {
      _foundWords.add(word);
      _selectedIndexes = [];
    });

    _showMessage('آفرین! «$word» پیدا شد 🎉');

    if (_foundWords.length == _stage.words.length && !_completionHandled) {
      _completionHandled = true;
      await widget.progressController.completeStage(
        _stage.id,
        maxStageId: widget.repository.stages.last.id,
      );
      Future.delayed(const Duration(milliseconds: 400), _showStageCompleted);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _showStageCompleted() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('مرحله کامل شد 🎉'),
        content: const Text('۲۰ سکه جایزه گرفتی و مرحله بعدی باز شد.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ادامه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _stage.words.isEmpty
        ? 0.0
        : _foundWords.length / _stage.words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحله ${_stage.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_foundWords.length}/${_stage.words.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _stage.words.map((word) {
                      final found = _foundWords.contains(word);
                      final revealed = _revealedLetters[word] ?? const <int>{};
                      final maskedWord = List.generate(
                        word.length,
                        (index) => revealed.contains(index) ? word[index] : '•',
                      ).join(' ');

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: word.length * 25.0 + 40,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: found ? Colors.green.shade100 : Colors.white,
                          border: Border.all(
                            color: found ? Colors.green : Colors.black12,
                            width: found ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          found ? word : maskedWord,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: found ? Colors.green.shade800 : Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: Container(
                  key: ValueKey(_currentWord),
                  width: double.infinity,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _currentWord.isEmpty
                          ? Colors.black12
                          : Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _currentWord.isEmpty ? 'حروف را لمس کن و بکش' : _currentWord,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: _currentWord.isEmpty
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LetterBoard(
                letters: _stage.letters,
                selectedIndexes: _selectedIndexes,
                onSelectionChanged: _onSelectionChanged,
                onSelectionCompleted: _onSelectionCompleted,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'حذف آخرین حرف',
                    onPressed: _selectedIndexes.isEmpty ? null : _removeLastLetter,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _selectedIndexes.isEmpty ? null : _submitWord,
                    icon: const Icon(Icons.check),
                    label: const Text('ثبت'),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'راهنما - $_hintCost سکه',
                    onPressed: _completionHandled ? null : _useHint,
                    icon: const Icon(Icons.lightbulb_outline),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'پاک کردن',
                    onPressed: _selectedIndexes.isEmpty ? null : _clearSelection,
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
