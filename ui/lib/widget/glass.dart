import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tickets/generated/assets.gen.dart';

class GlassContainer extends StatelessWidget {
  final double sigmaX;
  final double sigmaY;
  final BorderRadiusGeometry clipBorderRadius;
  final Color tintColor;
  final Widget child;
  const GlassContainer({
    super.key,
    required this.child,
    this.sigmaX = 10,
    this.sigmaY = 10,
    this.tintColor = Colors.white,
    this.clipBorderRadius = BorderRadius.zero,
  });
  @override
  Widget build(final BuildContext context) => ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: clipBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: sigmaX,
            sigmaY: sigmaY,
            tileMode: TileMode.clamp,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: (tintColor != Colors.transparent)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tintColor.withOpacity(0.1),
                        tintColor.withOpacity(0.08),
                      ],
                    )
                  : null,
              image: DecorationImage(
                image: AssetImage(Assets.images.noise.path),
                fit: BoxFit.cover,
              ),
            ),
            child: child,
          ),
        ),
      );
}
