import 'dart:convert';

import 'package:readaway/src/core/error/errors.dart';
import 'package:readaway/src/core/services/http/http_service.dart';
import 'package:readaway_core/readaway_core.dart';

/// Logs HTTP traffic through [AppLogger].
///
/// Registered last in the interceptor chain so that, in the error phase
/// (which runs in reverse registration order), it observes the raw
/// [DioException] before [HttpService._onError] maps it to an
/// [ApiException].
///
/// Sensitive data (auth headers, tokens, passwords in query parameters) is
/// redacted, and request/response bodies are truncated to keep logs readable.
class HttpLoggingInterceptor extends Interceptor {
  final _log = AppLogger.instance.scope('Http');

  static const _maxBodyChars = 2000;
  static const _maxHeaderChars = 200;
  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
  };
  static const _sensitiveQueryParams = {
    'api_key',
    'apikey',
    'access_token',
    'token',
    'password',
    'secret',
  };

  HttpLoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = _redactUri(options.uri);
    _log.d('--> ${options.method} $uri');
    _log.d('headers: ${_formatHeaders(options.headers)}');
    final body = _stringify(options.data);
    if (body.isNotEmpty) {
      _log.d('body: ${_truncate(body, _maxBodyChars)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final request = response.requestOptions;
    _log.d(
      '<-- ${response.statusCode} ${request.method} '
      '${_redactUri(request.uri)}',
    );
    final body = _stringify(response.data);
    if (body.isNotEmpty) {
      _log.d('body: ${_truncate(body, _maxBodyChars)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final status = err.response?.statusCode;
    final message = err.message ?? err.type.name;
    _log.w(
      '<-- ${status ?? 'ERR'} ${request.method} '
      '${_redactUri(request.uri)} (${err.type.name}) $message',
    );
    final body = _stringify(err.response?.data);
    if (body.isNotEmpty) {
      _log.w('body: ${_truncate(body, _maxBodyChars)}');
    }
    handler.next(err);
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    final redacted = <String, String>{};
    headers.forEach((key, value) {
      final isSensitive = _sensitiveHeaders.contains(key.toLowerCase());
      redacted[key] = isSensitive
          ? '***'
          : _truncate('$value', _maxHeaderChars);
    });
    return jsonEncode(redacted);
  }

  Uri _redactUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri;
    final redacted = uri.queryParameters.map((key, value) {
      final isSensitive = _sensitiveQueryParams.contains(key.toLowerCase());
      return MapEntry(key, isSensitive ? '***' : value);
    });
    return uri.replace(queryParameters: redacted);
  }

  String _stringify(Object? data) {
    if (data == null) return '';
    if (data is FormData) {
      final fieldKeys = data.fields.map((e) => e.key).toList();
      final fileKeys = data.files.map((e) => e.key).toList();
      return 'FormData(fields: $fieldKeys, files: $fileKeys)';
    }
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _truncate(String value, int maxChars) {
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars)}... (${value.length} chars)';
  }
}
