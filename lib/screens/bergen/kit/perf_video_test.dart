import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../main.dart' show navigatorKey;

/// Heat test only (harness `videoTest: "<file in documents>"`): plays a
/// looping video over the whole screen, pointer-transparent, to measure what
/// decoding and drawing a video costs on Impeller next to the live screen.
/// Never shown outside a harness run.
class PerfVideoTest {
  static OverlayEntry? _entry;
  static VideoPlayerController? _c;

  static Future<void> start(String file) async {
    stop();
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$file');
    if (!await f.exists()) {
      debugPrint('PERF_VIDEO missing ${f.path}');
      return;
    }
    final c = VideoPlayerController.file(f);
    _c = c;
    await c.initialize();
    await c.setLooping(true);
    await c.setVolume(0);
    await c.play();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final o = navigatorKey.currentState?.overlay;
      if (o == null || _c != c) return;
      _entry = OverlayEntry(
        builder: (_) => IgnorePointer(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
            ),
          ),
        ),
      );
      o.insert(_entry!);
      debugPrint('PERF_VIDEO playing ${c.value.size}');
    });
  }

  static void stop() {
    _entry?.remove();
    _entry = null;
    _c?.dispose();
    _c = null;
  }
}
