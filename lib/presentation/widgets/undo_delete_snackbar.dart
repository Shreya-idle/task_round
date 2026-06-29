import 'dart:async';

import 'package:flutter/material.dart';

class UndoDeleteSnackBar extends StatefulWidget {
  const UndoDeleteSnackBar({
    super.key,
    required this.taskTitle,
    required this.initialSeconds,
    required this.onUndo,
  });

  final String taskTitle;
  final int initialSeconds;
  final VoidCallback onUndo;

  @override
  State<UndoDeleteSnackBar> createState() => _UndoDeleteSnackBarState();
}

class _UndoDeleteSnackBarState extends State<UndoDeleteSnackBar> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 999));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('"${widget.taskTitle}" deleted · undo in ${_secondsLeft}s'),
        ),
        TextButton(onPressed: widget.onUndo, child: const Text('UNDO')),
      ],
    );
  }
}
