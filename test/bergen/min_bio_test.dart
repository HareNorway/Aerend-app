import 'package:aerend_customer/data/aegil/aegil_models.dart';
import 'package:aerend_customer/data/aegil/aegil_repo.dart';
import 'package:aerend_customer/screens/bergen/meg/min_bio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what Min Bio sends instead of calling the server.
class _FakeRepo extends AegilRepo {
  final List<int> glemt = [];
  final List<OnboardingChip> lagt = [];
  Map<String, dynamic>? innst;

  @override
  Future<bool> forget(int id) async {
    glemt.add(id);
    return true;
  }

  @override
  Future<({int stored, int earned, String? error})> submitChips(List<OnboardingChip> chips) async {
    lagt.addAll(chips);
    return (stored: chips.length, earned: 0, error: null);
  }

  @override
  Future<({AegilSettings? settings, String? error})> updateSettings(Map<String, dynamic> changes) async {
    innst = changes;
    return (settings: const AegilSettings(), error: null);
  }
}

void main() {
  test('bioTolk reads the design sample like the prototype', () {
    final p = bioTolk('Allergisk mot skalldyr. Elsker fisk og thai, og pizza på fredager. Ikke koriander, takk.');
    expect(p.all, {'Skalldyr': BioAll.allergi});
    expect(p.liker, ['Fisk', 'Thai', 'Pizza']);
    expect(p.ikke, ['Koriander']);
  });

  test('allergies and diets from the text wait for a tap; soft finds count', () {
    final b = const MinBio(tekst: 'Allergisk mot skalldyr. Jeg er vegetar. Elsker thai. Ikke melk.');
    final E = bioEff(b);
    expect(E.all, {'Melk': BioAll.unnga});
    expect(E.kost, isEmpty);
    expect(E.forslag, containsAll(['all:Skalldyr', 'kost:Vegetar']));
    expect(E.liker, ['Thai']);

    final k = MinBioKontroll(b)..allTrykk('Skalldyr');
    expect(k.eff.all['Skalldyr'], BioAll.allergi);
    expect(k.eff.forslag, isNot(contains('all:Skalldyr')));
    k.dispose();
  });

  test('a diet takes off the likes it rules out, and the score counts', () {
    final k = MinBioKontroll(const MinBio(liker: ['Fisk', 'Thai']));
    k.kost('Vegetar');
    expect(k.eff.liker, ['Thai']);
    expect(k.aeg, contains('Fisk passer ikke med vegetarisk'));
    expect(bioScore(k.bio), 1);
    k.dispose();
  });

  test('allergy taps go allergy → unngår → off', () {
    final k = MinBioKontroll(const MinBio());
    k.allTrykk('Egg');
    expect(k.eff.all['Egg'], BioAll.allergi);
    k.allTrykk('Egg');
    expect(k.eff.all['Egg'], BioAll.unnga);
    k.allTrykk('Egg');
    expect(k.eff.all.containsKey('Egg'), isFalse);
    k.dispose();
  });

  test('loads from memory and saves only the difference', () async {
    const minne = [
      MemoryEntry(id: 1, kind: 'allergen', value: 'skalldyr', label: 'Skalldyr', source: 'stated'),
      MemoryEntry(id: 2, kind: 'like', value: 'fisk', label: 'Fisk', source: 'onboarding'),
      MemoryEntry(id: 3, kind: 'store', value: 'sky-bangkok', label: 'Sky Bangkok', source: 'stated'),
      MemoryEntry(id: 4, kind: 'like', value: 'kategori:mote', label: 'Mote', source: 'onboarding'),
    ];
    final bio = minBioFra(minne, const AegilSettings(bioText: 'Elsker fisk.'));
    expect(bio.all, {'Skalldyr': BioAll.allergi});
    expect(bio.liker, ['Fisk']);

    final k = MinBioKontroll(bio)
      ..lik('Fisk', BioListe.liker)
      ..lik('Thai', BioListe.liker);
    final repo = _FakeRepo();
    final n = await minBioLagre(repo, k.bio, minne);
    expect(repo.glemt, [2]);
    expect(repo.lagt.map((c) => '${c.kind}:${c.value}:${c.label}'), ['like:thai:Thai']);
    expect(repo.innst, {'bio_text': 'Elsker fisk.', 'no_allergies': false});
    expect(n, 2);
    k.dispose();
  });
}
