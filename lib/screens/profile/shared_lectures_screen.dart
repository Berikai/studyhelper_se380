import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/lecture_model.dart';
import '../library/flashcard_screen.dart';

class SharedLecturesScreen extends StatefulWidget {
  final int senderId;
  final String senderEmail;

  const SharedLecturesScreen({
    super.key,
    required this.senderId,
    required this.senderEmail,
  });

  @override
  State<SharedLecturesScreen> createState() => _SharedLecturesScreenState();
}

class _SharedLecturesScreenState extends State<SharedLecturesScreen> {
  List<Map<String, dynamic>> _lectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSharedLectures();
  }

  Future<void> _fetchSharedLectures() async {
    try {
      final lectures = await ApiService.getSharedLectures(widget.senderId);
      if (mounted) {
        setState(() {
          _lectures = lectures;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openFlashcards(Map<String, dynamic> lectureData) {
    // We create a mock LectureModel to reuse the FlashcardScreen
    List<Map<String, dynamic>> parsedFlashcards = [];
    try {
      final decoded = jsonDecode(lectureData['flashcards'] ?? '[]');
      if (decoded is List) {
        parsedFlashcards = List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      parsedFlashcards = [];
    }

    final mockLecture = LectureModel(
      id: lectureData['lecture_id'] ?? 'shared',
      title: lectureData['lecture_title'] ?? 'Shared Flashcards',
      dateText: lectureData['shared_at'] ?? '',
      questions: 0,
      colorIcon: 'blue',
      documents: [],
      flashcards: parsedFlashcards,
      content: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(lecture: mockLecture),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141D),
      appBar: AppBar(
        title: Text('${widget.senderEmail}\'s Flashcards', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lectures.isEmpty
              ? const Center(child: Text('No lectures found.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = _lectures[index];
                    return Card(
                      color: const Color(0xff222536),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.style, color: Colors.purpleAccent),
                        title: Text(lecture['lecture_title'] ?? 'Unknown Lecture', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Shared at: ${lecture['shared_at'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        onTap: () => _openFlashcards(lecture),
                      ),
                    );
                  },
                ),
    );
  }
}
