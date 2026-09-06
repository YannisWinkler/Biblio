import 'package:diatek/data/external/api_client.dart';
import 'package:diatek/utils/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyMessage', () {
    test('passes AuthException messages through as-is', () {
      const error = AuthException('Invalid login credentials');
      expect(friendlyMessage(error), 'Invalid login credentials');
    });

    test('hides PostgrestException details behind a generic message', () {
      const error = PostgrestException(message: 'duplicate key value violates unique constraint');
      expect(friendlyMessage(error), 'Something went wrong saving your data. Please try again.');
    });

    test('hides ApiException details behind a generic message', () {
      final error = ApiException(Uri.parse('https://api.themoviedb.org/3/movie/1'), 500);
      expect(friendlyMessage(error), 'Could not reach the movie database. Please try again.');
    });

    test('falls back to a generic message for anything else', () {
      expect(friendlyMessage(StateError('boom')), 'Something went wrong. Please try again.');
    });
  });
}
