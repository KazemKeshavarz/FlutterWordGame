import 'package:flutter/material.dart';
import '../data/local_stage_repository.dart';
import '../domain/stage.dart';
import 'widgets/letter_board.dart';

class GamePage extends StatefulWidget {
  final int stageId;
  const GamePage({super.key, required this.stageId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _repository = LocalStageRepository();
  late final Stage _stage;

  List<int> _selectedIndexes = [];
  final Set<String> _foundWords = {};

  @override
  void initState() {
    super.initState();
    _stage = _repository.getStage(widget.stageId);
  }

  String get _currentWord =>
      _selectedIndexes.map((i) => _stage.letters[i]).join();

  void _onSelectionChanged(List<int> indexes) {
    setState(() => _selectedIndexes = indexes);
  }

  void _onSelectionCompleted() {
    _submitWord();
  }

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

  void _submitWord() {
    final word = _currentWord;
    if (word.isEmpty) return;

    if (_stage.words.contains(word)) {
      if (_foundWords.contains(word)) {
        _showMessage('این کلمه را قبلاً پیدا کرده‌ای.');
        _clearSelection();
        return;
      }

      setState(() {
        _foundWords.add(word);
        _selectedIndexes = [];
      });

      _showMessage('آفرین! «' + word + '» پیدا شد 🎉');

      if (_foundWords.length == _stage.words.length) {
        Future.delayed(
          const Duration(milliseconds: 400),
          _showStageCompleted,
        );
      }
    } else {
      _showMessage('این کلمه در این مرحله وجود ندارد.');
      _clearSelection();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showStageCompleted() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('مرحله کامل شد 🎉'),
        content: Text(
          'تبریک! همه ' +
              _stage.words.length.toString() +
              ' کلمه این مرحله را پیدا کردی.',
        ),
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
    final progress = _foundWords.length / _stage.words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحله ' + _stage.id.toString()),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _foundWords.length.toString() +
                    '/' +
                    _stage.words.length.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: word.length * 25.0 + 40,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: found
                              ? Colors.green.shade100
                              : Colors.white,
                          border: Border.all(
                            color: found ? Colors.green : Colors.black12,
                            width: found ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          found
                              ? word
                              : List.filled(word.length, '•').join(' '),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: found
                                ? Colors.green.shade800
                                : Colors.grey,
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
                    _currentWord.isEmpty
                        ? 'حروف را لمس کن و بکش'
                        : _currentWord,
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
                selectedIndexes: _selectedIndexes.toSet(),
                onSelectionChanged: _onSelectionChanged,
                onSelectionCompleted: _onSelectionCompleted,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'حذف آخرین حرف',
                    onPressed: _selectedIndexes.isEmpty
                        ? null
                        : _removeLastLetter,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed:
                        _selectedIndexes.isEmpty ? null : _submitWord,
                    icon: const Icon(Icons.check),
                    label: const Text('ثبت'),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'پاک کردن',
                    onPressed:
                        _selectedIndexes.isEmpty ? null : _clearSelection,
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
