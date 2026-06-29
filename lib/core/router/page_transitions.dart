import 'package:flutter/material.dart';

class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  SlideFadePageRoute({
    required Widget page,
    super.settings,
    Axis axis = Axis.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final offsetTween = axis == Axis.horizontal
                ? Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
                : Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero);

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: offsetTween.animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
        );
}
