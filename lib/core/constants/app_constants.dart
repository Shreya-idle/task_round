class AppConstants {
  static const String dbName = 'task_manager_pro.db';
  static const int dbVersion = 1;

  static const int undoDeleteSeconds = 5;
  static const int searchDebounceMs = 350;

  static const List<String> categories = [
    'Work',
    'Personal',
    'Urgent',
    'Shopping',
    'Health',
  ];
}
