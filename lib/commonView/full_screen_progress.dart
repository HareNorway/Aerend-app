import 'package:flutter/material.dart';

import 'dugnad_club_loader.dart';

class FullScreenProgress extends StatelessWidget {
  final String message;

  const FullScreenProgress({super.key, this.message = ""});

  @override
  Widget build(BuildContext context) {
    return DugnadClubLoaderScreen(
      label: message.isEmpty ? null : message,
    );
  }
}
