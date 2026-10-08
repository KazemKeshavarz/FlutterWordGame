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
  final List<String> _selectedLetters = [];
  final Set<String> _foundWords = {};

  @override
  void initState() {
    super.initState();
    _stage = _repository.getStage(widget.stageId);
  }

  void _selectLetter(String letter) {
    setState(() => _selectedLetters.add(letter));
  }

  void _clear() {
    setState(() => _selectedLetters.clear());
  }

  void _checkWord() {
    final word = _selectedLetters.join();
    if (word.isEmpty) return;

    if (_stage.words.contains(word)) {
      setState(() {
        _foundWords.add(word);
        _selectedLetters.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('آفرین! «' + word + '» درست است 🎉')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این کلمه در این مرحله نیست')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مرحله ' + _stage.id.toString())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _stage.words.map((word) {
                final found = _foundWords.contains(word);
                return Container(
                  width: word.length * 25.0 + 40,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: found ? Colors.green.shade100 : Colors.white,
                    border: Border.all(
                      color: found ? Colors.green : Colors.black12,
                    ),
                  ),
                  child: Text(
                    found ? word : List.filled(word.length, '•').join(' '),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              height: 55,
              child: Center(
                child: Text(
                  _selectedLetters.join(),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _stage.letters.map((letter) {
                return SizedBox(
                  width: 68,
                  height: 68,
                  child: ElevatedButton(
                    onPressed: () => _selectLetter(letter),
                    child: Text(
                      letter,
                      style: const TextStyle(fontSize: 27),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('پاک کردن'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _checkWord,
                  icon: const Icon(Icons.check),
                  label: const Text('بررسی'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
