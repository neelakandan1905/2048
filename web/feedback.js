// Sound and vibration for the web build. Phone browsers only allow audio and
// vibration from inside a real touch/key event, so the audio context is
// unlocked on the first interaction and sounds are synthesised instantly
// (no file loading that would lose the user-gesture window).
//
// Open the page with ?debug=1 to send diagnostics to tools/serve_web.py
// (POST /__log), which prints them on the Mac.
(function () {
  var BUILD = 'feedback-v3';
  var DEBUG = /[?&]debug=1/.test(location.search);
  var ctx = null;
  var unlockedBy = null;
  var AC = window.AudioContext || window.webkitAudioContext;

  // iOS mutes web audio while the ring/silent switch is on, unless the page
  // asks for a "playback" audio session (Safari 17+).
  var audioSession = 'n/a';
  try {
    if (navigator.audioSession) {
      navigator.audioSession.type = 'playback';
      audioSession = navigator.audioSession.type;
    }
  } catch (e) { audioSession = 'error: ' + e; }

  function activation() {
    var ua = navigator.userActivation;
    return ua ? { active: ua.isActive, hasBeenActive: ua.hasBeenActive } : 'n/a';
  }

  // Debug output: an on-screen panel (works anywhere, e.g. GitHub Pages) plus
  // a POST to tools/serve_web.py when served from the Mac.
  var panel = null;
  function show(line) {
    if (!panel) {
      if (!document.body) return;
      panel = document.createElement('pre');
      panel.style.cssText = 'position:fixed;left:0;right:0;bottom:0;z-index:2147483647;margin:0;' +
        'max-height:38vh;overflow:auto;padding:6px 8px;background:rgba(0,0,0,.85);color:#9f9;' +
        'font:11px/1.35 ui-monospace,Menlo,monospace;white-space:pre-wrap;pointer-events:none';
      document.body.appendChild(panel);
    }
    panel.textContent = (line + '\n' + panel.textContent).split('\n').slice(0, 40).join('\n');
  }

  function log(event, data) {
    if (!DEBUG) return;
    try {
      var body = JSON.stringify({ t: Date.now(), event: event, data: data || {} });
      show(new Date().toLocaleTimeString() + ' ' + event + ' ' + JSON.stringify(data || {}));
      fetch('__log', { method: 'POST', body: body, keepalive: true, headers: { 'Content-Type': 'application/json' } }).catch(function () {});
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
    // A fresh hidden switch each time, clicked through its <label>: the pattern
    // that reliably triggers the haptic on iOS 18+.
    var label = document.createElement('label');
    label.setAttribute('aria-hidden', 'true');
    label.style.display = 'none';
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    label.appendChild(input);
    document.head.appendChild(label);
    label.click();
    document.head.removeChild(label);
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
    audioSession: audioSession,
    hasSwitchInput: (function () { var i = document.createElement('input'); i.type = 'checkbox'; i.setAttribute('switch', ''); return 'switch' in i; })(),
    secureContext: window.isSecureContext,
    standalone: !!(window.navigator.standalone || (window.matchMedia && matchMedia('(display-mode: standalone)').matches))
  });
})();
