import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around a JSON REST API: base URL, default headers, and
/// error handling shared by every external data source (TMDB today, others
/// later), so each source only has to describe its own endpoints.
class ApiClient {
  ApiClient({required String baseUrl, Map<String, String> headers = const {}})
      : _baseUrl = Uri.parse(baseUrl),
        _headers = headers; // ignore: prefer_initializing_formals

  final Uri _baseUrl;
  final Map<String, String> _headers;

  /// GETs [path] (relative to the base URL) with [query] appended, and
  /// decodes the response body as JSON.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final uri = _baseUrl.replace(
      path: '${_baseUrl.path}$path',
      queryParameters: {..._baseUrl.queryParameters, ...query},
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(uri, response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

/// A request to an external API failed.
class ApiException implements Exception {
  ApiException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode) for $uri';
}
