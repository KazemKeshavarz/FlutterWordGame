import 'package:flutter/material.dart';
import '../../../core/audio/game_feedback.dart';
import '../../../core/utils/persian_text_normalizer.dart';
import '../data/local_stage_repository.dart';
import '../domain/stage.dart';
import '../../../core/storage/game_progress_controller.dart';
import 'widgets/letter_board.dart';
import 'widgets/word_success_effect.dart';

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
  String? _feedbackWord;
  bool? _feedbackSuccess;
  int _combo = 0;
  int _score = 0;
  bool _showCelebration = false;
  String? _successEffectWord;
  int _successEffectCombo = 0;
  final Map<String, Set<int>> _revealedLetters = {};
  static const int _hintCost = 10;

  @override
  void initState() {
    super.initState();
    _stage = widget.repository.getStage(widget.stageId);
  }

  String get _currentWord =>
      _selectedIndexes.map((i) => _stage.letters[i]).join();

  bool _isValidWord(String word) {
    final normalized = PersianTextNormalizer.normalize(word);
    return _stage.words.any(
      (item) => PersianTextNormalizer.normalize(item) == normalized,
    );
  }

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

    if (!_isValidWord(word)) {
      setState(() {
        _combo = 0;
        _feedbackWord = word;
        _feedbackSuccess = false;
      });
      await GameFeedback.wrong();
      _showMessage('این کلمه در این مرحله وجود ندارد.');
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _feedbackWord = null;
          _feedbackSuccess = null;
        });
      });
      _clearSelection();
      return;
    }

    if (_foundWords.contains(word)) {
      setState(() => _combo = 0);
      _showMessage('این کلمه را قبلاً پیدا کرده‌ای.');
      _clearSelection();
      return;
    }

    final nextCombo = _combo + 1;
    final comboBonus = (nextCombo > 6 ? 5 : nextCombo - 1) * 5;

    setState(() {
      _foundWords.add(word);
      _combo = nextCombo;
      _score += 10 + comboBonus;
      _selectedIndexes = [];
      _feedbackWord = word;
      _feedbackSuccess = true;
      _successEffectWord = word;
      _successEffectCombo = nextCombo;
    });

    Future.delayed(const Duration(milliseconds: 720), () {
      if (!mounted || _successEffectWord != word) return;
      setState(() => _successEffectWord = null);
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _feedbackWord = null;
        _feedbackSuccess = null;
      });
    });

    await GameFeedback.correct();
    _showMessage('آفرین! «$word» پیدا شد 🎉');

    if (_foundWords.length == _stage.words.length && !_completionHandled) {
      _completionHandled = true;
      setState(() => _showCelebration = true);
      await widget.progressController.completeStage(
        _stage.id,
        maxStageId: widget.repository.stages.last.id,
        stars: _stageStars,
      );
      Future.delayed(const Duration(milliseconds: 900), _showStageCompleted);
    }
  }

  int get _stageStars {
    if (_score >= _stage.words.length * 15) return 3;
    if (_score >= _stage.words.length * 10) return 2;
    return 1;
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
        content: Text('$_score امتیاز گرفتی و ۲۰ سکه جایزه گرفتی.\n\n${'⭐' * _stageStars}  رکورد این مرحله'),
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _combo > 1
                    ? Text('🔥 زنجیره $_combo', key: ValueKey(_combo), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                    : const SizedBox(height: 20),
              ),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      _currentWord.isEmpty
                          ? 'حروف را لمس کن و بکش'
                          : _currentWord,
                      key: ValueKey(_currentWord),
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: _feedbackWord == _currentWord
                            ? (_feedbackSuccess == true
                                ? Colors.green
                                : Colors.red)
                            : (_currentWord.isEmpty
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary),
                      ),
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
            if (_successEffectWord != null)
              WordSuccessEffect(
                key: ValueKey('success-$_successEffectWord-$_successEffectCombo'),
                word: _successEffectWord!,
                combo: _successEffectCombo,
              ),
            if (_showCelebration) const _StageCelebration(),
          ],
        ),
      ),
    );
  }
}

class _StageCelebration extends StatelessWidget {
  const _StageCelebration();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 82)),
                SizedBox(height: 8),
                Text('مرحله کامل شد!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('آفرین قهرمان 🌟', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
