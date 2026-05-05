import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/lecture_model.dart';
import '../services/api_service.dart';

// We inherit the ChangeNotifier class to manage the global state of the app, including the list of lectures and loading/error states
// We call notify listeners whenever we update the state to trigger UI updates.
// Then, widgets that have listenable builders can listen to this state and rebuild when it changes, allowing us to keep the UI in sync with the backend data.
// Also reduces our usage of setState across the app, since we can just update the state here and let the listeners handle the UI updates.
class AppState extends ChangeNotifier {
  List<LectureModel> lectures = []; // List of lectures fetched from the backend
  Map<String, dynamic>? userInfo; // User data, including credits
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
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      userInfo = await ApiService.getUserInfo();
      notifyListeners();
    } catch (e) {
      // Ignored
    }
  }

  // Asynchronous function to fetch lectures from the backend API
  Future<void> fetchLectures() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      lectures = await ApiService.getLectures();
    } catch (e) {
      errorMessage = 'Failed to connect to API: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Asynchronous function to add a new lecture by sending a POST request to the backend API
  Future<bool> addLecture(LectureModel lec) async {
    try {
      final newLecture = await ApiService.createLecture(
        lec.title, 
        lec.colorIcon,
        content: lec.content,
        documents: lec.documents,
        flashcards: lec.flashcards,
      );
      if (newLecture != null) {
        lectures.add(newLecture);
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Failed to add lecture (API returned null)';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Failed to add lecture: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLecture(String id, String title, String content) async {
    try {
      final success = await ApiService.updateLecture(id, title, content);
      if (success) {
        final index = lectures.indexWhere((l) => l.id == id);
        if (index != -1) {
          final old = lectures[index];
          lectures[index] = LectureModel(
            id: old.id,
            title: title,
            content: content,
            dateText: old.dateText,
            questions: old.questions,
            colorIcon: old.colorIcon,
            documents: old.documents,
            flashcards: old.flashcards,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = 'Failed to update lecture: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLecture(String id) async {
    try {
      final success = await ApiService.deleteLecture(id);
      if (success) {
        lectures.removeWhere((l) => l.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      errorMessage = 'Failed to delete lecture: $e';
      notifyListeners();
      return false;
    }
  }
}

// Global state instance for easy access across the clean architecture
final appState = AppState();
