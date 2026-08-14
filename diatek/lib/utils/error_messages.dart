import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/external/api_client.dart';

/// Turns a caught error into a short, user-facing message, keeping
/// implementation details (exception types, raw DB/HTTP error text) out of
/// the UI. Reused across every page that surfaces repository or external
/// API errors.
String friendlyMessage(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    return 'Something went wrong saving your data. Please try again.';
  }
  if (error is ApiException) {
    return 'Could not reach the movie database. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
