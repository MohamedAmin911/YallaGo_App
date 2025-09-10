import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymobWebViewScreen extends StatefulWidget {
  final String paymentToken;
  const PaymobWebViewScreen({super.key, required this.paymentToken});

  @override
  State<PaymobWebViewScreen> createState() => _PaymobWebViewScreenState();
}

class _PaymobWebViewScreenState extends State<PaymobWebViewScreen> {
  late final WebViewController _controller;
  final String _iframeId = "914606";

  @override
  void initState() {
    super.initState();
    final paymobUrl =
        'https://accept.paymob.com/api/acceptance/iframes/$_iframeId?payment_token=${widget.paymentToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url.contains('success=true')) {
              Navigator.of(context).pop(true);
            } else if (url.contains('success=false')) {
              Navigator.of(context).pop(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paymobUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Card Details")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
