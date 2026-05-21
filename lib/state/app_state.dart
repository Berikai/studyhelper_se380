import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lecture_model.dart';
import '../services/api_service.dart';

// We inherit the ChangeNotifier class to manage the global state of the app, including the list of lectures and loading/error states
// We call notify listeners whenever we update the state to trigger UI updates.
// Then, widgets that have listenable builders can listen to this state and rebuild when it changes, allowing us to keep the UI in sync with the backend data.
// Also reduces our usage of setState across the app, since we can just update the state here and let the listeners handle the UI updates.
class AppState extends ChangeNotifier {
  List<LectureModel> lectures = [];
  Map<String, dynamic>? userInfo;
  bool isLoading = false;
  String errorMessage = '';
  
  // Study plans: maps date strings (YYYY-MM-DD) to list of plan maps
  Map<String, List<Map<String, dynamic>>> studyPlansByDate = {};
  bool isLoadingPlans = false;

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

  Future<bool> addLectureWithFile(String title, String content, PlatformFile document) async {
    try {
      final newLecture = await ApiService.createLectureWithFile(
        title,
        'blue',
        content: content,
        document: document,
      );
      if (newLecture != null) {
        lectures.add(newLecture);
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Failed to add lecture with file';
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

  // Study plan methods
  Future<void> fetchStudyPlans(String start, String end) async {
    isLoadingPlans = true;
    notifyListeners();
    try {
      final plans = await ApiService.getStudyPlansByDateRange(start, end);
      studyPlansByDate = {};
      for (final plan in plans) {
        final date = plan['target_date'] as String;
        studyPlansByDate.putIfAbsent(date, () => []).add(plan);
      }
    } catch (e) {
      // silently fail for plans
    } finally {
      isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudyPlansForDate(String date) async {
    try {
      final plans = await ApiService.getStudyPlans(date: date);
      studyPlansByDate[date] = plans;
      notifyListeners();
    } catch (e) {
      // silently fail
    }
  }

  Future<Map<String, dynamic>?> createStudyPlan(String lectureId, String lectureTitle, String targetDate) async {
    try {
      final plan = await ApiService.createStudyPlan(lectureId, lectureTitle, targetDate);
      if (plan != null) {
        studyPlansByDate.putIfAbsent(targetDate, () => []).add(plan);
        notifyListeners();
        return plan;
      }
    } catch (e) {
      errorMessage = 'Failed to create study plan: $e';
      notifyListeners();
    }
    return null;
  }

  Future<void> toggleStudyPlan(String planId, String targetDate) async {
    try {
      final success = await ApiService.toggleStudyPlan(planId);
      if (success && studyPlansByDate.containsKey(targetDate)) {
        final plans = studyPlansByDate[targetDate]!;
        final idx = plans.indexWhere((p) => p['id'].toString() == planId);
        if (idx != -1) {
          plans[idx] = {
            ...plans[idx],
            'completed': plans[idx]['completed'] == 0 ? 1 : 0,
          };
          notifyListeners();
        }
      }
    } catch (e) {
      // silently fail
    }
  }

  Future<void> deleteStudyPlan(String planId, String targetDate) async {
    try {
      final success = await ApiService.deleteStudyPlan(planId);
      if (success && studyPlansByDate.containsKey(targetDate)) {
        studyPlansByDate[targetDate]!.removeWhere((p) => p['id'].toString() == planId);
        if (studyPlansByDate[targetDate]!.isEmpty) {
          studyPlansByDate.remove(targetDate);
        }
        notifyListeners();
      }
    } catch (e) {
      // silently fail
    }
  }

  List<Map<String, dynamic>> getPlansForDate(String date) {
    return studyPlansByDate[date] ?? [];
  }
}

// Global state instance for easy access across the clean architecture
final appState = AppState();
