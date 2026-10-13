import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:xml/xml.dart';

void main() {
  test('launch nativo comparte primary en ambas apariencias de Android', () {
    final hex =
        '#${AppColors.primary.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final config = File('flutter_native_splash.yaml').readAsStringSync();
    expect(RegExp(RegExp.escape(hex)).allMatches(config), hasLength(4));
    for (final variant in ['values-v31', 'values-night-v31']) {
      final styles = File(
        'android/app/src/main/res/$variant/styles.xml',
      ).readAsStringSync();
      final xml = XmlDocument.parse(styles);
      expect(
        xml
            .findAllElements('item')
            .firstWhere(
              (item) =>
                  item.getAttribute('name') ==
                  'android:windowSplashScreenBackground',
            )
            .innerText,
        hex,
      );
      expect(styles, contains('android:windowSplashScreenAnimatedIcon'));
    }
    for (final variant in [
      'drawable',
      'drawable-night',
      'drawable-v21',
      'drawable-night-v21',
    ]) {
      final background = File(
        'android/app/src/main/res/$variant/launch_background.xml',
      ).readAsStringSync();
      expect(background, contains('splash'));
      expect(background, contains('background'));
    }
  });

  test('PNG de iOS tiene 288 puntos en todas las densidades y apariencias', () {
    for (final dark in ['', 'Dark']) {
      for (var scale = 1; scale <= 3; scale++) {
        final suffix = scale == 1 ? '' : '@${scale}x';
        final bytes = File(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$dark$suffix.png',
        ).readAsBytesSync();
        final header = ByteData.sublistView(bytes);
        expect(header.getUint32(16), 288 * scale);
        expect(header.getUint32(20), 288 * scale);
      }
    }
  });
}
