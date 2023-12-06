import 'package:flutter/material.dart';
import 'package:tickets/widget/glass.dart';

class Empty extends StatelessWidget {
  const Empty({super.key});
  @override
  Widget build(final BuildContext context) => const SizedBox(
        height: 50,
        child: GlassContainer(
          tintColor: Colors.blueGrey,
          child: Center(
            child: Text(
              "No Item",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}
