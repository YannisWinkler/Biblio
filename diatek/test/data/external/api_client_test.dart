import 'dart:convert';

import 'package:diatek/data/external/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient.getJson', () {
    test('decodes a successful JSON response', () async {
      final client = ApiClient(
        baseUrl: 'https://api.example.com/3',
        client: MockClient((request) async {
          expect(request.url.origin, 'https://api.example.com');
          expect(request.url.path, '/3/movie/1');
          return http.Response(jsonEncode({'id': 1, 'title': 'Arrival'}), 200);
        }),
      );

      final json = await client.getJson('/movie/1');
      expect(json, {'id': 1, 'title': 'Arrival'});
    });

    test('sends the configured headers and merges query parameters with the base URL', () async {
      final client = ApiClient(
        baseUrl: 'https://api.example.com/3?language=fr-FR',
        headers: {'Authorization': 'Bearer token'},
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token');
          expect(request.url.queryParameters, {'language': 'fr-FR', 'query': 'arrival'});
          return http.Response(jsonEncode({}), 200);
        }),
      );

      await client.getJson('/search/movie', query: {'query': 'arrival'});
    });

    test('throws ApiException for a non-2xx response, without the response body', () async {
      final client = ApiClient(
        baseUrl: 'https://api.example.com/3',
        client: MockClient((request) async => http.Response('not found', 404)),
      );

      await expectLater(
        client.getJson('/movie/999'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
