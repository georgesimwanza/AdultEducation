/// Not known on this platform: the server check decides.
bool get deviceOnline => true;

Stream<bool> networkChanges() => const Stream.empty();
