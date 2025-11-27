import 'dart:developer' as developer;

/// Lightweight logging wrapper to replace `print()` calls.
/// By default logging is disabled to avoid showing logs on every page.
/// Call `setAppLogEnabled(true)` to re-enable logs during development.
bool _appLogEnabled = false;

void setAppLogEnabled(bool enabled) {
  _appLogEnabled = enabled;
}

void appLog(Object? message, {String name = 'app'}) {
  if (!_appLogEnabled) return; // no-op when logging disabled
  developer.log(message?.toString() ?? '', name: name);
}
