import 'dart:developer' as developer;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Lightweight logging wrapper to replace `print()` calls.
/// By default logging is disabled to avoid showing logs on every page.
/// Call `setAppLogEnabled(true)` to re-enable logs during development.
bool _appLogEnabled = true; // Enabled by default for web browser console

void setAppLogEnabled(bool enabled) {
  _appLogEnabled = enabled;
}

void appLog(Object? message, {String name = 'app'}) {
  if (!_appLogEnabled) return; // no-op when logging disabled

  final msg = message?.toString() ?? '';

  // Always log to browser console on web
  if (kIsWeb) {
    html.window.console.log('[$name] $msg');
  }

  // Also use developer log for other platforms
  developer.log(msg, name: name);
}
