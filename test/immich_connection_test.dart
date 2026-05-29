import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_pipeline_app/src/immich_connection.dart';

void main() {
  group('buildImmichApiBaseUri', () {
    test('adds scheme and api path to host-only input', () {
      expect(
        buildImmichApiBaseUri('localhost:2283').toString(),
        'http://localhost:2283/api/',
      );
    });

    test('keeps existing api path without duplicating it', () {
      expect(
        buildImmichApiBaseUri('https://photos.example.test/api').toString(),
        'https://photos.example.test/api/',
      );
    });

    test('rejects unsupported schemes', () {
      expect(
        () => buildImmichApiBaseUri('ftp://photos.example.test'),
        throwsFormatException,
      );
    });
  });

  group('ImmichApiClient', () {
    test(
      'checks ping, about, and statistics using read-only GET requests',
      () async {
        final calls = <Uri>[];
        final headersByPath = <String, Map<String, String>>{};
        final client = ImmichApiClient(
          get: (uri, headers) async {
            calls.add(uri);
            headersByPath[uri.path] = headers;
            return switch (uri.path) {
              '/api/server/ping' => const ImmichHttpResponse(
                statusCode: 200,
                body: '{"res":"pong"}',
              ),
              '/api/server/about' => ImmichHttpResponse(
                statusCode: 200,
                body: jsonEncode({'version': '1.140.0', 'licensed': false}),
              ),
              '/api/server/statistics' => ImmichHttpResponse(
                statusCode: 200,
                body: jsonEncode({
                  'photos': 1200,
                  'videos': 45,
                  'usage': 987654321,
                }),
              ),
              _ => const ImmichHttpResponse(statusCode: 404, body: '{}'),
            };
          },
        );

        final report = await client.check(
          const ImmichConnectionSettings(
            serverUrl: 'http://immich.local:2283',
            apiKey: 'secret',
          ),
        );

        expect(calls.map((uri) => uri.path), [
          '/api/server/ping',
          '/api/server/about',
          '/api/server/statistics',
        ]);
        expect(headersByPath['/api/server/ping'], isEmpty);
        expect(headersByPath['/api/server/about'], {'x-api-key': 'secret'});
        expect(report.pingOk, isTrue);
        expect(report.authenticated, isTrue);
        expect(report.version, '1.140.0');
        expect(report.photos, 1200);
        expect(report.videos, 45);
        expect(report.usageBytes, 987654321);
      },
    );

    test('does not call authenticated endpoints without an API key', () async {
      final calls = <Uri>[];
      final client = ImmichApiClient(
        get: (uri, headers) async {
          calls.add(uri);
          return const ImmichHttpResponse(
            statusCode: 200,
            body: '{"res":"pong"}',
          );
        },
      );

      final report = await client.check(
        const ImmichConnectionSettings(
          serverUrl: 'http://localhost:2283',
          apiKey: '',
        ),
      );

      expect(calls.map((uri) => uri.path), ['/api/server/ping']);
      expect(report.pingOk, isTrue);
      expect(report.authenticated, isFalse);
    });
  });
}
