import 'package:flutter/cupertino.dart';

import '../theme/sc_saas_theme.dart';
import 'utils.dart';

class InputDoneView extends StatelessWidget {
  const InputDoneView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ScSaasThemeTokens.rowHover,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
          child: CupertinoButton(
            padding: const EdgeInsets.only(right: 24.0, top: 6.0, bottom: 6.0),
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Text("Done", style: bodyText(textColor: ScSaasThemeTokens.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

OverlayEntry? overlayEntry;

showOverlay(BuildContext context) {
  if (overlayEntry != null) return;
  OverlayState overlayState = Overlay.of(context);
  overlayEntry = OverlayEntry(builder: (context) {
    return Positioned(bottom: MediaQuery.of(context).viewInsets.bottom, right: 0.0, left: 0.0, child: const InputDoneView());
  });

  overlayState.insert(overlayEntry!);
}

removeOverlay() {
  if (overlayEntry != null) {
    overlayEntry?.remove();
    overlayEntry = null;
  }
}
