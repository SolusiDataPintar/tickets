import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

@RoutePage<String?>()
class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});
  @override
  Widget build(final BuildContext context) =>
      const SimpleBarcodeScannerPage(scanType: ScanType.qr);
}
