import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../screens/common/auth/launch/lf_css.dart' show CssBg, CssShadow;
import 'bergen_modus.dart';
import 'mk_stil.dart';

/// Lys plan: the mode for a subtree. Mounted once in `MaterialApp.builder`
/// above the Navigator and the onboarding layers ([BergenModusRot]); fjord
/// screens wrap their root in [BergenModusScope.fjord], which pins the subtree
/// to dark whatever the switch says (Hjem, Sporing, Fjordfiske, liga, …).
///
/// Only widgets that read `context.lys` rebuild on a switch (an
/// InheritedWidget with value equality), nothing else does.
class BergenModusScope extends InheritedWidget {
  const BergenModusScope({super.key, required this.lys, this.mal, required super.child});

  /// A subtree that is always dark (the design's «fjordfarget i begge»).
  const BergenModusScope.fjord({super.key, required super.child})
      : lys = false,
        mal = false;

  final bool lys;

  /// The target during a switch moment (Utseende's tick), else [lys].
  final bool? mal;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BergenModusScope>()?.lys ?? BergenModus.i.lys;

  static bool malOf(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<BergenModusScope>();
    return s == null ? BergenModus.i.modusMal : (s.mal ?? s.lys);
  }

  @override
  bool updateShouldNotify(BergenModusScope old) => old.lys != lys || old.mal != mal;
}

/// Status bar over dark (fjord) screens: exactly the style `main()` sets for
/// the whole app (light icons), so the dark mode is unchanged (L6).
const SystemUiOverlayStyle modusStatusMork = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  statusBarBrightness: Brightness.dark,
);

/// Status bar over light screens in Lys: dark icons (L8).
const SystemUiOverlayStyle modusStatusLys = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
);

/// The root scope: follows [BergenModus.i] and sets the status-bar icons for
/// light screens (L8: dark icons in Lys; fjord screens put their own light
/// region over it with [ModusFjord]).
class BergenModusRot extends StatelessWidget {
  const BergenModusRot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BergenModus.i,
      builder: (context, child) {
        final m = BergenModus.i;
        return BergenModusScope(
          lys: m.lys,
          mal: m.modusMal,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: m.lys ? modusStatusLys : modusStatusMork,
            child: child!,
          ),
        );
      },
      child: child,
    );
  }
}

/// A fjord subtree: always dark ([BergenModusScope.fjord]) with light
/// status-bar icons.
class ModusFjord extends StatelessWidget {
  const ModusFjord({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BergenModusScope.fjord(
        child: AnnotatedRegion<SystemUiOverlayStyle>(value: modusStatusMork, child: child),
      );
}

/// Light status-bar icons over a dark header that sits under the status bar
/// on a screen that is light in Lys (the Meg stadium, Konto's Bryggen picture,
/// the Kassen header, the Søk hero, a store's hero photo). In dark it is the
/// global style, so nothing changes there.
class ModusStatusMork extends StatelessWidget {
  const ModusStatusMork({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(value: modusStatusMork, child: child);
}

extension BergenModusX on BuildContext {
  /// The mode here (subscribes: the widget rebuilds on a switch).
  bool get lys => BergenModusScope.of(this);

  /// The Dart twin of the design's `__aeM(dark, light)`.
  T aeM<T>(T dark, T light) => BergenModusScope.of(this) ? light : dark;

  /// The side of a theme class for the mode here (null: the class sets
  /// nothing in this mode — keep the widget's own value).
  MkVerdi? mk(MkStil s) => s.side(BergenModusScope.of(this));

  /// A theme class's background layers here, or [dark] (the app's own value)
  /// when the class leaves it alone in this mode.
  List<CssBg> mkBg(MkStil s, List<CssBg> dark) => mk(s)?.bg ?? dark;

  List<CssShadow> mkSkygge(MkStil s, List<CssShadow> dark) => mk(s)?.skygge ?? dark;

  Color mkFarge(MkStil s, Color dark) => mk(s)?.farge ?? dark;
}

/// Same as [BergenModusX.aeM] without a context (painters, statics): the
/// applied global mode. Prefer the context version inside widgets.
T aeMGlobal<T>(T dark, T light) => BergenModus.i.lys ? light : dark;
