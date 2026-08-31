import 'package:flutter/material.dart';

import '../constant/constant.dart';
import '../theme/sc_saas_theme.dart';

class HintTooltip extends StatefulWidget {
  final String message;

  const HintTooltip({super.key, required this.message});

  @override
  State createState() => _HintTooltipState();
}

class _HintTooltipState extends State<HintTooltip> {
  GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.message,
      key: globalKey,
      child: IconButton(
        icon: Icon(
          Icons.error,
          color: ScSaasThemeTokens.danger,
          size: deviceAverageSize * 0.035,
        ),
        onPressed: () {
          final dynamic tooltip = globalKey.currentState;
          tooltip.ensureTooltipVisible();
          _startTimer(tooltip);
        },
      ),
    );
  }

  void _startTimer(dynamic tooltip) async {
    await Future.delayed(const Duration(seconds: 3));
    tooltip.deactivate();
  }
}
