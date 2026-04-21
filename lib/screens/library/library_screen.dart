import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  TextEditingController searchController = TextEditingController();

  // This function will be called whenever the search textfield changes.
  // It calls an empty setState to trigger a rebuild, and the filtering logic is handled in the ListenableBuilder below.
  void filterLessons(String query) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text("Library", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent, 
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search bar at the top of the library screen
            TextField(
              controller: searchController,
              onChanged: filterLessons,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search lectures...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF242938).withValues(alpha: 0.8), // withOpacity is deprecated, using withValues instead
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // Spacing between search bar and lecture list
            const SizedBox(height: 16),
            
            // List of lectures, wrapped in an Expanded to take up remaining space
            Expanded(
              child: ListenableBuilder(
                // Listen to changes in the app state to update the lecture list when new lectures are added or when loading state changes
                listenable: appState, 
                // Builder function that builds the lecture list based on the current state of the app
                builder: (context, child) {
                  // Filter lectures with searchController text, ignoring case
                  final displayedLectures = appState.lectures
                    .where((lec) => lec.title.toLowerCase().contains(searchController.text.toLowerCase()))
                    .toList();

                  if (appState.isLoading && displayedLectures.isEmpty) {
                     return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }

                  return ListView.builder(
                    itemCount: displayedLectures.length,
                    itemBuilder: (context, index) {
                      final lecture = displayedLectures[index];
                      
                      Color iconBgColor = Colors.blueAccent;
                      if (lecture.colorIcon == "green") iconBgColor = Colors.teal;
                      if (lecture.colorIcon == "orange") iconBgColor = Colors.orange;
                      if (lecture.colorIcon == "pink") iconBgColor = Colors.pinkAccent;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xff222536),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: iconBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.book, color: Colors.white),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lecture.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 5),
                                    Text(lecture.dateText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1A1C29), // Same as bottom nav bg for contrast
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.message, color: Colors.blueAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text("${lecture.questions}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ]
                                )
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}