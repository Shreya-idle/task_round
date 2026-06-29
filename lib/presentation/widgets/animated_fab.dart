import 'package:flutter/material.dart';

class AnimatedFab extends StatefulWidget {
  const AnimatedFab({
    super.key,
    required this.onAddTask,
    required this.onToggleTheme,
  });

  final VoidCallback onAddTask;
  final VoidCallback onToggleTheme;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _isOpen = false;

  static const _actionSpacing = 64.0;
  static const _fabSize = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_fade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _closeAndRun(VoidCallback action) {
    action();
    if (_isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: _fabSize + (_actionSpacing * 2) + 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          _buildAction(
            bottom: _fabSize + (_actionSpacing * 2) + 12,
            icon: Icons.dark_mode_outlined,
            label: 'Theme',
            onTap: () => _closeAndRun(widget.onToggleTheme),
          ),
          _buildAction(
            bottom: _fabSize + _actionSpacing + 12,
            icon: Icons.add_task_rounded,
            label: 'New Task',
            onTap: () => _closeAndRun(widget.onAddTask),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(_isOpen ? Icons.close : Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required double bottom,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Positioned(
      right: 0,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !_isOpen && _controller.value == 0,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: 'fab_$label',
                  onPressed: onTap,
                  child: Icon(icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
