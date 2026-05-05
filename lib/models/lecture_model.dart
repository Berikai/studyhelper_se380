import 'dart:convert';

/// Structure for a lecture item in the app
class LectureModel {
  final String id;
  final String title;
  final String dateText;
  final int questions;
  final String colorIcon;
  final List<String> documents;
  final List<Map<String, dynamic>> flashcards;
  final String content;

  LectureModel({
    required this.id,
    required this.title,
    required this.dateText,
    required this.questions,
    required this.colorIcon,
    this.documents = const [],
    this.flashcards = const [],
    this.content = '',
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedDocs = [];
    if (json['documents'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(json['documents']);
        parsedDocs = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    List<Map<String, dynamic>> parsedFlashcards = [];
    if (json['flashcards'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(json['flashcards']);
        parsedFlashcards = decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {}
    }

    return LectureModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      dateText: json['dateText'] ?? '',
      questions: json['questions'] ?? 0,
      colorIcon: json['colorIcon'] ?? 'blue',
      documents: parsedDocs,
      flashcards: parsedFlashcards,
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateText': dateText,
      'questions': questions,
      'colorIcon': colorIcon,
      'documents': jsonEncode(documents),
      'flashcards': jsonEncode(flashcards),
      'content': content,
    };
  }
}
