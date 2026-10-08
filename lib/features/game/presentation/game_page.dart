import 'package:flutter/material.dart';
import '../data/local_stage_repository.dart';
import '../domain/stage.dart';

class GamePage extends StatefulWidget {
  final int stageId;
  const GamePage({super.key, required this.stageId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _repository = LocalStageRepository();
  late final Stage _stage;
  final List<int> _selectedIndexes = [];
  final Set<String> _foundWords = {};

  @override
  void initState() {
    super.initState();
    _stage = _repository.getStage(widget.stageId);
  }

  String get _currentWord =>
      _selectedIndexes.map((index) => _stage.letters[index]).join();

  void _addLetter(int index) {
    if (_selectedIndexes.contains(index)) return;
    setState(() => _selectedIndexes.add(index));
  }

  void _removeLastLetter() {
    if (_selectedIndexes.isEmpty) return;
    setState(() => _selectedIndexes.removeLast());
  }

  void _clearSelection() {
    if (_selectedIndexes.isEmpty) return;
    setState(() => _selectedIndexes.clear());
  }

  void _submitWord() {
    final word = _currentWord;
    if (word.isEmpty) return;

    if (_stage.words.contains(word)) {
      if (_foundWords.contains(word)) {
        _showMessage('این کلمه را قبلاً پیدا کرده‌ای.');
        return;
      }

      setState(() {
        _foundWords.add(word);
        _selectedIndexes.clear();
      });

      _showMessage('آفرین! «' + word + '» پیدا شد 🎉');

      if (_foundWords.length == _stage.words.length) {
        Future.delayed(const Duration(milliseconds: 350), _showStageCompleted);
      }
    } else {
      _showMessage('این کلمه در این مرحله وجود ندارد.');
      setState(() => _selectedIndexes.clear());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showStageCompleted() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('مرحله کامل شد 🎉'),
        content: Text(
          'تبریک! همه ' + _stage.words.length.toString() +
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
                _foundWords.length.toString() + '/' +
                    _stage.words.length.toString(),
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
                          found ? word : List.filled(word.length, '•').join(' '),
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
                duration: const Duration(milliseconds: 150),
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
                    _currentWord.isEmpty ? 'حروف را انتخاب کن' : _currentWord,
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
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(_stage.letters.length, (index) {
                  return _LetterButton(
                    letter: _stage.letters[index],
                    selected: _selectedIndexes.contains(index),
                    onTap: () => _addLetter(index),
                  );
                }),
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
                    label: const Text('ثبت کلمه'),
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

class _LetterButton extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;

  const _LetterButton({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 0.92 : 1,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        width: 70,
        height: 70,
        child: ElevatedButton(
          onPressed: selected ? null : onTap,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            letter,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
