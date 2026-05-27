import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlLaunchFn =
    Future<bool> Function(Uri uri, {required LaunchMode mode});

Future<bool> openExternalLink({
  required BuildContext context,
  required String url,
  UrlLaunchFn launch = _launchWithMode,
}) async {
  final uri = Uri.parse(url);
  final opened = await launch(uri, mode: LaunchMode.inAppWebView);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Unable to open link')));
  }
  return opened;
}

Future<bool> _launchWithMode(Uri uri, {required LaunchMode mode}) {
  return launchUrl(uri, mode: mode);
}
