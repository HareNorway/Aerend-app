import 'package:flutter_test/flutter_test.dart';

import 'package:aerend_customer/screens/bergen/kasse/kurv_beskjed.dart';

/// Kassen › Flere valg (Onboarding Step 7): the «Eget beløp» rule and the
/// store note's count and text.
void main() {
  test('«Eget beløp» keeps digits only, drops leading zeros, four digits, 2000 at most', () {
    expect(KasseValg.tipsEget(''), '');
    expect(KasseValg.tipsEget('0'), '');
    expect(KasseValg.tipsEget('0035'), '35');
    expect(KasseValg.tipsEget('35 kr'), '35');
    expect(KasseValg.tipsEget('12345'), '1234');
    expect(KasseValg.tipsEget('9999'), '2000');
    expect(KasseValg.tipsEget('abc'), '');
  });

  test('the note count is the chips plus the text when any; the text joins them with ·', () {
    expect(KasseValg.antall(const [], ''), 0);
    expect(KasseValg.antall(const ['Ingen bestikk'], '  '), 1);
    expect(KasseValg.antall(const ['Ingen bestikk', 'Allergi'], 'nøtter'), 3);
    expect(KasseValg.notat(const ['Ingen bestikk', 'Allergi'], ' nøtter '), 'Ingen bestikk · Allergi · nøtter');
    expect(KasseValg.notat(const [], ''), '');
  });

  // Design 21 Nov plan Step 2 (A2).
  test('the courier note is its parts with « · »; a chip toggles, the pair «Ring på» / «Ikke ring på» excludes', () {
    const mot = {'Ring på': 'Ikke ring på', 'Ikke ring på': 'Ring på'};
    expect(KasseValg.dorDeler(''), isEmpty);
    expect(KasseValg.dorDeler(' Porten står åpen ·  · Ring på '), ['Porten står åpen', 'Ring på']);
    expect(KasseValg.dorBytt('', 'Ring på', mot), 'Ring på');
    expect(KasseValg.dorBytt('Ring på', 'Porten står åpen', mot), 'Ring på · Porten står åpen');
    expect(KasseValg.dorBytt('Ring på · Porten står åpen', 'Ikke ring på', mot), 'Porten står åpen · Ikke ring på');
    expect(KasseValg.dorBytt('Porten står åpen · Ikke ring på', 'Ikke ring på', mot), 'Porten står åpen');
    expect(KasseValg.dorBytt('3. etasje', 'Legg igjen ved døra', mot), '3. etasje · Legg igjen ved døra');
  });

  test('the flat is dropped from the address title when it is a placeholder', () {
    expect(KasseValg.flatNo('3. etasje'), '3. etasje');
    expect(KasseValg.flatNo(' N/A '), isNull);
    expect(KasseValg.flatNo('na'), isNull);
    expect(KasseValg.flatNo('-'), isNull);
    expect(KasseValg.flatNo(''), isNull);
  });

  test('the phone reads 412 34 567', () {
    expect(KasseValg.tlf('41234567'), '412 34 567');
    expect(KasseValg.tlf('+47 412 34 567'), '412 34 567');
    expect(KasseValg.tlf('004741234567'), '004741234567');
    expect(KasseValg.tlf(''), '');
    expect(KasseValg.tlf(' +45 12 34 56 78 '), '+45 12 34 56 78');
  });
}
