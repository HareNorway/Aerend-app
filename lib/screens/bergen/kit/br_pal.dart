import 'package:flutter/foundation.dart';

import '../../common/home/bergen/bergen_kit.dart' show BergenWeather, BergenWeatherLook;
import '../hjem/hjem_harness.dart';

/// The prototype's `brPal()` for Bergen's four looks, read from the
/// prototype itself per weather (`ui-tools/br_data.json`): the sky's top /
/// middle / bottom, night, sun, sunset, rain, wet, the Hjem veil (`tekst`
/// darker than mid-grey), the cloud base `cb` and the visibility `vis`.
/// The live scenes read it: Bryggen (Hjem), Fløyen (Ægil), the stadium (Meg).
class BrPal {
  const BrPal(this.skT, this.skM, this.skB, {required this.night, this.sun = 0, this.sunset = 0, this.rain = 0, required this.wet, required this.veil, required this.cb, required this.vis});

  final List<double> skT, skM, skB;
  final double night, sun, sunset, rain, wet, veil, cb, vis;

  /// Bergen's looks have no snow.
  double get snow => 0;

  static const Map<BergenWeather, BrPal> av = {
    BergenWeather.regn: BrPal([.7176, .7765, .8235], [.8275, .8627, .8745], [.7882, .8275, .8353], night: .74, rain: 1, wet: 1, veil: 1, cb: 196, vis: 1100),
    BergenWeather.sol: BrPal([.36, .57, .78], [.55, .71, .84], [.72, .82, .88], night: .06, sun: 1, wet: .55, veil: 1, cb: 2400, vis: 1700),
    BergenWeather.solnedgang: BrPal([.4941, .4706, .5647], [.7882, .5647, .4314], [.8510, .6314, .4627], night: .55, sunset: 1, wet: .55, veil: 0, cb: 330, vis: 1900),
    BergenWeather.natt: BrPal([.0627, .1176, .1882], [.0863, .1961, .2902], [.1216, .2667, .3765], night: 1, wet: .55, veil: 0, cb: 275, vis: 1900),
  };

  static BrPal of(BergenWeather w) => av[w]!;

  /// The weather for now: Bergen's look for the hour, or the debug harness's
  /// `vaer` (the same rule as Hjem, Ægil and Meg).
  static BergenWeather naa() {
    if (kDebugMode && HjemHarness.vaer != null) return BergenWeather.values.byName(HjemHarness.vaer!.name);
    return BergenWeatherLook.forHour(DateTime.now().hour).kind;
  }
}
