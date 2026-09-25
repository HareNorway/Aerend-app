import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;

/// The dashboard's SVGs were extracted from the design file; every one must
/// parse with flutter_svg's compiler (no filters, no unsupported CSS).
void main() {
  final dir = Directory('assets/svgs/dashboard');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .toList();

  test('dashboard svg folder is not empty', () {
    expect(files, isNotEmpty);
  });

  for (final f in files) {
    test('${f.uri.pathSegments.last} parses', () {
      final src = f.readAsStringSync();
      final result = vg.parseWithoutOptimizers(src, key: f.path);
      expect(result.paths.length + result.text.length + result.images.length,
          greaterThan(0));
    });
  }
}
