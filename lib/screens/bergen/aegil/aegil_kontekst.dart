// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../common/auth/launch/lf_css.dart';
import 'aegil_bits.dart';

/// What Ægil was opened about (D-K20): a store's or a category's «Spør
/// Ægil», a gift for someone, the basket's door note. Read from the route's
/// arguments (`intent`, `store_id`, `store`, `category`, `for`); the store,
/// category and recipient go with every chat turn while the chip is shown.
/// Nothing stands in for a question the customer did not ask.
class AeKontekst {
  const AeKontekst({this.intent, this.storeId, this.store, this.category, this.recipient, this.orderId, this.order});

  final String? intent;
  final int? storeId;
  final String? store;
  final String? category;
  final String? recipient;

  /// Customer Step 5: «Spør Ægil» on an order's tracking view (`order_id`,
  /// `order` = its number); the chat answers about that order first.
  final int? orderId;
  final String? order;

  /// Null when the route names no context.
  static AeKontekst? fra(Map<String, String> args) {
    String? v(String k) {
      final s = args[k]?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    final k = AeKontekst(
      intent: v('intent'),
      storeId: int.tryParse(v('store_id') ?? ''),
      store: v('store'),
      category: v('category'),
      recipient: v('for'),
      orderId: int.tryParse(v('order_id') ?? ''),
      order: v('order'),
    );
    if (k.storeId == null && k.store == null && k.category == null && k.recipient == null && k.intent == null && k.orderId == null) return null;
    return k;
  }

  /// The chip's line, or null when there is nothing to name.
  String? get etikett {
    final hvor = store ?? category;
    return switch (intent) {
      'gift' => AeKtxCopy.cus_aegil_ktx_gave(recipient, hvor),
      'door' => AeKtxCopy.cus_aegil_ktx_dor,
      _ when orderId != null => AeKtxCopy.cus_aegil_ktx_om(order ?? '#$orderId'),
      _ => hvor == null ? null : AeKtxCopy.cus_aegil_ktx_om(hvor),
    };
  }
}

/// Copy for the context chip (Customer Step 0, not in the design).
abstract final class AeKtxCopy {
  static bool get _en => resolveSelectedLanguage() == 'en';
  static String _t(String no, String en) => _en ? en : no;

  static String cus_aegil_ktx_om(String hva) => _t('Om $hva', 'About $hva');
  static String cus_aegil_ktx_gave(String? til, String? hvor) {
    final no = til == null ? 'Gave' : 'Gave til $til';
    final en = til == null ? 'Gift' : 'Gift for $til';
    return hvor == null ? _t(no, en) : _t('$no · $hvor', '$en · $hvor');
  }

  static String get cus_aegil_ktx_dor => _t('Beskjed til budet', 'Note for the courier');
  static String get cus_aegil_ktx_fjern => _t('Fjern', 'Remove');
}

/// The context chip at the top of Ægil's sheet: what the chat is about, and
/// × to talk about anything. Built from the chat's own chip (`AeForslag`).
class AeKontekstChip extends StatelessWidget {
  const AeKontekstChip({super.key, required this.etikett, required this.onFjern});

  final String etikett;
  final VoidCallback onFjern;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: CssBox(
      key: const Key('cus_aegil_ktx'),
      radius: BorderRadius.circular(999),
      bg: const [CssSolid(Color.fromRGBO(6, 22, 30, .32))],
      shadows: const [
        CssShadow.inset(0, 0, 0, 1, Color.fromRGBO(159, 240, 212, .38)),
        CssShadow(0, 6, 10, -8, Color.fromRGBO(3, 16, 24, .8)),
      ],
      padding: const EdgeInsets.fromLTRB(11, 4, 4, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AeIkon('M12 21s-6.5-5.4-6.5-11a6.5 6.5 0 0 1 13 0c0 5.6-6.5 11-6.5 11z', size: 11, stroke: 2.6, color: kAeMintLys),
          const SizedBox(width: 6),
          Flexible(
            child: Text(etikett, maxLines: 1, overflow: TextOverflow.ellipsis, style: inter(12, weight: FontWeight.w800, color: const Color(0xFFDFF8EE))),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: AeKtxCopy.cus_aegil_ktx_fjern,
            child: AePress(
              key: const Key('cus_aegil_ktx_fjern'),
              onTap: onFjern,
              dy: 0,
              scale: .9,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 255, 255, .12)),
                alignment: Alignment.center,
                child: const AeIkon('M7 7l10 10M17 7L7 17', size: 9, stroke: 3, color: Color.fromRGBO(255, 255, 255, .8)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
