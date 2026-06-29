import 'package:equatable/equatable.dart';

enum TaskStatusFilter { all, pending, done }

enum DueDateFilter { all, today, overdue, thisWeek }

class TaskFilter extends Equatable {
  const TaskFilter({
    this.category,
    this.status = TaskStatusFilter.all,
    this.dueDateFilter = DueDateFilter.all,
    this.searchQuery = '',
  });

  final String? category;
  final TaskStatusFilter status;
  final DueDateFilter dueDateFilter;
  final String searchQuery;

  TaskFilter copyWith({
    String? Function()? category,
    TaskStatusFilter? status,
    DueDateFilter? dueDateFilter,
    String? searchQuery,
  }) {
    return TaskFilter(
      category: category != null ? category() : this.category,
      status: status ?? this.status,
      dueDateFilter: dueDateFilter ?? this.dueDateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'status': status.name,
        'dueDateFilter': dueDateFilter.name,
        'searchQuery': searchQuery,
      };

  factory TaskFilter.fromJson(Map<String, dynamic> json) {
    return TaskFilter(
      category: json['category'] as String?,
      status: TaskStatusFilter.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatusFilter.all,
      ),
      dueDateFilter: DueDateFilter.values.firstWhere(
        (e) => e.name == json['dueDateFilter'],
        orElse: () => DueDateFilter.all,
      ),
      searchQuery: json['searchQuery'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [category, status, dueDateFilter, searchQuery];

  bool get hasActiveFilters =>
      category != null ||
      status != TaskStatusFilter.all ||
      dueDateFilter != DueDateFilter.all;

  List<String> get activeLabels {
    final labels = <String>[];
    if (category != null) labels.add(category!);
    if (status != TaskStatusFilter.all) {
      labels.add(switch (status) {
        TaskStatusFilter.all => 'All',
        TaskStatusFilter.pending => 'Pending',
        TaskStatusFilter.done => 'Done',
      });
    }
    if (dueDateFilter != DueDateFilter.all) {
      labels.add(switch (dueDateFilter) {
        DueDateFilter.all => 'Any date',
        DueDateFilter.today => 'Due today',
        DueDateFilter.overdue => 'Overdue',
        DueDateFilter.thisWeek => 'This week',
      });
    }
    return labels;
  }
}
