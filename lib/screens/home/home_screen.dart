import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final lectures = appState.lectures;

        int totalFlashcards = 0;
        for (var l in lectures) {
          totalFlashcards += l.questions;
        }

        // Find lecture with most questions as "Most Studied"
        var mostStudiedLecture = lectures.isNotEmpty ? lectures.first : null;
        for (var l in lectures) {
          if (mostStudiedLecture != null && l.questions > mostStudiedLecture.questions) {
            mostStudiedLecture = l;
          }
        }

        // Find lecture with least questions for suggestions
        var leastStudiedLecture = lectures.isNotEmpty ? lectures.first : null;
        for (var l in lectures) {
          if (leastStudiedLecture != null && l.questions < leastStudiedLecture.questions) {
            leastStudiedLecture = l;
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Dashboard',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff222536),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    sixWeekMonthsEnforced: true,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle:
                          TextStyle(color: Colors.white),
                      weekendTextStyle:
                          TextStyle(color: Colors.grey),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle:
                          TextStyle(color: Colors.white),
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: Colors.white),
                      rightChevronIcon:
                          Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Welcome back, Student!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here is your study overview for today.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Statistics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Flashcards',
                        '$totalFlashcards', Icons.style, Colors.blueAccent),
                    _buildStatCard('Total Lectures',
                        '${lectures.length}', Icons.book, Colors.green),
                    _buildStatCard('Time Studied',
                        '${totalFlashcards * 2}m', Icons.timer, Colors.orange),
                    _buildStatCard('Mastery',
                        'In Progress', Icons.stars, Colors.pinkAccent),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  'Most Studied Lecture',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),

                if (mostStudiedLecture != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff222536),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book,
                              color: Colors.teal),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                mostStudiedLecture.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${mostStudiedLecture.questions} flashcards generated',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'No lectures yet. Create one to see stats!',
                    style: TextStyle(color: Colors.grey),
                  ),

                const SizedBox(height: 24),

                const Text(
                  'AI Study Suggestions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),

                if (leastStudiedLecture != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.8),
                          Colors.purpleAccent.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Recommended Plan',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You should focus on "${leastStudiedLecture.title}". It currently has the least amount of flashcards (${leastStudiedLecture.questions}). Generate more flashcards to improve mastery!',
                          style:
                              const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Can navigate to lecture if we want
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                          ),
                          child: const Text('Start reviewing'),
                        )
                      ],
                    ),
                  )
                else
                  const Text(
                    'Create a lecture to get AI suggestions.',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff222536),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ],
      ),
    );
  }
}
