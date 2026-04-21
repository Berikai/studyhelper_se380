/// Structure for a lecture item in the app
class LectureModel {
  final String id;
  final String title;
  final String dateText;
  final int questions;
  final String colorIcon;

  LectureModel({
    required this.id,
    required this.title,
    required this.dateText,
    required this.questions,
    required this.colorIcon,
  });
}
