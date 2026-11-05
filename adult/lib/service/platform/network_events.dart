// The browser reports when the network drops or returns; other platforms
// rely on ConnectivityService's periodic server check alone.
export 'network_events_io.dart' if (dart.library.js_interop) 'network_events_web.dart';
