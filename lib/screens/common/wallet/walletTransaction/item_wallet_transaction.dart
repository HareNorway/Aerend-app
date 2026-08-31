import 'package:flutter/material.dart';

import '../../../../theme/sc_saas_theme.dart';
import '../../../../utils/utils.dart';
import '../wallet_dl.dart';

class ItemWalletTransaction extends StatelessWidget {
  final TransactionsItem transactionsItem;

  const ItemWalletTransaction({super.key, required this.transactionsItem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.brightness == Brightness.dark
        ? Colors.white70
        : ScSaasThemeTokens.muted;
    return Container(
      color: theme.colorScheme.surface,
      margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.012),
      padding: EdgeInsetsDirectional.only(
        start: deviceWidth * 0.03,
        top: deviceHeight * 0.015,
        end: deviceWidth * 0.02,
        bottom: deviceHeight * 0.015,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 0,
            child: Image.asset(
              transactionsItem.transactionType == 1
                  ? "assets/images/ic_add_money.png"
                  : "assets/images/ic_pay_money.png",
              width: deviceAverageSize * 0.065,
              height: deviceAverageSize * 0.065,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: AlignmentDirectional.centerStart,
              margin: EdgeInsetsDirectional.only(start: deviceWidth * 0.025),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transactionsItem.subject,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.start,
                    style: bodyText(
                      textColor: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    margin: EdgeInsetsDirectional.only(
                      top: deviceHeight * 0.01,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 0,
                          child: Text(
                            getDateTime(
                              transactionsItem.dateTime,
                              returnFormat: "yyyy-MM-dd hh:mm a",
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.start,
                            style: bodyText(
                              textColor: mutedColor,
                              fontSize: textSizeSmallest,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            alignment: AlignmentDirectional.bottomEnd,
                            margin: EdgeInsetsDirectional.only(
                              start: deviceWidth * 0.005,
                            ),
                            child: Text(
                              getAmountWithCurrency(
                                double.parse(
                                  transactionsItem.amount.toString(),
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.start,
                              style: bodyText(
                                textColor: transactionsItem.transactionType == 1
                                    ? ScSaasThemeTokens.accent
                                    : ScSaasThemeTokens.danger,
                                fontSize: textSizeMediumBig,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
