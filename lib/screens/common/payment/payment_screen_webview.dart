import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../utils/utils.dart';

const int paymentTypeKlarna = 4;

class PaymentScreen extends StatefulWidget {
  final String paymentUrl, failUrl, successUrl;

  const PaymentScreen({super.key, required this.paymentUrl, required this.failUrl, required this.successUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  WebViewController webController = WebViewController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    webController = WebViewController()
      ..loadRequest(Uri.parse(widget.paymentUrl))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (value) {
          debugPrint('onPageStarted to $value');
          if (value.contains(widget.successUrl)) {
            Navigator.pop(context, true);
          } else if (value.contains(widget.failUrl)) {
            Navigator.pop(context, false);
          }
        },
        onNavigationRequest: (navigation) {
          String navigationUrl = navigation.url;
          debugPrint('navigation to $navigationUrl');
          if (navigationUrl.contains(widget.successUrl)) {
            Navigator.pop(context, true);
            return NavigationDecision.prevent;
          } else if (navigationUrl.contains(widget.failUrl)) {
            Navigator.pop(context, false);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    if (webController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
    }

    return WillPopScope(
      onWillPop: () async {
        // Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: WebViewWidget(
            controller: webController,
          ),
        ),
      ),
    );
  }
}

paymentMethodCheck(
  BuildContext context,
  int paymentMethod, {
  required String successUrl,
  required String failedUrl,
  required String redirectUrl,
  required Function() onSuccess,
  required Function() onFailed,
}) {
  if (paymentMethod == paymentTypeCard || paymentMethod == paymentTypeKlarna) {
    if (redirectUrl.trim().isNotEmpty) {
      openScreenWithResult(context, PaymentScreen(paymentUrl: redirectUrl, failUrl: failedUrl, successUrl: successUrl)).then((value) {
        if (value) {
          onSuccess.call();
        } else {
          onFailed.call();
        }
      });
    } else {
      onFailed.call();
    }
  } else {
    onSuccess.call();
  }
}
