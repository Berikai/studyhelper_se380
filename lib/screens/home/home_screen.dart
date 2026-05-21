import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../state/app_state.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _plansLoaded = false;
  List<dynamic> _studyHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await ApiService.getStudyHistory();
      if (mounted) {
        setState(() {
          _studyHistory = history;
        });
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _loadMonthPlans(AppState appState) {
    final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    appState.fetchStudyPlans(
      _formatDate(start),
      _formatDate(end),
    );
  }

  void _showAddPlanDialog(AppState appState) {
    if (_selectedDay == null || appState.lectures.isEmpty) return;
    final dateStr = _formatDate(_selectedDay!);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xff1A1C29),
          title: Text('Study Plan for $dateStr', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: appState.lectures.length,
              itemBuilder: (_, i) {
                final lec = appState.lectures[i];
                return ListTile(
                  leading: Icon(Icons.book, color: _getColorForLecture(lec.colorIcon)),
                  title: Text(lec.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${lec.questions} questions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () {
                    appState.createStudyPlan(lec.id, lec.title, dateStr);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForLecture(String colorIcon) {
    switch (colorIcon) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pinkAccent;
      default: return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!_plansLoaded) {
          _plansLoaded = true;
          _loadMonthPlans(appState);
        }

        final lectures = appState.lectures;

        int totalFlashcards = 0;
        for (var l in lectures) {
          totalFlashcards += l.questions;
        }

        var mostStudiedLecture = lectures.isNotEmpty ? lectures.first : null;
        for (var l in lectures) {
          if (mostStudiedLecture != null && l.questions > mostStudiedLecture.questions) {
            mostStudiedLecture = l;
          }
        }

        var leastStudiedLecture = lectures.isNotEmpty ? lectures.first : null;
        for (var l in lectures) {
          if (leastStudiedLecture != null && l.questions < leastStudiedLecture.questions) {
            leastStudiedLecture = l;
          }
        }

        int totalCorrectAnswers = 0;
        int totalQuestionsAttempted = 0;
        for (var session in _studyHistory) {
          totalCorrectAnswers += (session['score'] as num?)?.toInt() ?? 0;
          totalQuestionsAttempted += (session['total_questions'] as num?)?.toInt() ?? 0;
        }
        double rate = totalQuestionsAttempted > 0 ? (totalCorrectAnswers / totalQuestionsAttempted) : 0.0;
        String masteryText = '${(rate * 100).toStringAsFixed(0)}%';
        
        if (totalQuestionsAttempted == 0) {
          masteryText = 'No Data';
        } else if (rate >= 0.9) {
          masteryText = 'Master ($masteryText)';
        } else if (rate >= 0.7) {
          masteryText = 'Adept ($masteryText)';
        } else {
          masteryText = 'Novice ($masteryText)';
        }

        final selectedDateStr = _selectedDay != null ? _formatDate(_selectedDay!) : null;
        final dayPlans = selectedDateStr != null ? appState.getPlansForDate(selectedDateStr) : [];

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text('Welcome back, Student!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Here is your study overview for today.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 24),

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
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        final dateStr = _formatDate(day);
                        final dayPlans = appState.getPlansForDate(dateStr);
                        if (dayPlans.isEmpty) return null;
                        final hasCompleted = dayPlans.any((p) => p['completed'] == 1);
                        final hasPending = dayPlans.any((p) => p['completed'] == 0);
                        return Positioned(
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasPending)
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                ),
                              if (hasPending && hasCompleted) const SizedBox(width: 2),
                              if (hasCompleted)
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      final dateStr = _formatDate(selectedDay);
                      appState.fetchStudyPlansForDate(dateStr);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadMonthPlans(appState);
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                      defaultTextStyle: TextStyle(color: Colors.white),
                      weekendTextStyle: TextStyle(color: Colors.grey),
                      markerDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(color: Colors.white),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ),

                if (_selectedDay != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Study Plan: ${_formatDate(_selectedDay!)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddPlanDialog(appState),
                        icon: const Icon(Icons.add, color: Colors.blueAccent, size: 18),
                        label: const Text('Add Plan', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                  if (dayPlans.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff222536),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event_note, color: Colors.grey, size: 32),
                          const SizedBox(height: 8),
                          const Text('No study plans for this day', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          const Text('Tap "Add Plan" to schedule a lecture', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...dayPlans.map((plan) {
                      final completed = plan['completed'] == 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xff222536),
                          borderRadius: BorderRadius.circular(12),
                          border: completed
                              ? Border.all(color: Colors.green.withOpacity(0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => appState.toggleStudyPlan(plan['id'].toString(), selectedDateStr!),
                              child: Icon(
                                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: completed ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['lecture_title'] ?? 'Untitled',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: completed ? Colors.grey : Colors.white,
                                      decoration: completed ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => appState.deleteStudyPlan(plan['id'].toString(), selectedDateStr!),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                ],

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Total Flashcards', '$totalFlashcards', Icons.style, Colors.blueAccent),
                    _buildStatCard('Total Lectures', '${lectures.length}', Icons.book, Colors.green),
                    _buildStatCard('Time Studied', '${totalFlashcards * 2}m', Icons.timer, Colors.orange),
                    _buildStatCard('Mastery', masteryText, Icons.stars, Colors.pinkAccent),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('Most Studied Lecture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),

                if (mostStudiedLecture != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xff222536), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.menu_book, color: Colors.teal),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mostStudiedLecture.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('${mostStudiedLecture.questions} flashcards generated',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text('No lectures yet. Create one to see stats!', style: TextStyle(color: Colors.grey)),

                /*
                const SizedBox(height: 24),
                const Text('AI Study Suggestions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),

                if (leastStudiedLecture != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withOpacity(0.8), Colors.purpleAccent.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.auto_awesome, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Recommended Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                        const SizedBox(height: 12),
                        Text(
                          'You should focus on "${leastStudiedLecture.title}". It currently has the least amount of flashcards (${leastStudiedLecture.questions}). Generate more flashcards to improve mastery!',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent),
                          child: const Text('Start reviewing'),
                        ),
                      ],
                    ),
                  )
                else
                  const Text('Create a lecture to get AI suggestions.', style: TextStyle(color: Colors.grey)),*/
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xff222536), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
