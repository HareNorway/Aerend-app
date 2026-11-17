import 'package:aerend_customer/screens/common/auth/launch/lf_css.dart';
import 'package:aerend_customer/theme/lys/bergen_modus.dart';
import 'package:aerend_customer/theme/lys/lys_palett.dart';
import 'package:aerend_customer/theme/lys/mk_stil.g.dart';
import 'package:aerend_customer/theme/lys/modus_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Teller extends StatelessWidget {
  const _Teller(this.ut);
  final List<bool> ut;

  @override
  Widget build(BuildContext context) {
    ut.add(context.lys);
    return const SizedBox();
  }
}

void main() {
  setUp(() => BergenModus.i.tilbakestill());

  test('default is Mørk when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    await BergenModus.i.last();
    expect(BergenModus.i.lys, isFalse);
  });

  test('a saved «lys» loads as Lys; anything else is Mørk', () async {
    SharedPreferences.setMockInitialValues({BergenModus.nokkel: 'lys'});
    await BergenModus.i.last();
    expect(BergenModus.i.lys, isTrue);
    SharedPreferences.setMockInitialValues({BergenModus.nokkel: 'tull'});
    await BergenModus.i.last();
    expect(BergenModus.i.lys, isFalse);
  });

  test('sett saves the mode on the phone (aerend.modus.v1)', () async {
    SharedPreferences.setMockInitialValues({});
    BergenModus.i.sett(true, stille: true);
    await Future<void>.delayed(Duration.zero);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('aerend.modus.v1'), 'lys');
    BergenModus.i.sett(false, stille: true);
    await Future<void>.delayed(Duration.zero);
    expect(p.getString('aerend.modus.v1'), 'mork');
  });

  testWidgets('the scope rebuilds readers on a switch, and only on a switch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: BergenModusRot(child: _TellerHolder())));
    expect(_TellerHolder.ut, [false]);
    BergenModus.i.sett(true, stille: true);
    await tester.pump();
    expect(_TellerHolder.ut, [false, true]);
    // The same mode again: nothing to do.
    BergenModus.i.sett(true, stille: true);
    await tester.pump();
    expect(_TellerHolder.ut, [false, true]);
    _TellerHolder.ut.clear();
  });

  testWidgets('a fjord subtree stays dark in Lys', (tester) async {
    BergenModus.i.tilbakestill(lys: true);
    final inne = <bool>[], ute = <bool>[];
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: BergenModusRot(child: Column(children: [_Teller(ute), ModusFjord(child: _Teller(inne))])),
    ));
    expect(ute.last, isTrue);
    expect(inne.last, isFalse);
  });

  testWidgets('aeM picks the light value only in Lys', (tester) async {
    BergenModus.i.tilbakestill(lys: true);
    late String v;
    await tester.pumpWidget(BergenModusRot(child: Builder(builder: (c) {
      v = c.aeM('mork', 'lys');
      return const SizedBox();
    })));
    expect(v, 'lys');
    BergenModus.i.sett(false, stille: true);
    await tester.pump();
    expect(v, 'mork');
  });

  test('the generated table matches the design CSS (spot check)', () {
    expect(mkAlle.length, 566);
    // .mk0 dark color:rgba(255,255,255,.62) / light rgba(255,255,255,.82)
    expect(mk0.dark!.farge, const Color.fromRGBO(255, 255, 255, .62));
    expect(mk0.light!.farge, const Color.fromRGBO(255, 255, 255, .82));
    // .mk3 light background:var(--lys-ull);color:var(--lys-brod)
    expect((mk3.light!.bg!.single as CssSolid).color, LysPalett.ull);
    expect(mk3.light!.farge, LysPalett.brod);
    // .mk4 has no dark rule
    expect(mk4.dark, isNull);
    // .mk5 light: --lys-hvit / --lys-tittel
    expect((mk5.light!.bg!.single as CssSolid).color, LysPalett.hvit);
    expect(mk5.light!.farge, LysPalett.tittel);
    // .mk7 dark rgba(4,18,26,.45) → light --lys-dis
    expect((mk7.dark!.bg!.single as CssSolid).color, const Color.fromRGBO(4, 18, 26, .45));
    expect((mk7.light!.bg!.single as CssSolid).color, LysPalett.dis);
    // sheet: .mkd1 cream → --lys-ark tone, .mkd3 handle, .mkd4 title, .mkd5 line
    expect((mkd1.light!.bg!.single as CssSolid).color, const Color.fromRGBO(247, 251, 253, .94));
    expect((mkd3.light!.bg!.single as CssSolid).color, ArkTone.lys.handtak);
    expect(mkd4.light!.farge, LysPalett.tittel);
    expect(mkd5.light!.farge, LysPalett.sekundar);
    // .mkd6 close key: round, white, 1px kant, card shadow
    expect(mkd6.light!.rund, isTrue);
    expect(mkd6.light!.kant!.farge, LysPalett.kantFarge);
    expect(mkd6.light!.skygge, LysPalett.kortskygge);
    // .mkd7 svg stroke --am-ikon = --lys-fjord
    expect(mkd7.light!.strek, LysPalett.fjord);
    expect(mkd7.side(false), isNull);
  });
}

class _TellerHolder extends StatelessWidget {
  const _TellerHolder();
  static final List<bool> ut = [];

  @override
  Widget build(BuildContext context) => _Teller(ut);
}
