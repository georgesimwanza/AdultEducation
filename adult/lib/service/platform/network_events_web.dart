import 'dart:async';

import 'package:web/web.dart' as web;

/// Whether the browser thinks there is a network at all.
bool get deviceOnline => web.window.navigator.onLine;

/// Fires true when the network returns and false when it drops.
Stream<bool> networkChanges() {
  final controller = StreamController<bool>();
  final subs = <StreamSubscription<web.Event>>[
    web.EventStreamProviders.onlineEvent.forTarget(web.window).listen((_) => controller.add(true)),
    web.EventStreamProviders.offlineEvent.forTarget(web.window).listen((_) => controller.add(false)),
  ];
  controller.onCancel = () {
    for (final s in subs) {
      s.cancel();
    }
  };
  return controller.stream;
}
