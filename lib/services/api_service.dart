import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture_model.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/web
  // TODO: Replace with actual IP address when deploying
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:9090/api';
    return Platform.isAndroid ? 'http://10.0.2.2:9090/api' : 'http://localhost:9090/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
    }
    return {'statusCode': response.statusCode, 'data': data};
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<List<LectureModel>> getLectures() async {
    final token = await getToken();
    if (token == null) return [];
    
    final response = await http.get(
      Uri.parse('$baseUrl/lectures'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LectureModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<LectureModel?> createLecture(String title, String colorIcon, {String content = '', List<String> documents = const [], List<Map<String, dynamic>> flashcards = const []}) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.post(
      Uri.parse('$baseUrl/lectures'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'colorIcon': colorIcon,
        'content': content,
        'documents': jsonEncode(documents),
        'flashcards': jsonEncode(flashcards),
      }),
    );

    if (response.statusCode == 201) {
      return LectureModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? "Failed to create lecture");
  }

  static Future<LectureModel?> createLectureWithFile(
    String title,
    String colorIcon, {
    String content = '',
    PlatformFile? document,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final uri = Uri.parse('$baseUrl/lectures');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['colorIcon'] = colorIcon
      ..fields['content'] = content;

    if (document != null) {
      final bytes = document.bytes ??
          await File(document.path!).readAsBytes();
      final ext = document.name.split('.').last.toLowerCase();
      final mimeMap = {
        'pdf': 'application/pdf',
        'txt': 'text/plain',
        'doc': 'application/msword',
        'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      };
      final mimeFull = mimeMap[ext] ?? 'application/octet-stream';
      final mimeParts = mimeFull.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'document',
          bytes,
          filename: document.name,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return LectureModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create lecture');
  }

  static Future<void> seedLectures() async {
    final token = await getToken();
    if (token == null) return;
    await http.post(
      Uri.parse('$baseUrl/lectures/seed'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<List<dynamic>> generateCurriculum(String lectureId, String lectureTitle, {bool force = false}) async {
    final token = await getToken();
    if (token == null) return [];

    final response = await http.post(
      Uri.parse('$baseUrl/ai/generate-curriculum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'lectureId': lectureId,
        'lectureTitle': lectureTitle,
        'force': force,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['curriculum'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> generateQuestion(String lectureId) async {
    final token = await getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.post(
      Uri.parse('$baseUrl/ai/generate-question'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'lectureId': lectureId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    
    throw Exception(jsonDecode(response.body)['error'] ?? "Failed to generate question");
  }

  static Future<String> chatWithAi(String message, String context) async {
    final token = await getToken();
    if (token == null) return "Error: Not authenticated";

    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message, 'context': context}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? "Error processing AI response";
    }
    return "Error: Could not reach AI";
  }

  static Future<List<dynamic>> getStudyHistory() async {
    final token = await getToken();
    if (token == null) return [];
    final response = await http.get(Uri.parse('$baseUrl/history'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> saveStudyHistory(String lectureId, String lectureTitle, int score, int totalQuestions, String sessionData) async {
    final token = await getToken();
    if (token == null) return;
    await http.post(
      Uri.parse('$baseUrl/history'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'lecture_id': lectureId, 
        'lecture_title': lectureTitle, 
        'score': score, 
        'total_questions': totalQuestions,
        'session_data': sessionData
      }),
    );
  }

  static Future<bool> updateLecture(String id, String title, String content) async {
    final token = await getToken();
    if (token == null) return false;
    final response = await http.put(
      Uri.parse('$baseUrl/lectures/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteLecture(String id) async {
    final token = await getToken();
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('$baseUrl/lectures/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<List<String>> addDocument(String lectureId, PlatformFile document) async {
    final token = await getToken();
    if (token == null) return [];
    
    final uri = Uri.parse('$baseUrl/lectures/$lectureId/documents');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    final bytes = document.bytes ?? await File(document.path!).readAsBytes();
    final ext = document.name.split('.').last.toLowerCase();
    final mimeMap = {
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    final mimeFull = mimeMap[ext] ?? 'application/octet-stream';
    final mimeParts = mimeFull.split('/');
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'document',
        bytes,
        filename: document.name,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final List<dynamic> docs = jsonDecode(response.body)['documents'];
      return docs.map((e) {
        if (e is Map) return e['name']?.toString() ?? e.toString();
        return e.toString();
      }).toList();
    }
    return [];
  }

  static Future<List<String>> removeDocument(String lectureId, int index) async {
    final token = await getToken();
    if (token == null) return [];
    final response = await http.delete(
      Uri.parse('$baseUrl/lectures/$lectureId/documents/$index'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> docs = jsonDecode(response.body)['documents'];
      return docs.map((e) {
        if (e is Map) return e['name']?.toString() ?? e.toString();
        return e.toString();
      }).toList();
    }
    return [];
  }

  static Future<void> addFlashcard(String lectureId, String question, String answer) async {
    final token = await getToken();
    if (token == null) return;
    await http.post(
      Uri.parse('$baseUrl/lectures/$lectureId/flashcards'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'answer': answer}),
    );
  }

  // Study plan methods
  static Future<List<Map<String, dynamic>>> getStudyPlans({String? date}) async {
    final token = await getToken();
    if (token == null) return [];
    final url = date != null
        ? Uri.parse('$baseUrl/plans?date=$date')
        : Uri.parse('$baseUrl/plans');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getStudyPlansByDateRange(String start, String end) async {
    final token = await getToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/plans/range?start=$start&end=$end'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createStudyPlan(String lectureId, String lectureTitle, String targetDate) async {
    final token = await getToken();
    if (token == null) return null;
    final response = await http.post(
      Uri.parse('$baseUrl/plans'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'lecture_id': lectureId, 'lecture_title': lectureTitle, 'target_date': targetDate}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> toggleStudyPlan(String planId) async {
    final token = await getToken();
    if (token == null) return false;
    final response = await http.put(
      Uri.parse('$baseUrl/plans/$planId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteStudyPlan(String planId) async {
    final token = await getToken();
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('$baseUrl/plans/$planId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
