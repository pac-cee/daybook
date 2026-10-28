class Task {
  Task({
    required this.id,
    required String title,
    this.notes = '',
    this.priority = 0,
    this.done = false,
    this.due,
    DateTime? created,
  }) : title = title.trim(),
       created = created ?? DateTime.now() {
    if (this.title.isEmpty || this.title.length > 160) {
      throw ArgumentError('Use a title of 1–160 characters.');
    }
    if (priority < 0 || priority > 2) throw ArgumentError('Invalid priority');
  }
  final String id, title, notes;
  final int priority;
  final bool done;
  final DateTime? due;
  final DateTime created;
  Task copyWith({String? title, String? notes, int? priority, bool? done}) =>
      Task(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        priority: priority ?? this.priority,
        done: done ?? this.done,
        due: due,
        created: created,
      );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'priority': priority,
    'done': done ? 1 : 0,
    'due': due?.toIso8601String(),
    'created': created.toIso8601String(),
  };
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    notes: json['notes'] as String,
    priority: json['priority'] as int,
    done: json['done'] == 1,
    due: json['due'] == null ? null : DateTime.parse(json['due'] as String),
    created: DateTime.parse(json['created'] as String),
  );
}
