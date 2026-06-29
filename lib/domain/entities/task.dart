import 'package:equatable/equatable.dart';

class Task extends Equatable {
  const Task({
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
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? completedAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? Function()? dueDate,
    DateTime? Function()? reminderAt,
    DateTime? Function()? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      reminderAt: reminderAt != null ? reminderAt() : this.reminderAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        isCompleted,
        sortOrder,
        createdAt,
        dueDate,
        reminderAt,
        completedAt,
      ];
}
