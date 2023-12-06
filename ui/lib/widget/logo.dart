import 'package:flutter/material.dart';
import 'package:tickets/generated/assets.gen.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});
  @override
  Widget build(final BuildContext context) => Assets.images.logo.image(
        height: 47,
        alignment: Alignment.topRight,
        scale: 2.5,
      );
}
