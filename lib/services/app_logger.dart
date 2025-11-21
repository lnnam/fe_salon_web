import 'dart:developer' as developer;

/// Lightweight logging wrapper to replace `print()` calls.
/// Uses `dart:developer.log` which is suitable for production and
/// integrates with observability tools.
void appLog(Object? message, {String name = 'app'}) {
  developer.log(message?.toString() ?? '', name: name);
}
