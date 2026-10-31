import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/butikk/kategori_produkt.dart';

/// Kategori › Produkter, the product cards (Onboarding Step 6): the grid's
/// rows, the tag colours and the store mark without a logo.
void main() {
  test('the hero takes the first row alone, the rest go in pairs', () {
    expect(katProduktRader(0), isEmpty);
    expect(katProduktRader(1), [
      [0],
    ]);
    expect(katProduktRader(4), [
      [0],
      [1, 2],
      [3],
    ]);
    expect(katProduktRader(5), [
      [0],
      [1, 2],
      [3, 4],
    ]);
  });

  test('«Tilbud» is orange on white, «Ny» white on red, «Mest kjøpt» gold on ink', () {
    final t = katTagFarger('Tilbud', tilbud: 'Tilbud', ny: 'Ny');
    expect(t.gradient, isNotNull);
    expect(t.fg, Colors.white);
    final n = katTagFarger('Ny', tilbud: 'Tilbud', ny: 'Ny');
    expect(n.color, Colors.white);
    expect(n.fg.toARGB32(), 0xFFB8380F);
    final m = katTagFarger('Mest kjøpt', tilbud: 'Tilbud', ny: 'Ny');
    expect(m.color?.toARGB32(), 0xFFF2C14E);
    expect(m.fg.toARGB32(), 0xFF23201D);
  });

  test('the store mark is two initials on a colour hashed from the name', () {
    final a = katMerke('Casa Maria');
    expect(a.mono, 'CM');
    expect(katMerke('Torgboden').mono, 'T');
    expect(katMerke('Bergen Baklava & Børekbakeri').mono, 'BB');
    // The same name always gets the same colour; it is one of the four.
    expect(katMerke('Casa Maria').bg, a.bg);
    expect(const [Color(0xFFB0472C), Color(0xFF2A6272), Color(0xFF8A5A1E), Color(0xFF4A3A6B)], contains(a.bg));
  });

  test('the cloth colours follow the store\'s place, four of each', () {
    expect(kKatBord.length, 4);
    expect(kKatBordDyp.length, 4);
    expect(kKatBord[1].toARGB32(), 0xFFFFDAD6);
  });
}
