import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iPhone, iPad and Mac get iOS-style UI; everything else gets Material.
/// (The web build reports the phone's platform, so Safari on iPhone is iOS.)
bool useCupertino(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

/// A yes/no question in the platform's native alert style.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = useCupertino(context)
      ? await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              CupertinoDialogAction(isDestructiveAction: destructive, onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
            ],
          ),
        )
      : await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
            ],
          ),
        );
  return result ?? false;
}

/// A message with a single button that must be tapped to continue.
Future<void> showNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String buttonLabel,
}) =>
    useCupertino(context)
        ? showCupertinoDialog<void>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(context), child: Text(buttonLabel))],
            ),
          )
        : showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(buttonLabel))],
            ),
          );
