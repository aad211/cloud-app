import 'package:flutter/material.dart';

/// Shows a confirmation dialog asking the user if they want to exit the app.
///
/// Returns `true` if the user confirms exit, `false` if they cancel or
/// dismiss the dialog.
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit App?'),
      content: const Text('Are you sure you want to exit CLOUD?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Exit'),
        ),
      ],
    ),
  );
  
  return result ?? false;
}
