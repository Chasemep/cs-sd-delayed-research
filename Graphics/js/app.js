/**
 * Main Application Lifecycle Orchestrator
 */
class App {
  constructor() {
    this.renderer = new BirdRenderer('canvas-container');
    this.scenarioManager = new ScenarioManager(this.onScenarioLoaded.bind(this));
    this.controlsManager = new ControlsManager(this);

    this.dataset = null;
    this.scenarioInfo = null;

    // HUD Elements
    this.hudScenarioName = document.getElementById('hud-scenario-name');
    this.hudModelName = document.getElementById('hud-model-name');
    this.hudAgentCount = document.getElementById('hud-agent-count');
    this.hudTimeStep = document.getElementById('hud-time-step');
    this.hudMeanSpeed = document.getElementById('hud-mean-speed');
    this.hudDispersion = document.getElementById('hud-dispersion');
    this.hudConvStatus = document.getElementById('hud-conv-status');

    // UI Buttons
    this.btnToggleDrawer = document.getElementById('btn-toggle-drawer');
    this.btnCloseDrawer = document.getElementById('btn-close-drawer');
    this.sidebar = document.getElementById('sidebar');
    this.btnToggleCamera = document.getElementById('btn-toggle-camera');
    this.cameraModeText = document.getElementById('camera-mode-text');
    this.btnToggleTrails = document.getElementById('btn-toggle-trails');
    this.btnHotkeys = document.getElementById('btn-hotkeys');
    this.hotkeysModal = document.getElementById('hotkeys-modal');
    this.btnCloseModal = document.getElementById('btn-close-modal');

    this.initUI();
    this.animate(0);
  }

  initUI() {
    this.btnToggleDrawer.addEventListener('click', () => this.sidebar.classList.toggle('collapsed'));
    this.btnCloseDrawer.addEventListener('click', () => this.sidebar.classList.add('collapsed'));

    this.btnToggleCamera.addEventListener('click', () => this.toggleCameraMode());
    this.btnToggleTrails.addEventListener('click', () => this.toggleTrails());

    this.btnHotkeys.addEventListener('click', () => this.toggleHotkeysModal());
    this.btnCloseModal.addEventListener('click', () => this.hotkeysModal.classList.remove('open'));
  }

  onScenarioLoaded(scenarioData) {
    this.scenarioInfo = scenarioData;
    this.dataset = scenarioData.dataset;

    const pathParts = scenarioData.scenarioPath.split('/');
    const scenarioName = pathParts[pathParts.length - 1].replace(/_/g, ' ');
    const modelTitle = scenarioData.modelName.replace(/_/g, ' ').toUpperCase();

    this.hudScenarioName.textContent = scenarioName;
    this.hudModelName.textContent = modelTitle;
    this.hudAgentCount.textContent = this.dataset.agentCount;

    if (this.dataset.times.length > 1) {
      const step = this.dataset.times[1] - this.dataset.times[0];
      this.hudTimeStep.textContent = `${step.toFixed(3)} s`;
    }

    // Convergence Status Telemetry
    if (scenarioData.convergenceInfo && scenarioData.convergenceInfo[scenarioData.modelName]) {
      const info = scenarioData.convergenceInfo[scenarioData.modelName];
      if (info.consensus_reached && info.t_conv >= 0) {
        const vStr = info.v_conv && info.v_conv >= 0 ? `, v_conv = ${info.v_conv.toFixed(2)}` : '';
        this.hudConvStatus.innerHTML = `<span style="color: var(--accent-emerald);"><i class="fa-solid fa-circle-check"></i> Reached at t = ${info.t_conv.toFixed(2)}s${vStr}</span>`;
      } else {
        this.hudConvStatus.innerHTML = `<span style="color: var(--accent-rose);"><i class="fa-solid fa-circle-xmark"></i> No Convergence</span>`;
      }
    } else {
      this.hudConvStatus.innerHTML = `<span style="color: var(--text-muted);">No Metadata</span>`;
    }

    this.controlsManager.setDataset(this.dataset);
  }

  onFrameUpdate(frame, frameIdx) {
    if (!frame) return;

    // Update 3D WebGL Scene
    this.renderer.updateFrame(frame.agents);

    // Compute Telemetry Stats (Mean Speed & Dispersion)
    let sumVx = 0, sumVy = 0, sumVz = 0;
    const N = frame.agents.length;

    for (let a of frame.agents) {
      sumVx += a.VX;
      sumVy += a.VY;
      sumVz += a.VZ;
    }

    const avgVx = sumVx / N;
    const avgVy = sumVy / N;
    const avgVz = sumVz / N;
    const meanSpeed = Math.sqrt(avgVx * avgVx + avgVy * avgVy + avgVz * avgVz);

    let varianceSum = 0;
    for (let a of frame.agents) {
      const dvx = a.VX - avgVx;
      const dvy = a.VY - avgVy;
      const dvz = a.VZ - avgVz;
      varianceSum += (dvx * dvx + dvy * dvy + dvz * dvz);
    }
    const dispersion = varianceSum / N;

    this.hudMeanSpeed.textContent = meanSpeed.toFixed(2);
    this.hudDispersion.textContent = dispersion.toFixed(4);
  }

  toggleCameraMode() {
    const modeName = this.renderer.toggleCameraMode();
    this.cameraModeText.textContent = modeName;
  }

  toggleTrails() {
    const isShowing = this.renderer.toggleTrails();
    this.btnToggleTrails.style.opacity = isShowing ? '1' : '0.5';
  }

  toggleHotkeysModal() {
    this.hotkeysModal.classList.toggle('open');
  }

  animate(timestamp) {
    requestAnimationFrame(this.animate.bind(this));
    this.controlsManager.tick(timestamp);
    this.renderer.render();
  }
}

// Initialize Web Application when DOM is ready
window.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
});
