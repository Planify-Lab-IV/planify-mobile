import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const classicAsset = 'assets/splash/planify_splash_classic.png';
  static const androidAsset = 'assets/splash/planify_splash_android12.png';

  static String assetForPlatform(TargetPlatform platform) =>
      platform == TargetPlatform.android ? androidAsset : classicAsset;

  /// Llena ImageCache antes del primer frame para evitar un fondo sin logo.
  static Future<void> precacheLogo(TargetPlatform platform) async {
    final stream = AssetImage(
      assetForPlatform(platform),
    ).resolve(ImageConfiguration.empty);
    final ready = Completer<void>();
    final listener = ImageStreamListener(
      (info, synchronousCall) {
        info.dispose();
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!ready.isCompleted) ready.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    try {
      await ready.future;
    } finally {
      stream.removeListener(listener);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final asset = assetForPlatform(Theme.of(context).platform);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const Key('startup_splash'),
        backgroundColor: color,
        body: Center(
          child: Image.asset(
            asset,
            width: AppDimens.splashLogoSize,
            height: AppDimens.splashLogoSize,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
