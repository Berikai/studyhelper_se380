import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:convert';
import '../../models/lecture_model.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class StudySessionScreen extends StatefulWidget {
  final LectureModel lecture;
  final int totalQuestions;

  const StudySessionScreen({super.key, required this.lecture, this.totalQuestions = 5});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  int? _selectedIndex;
  bool _isAnswered = false;
  String _chatResponse = '';
  late AnimationController _shakeController;
  
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  String? _errorMessage;
  final List<Map<String, dynamic>> _sessionHistory = [];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fetchNextQuestion();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _fetchNextQuestion() async {
    if (_isAnswered) {
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= widget.totalQuestions) {
        _showQuizSummary();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _selectedIndex = null;
      _isAnswered = false;
      _chatResponse = '';
      _errorMessage = null;
    });

    try {
      final q = await ApiService.generateQuestion(widget.lecture.id);
      if (mounted) {
        setState(() {
          _currentQuestion = q;
          _isLoading = false;
        });
        context.read<AppState>().fetchUserInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _submitAnswer(int index) {
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (index == _currentQuestion!['correctIndex']) {
        _correctAnswers++;
      }
      
      _sessionHistory.add({
        'question': _currentQuestion!['question'],
        'options': _currentQuestion!['options'],
        'correctIndex': _currentQuestion!['correctIndex'],
        'selectedIndex': index,
        'explanation': _currentQuestion!['explanation'],
      });
    });
  }

  void _showQuizSummary() {
    ApiService.saveStudyHistory(
      widget.lecture.id, 
      widget.lecture.title, 
      _correctAnswers, 
      widget.totalQuestions,
      jsonEncode(_sessionHistory),
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff222536),
          title: const Text('Quiz Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text('You answered $_correctAnswers out of $_currentQuestionIndex correctly.', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Score: ${(_currentQuestionIndex > 0 ? (_correctAnswers / _currentQuestionIndex * 100).toStringAsFixed(0) : 0)}%', style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close screen
              },
              child: const Text('Back to Lecture', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _chatWithAI() async {
    if (_currentQuestion == null) return;
    
    setState(() {
      _chatResponse = 'AI is thinking...';
    });
    
    final contextData = "Question: ${_currentQuestion!['question']} \nCorrect Answer: ${_currentQuestion!['options'][_currentQuestion!['correctIndex']]} \nExplanation: ${_currentQuestion!['explanation']}";
    final response = await ApiService.chatWithAi("Can you explain this question in more detail?", contextData);
    
    if (mounted) {
      setState(() {
        _chatResponse = response;
      });
    }
  }

  Future<void> _saveAsFlashcard() async {
    if (_currentQuestion == null) return;
    final question = _currentQuestion!['question'];
    final answer = _currentQuestion!['options'][_currentQuestion!['correctIndex']];
    await ApiService.addFlashcard(widget.lecture.id, question, answer);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to flashcards!')));
    }
  }

  Widget _buildMathText(String text, {TextStyle? style}) {
    if (!text.contains('\$')) {
      return Text(text, style: style);
    }

    final parts = text.split('\$');
    List<Widget> children = [];
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // LaTeX part
        final String tex = parts[i].trim();
        if (tex.isEmpty) continue;
        
        // If it looks like just text (no special math chars), render as Text
        final bool isLikelyText = !tex.contains('\\') && !tex.contains('_') && !tex.contains('^') && !tex.contains('{');
        
        if (isLikelyText) {
          children.add(Text(tex, style: style));
        } else {
          children.add(SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              tex,
              textStyle: style?.copyWith(color: Colors.white),
              mathStyle: MathStyle.display,
            ),
          ));
        }
      } else if (parts[i].isNotEmpty) {
        children.add(Text(parts[i], style: style));
      }
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141D),
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1} / ${widget.totalQuestions}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  return Text(
                    '💎 ${appState.userInfo?['credits'] ?? 0}',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  );
                },
              ),
            ),
          ),
          TextButton(
            onPressed: _showQuizSummary,
            child: const Text('End Quiz', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage != null || _currentQuestion == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage ?? 'Failed to load question',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _fetchNextQuestion,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff222536), Color(0xff1A1C29)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology, color: Colors.blueAccent),
                                SizedBox(width: 8),
                                Text("QUESTION", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildMathText(
                              _currentQuestion!['question'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Options
                      ...List.generate(
                        (_currentQuestion!['options'] as List).length,
                        (index) {
                          final option = _currentQuestion!['options'][index];
                          final isCorrect = index == _currentQuestion!['correctIndex'];
                          final isSelected = index == _selectedIndex;
                          
                          Color borderColor = Colors.transparent;
                          Color bgColor = const Color(0xff222536);
                          Color textColor = Colors.white70;

                          if (_isAnswered) {
                            if (isCorrect) {
                              borderColor = Colors.greenAccent;
                              bgColor = Colors.greenAccent.withOpacity(0.1);
                              textColor = Colors.greenAccent;
                            } else if (isSelected) {
                              borderColor = Colors.redAccent;
                              bgColor = Colors.redAccent.withOpacity(0.1);
                              textColor = Colors.redAccent;
                            }
                          } else if (isSelected) {
                            borderColor = Colors.blueAccent;
                            bgColor = Colors.blueAccent.withOpacity(0.1);
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: _isAnswered && isCorrect 
                                  ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)] 
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _isAnswered ? null : () => _submitAnswer(index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: textColor, width: 2),
                                          color: _isAnswered && isCorrect ? Colors.greenAccent : (isSelected ? textColor : Colors.transparent),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index), // A, B, C, D
                                            style: TextStyle(
                                              color: _isAnswered && isCorrect ? Colors.black : (isSelected && !_isAnswered ? Colors.black : textColor),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildMathText(option, style: TextStyle(fontSize: 16, color: textColor)),
                                      ),
                                      if (_isAnswered && isCorrect)
                                        const Icon(Icons.check_circle, color: Colors.greenAccent)
                                      else if (_isAnswered && isSelected && !isCorrect)
                                        const Icon(Icons.cancel, color: Colors.redAccent)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Explanation & Actions
                      AnimatedOpacity(
                        opacity: _isAnswered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: _isAnswered ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.lightbulb, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text("EXPLANATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMathText(
                                    _currentQuestion!['explanation'],
                                    style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                                    label: const Text('Discuss', style: TextStyle(color: Colors.blueAccent)),
                                    onPressed: _chatWithAI,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Colors.blueAccent),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.bookmark_add, color: Colors.purpleAccent),
                                    label: const Text('Save', style: TextStyle(color: Colors.purpleAccent)),
                                    onPressed: _saveAsFlashcard,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Colors.purpleAccent),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _fetchNextQuestion,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      elevation: 5,
                                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Next', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_chatResponse.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xff222536),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                                        SizedBox(width: 8),
                                        Text("AI TUTOR", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMathText(_chatResponse, style: const TextStyle(color: Colors.white70, height: 1.5)),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 40), // Bottom padding
                          ],
                        ) : const SizedBox(),
                      ),
                    ],
                  ),
                ),
    );
  }
}
