import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'session_detail_screen.dart';
import 'dart:convert';

class StudyHistoryScreen extends StatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  State<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends State<StudyHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ApiService.getStudyHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xff12141D),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No study history found.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final date = item['date'] ?? 'Unknown date';
                    final title = item['lecture_title'] ?? 'Unknown lecture';
                    final score = item['score'] ?? 0;
                    final total = item['total_questions'] ?? 0;
                    final percentage = total > 0 ? (score / total * 100).toStringAsFixed(0) : 0;
                    final String? sessionDataRaw = item['session_data'];

                    return Card(
                      color: const Color(0xff222536),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: sessionDataRaw == null ? null : () {
                          try {
                            final List<dynamic> sessionData = jsonDecode(sessionDataRaw);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionDetailScreen(
                                  sessionData: sessionData, 
                                  lectureTitle: title,
                                  date: date,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load session details')));
                          }
                        },
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.blueAccent),
                          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: $date', style: const TextStyle(color: Colors.white70)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$score/$total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('$percentage%', style: const TextStyle(color: Colors.blueAccent)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
