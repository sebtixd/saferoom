import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/errors/exceptions.dart';

/// Shared HTTP transport for all SafeRoom backend services.
///
/// Every non-2xx response is converted into a typed [AppException], keeping
/// repositories free of transport and JSON-decoding details.
class ApiClient {
  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> send(
    String path,
    String method, {
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.authBaseUrl}$path');
    try {
      final response = await _client
          .send(
            http.Request(method, uri)
              ..headers.addAll({
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (accessToken != null) 'Authorization': 'Bearer $accessToken',
              })
              ..body = body == null ? '' : jsonEncode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      final responseBody = await response.stream.bytesToString();
      final decoded = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw _mapError(response.statusCode, decoded);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(message: 'The server took too long to respond');
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'Could not reach the server: ${e.message}');
    } on FormatException {
      throw const ServerException(message: 'The server returned an invalid response');
    }
  }

  AppException _mapError(int statusCode, Map<String, dynamic> decoded) {
    final error = (decoded['error'] as Map?) ?? const <String, dynamic>{};
    final code = error['code'] as String? ?? 'http_$statusCode';
    final message = error['message'] as String? ?? 'Request failed ($statusCode)';
    final fields = error['fields'] as Map?;

    switch (code) {
      case 'validation_error':
        final detail = fields?.values.isNotEmpty == true
            ? ' ${fields!.values.first}'
            : '';
        return ValidationException(message: '$message.$detail', code: code);
      case 'invalid_credentials':
      case 'email_taken':
      case 'invalid_token':
      case 'token_expired':
      case 'invalid_refresh_token':
      case 'invalid_reset_token':
        return AuthException(message: message, code: code);
      default:
        return ServerException(message: message, code: code);
    }
  }
}
