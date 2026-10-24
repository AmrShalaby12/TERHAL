import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/allen_driver_webview_app.dart';
import 'src/services/platform_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const driverWebViewMode =
      String.fromEnvironment('APP_MODE', defaultValue: 'terhal') == 'driver';

  final enablePreview =
      !kReleaseMode &&
      (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  final app = driverWebViewMode
      ? const AllenDriverWebViewApp()
      : enablePreview
      ? DevicePreview(builder: (context) => const TerhalApp())
      : const TerhalApp();

  runApp(ProviderScope(child: app));

  // These platform tasks no longer delay the first rendered frame.
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );
  unawaited(PlatformBootstrap.ensureInitialized());
}
