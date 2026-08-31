import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../commonView/dugnad_club_loader.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../dugnad_club_theme.dart';
import '../dugnad_repo.dart';
import '../dugnad_state.dart';
import '../widgets/dugnad_subpage_shell.dart';
import 'club_shop_models.dart';
import 'club_shop_receipt_screen.dart';

class ClubShopOrdersScreen extends StatefulWidget {
  const ClubShopOrdersScreen({super.key});

  @override
  State<ClubShopOrdersScreen> createState() => _ClubShopOrdersScreenState();
}

class _ClubShopOrdersScreenState extends State<ClubShopOrdersScreen> {
  final DugnadRepo _repo = DugnadRepo();
  List<ClubShopPaidOrder> _orders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _repo.clubShopOrders(
      clubId: DugnadState.instance.clubId,
    );
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'klar':
        return languages.dugnadClubShopStatusReady;
      case 'behandles':
        return languages.dugnadClubShopStatusPending;
      case 'utlevert':
        return languages.dugnadClubShopStatusCollected;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.dp(18),
              MediaQuery.paddingOf(context).top + context.dp(8),
              context.dp(18),
              context.dp(10),
            ),
            child: Row(
              children: [
                DugnadLbBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    languages.dugnadClubShopMyOrders,
                    textAlign: TextAlign.center,
                    style: aeH2(color: theme.text)
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w800)
                        .dp(context),
                  ),
                ),
                SizedBox(width: context.dp(38)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: DugnadClubLoader())
                : _orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.dp(28),
                          ),
                          child: Text(
                            languages.dugnadClubShopEmptyOrders,
                            textAlign: TextAlign.center,
                            style: aeBody(color: ScSaasThemeTokens.gray500)
                                .copyWith(fontWeight: FontWeight.w600)
                                .dp(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          context.dp(18),
                          context.dp(4),
                          context.dp(18),
                          context.dp(24),
                        ),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.dp(12)),
                        itemBuilder: (context, i) {
                          final o = _orders[i];
                          final qty = o.items.fold<int>(0, (s, l) => s + l.qty);
                          return GestureDetector(
                            onTap: () => openScreen(
                              context,
                              ClubShopReceiptScreen(order: o, fresh: false),
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                context.dp(15),
                                context.dp(14),
                                context.dp(15),
                                context.dp(14),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(context.dp(17)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: context.dp(42),
                                    height: context.dp(42),
                                    decoration: BoxDecoration(
                                      color: theme.primaryTint,
                                      borderRadius:
                                          BorderRadius.circular(context.dp(13)),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/svgs/order_history.svg',
                                        width: context.dp(20),
                                        height: context.dp(20),
                                        fit: BoxFit.contain,
                                        colorFilter: ColorFilter.mode(
                                          theme.primaryHover,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.dp(13)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          o.orderNumber,
                                          style: aeBody(color: theme.text)
                                              .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              )
                                              .dp(context),
                                        ),
                                        SizedBox(height: context.dp(3)),
                                        Text(
                                          languages.dugnadClubShopOrderMeta(
                                            qty,
                                          ),
                                          style: aeCaption(
                                            color: ScSaasThemeTokens.gray500,
                                          )
                                              .copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              )
                                              .dp(context),
                                        ),
                                        SizedBox(height: context.dp(5)),
                                        Text(
                                          _statusLabel(o.status),
                                          style: aeCaption(
                                            color: o.status == 'klar'
                                                ? const Color(0xFF14663F)
                                                : ScSaasThemeTokens.gray500,
                                          )
                                              .copyWith(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              )
                                              .dp(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    shopKr(o.amountPaid),
                                    style: aeBody(color: theme.text)
                                        .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        )
                                        .dp(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
