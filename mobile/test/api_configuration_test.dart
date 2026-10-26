import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/api_service.dart';

void main() {
  test('iOS release archive without dart defines resolves production API', () {
    expect(
      ApiService.resolveBaseUrl(
        releaseMode: true,
        isWeb: false,
        platform: TargetPlatform.iOS,
        apiBaseUrlOverride: '',
        apiHostOverride: '',
      ),
      'https://ter7al.noxusai.online/api',
    );
  });

  test('Android release also works without custom build arguments', () {
    expect(
      ApiService.resolveBaseUrl(
        releaseMode: true,
        isWeb: false,
        platform: TargetPlatform.android,
        apiBaseUrlOverride: '',
        apiHostOverride: '',
      ),
      'https://ter7al.noxusai.online/api',
    );
  });

  test('explicit HTTPS API override is preserved and normalized', () {
    expect(
      ApiService.resolveBaseUrl(
        releaseMode: true,
        apiBaseUrlOverride: 'https://staging.example.com/api/',
        apiHostOverride: '',
      ),
      'https://staging.example.com/api',
    );
  });

  test('invalid and insecure production overrides remain rejected', () {
    for (final url in ['relative/api', 'http://example.com/api']) {
      expect(
        () => ApiService.resolveBaseUrl(
          releaseMode: true,
          apiBaseUrlOverride: url,
          apiHostOverride: '',
        ),
        throwsStateError,
      );
    }
    expect(
      () => ApiService.resolveBaseUrl(
        releaseMode: true,
        apiBaseUrlOverride: '',
        apiHostOverride: '192.168.1.2',
      ),
      throwsStateError,
    );
  });

  test('development emulator and iOS endpoints stay local', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      expect(
        ApiService.resolveBaseUrl(
          releaseMode: false,
          isWeb: false,
          platform: platform,
          apiBaseUrlOverride: '',
          apiHostOverride: '',
        ),
        platform == TargetPlatform.android
            ? 'http://10.0.2.2:8001/api'
            : 'http://127.0.0.1:8001/api',
      );
    }
  });
}
