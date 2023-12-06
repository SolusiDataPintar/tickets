import 'package:flutter/material.dart';
import 'package:tickets/generated/l10n.dart';

class ErrorStatus extends StatelessWidget {
  final String? err;
  final VoidCallback? onTry;
  const ErrorStatus({super.key, this.err, this.onTry});
  @override
  Widget build(final BuildContext context) {
    const style = TextStyle(
      color: Colors.grey,
      fontSize: 12.0,
    );
    return Center(
      child: onTry == null
          ? Text(
              err ?? S.of(context).errorOccurred,
              style: style,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  err ?? S.of(context).errorOccurred,
                  style: style,
                ),
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onTry,
                ),
              ],
            ),
    );
  }
}
