import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../models/lecture_model.dart';

class FlashcardScreen extends StatefulWidget {
  final LectureModel lecture;

  const FlashcardScreen({super.key, required this.lecture});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  Widget _buildMathText(String text, {TextStyle? style}) {
    final parts = text.split('\$');
    List<Widget> children = [];
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        children.add(Math.tex(
          parts[i],
          textStyle: style?.copyWith(color: Colors.white),
          mathStyle: MathStyle.display,
        ));
      } else if (parts[i].isNotEmpty) {
        children.add(Text(parts[i], style: style));
      }
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  void _nextCard() {
    if (_currentIndex < widget.lecture.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lecture.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards'), backgroundColor: Colors.transparent),
        backgroundColor: const Color(0xff12141D),
        body: const Center(child: Text('No flashcards yet. Save some during study sessions!', style: TextStyle(color: Colors.white70))),
      );
    }

    final card = widget.lecture.flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard ${_currentIndex + 1} / ${widget.lecture.flashcards.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xff12141D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _showAnswer = !_showAnswer),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 300,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _showAnswer ? const Color(0xff2A2D3E) : const Color(0xff222536),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _showAnswer ? Colors.purpleAccent : Colors.blueAccent, width: 2),
                    boxShadow: [
                      BoxShadow(color: (_showAnswer ? Colors.purpleAccent : Colors.blueAccent).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_showAnswer ? "ANSWER" : "QUESTION", style: TextStyle(color: _showAnswer ? Colors.purpleAccent : Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 24),
                          _buildMathText(
                            _showAnswer ? (card['answer'] ?? '') : (card['question'] ?? ''),
                            style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Tap the card to flip', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    disabledColor: Colors.white24,
                    iconSize: 32,
                  ),
                  IconButton(
                    onPressed: _currentIndex < widget.lecture.flashcards.length - 1 ? _nextCard : null,
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    disabledColor: Colors.white24,
                    iconSize: 32,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
