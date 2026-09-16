class ReceiptTask {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  ReceiptTask({
    required this.id,
    required this.title,
    bool isDone = false,
    bool? isCompleted,
    DateTime? createdAt,
  })  : isDone = isCompleted ?? isDone,
        createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => isDone;

  ReceiptTask copyWith({
    String? id,
    String? title,
    bool? isDone,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ReceiptTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isCompleted ?? isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
