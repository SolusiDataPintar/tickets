import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String label, text;
  final TextStyle? labelStyle, textStyle;
  const LabeledText({
    super.key,
    required this.label,
    required this.text,
    this.labelStyle,
    this.textStyle,
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
          Text(
            text,
            style: textStyle,
          ),
        ],
      );
}
