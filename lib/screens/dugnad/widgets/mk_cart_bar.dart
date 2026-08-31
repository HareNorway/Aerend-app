import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/ae_typography.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../campaign/bloc/campaign_detail_bloc.dart';
import '../../campaign/campaign_checkout_screen.dart';
import '../../campaign/models/campaign_detail_pojo.dart';
import '../dugnad_club_branding.dart';
import '../../../ui/kit/ae_theme.dart';
import '../../../ui/kit/ae_qty_stepper.dart';

/// Expandable sticky cart bar — mirrors prototype `MkCartBar`.
class MkCartBar extends StatefulWidget {
  const MkCartBar({super.key, required this.bloc});

  final CampaignDetailBloc bloc;

  @override
  State<MkCartBar> createState() => _MkCartBarState();
}

class _MkCartBarState extends State<MkCartBar> {
  bool _open = false;

  String get _cartTitle => languages.campaignCartTitle;

  String get _clearCartLabel => languages.campaignCartClear;

  String get _payLabel => languages.campaignCartCheckout;

  String _summaryLabel(int count) => languages.campaignCartSummary(count);

  String _clubLabel(CampaignDetail? campaign) {
    final club = campaign?.club?.name.trim();
    if (club != null && club.isNotEmpty) return club;
    return DugnadClubBranding.compactName();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.aeTheme;

    return StreamBuilder<List<CampaignCartItem>>(
      stream: widget.bloc.cartStream,
      builder: (context, cartSnap) {
        final cart = cartSnap.data ?? [];
        if (cart.isEmpty) {
          if (_open) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _open = false);
            });
          }
          return const SizedBox.shrink();
        }

        final total = widget.bloc.cartTotal;
        final count = widget.bloc.cartItemCount;

        return StreamBuilder(
          stream: widget.bloc.detailStream,
          builder: (context, detailSnap) {
            final campaign = detailSnap.data?.data?.campaign;

            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_open)
                    _CartSheet(
                      cart: cart,
                      campaign: campaign,
                      clubLabel: _clubLabel(campaign),
                      title: _cartTitle,
                      clearLabel: _clearCartLabel,
                      onClear: widget.bloc.clearCart,
                      onDecrement: widget.bloc.decrementQty,
                      onIncrement: widget.bloc.incrementQty,
                      theme: theme,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.dp(20)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.text.withValues(alpha: 0.05),
                          blurRadius: context.dp(6),
                          offset: const Offset(0, -2),
                        ),
                        BoxShadow(
                          color: theme.text.withValues(alpha: 0.28),
                          blurRadius: context.dp(36),
                          offset: const Offset(0, -16),
                          spreadRadius: -16,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                      14,
                      12,
                      14,
                      MediaQuery.paddingOf(context).bottom + 14,
                    ),
                    child: Row(
                      children: [
                        _CartToggle(
                          count: count,
                          open: _open,
                          theme: theme,
                          onTap: () => setState(() => _open = !_open),
                        ),
                        SizedBox(width: context.dp(12)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _open = !_open),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _summaryLabel(count),
                                  style: aeCaption(
                                    color: ScSaasThemeTokens.gray500,
                                  ).copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${total.toInt()} kr',
                                  style: aeH2(color: theme.text).copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            openScreen(
                              context,
                              CampaignCheckoutScreen(
                                campaign: widget.bloc,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              gradient: theme.shinyGradient,
                              borderRadius: BorderRadius.circular(context.dp(13)),
                              boxShadow: theme.shadowButton,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: context.dp(16),
                                ),
                                SizedBox(width: context.dp(7)),
                                Text(
                                  _payLabel,
                                  style: aeLabel(color: Colors.white).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CartToggle extends StatelessWidget {
  const _CartToggle({
    required this.count,
    required this.open,
    required this.theme,
    required this.onTap,
  });

  final int count;
  final bool open;
  final AeThemePalette theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: context.dp(42),
                height: context.dp(42),
                decoration: BoxDecoration(
                  color: theme.primaryTint,
                  borderRadius: BorderRadius.circular(context.dp(13)),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: context.dp(20),
                  color: theme.primaryHover,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: EdgeInsets.symmetric(horizontal: context.dp(4)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22A769),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: context.dp(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: context.dp(6)),
          AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.dp(15),
              color: theme.primaryHover.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.campaign,
    required this.clubLabel,
    required this.title,
    required this.clearLabel,
    required this.onClear,
    required this.onDecrement,
    required this.onIncrement,
    required this.theme,
  });

  final List<CampaignCartItem> cart;
  final CampaignDetail? campaign;
  final String clubLabel;
  final String title;
  final String clearLabel;
  final VoidCallback onClear;
  final void Function(int productId) onDecrement;
  final void Function(int productId) onIncrement;
  final AeThemePalette theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.dp(18))),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.3),
            blurRadius: context.dp(24),
            offset: const Offset(0, -8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(14), context.dp(16), context.dp(10)),
            child: Row(
              children: [
                Text(
                  title,
                  style: aeLabel(color: theme.text).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    clearLabel,
                    style: aeCaption(color: ScSaasThemeTokens.danger).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(context.dp(16), context.dp(0), context.dp(16), context.dp(16)),
              itemCount: cart.length,
              separatorBuilder: (_, __) => Divider(
                height: context.dp(1),
                color: ScSaasThemeTokens.gray100,
              ),
              itemBuilder: (context, index) {
                final item = cart[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: context.dp(9)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: aeLabel(color: theme.text).copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: context.dp(2)),
                            Text(
                              '$clubLabel · ${item.product.price.toInt()} kr',
                              style: aeCaption(
                                color: ScSaasThemeTokens.gray500,
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.dp(10)),
                      AeQtyStepper(
                        qty: item.quantity,
                        theme: theme,
                        onDecrement: () => onDecrement(item.product.id),
                        onIncrement: () => onIncrement(item.product.id),
                      ),
                      SizedBox(width: context.dp(10)),
                      Text(
                        '${item.lineTotal.toInt()} kr',
                        style: aeLabel(color: theme.text).copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
