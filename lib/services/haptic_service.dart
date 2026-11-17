import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'web_feedback.dart';

/// On the web, Flutter maps these to 10–30 ms `navigator.vibrate` pulses that
/// most phones can't feel (and iOS Safari ignores), so the web build uses
/// web/feedback.js instead.
class HapticService {
  static void move() => kIsWeb ? webHaptic('move') : HapticFeedback.selectionClick();
  static void merge() => kIsWeb ? webHaptic('merge') : HapticFeedback.mediumImpact();
  static void milestone() => kIsWeb ? webHaptic('milestone') : HapticFeedback.heavyImpact();
}
