import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SessionDetailScreen extends StatelessWidget {
  final List<dynamic> sessionData;
  final String lectureTitle;
  final String date;

  const SessionDetailScreen({
    super.key, 
    required this.sessionData, 
    required this.lectureTitle,
    required this.date,
  });

  Widget _buildMathText(String text, {TextStyle? style}) {
    final parts = text.split('\$');
    List<Widget> children = [];
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        children.add(Math.tex(
          parts[i],
          textStyle: style?.copyWith(color: Colors.white),
          mathStyle: MathStyle.display,
        ));
      } else if (parts[i].isNotEmpty) {
        children.add(Text(parts[i], style: style));
      }
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141D),
      appBar: AppBar(
        title: Text(lectureTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessionData.length,
        itemBuilder: (context, index) {
          final item = sessionData[index];
          final bool isCorrect = item['selectedIndex'] == item['correctIndex'];
          
          return Card(
            color: const Color(0xff1C1F2E),
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: TextStyle(color: Colors.blueAccent.shade100, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMathText(
                    item['question'],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(item['options'].length, (optIndex) {
                    final bool isSelected = optIndex == item['selectedIndex'];
                    final bool isActualCorrect = optIndex == item['correctIndex'];
                    
                    Color bgColor = Colors.transparent;
                    Color borderColor = Colors.white10;
                    IconData? icon;

                    if (isActualCorrect) {
                      bgColor = Colors.green.withOpacity(0.1);
                      borderColor = Colors.green.withOpacity(0.5);
                      icon = Icons.check_circle;
                    } else if (isSelected && !isCorrect) {
                      bgColor = Colors.red.withOpacity(0.1);
                      borderColor = Colors.red.withOpacity(0.5);
                      icon = Icons.cancel;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['options'][optIndex],
                              style: TextStyle(
                                color: isSelected || isActualCorrect ? Colors.white : Colors.white60,
                                fontWeight: isSelected || isActualCorrect ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (icon != null) Icon(icon, size: 18, color: icon == Icons.check_circle ? Colors.green : Colors.red),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Explanation', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['explanation'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
