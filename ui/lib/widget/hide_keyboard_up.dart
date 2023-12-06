import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

Widget _kTransitionBuilder(
  final Widget child,
  final Animation<double> animation,
) =>
    ScaleTransition(
      scale: animation,
      child: child,
    );

class HideKeyboardUp extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  const HideKeyboardUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.transitionBuilder = _kTransitionBuilder,
  });
  @override
  Widget build(final BuildContext context) => KeyboardVisibilityBuilder(
        builder: (final _, final isVisible) => AnimatedSwitcher(
          duration: duration,
          transitionBuilder: transitionBuilder,
          child: isVisible ? const SizedBox() : child,
        ),
      );
}
