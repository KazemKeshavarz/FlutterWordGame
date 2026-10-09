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
  bool _rewardEarned = false;
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

  String? _matchingStageWord(String word) {
    final normalized = PersianTextNormalizer.normalize(word);
    for (final item in _stage.words) {
      if (PersianTextNormalizer.normalize(item) == normalized) return item;
    }
    return null;
  }

  bool _isValidWord(String word) => _matchingStageWord(word) != null;

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
    if (!mounted) return;
    if (!success) {
      _showMessage('برای استفاده از راهنما حداقل $_hintCost سکه لازم است.');
      return;
    }

    setState(() {
      final revealed = Set<int>.from(_revealedLetters[targetWord!] ?? const {});
      revealed.add(targetIndex!);
      _revealedLetters[targetWord!] = revealed;
    });

    await GameFeedback.hintUsed();
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

    final matchedWord = _matchingStageWord(word)!;
    if (_foundWords.contains(matchedWord)) {
      setState(() => _combo = 0);
      _showMessage('این کلمه را قبلاً پیدا کرده‌ای.');
      _clearSelection();
      return;
    }

    final nextCombo = _combo + 1;
    final comboBonus = (nextCombo > 6 ? 5 : nextCombo - 1) * 5;

    setState(() {
      _foundWords.add(matchedWord);
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
      final rewardEarned = await widget.progressController.completeStage(
        _stage.id,
        maxStageId: widget.repository.stages.last.id,
        stars: _stageStars,
      );
      if (!mounted) return;
      setState(() => _rewardEarned = rewardEarned);
      await GameFeedback.stageCompleted();
      Future.delayed(
        const Duration(milliseconds: 900),
        () => _showStageCompleted(rewardEarned: rewardEarned),
      );
    }
  }

  int get _stageStars {
    // امتیاز پایه هر کلمه ۱۰ است؛ امتیاز کامل ممکن با توجه به Combo محاسبه می‌شود.
    // این روش باعث می‌شود مرحله‌های کوتاه هم بتوانند سه ستاره بگیرند.
    final wordCount = _stage.words.length;
    if (wordCount == 0) return 1;

    var maximumScore = 0;
    for (var index = 1; index <= wordCount; index++) {
      final comboBonus = (index > 6 ? 5 : index - 1) * 5;
      maximumScore += 10 + comboBonus;
    }

    final performance = _score / maximumScore;
    if (performance >= 0.80) return 3;
    if (performance >= 0.50) return 2;
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

  void _showStageCompleted({required bool rewardEarned}) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('مرحله کامل شد 🎉'),
        content: Text(
          rewardEarned
              ? '$_score امتیاز گرفتی و ۲۰ سکه جایزه گرفتی.\n\n${'⭐' * _stageStars} ستاره'
              : '$_score امتیاز گرفتی. این مرحله را دوباره با موفقیت تمام کردی!\n\n${'⭐' * _stageStars} ستاره',
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
              const SizedBox(height: 10),
              Row(
                children: [
                  _GameInfoChip(
                    icon: Icons.stars_rounded,
                    label: 'امتیاز',
                    value: _score.toString(),
                    color: const Color(0xFF286F93),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: widget.progressController,
                    builder: (context, _) => _GameInfoChip(
                      icon: Icons.monetization_on_rounded,
                      label: 'سکه',
                      value: widget.progressController.progress.coins.toString(),
                      color: const Color(0xFFB77900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          ),
                          child: Text(
                            found ? word : maskedWord,
                            key: ValueKey('${found ? 'found' : 'masked'}-${found ? word : maskedWord}'),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: found ? Colors.green.shade800 : Colors.grey,
                            ),
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
            if (_showCelebration)
              _StageCelebration(rewardEarned: _rewardEarned),
          ],
        ),
      ),
    );
  }
}

class _GameInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GameInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _StageCelebration extends StatelessWidget {
  final bool rewardEarned;

  const _StageCelebration({required this.rewardEarned});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.65, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 76)),
                  const SizedBox(height: 8),
                  const Text(
                    'مرحله کامل شد!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text('آفرین قهرمان 🌟', style: TextStyle(fontSize: 17)),
                  if (rewardEarned) ...[
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value.clamp(0.0, 1.0).toDouble(), child: child),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4CC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFFD76A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 27)),
                            const SizedBox(width: 9),
                            Text(
                              '+20 سکه',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      'رکورد مرحله‌ات بهتر شد!',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
