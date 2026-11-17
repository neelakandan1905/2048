import 'dart:js_interop';

@JS('gameFeedback.sound')
external void _sound(String kind);

@JS('gameFeedback.haptic')
external void _haptic(String kind);

@JS('gameFeedback')
external JSObject? get _bridge;

void webSound(String kind) {
  if (_bridge != null) _sound(kind);
}

void webHaptic(String kind) {
  if (_bridge != null) _haptic(kind);
}
