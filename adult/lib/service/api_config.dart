import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend origin used by every service. A browser uses localhost directly;
/// the Android emulator reaches the development machine through 10.0.2.2.
/// A phone on USB runs with `adb reverse tcp:8080 tcp:8080` and
/// `--dart-define=BACKEND_HOST=http://localhost:8080`.
const String kBackendHost = String.fromEnvironment(
  'BACKEND_HOST',
  defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
);
