// Opens the app's local database with the right engine for the platform:
// sqlite compiled to WASM (stored in IndexedDB) on the web, the device's
// own sqlite on Android / iOS / desktop.
export 'app_database_io.dart' if (dart.library.js_interop) 'app_database_web.dart';
