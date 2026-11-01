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
}
