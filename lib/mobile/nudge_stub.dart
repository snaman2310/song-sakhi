import 'package:flutter/foundation.dart';

/// Web build: there is no floating nudge, so this is an inert stand-in with the
/// same surface as the real NudgeController.
class NudgeController {
  NudgeController._();
  static final NudgeController instance = NudgeController._();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  Future<String?> enable() async => 'The floating nudge only works in the Android app.';
  Future<void> disable() async {}
}
