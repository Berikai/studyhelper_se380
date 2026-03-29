import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<String> allLessons = []; 
  List<String> displayedLessons = [];
  TextEditingController searchController = TextEditingController();

  void filterLessons(String query) {
    setState(() {
      displayedLessons = allLessons
          .where((lesson) => lesson.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void addLesson() {
    TextEditingController newLessonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF242938), 
          title: const Text("Add Lesson", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: newLessonController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Lesson Name",
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newLessonController.text.isNotEmpty) {
                  setState(() {
                    allLessons.add(newLessonController.text);
                    filterLessons(searchController.text); 
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text("Library", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent, 
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: filterLessons,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search lectures...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF242938).withOpacity(0.8), 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: addLesson,
              icon: const Icon(Icons.add),
              label: const Text("Add Lesson"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: displayedLessons.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFF242938).withOpacity(0.9),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: Colors.blueAccent),
                      title: Text(
                        displayedLessons[index],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
