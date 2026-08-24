/**
 * Controls Manager: Playback Animation Engine & Keyboard Hotkey Listener
 */
class ControlsManager {
  constructor(app) {
    this.app = app;
    this.isPlaying = false;
    this.currentFrameIdx = 0;
    this.playbackSpeed = 1.0;
    this.lastFrameTime = performance.now();

    this.playPauseBtn = document.getElementById('btn-play-pause');
    this.playIcon = document.getElementById('play-icon');
    this.resetBtn = document.getElementById('btn-reset');
    this.stepBackBtn = document.getElementById('btn-step-back');
    this.stepForwardBtn = document.getElementById('btn-step-forward');
    this.timeScrubber = document.getElementById('time-scrubber');
    this.speedSelect = document.getElementById('speed-select');
    
    this.timeCurrentEl = document.getElementById('time-current');
    this.timeTotalEl = document.getElementById('time-total');

    this.initUIEventListeners();
    this.initHotkeyListeners();
  }

  initUIEventListeners() {
    this.playPauseBtn.addEventListener('click', () => this.togglePlayPause());
    this.resetBtn.addEventListener('click', () => this.resetTime());
    this.stepBackBtn.addEventListener('click', () => this.stepBackward());
    this.stepForwardBtn.addEventListener('click', () => this.stepForward());

    this.timeScrubber.addEventListener('input', (e) => {
      this.currentFrameIdx = parseInt(e.target.value, 10);
      this.updateFrame();
    });

    this.speedSelect.addEventListener('change', (e) => {
      this.playbackSpeed = parseFloat(e.target.value);
    });
  }

  initHotkeyListeners() {
    window.addEventListener('keydown', (e) => {
      // Avoid triggering when user is typing in input fields
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;

      switch(e.code) {
        case 'Space':
        case 'KeyK':
          e.preventDefault();
          this.togglePlayPause();
          break;
        case 'KeyR':
          e.preventDefault();
          this.resetTime();
          break;
        case 'ArrowLeft':
        case 'KeyA':
          e.preventDefault();
          this.stepBackward();
          break;
        case 'ArrowRight':
        case 'KeyD':
          e.preventDefault();
          this.stepForward();
          break;
        case 'ArrowUp':
        case 'KeyW':
          e.preventDefault();
          this.changeSpeed(1);
          break;
        case 'ArrowDown':
        case 'KeyS':
          e.preventDefault();
          this.changeSpeed(-1);
          break;
        case 'KeyC':
          e.preventDefault();
          this.app.toggleCameraMode();
          break;
        case 'KeyT':
          e.preventDefault();
          this.app.toggleTrails();
          break;
        case 'KeyH':
          e.preventDefault();
          this.app.toggleHotkeysModal();
          break;
      }
    });
  }

  togglePlayPause() {
    this.isPlaying = !this.isPlaying;
    if (this.isPlaying) {
      this.playIcon.className = 'fa-solid fa-pause';
      this.lastFrameTime = performance.now();
    } else {
      this.playIcon.className = 'fa-solid fa-play';
    }
  }

  resetTime() {
    this.currentFrameIdx = 0;
    this.updateFrame();
  }

  stepForward() {
    if (!this.app.dataset) return;
    const maxIdx = this.app.dataset.frames.length - 1;
    this.currentFrameIdx = Math.min(maxIdx, this.currentFrameIdx + 1);
    this.updateFrame();
  }

  stepBackward() {
    if (!this.app.dataset) return;
    this.currentFrameIdx = Math.max(0, this.currentFrameIdx - 1);
    this.updateFrame();
  }

  changeSpeed(direction) {
    const options = Array.from(this.speedSelect.options).map(o => parseFloat(o.value));
    const currentIdx = options.indexOf(this.playbackSpeed);
    let nextIdx = currentIdx + direction;
    nextIdx = Math.max(0, Math.min(options.length - 1, nextIdx));
    
    this.playbackSpeed = options[nextIdx];
    this.speedSelect.value = this.playbackSpeed.toString();
  }

  setDataset(dataset) {
    this.currentFrameIdx = 0;
    this.timeScrubber.min = 0;
    this.timeScrubber.max = dataset.frames.length - 1;
    this.timeScrubber.value = 0;

    const totalT = dataset.times[dataset.times.length - 1] || 0;
    this.timeTotalEl.textContent = `${totalT.toFixed(2)}s`;
    this.updateFrame();
  }

  updateFrame() {
    if (!this.app.dataset || !this.app.dataset.frames[this.currentFrameIdx]) return;
    
    const frame = this.app.dataset.frames[this.currentFrameIdx];
    this.timeScrubber.value = this.currentFrameIdx;
    this.timeCurrentEl.textContent = `${frame.time.toFixed(2)}s`;

    this.app.onFrameUpdate(frame, this.currentFrameIdx);
  }

  tick(timestamp) {
    if (this.isPlaying && this.app.dataset) {
      const delta = (timestamp - this.lastFrameTime) / 1000;
      
      let dtSim = 0.1;
      if (this.app.dataset.times && this.app.dataset.times.length > 1) {
        dtSim = this.app.dataset.times[1] - this.app.dataset.times[0];
      }
      if (dtSim <= 0) dtSim = 0.1;

      // 1.0x speed = 1.0 sim second per 1.0 wall-clock second
      const targetFPS = (1.0 / dtSim) * this.playbackSpeed;

      if (delta >= (1 / targetFPS)) {
        const maxIdx = this.app.dataset.frames.length - 1;
        if (this.currentFrameIdx < maxIdx) {
          this.currentFrameIdx++;
          this.updateFrame();
        } else {
          // Loop playback
          this.currentFrameIdx = 0;
          this.updateFrame();
        }
        this.lastFrameTime = timestamp;
      }
    }
  }
}
