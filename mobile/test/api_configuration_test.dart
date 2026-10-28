import 'package:flutter_test/flutter_test.dart';
import 'package:terhal_mobile/src/api_service.dart';

void main() {
  test('default service starts without any build defines', () {
    expect(ApiService.new, returnsNormally);
    expect(ApiService.apiBaseUrl, 'https://ter7al.noxusai.online/api');
  });

  for (final release in [true, false]) {
    test('missing build defines use production API (release=$release)', () {
      expect(
        ApiService.resolveBaseUrl(
          releaseMode: release,
          apiBaseUrlOverride: '',
          apiHostOverride: '',
        ),
        'https://ter7al.noxusai.online/api',
      );
    });
  }

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

  test('release cannot target localhost or the Android emulator', () {
    for (final host in ['localhost', '127.0.0.1', '[::1]', '10.0.2.2']) {
      for (final scheme in ['http', 'https']) {
        expect(
          () => ApiService.resolveBaseUrl(
            releaseMode: true,
            apiBaseUrlOverride: '$scheme://$host:8001/api',
            apiHostOverride: '',
          ),
          throwsStateError,
        );
      }
    }
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

  test('local development requires an explicit override', () {
    expect(
      ApiService.resolveBaseUrl(
        releaseMode: false,
        apiBaseUrlOverride: '',
        apiHostOverride: '127.0.0.1',
      ),
      'http://127.0.0.1:8001/api',
    );
    expect(
      ApiService.resolveBaseUrl(
        releaseMode: false,
        apiBaseUrlOverride: 'http://127.0.0.1:8001/api',
        apiHostOverride: '',
      ),
      'http://127.0.0.1:8001/api',
    );
  });
}
