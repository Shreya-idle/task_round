import '../../domain/entities/task.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    required this.sortOrder,
    required this.createdAt,
    this.dueDate,
    this.reminderAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;
  final int sortOrder;
  final int createdAt;
  final int? dueDate;
  final int? reminderAt;
  final int? completedAt;

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      isCompleted: task.isCompleted,
      sortOrder: task.sortOrder,
      createdAt: task.createdAt.millisecondsSinceEpoch,
      dueDate: task.dueDate?.millisecondsSinceEpoch,
      reminderAt: task.reminderAt?.millisecondsSinceEpoch,
      completedAt: task.completedAt?.millisecondsSinceEpoch,
    );
  }

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      category: category,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      dueDate: dueDate != null
          ? DateTime.fromMillisecondsSinceEpoch(dueDate!)
          : null,
      reminderAt: reminderAt != null
          ? DateTime.fromMillisecondsSinceEpoch(reminderAt!)
          : null,
      completedAt: completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(completedAt!)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'is_completed': isCompleted ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': createdAt,
        'due_date': dueDate,
        'reminder_at': reminderAt,
        'completed_at': completedAt,
      };

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      sortOrder: map['sort_order'] as int,
      createdAt: map['created_at'] as int,
      dueDate: map['due_date'] as int?,
      reminderAt: map['reminder_at'] as int?,
      completedAt: map['completed_at'] as int?,
    );
  }
}
