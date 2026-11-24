// Picks the real controller on Android and a stub on web (the overlay and
// ML Kit plugins don't compile for web).
export 'nudge_stub.dart' if (dart.library.io) 'nudge_controller.dart';
