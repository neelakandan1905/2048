// Calls into web/feedback.js on the web build; no-ops on Android/iOS.
export 'web_feedback_stub.dart' if (dart.library.js_interop) 'web_feedback_web.dart';
