import 'package:flutter/material.dart';

import '../ui/kit/ae_loader.dart';

class FullScreenProgress extends StatelessWidget {
  final String message;

  const FullScreenProgress({super.key, this.message = ""});

  @override
  Widget build(BuildContext context) {
    return AeLoaderScreen(
      label: message.isEmpty ? null : message,
    );
  }
}
