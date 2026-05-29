import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ImmichConnectionSettings {
  const ImmichConnectionSettings({
    required this.serverUrl,
    required this.apiKey,
  });

  final String serverUrl;
  final String apiKey;

  Uri get apiBaseUri => buildImmichApiBaseUri(serverUrl);
}

class ImmichConnectionReport {
  const ImmichConnectionReport({
    required this.serverUrl,
    required this.pingOk,
    required this.authenticated,
    this.version,
    this.licensed,
    this.photos,
    this.videos,
    this.usageBytes,
    this.message,
  });

  final String serverUrl;
  final bool pingOk;
  final bool authenticated;
  final String? version;
  final bool? licensed;
  final int? photos;
  final int? videos;
  final int? usageBytes;
  final String? message;

  String get statusLabel {
    if (!pingOk) {
      return 'Server not reachable';
    }
    if (!authenticated) {
      return 'Server reachable; API key not verified';
    }
    return 'Server reachable; API key verified';
  }
}

class ImmichConnectionException implements Exception {
  const ImmichConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImmichHttpResponse {
  const ImmichHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef ImmichHttpGet =
    Future<ImmichHttpResponse> Function(Uri uri, Map<String, String> headers);

class ImmichApiClient {
  ImmichApiClient({ImmichHttpGet? get}) : _get = get ?? _defaultGet;

  final ImmichHttpGet _get;

  Future<ImmichConnectionReport> check(
    ImmichConnectionSettings settings,
  ) async {
    final apiBase = settings.apiBaseUri;
    final ping = await _get(apiBase.resolve('server/ping'), const {});
    if (ping.statusCode < 200 || ping.statusCode >= 300) {
      return ImmichConnectionReport(
        serverUrl: apiBase.toString(),
        pingOk: false,
        authenticated: false,
        message: 'Ping failed with HTTP ${ping.statusCode}.',
      );
    }

    if (settings.apiKey.trim().isEmpty) {
      return ImmichConnectionReport(
        serverUrl: apiBase.toString(),
        pingOk: true,
        authenticated: false,
        message: 'Add an Immich API key to verify authenticated access.',
      );
    }

    final headers = {'x-api-key': settings.apiKey.trim()};
    final about = await _get(apiBase.resolve('server/about'), headers);
    if (about.statusCode == HttpStatus.unauthorized ||
        about.statusCode == HttpStatus.forbidden) {
      return ImmichConnectionReport(
        serverUrl: apiBase.toString(),
        pingOk: true,
        authenticated: false,
        message:
            'API key was rejected. It needs at least the server.about permission.',
      );
    }
    if (about.statusCode < 200 || about.statusCode >= 300) {
      return ImmichConnectionReport(
        serverUrl: apiBase.toString(),
        pingOk: true,
        authenticated: false,
        message: 'Server info failed with HTTP ${about.statusCode}.',
      );
    }

    final aboutJson = _decodeObject(about.body);
    Map<String, Object?> statisticsJson = const {};
    final statistics = await _get(
      apiBase.resolve('server/statistics'),
      headers,
    );
    if (statistics.statusCode >= 200 && statistics.statusCode < 300) {
      statisticsJson = _decodeObject(statistics.body);
    }

    return ImmichConnectionReport(
      serverUrl: apiBase.toString(),
      pingOk: true,
      authenticated: true,
      version: _stringValue(aboutJson['version']),
      licensed: aboutJson['licensed'] is bool
          ? aboutJson['licensed'] as bool
          : null,
      photos: _intValue(statisticsJson['photos']),
      videos: _intValue(statisticsJson['videos']),
      usageBytes:
          _intValue(statisticsJson['usage']) ??
          _intValue(statisticsJson['usageByUser']),
      message: statisticsJson.isEmpty
          ? 'Server info verified. Statistics were not available with this key.'
          : 'Read-only Immich API check completed.',
    );
  }

  static Future<ImmichHttpResponse> _defaultGet(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      for (final header in headers.entries) {
        request.headers.set(header.key, header.value);
      }
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await utf8
          .decodeStream(response)
          .timeout(const Duration(seconds: 12));
      return ImmichHttpResponse(statusCode: response.statusCode, body: body);
    } on TimeoutException {
      throw const ImmichConnectionException('Immich request timed out.');
    } on SocketException catch (error) {
      throw ImmichConnectionException(error.message);
    } finally {
      client.close(force: true);
    }
  }
}

Uri buildImmichApiBaseUri(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Server URL is required.');
  }

  final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
  final uri = Uri.parse(withScheme);
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('Enter a valid Immich server URL.');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw const FormatException('Immich URL must use http or https.');
  }

  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  final normalizedSegments = [
    ...segments,
    if (segments.isEmpty || segments.last != 'api') 'api',
    '',
  ];
  return uri.replace(pathSegments: normalizedSegments);
}

Map<String, Object?> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, Object?>) {
    return decoded;
  }
  return const {};
}

String? _stringValue(Object? value) => value == null ? null : '$value';

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return null;
}
