import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../service/connectivity_service.dart';

class KMFRIWebView extends StatefulWidget {
  const KMFRIWebView({super.key});

  @override
  State<KMFRIWebView> createState() => _KMFRIWebViewState();
}

class _KMFRIWebViewState extends State<KMFRIWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFD))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _progress = 0;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted && !_hasError) {
              setState(() => _progress = 100);
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              'WebView error: ${error.description} (${error.errorType}, isMainFrame: ${error.isForMainFrame})',
            );
            if (error.isForMainFrame != false) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _controller.loadRequest(Uri.parse(kmfriUrl));
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(kmfriUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Stack(
          children: [
            if (!_hasError)
              WebViewWidget(controller: _controller)
            else
              _buildErrorView(),
            if (_progress < 100 && !_hasError)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: const Color(0xFF005B96),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color: Color(0xFFB26A00),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to Load KMFRI Portal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A3D62),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ??
                  'Check your internet connection or try reloading the page.',
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RELOAD PAGE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005B96),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
