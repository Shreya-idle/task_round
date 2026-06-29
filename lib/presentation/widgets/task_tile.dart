import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.dragHandle,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueLabel = task.dueDate != null
        ? DateFormat('MMM d, yyyy').format(task.dueDate!)
        : null;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dragHandle,
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggleComplete(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Chip(label: task.category),
                        if (dueLabel != null)
                          _Chip(
                            label: dueLabel,
                            color: isOverdue
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.secondaryContainer,
                            textColor: isOverdue
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        if (task.reminderAt != null)
                          _Chip(
                            label:
                                'Reminder ${DateFormat('HH:mm').format(task.reminderAt!)}',
                            icon: Icons.notifications_active_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.color,
    this.textColor,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
