import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a caught error into a short, user-facing message, keeping
/// implementation details (exception types, raw DB error text) out of the
/// UI. Reused across every page that surfaces repository errors.
String friendlyMessage(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    return 'Something went wrong saving your data. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
