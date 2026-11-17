// Sound and vibration for the web build. Phone browsers only allow audio and
// vibration from inside a real touch/key event, so the audio context is
// unlocked on the first interaction and sounds are synthesised instantly
// (no file loading that would lose the user-gesture window).
//
// Open the page with ?debug=1 to send diagnostics to tools/serve_web.py
// (POST /__log), which prints them on the Mac.
(function () {
  var BUILD = 'feedback-v2';
  var DEBUG = /[?&]debug=1/.test(location.search);
  var ctx = null;
  var sw = null;
  var unlockedBy = null;
  var AC = window.AudioContext || window.webkitAudioContext;

  function activation() {
    var ua = navigator.userActivation;
    return ua ? { active: ua.isActive, hasBeenActive: ua.hasBeenActive } : 'n/a';
  }

  function log(event, data) {
    if (!DEBUG) return;
    try {
      var body = JSON.stringify({ t: Date.now(), event: event, data: data || {} });
      fetch('/__log', { method: 'POST', body: body, keepalive: true, headers: { 'Content-Type': 'application/json' } }).catch(function () {});
    } catch (e) {}
  }

  function unlock(e) {
    if (!AC) return;
    try {
      if (!ctx) ctx = new AC();
      if (ctx.state !== 'running') {
        ctx.resume().then(function () {
          log('audio-resumed', { by: e && e.type, state: ctx.state });
        }, function (err) {
          log('audio-resume-failed', { by: e && e.type, error: String(err) });
        });
      }
      // iOS needs something actually started inside the gesture.
      var src = ctx.createBufferSource();
      src.buffer = ctx.createBuffer(1, 1, 22050);
      src.connect(ctx.destination);
      src.start(0);
      if (!unlockedBy && e) {
        unlockedBy = e.type;
        log('unlock', { by: e.type, state: ctx.state, activation: activation() });
      }
    } catch (err) {
      log('unlock-error', { error: String(err) });
    }
  }
  ['pointerdown', 'pointerup', 'touchstart', 'touchend', 'mousedown', 'keydown', 'click'].forEach(function (t) {
    document.addEventListener(t, unlock, { capture: true, passive: true });
  });

  function tone(freq, start, dur, vol) {
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(vol, start + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(start);
    osc.stop(start + dur + 0.02);
  }

  // iOS Safari has no Vibration API; since iOS 18 toggling a native
  // <input type="checkbox" switch> gives a haptic tick during a user gesture.
  function iosHaptic() {
    if (!sw) {
      sw = document.createElement('label');
      sw.setAttribute('aria-hidden', 'true');
      sw.style.cssText = 'position:fixed;left:-9999px;top:0;opacity:0;pointer-events:none';
      var input = document.createElement('input');
      input.type = 'checkbox';
      input.setAttribute('switch', '');
      input.tabIndex = -1;
      sw.appendChild(input);
      document.body.appendChild(sw);
    }
    sw.click();
  }

  var VIBRATE = { move: 25, merge: 45, milestone: [70, 50, 90] };

  window.gameFeedback = {
    sound: function (kind) {
      try {
        if (!ctx) unlock();
        if (!ctx) { log('sound-skipped', { kind: kind, reason: 'no AudioContext' }); return; }
        if (ctx.state !== 'running') ctx.resume();
        var t = ctx.currentTime + 0.005;
        if (kind === 'merge') { tone(660, t, 0.07, 0.25); tone(990, t + 0.06, 0.12, 0.25); }
        else { tone(520, t, 0.06, 0.18); }
        log('sound', { kind: kind, state: ctx.state, activation: activation() });
      } catch (err) {
        log('sound-error', { kind: kind, error: String(err) });
      }
    },
    haptic: function (kind) {
      try {
        if (typeof navigator.vibrate === 'function') {
          var ok = navigator.vibrate(VIBRATE[kind] || 25);
          log('haptic', { kind: kind, method: 'navigator.vibrate', accepted: ok, activation: activation() });
        } else {
          iosHaptic();
          log('haptic', { kind: kind, method: 'ios-switch', activation: activation() });
        }
      } catch (err) {
        log('haptic-error', { kind: kind, error: String(err) });
      }
    }
  };

  window.addEventListener('error', function (e) { log('page-error', { message: e.message }); });
  log('load', {
    build: BUILD,
    userAgent: navigator.userAgent,
    hasVibrate: typeof navigator.vibrate === 'function',
    hasAudioContext: !!AC,
    secureContext: window.isSecureContext,
    standalone: !!(window.navigator.standalone || (window.matchMedia && matchMedia('(display-mode: standalone)').matches))
  });
})();
