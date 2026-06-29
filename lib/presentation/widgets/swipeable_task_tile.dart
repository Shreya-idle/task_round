import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../domain/entities/task.dart';
import 'task_tile.dart';

class SwipeableTaskTile extends StatelessWidget {
  const SwipeableTaskTile({
    super.key,
    required this.task,
    required this.index,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final Task task;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete_outline,
            borderRadius: BorderRadius.circular(16),
            label: 'Delete',
          ),
        ],
      ),
      child: TaskTile(
        task: task,
        onTap: onTap,
        onToggleComplete: onToggleComplete,
        dragHandle: ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.drag_handle,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
