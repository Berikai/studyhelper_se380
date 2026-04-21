import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/lecture_model.dart';

// We inherit the ChangeNotifier class to manage the global state of the app, including the list of lectures and loading/error states
// We call notify listeners whenever we update the state to trigger UI updates.
// Then, widgets that have listenable builders can listen to this state and rebuild when it changes, allowing us to keep the UI in sync with the backend data.
// Also reduces our usage of setState across the app, since we can just update the state here and let the listeners handle the UI updates.
class AppState extends ChangeNotifier {
  List<LectureModel> lectures = []; // List of lectures fetched from the backend
  bool isLoading = false; // Indicates if the app is currently loading data from the backend
  String errorMessage = ''; // Stores any error messages from API calls to display in the UI

  // Handle local host URLs across macOS (desktop), Web, and Android Emulator
  String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:9090/api';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:9090/api';
    return 'http://localhost:9090/api'; // Desktop / iOS 
  }

  AppState() {
    // Automatically fetch on creation
    fetchLectures();
  }

  // Asynchronous function to fetch lectures from the backend API
  Future<void> fetchLectures() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // We use http lib to make a get request to the backend API
      final response = await http.get(Uri.parse('$apiBaseUrl/lectures'));
      if (response.statusCode == 200) { // Status code 200 means success, if the call is successful we move on.
        final List<dynamic> data = json.decode(response.body);
        lectures = data.map((json) => LectureModel(
          id: json['id'],
          title: json['title'],
          dateText: json['dateText'],
          questions: json['questions'],
          colorIcon: json['colorIcon']
        )).toList();
      } else {
        errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Failed to connect to API: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Asynchronous function to add a new lecture by sending a POST request to the backend API
  Future<void> addLecture(LectureModel lec) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/lectures'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': lec.title,
          'colorIcon': lec.colorIcon,
        }),
      );
      
      if (response.statusCode == 201) { // Status code 201 means created, if the call is successful we move on.
        final jsonData = json.decode(response.body);
        final newLecture = LectureModel(
          id: jsonData['id'],
          title: jsonData['title'],
          dateText: jsonData['dateText'],
          questions: jsonData['questions'],
          colorIcon: jsonData['colorIcon'],
        );
        lectures.add(newLecture);
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to add lecture: $e';
      notifyListeners();
    }
  }
}

// Global state instance for easy access across the clean architecture
final appState = AppState();
