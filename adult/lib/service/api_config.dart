import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend origin used by every service. The Android emulator reaches the
/// development machine through 10.0.2.2; a browser can use localhost directly.
const String kBackendHost =
    kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
