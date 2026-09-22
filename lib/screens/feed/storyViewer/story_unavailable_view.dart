import 'package:flutter/material.dart';

/// Shown in place of a story whose media has expired (handover T3).
///
/// Names the store, so the viewer knows *whose* story ended rather than
/// wondering which one they lost, and reports the expiry to the viewer exactly
/// once — `initState` rather than `build`, which runs again on every repaint.
class StoryUnavailableView extends StatefulWidget {
  const StoryUnavailableView({
    super.key,
    required this.storeName,
    required this.message,
    required this.onExpired,
  });

  final String storeName;
  final String message;
  final VoidCallback onExpired;

  @override
  State<StoryUnavailableView> createState() => _StoryUnavailableViewState();
}

class _StoryUnavailableViewState extends State<StoryUnavailableView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('story_unavailable'),
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_delete_outlined,
                  color: Colors.white70, size: 48),
              const SizedBox(height: 14),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.storeName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
