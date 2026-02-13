class AdaptationTask {
  final String id;
  final String text;
  final String hint;
  bool isCompleted;

  AdaptationTask(
      {required this.id,
      required this.text,
      required this.hint,
      this.isCompleted = false});

  factory AdaptationTask.fromJson(Map<String, dynamic> json) {
    return AdaptationTask(
      id: json['id'],
      text: json['text'],
      hint: json['hint'],
    );
  }
}

class AdaptationCategory {
  final String title;
  final List<AdaptationTask> tasks;

  AdaptationCategory({required this.title, required this.tasks});
}
