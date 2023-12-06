import 'package:flutter/material.dart';

class LabeledWidget extends StatelessWidget {
  final String label;
  final Widget content;
  final TextStyle? labelStyle;
  const LabeledWidget({
    super.key,
    required this.label,
    required this.content,
    this.labelStyle,
  });
  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: labelStyle ??
                const TextStyle(
                  color: Colors.grey,
                  fontSize: 10.0,
                ),
          ),
          const SizedBox(height: 1),
          content,
        ],
      );
}
