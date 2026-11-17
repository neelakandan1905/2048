import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'web_feedback.dart';

/// Short UI sounds. Failures (e.g. no audio device, browser autoplay rules,
/// tests without a platform) are swallowed: sound is never critical.
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  AudioPlayer? _move;
  AudioPlayer? _merge;

  // On the web, sounds are synthesised by web/feedback.js: phone browsers block
  // audio that starts after an async file load, outside the touch event.
  Future<void> move() async => kIsWeb ? webSound('move') : _play(_move ??= AudioPlayer(), 'audio/move.wav');
  Future<void> merge() async => kIsWeb ? webSound('merge') : _play(_merge ??= AudioPlayer(), 'audio/merge.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _move?.dispose();
    await _merge?.dispose();
    _move = _merge = null;
  }
}
