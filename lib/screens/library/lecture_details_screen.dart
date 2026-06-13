import 'package:flutter/material.dart';
import '../../models/lecture_model.dart';
import '../../services/api_service.dart';
import 'study_session_screen.dart';
import 'flashcard_screen.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'package:file_picker/file_picker.dart';

class LectureDetailsScreen extends StatefulWidget {
  final LectureModel lecture;

  const LectureDetailsScreen({super.key, required this.lecture});

  @override
  State<LectureDetailsScreen> createState() => _LectureDetailsScreenState();
}

class _LectureDetailsScreenState extends State<LectureDetailsScreen> {
  List<dynamic> _curriculum = [];
  bool _isLoading = true;
  String _successRate = "0%";
  List<String> _docs = [];

  @override
  void initState() {
    super.initState();
    _docs = List.from(widget.lecture.documents);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Provider.of<AppState>(context, listen: false).fetchLectures();
      final history = await ApiService.getStudyHistory();
      int totalCorrect = 0;
      int totalQuestions = 0;
      for (var h in history) {
        if (h['lecture_id'] == widget.lecture.id) {
          totalCorrect += (h['score'] as int? ?? 0);
          totalQuestions += (h['total_questions'] as int? ?? 0);
        }
      }
      
      final curriculum = await ApiService.generateCurriculum(widget.lecture.id, widget.lecture.title);
      if (mounted) {
        setState(() {
          if (totalQuestions > 0) {
            _successRate = "${(totalCorrect / totalQuestions * 100).toStringAsFixed(0)}%";
          }
          _curriculum = curriculum;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshCurriculum() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final curriculum = await ApiService.generateCurriculum(widget.lecture.id, widget.lecture.title, force: true);
      if (mounted) {
        setState(() {
          _curriculum = curriculum;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error refreshing curriculum: $e')));
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final updatedDocs = await ApiService.addDocument(widget.lecture.id, file);
        setState(() {
          _docs = updatedDocs;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded ${file.name}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }



  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.lecture.title);
    final contentController = TextEditingController(text: widget.lecture.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff181a26),
        title: const Text('Edit Lecture', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title', 
                labelStyle: TextStyle(color: Colors.blueAccent),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Content / Notes', 
                labelStyle: TextStyle(color: Colors.blueAccent),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              final success = await appState.updateLecture(widget.lecture.id, titleController.text, contentController.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lecture updated')));
                  setState(() {}); // Refresh local UI
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff181a26),
        title: const Text('Delete Lecture', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this lecture? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              final success = await appState.deleteLecture(widget.lecture.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                if (success) {
                  Navigator.pop(context); // Go back to library
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff181a26),
        title: const Text('Share Flashcards', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of the user you want to share these flashcards with:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'User Email',
                labelStyle: TextStyle(color: Colors.blueAccent),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              
              Navigator.pop(context); // Close dialog
              
              try {
                await ApiService.shareFlashcards(widget.lecture.id, email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flashcards shared successfully!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                }
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lecture = appState.lectures.firstWhere((l) => l.id == widget.lecture.id, orElse: () => widget.lecture);

    return Scaffold(
      backgroundColor: const Color(0xff12141D),
      appBar: AppBar(
        title: Text(lecture.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xff222536),
            onSelected: (value) {
              if (value == 'edit') _showEditDialog();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff222536),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Flashcards:', style: TextStyle(color: Colors.white70)),
                      Text('${lecture.flashcards.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Questions Attempted:', style: TextStyle(color: Colors.white70)),
                      Text('${lecture.questions}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Success Rate:', style: TextStyle(color: Colors.white70)),
                      Text(_successRate, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.style, color: Colors.white),
                      label: const Text('View Flashcards', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardScreen(lecture: lecture)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Share Flashcards', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        _showShareDialog();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Documents Section
            const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff222536),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: Colors.blueAccent, size: 32),
                      SizedBox(height: 8),
                      Text("Tap to upload PDF or Text", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ],
                  )
                ),
              ),
            ),
            const SizedBox(height: 16),
            _docs.isEmpty 
                ? const SizedBox.shrink()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _docs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: const Color(0xff222536).withOpacity(0.5),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.description, color: Colors.white70, size: 20),
                          title: Text(_docs[index], style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final updatedDocs = await ApiService.removeDocument(widget.lecture.id, index);
                              setState(() => _docs = updatedDocs);
                            },
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Study Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                  onPressed: _refreshCurriculum,
                  tooltip: 'Refresh Curriculum',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _curriculum.length,
                    itemBuilder: (context, index) {
                      final item = _curriculum[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.2), child: Text('${index + 1}', style: const TextStyle(color: Colors.blueAccent))),
                        title: Text(item['topic'] ?? 'Topic', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(item['duration'] ?? 'Duration', style: const TextStyle(color: Colors.white70)),
                      );
                    },
                  ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudySessionScreen(lecture: lecture),
                    ),
                  ).then((_) {
                      _fetchData(); // Refresh stats on return
                      context.read<AppState>().fetchUserInfo(); // Refresh credits
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Studying', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
