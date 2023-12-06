import 'package:flutter/material.dart';
import 'package:tickets/widget/glass.dart';

class AppBarThemed extends StatelessWidget {
  final double height;
  final Widget? child;
  const AppBarThemed({super.key, this.height = 100, this.child});
  @override
  Widget build(final BuildContext context) => Container(
        height: 100,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: GlassContainer(
          child: SizedBox(height: height, child: child),
        ),
      );
}
