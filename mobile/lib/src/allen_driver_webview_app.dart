import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'services/location_foreground_service.dart';
import 'services/platform_bootstrap.dart';
import 'services/push_service.dart';

const _driverHomeUrl = 'https://allen-travels.com/allen/driver/';
const _allenOrigin = 'https://allen-travels.com';

class AllenDriverWebViewApp extends StatelessWidget {
  const AllenDriverWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allen Travel Driver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5d22aa)),
        useMaterial3: true,
      ),
      home: const _AllenDriverWebViewPage(),
    );
  }
}

class _AllenDriverWebViewPage extends StatefulWidget {
  const _AllenDriverWebViewPage();

  @override
  State<_AllenDriverWebViewPage> createState() =>
      _AllenDriverWebViewPageState();
}

class _AllenDriverWebViewPageState extends State<_AllenDriverWebViewPage> {
  final AllenDriverLocationService _locationService =
      const AllenDriverLocationService();
  late final WebViewController _controller;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _fcmToken;
  String? _deviceId;
  int _progress = 0;
  bool _startingLocationService = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'AllenDriver',
        onMessageReceived: (message) => unawaited(_handleBridge(message.message)),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (_) => unawaited(_onPageFinished()),
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || request.url == 'about:blank') {
              return NavigationDecision.navigate;
            }
            return _isAllenUrl(uri)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_driverHomeUrl));
    unawaited(_initialiseNativeFeatures());
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  bool _isAllenUrl(Uri uri) =>
      uri.scheme == 'https' && uri.host.toLowerCase() == 'allen-travels.com';

  Future<void> _initialiseNativeFeatures() async {
    await PlatformBootstrap.ensureInitialized();
    _deviceId = await _loadDeviceId();
    _fcmToken = await PushService.instance.setUp(onOpen: _openPushTarget);
    _tokenRefreshSubscription = PushService.instance.onTokenRefresh.listen((token) {
      _fcmToken = token;
      unawaited(_registerDevice());
    });
    await _registerDevice();
  }

  Future<String> _loadDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    const key = 'allen_driver_webview_device_id';
    final existing = preferences.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated =
        'allen-driver-${DateTime.now().microsecondsSinceEpoch}-${Object().hashCode}';
    await preferences.setString(key, generated);
    return generated;
  }

  void _openPushTarget(Map<String, dynamic> data) {
    final rawTarget = data['url']?.toString() ?? _driverHomeUrl;
    final uri = Uri.tryParse(rawTarget.startsWith('/') ? '$_allenOrigin$rawTarget' : rawTarget);
    if (uri != null && _isAllenUrl(uri)) {
      unawaited(_controller.loadRequest(uri));
    }
  }

  Future<void> _onPageFinished() async {
    await _injectNativeBridge();
    await _registerDevice();
  }

  Future<void> _injectNativeBridge() {
    return _controller.runJavaScript('''
      window.AllenDriverLocationBridge = {
        startLocation: function(busId) {
          window.AllenDriver.postMessage(JSON.stringify({type: 'start_location', bus_id: Number(busId)}));
        },
        stopLocation: function() {
          window.AllenDriver.postMessage(JSON.stringify({type: 'stop_location'}));
        }
      };
    ''');
  }

  Future<void> _registerDevice() async {
    final token = _fcmToken;
    final deviceId = _deviceId;
    if (token == null || token.isEmpty || deviceId == null || deviceId.isEmpty) return;
    final tokenJson = jsonEncode(token);
    final deviceJson = jsonEncode(deviceId);
    await _controller.runJavaScript('''
      (function() {
        var csrf = (document.cookie.match(/(?:^|; )csrftoken=([^;]*)/) || [])[1] || '';
        fetch('/allen/api/webview/register-device/', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {'Content-Type': 'application/json', 'X-CSRFToken': decodeURIComponent(csrf)},
          body: JSON.stringify({platform: 'android', fcm_token: $tokenJson, device_id: $deviceJson})
        }).catch(function() {});
      })();
    ''');
  }

  Future<void> _handleBridge(String rawMessage) async {
    Map<String, dynamic> message;
    try {
      message = (jsonDecode(rawMessage) as Map).cast<String, dynamic>();
    } catch (_) {
      return;
    }
    switch (message['type']?.toString()) {
      case 'start_location':
        final busId = int.tryParse(message['bus_id']?.toString() ?? '');
        if (busId != null && busId > 0) await _requestLocationSession(busId);
        return;
      case 'location_session':
        await _startForegroundLocation(message);
        return;
      case 'stop_location':
        await _locationService.stop();
        return;
    }
  }

  Future<void> _requestLocationSession(int busId) async {
    await _controller.runJavaScript('''
      (function() {
        var csrf = (document.cookie.match(/(?:^|; )csrftoken=([^;]*)/) || [])[1] || '';
        fetch('/allen/api/mobile/driver/location/start/$busId/', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {'Content-Type': 'application/json', 'X-CSRFToken': decodeURIComponent(csrf)}
        }).then(async function(response) {
          var payload = await response.json().catch(function() { return {}; });
          window.AllenDriver.postMessage(JSON.stringify({type: 'location_session', ok: response.ok, payload: payload}));
        }).catch(function() {
          window.AllenDriver.postMessage(JSON.stringify({type: 'location_session', ok: false, payload: {}}));
        });
      })();
    ''');
  }

  Future<void> _startForegroundLocation(Map<String, dynamic> message) async {
    if (_startingLocationService) return;
    final payload = message['payload'];
    if (message['ok'] != true || payload is! Map) {
      await _notifyLocationStartFailure();
      return;
    }
    final token = payload['location_token']?.toString() ?? '';
    final busId = int.tryParse(payload['bus_id']?.toString() ?? '');
    if (token.isEmpty || busId == null || busId <= 0) {
      await _notifyLocationStartFailure();
      return;
    }
    _startingLocationService = true;
    try {
      await PlatformBootstrap.ensureInitialized();
      final started = await _locationService.start(
        busId: busId,
        locationToken: token,
        baseUrl: _allenOrigin,
      );
      if (!started) await _notifyLocationStartFailure();
    } finally {
      _startingLocationService = false;
    }
  }

  Future<void> _notifyLocationStartFailure() {
    return _controller.runJavaScript('''
      window.dispatchEvent(new Event('allen-driver-native-location-error'));
    ''');
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_progress < 100)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    color: const Color(0xff5d22aa),
                    backgroundColor: const Color(0xffeee8f6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
