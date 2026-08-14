import 'package:flutter/material.dart';

/// Shows a Yes/No confirmation dialog, returning true if the user tapped
/// [confirmLabel] (false if they cancelled or dismissed it). Shared by every
/// action that shouldn't happen from a single accidental tap (removing a
/// film from the list, marking one back as not watched).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
