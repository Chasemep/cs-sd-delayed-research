/**
 * Scenario Manager: Scans output folders, parses CSV datasets, and builds tree UI
 */
class ScenarioManager {
  constructor(onSelectScenarioCallback) {
    this.onSelectScenario = onSelectScenarioCallback;
    this.container = document.getElementById('scenario-tree');
    this.scenariosTree = null;
    this.activeScenarioPath = null;
    this.activeModel = null;
    this.parsedDataset = null; // Map of time -> array of agent state objects
    this.convergenceInfo = null;
    
    this.loadScenariosTree();
  }

  async loadScenariosTree() {
    try {
      const response = await fetch('/api/scenarios');
      if (!response.ok) throw new Error('API request failed');
      this.scenariosTree = await response.json();
      this.renderTreeUI();
    } catch (err) {
      console.warn('Could not load /api/scenarios from server, showing manual fallback notice.', err);
      this.renderFallbackUI();
    }
  }

  renderTreeUI() {
    this.container.innerHTML = '';
    if (!this.scenariosTree || (!this.scenariosTree.isScenario && (!this.scenariosTree.children || this.scenariosTree.children.length === 0))) {
      this.container.innerHTML = '<div style="padding: 16px; color: var(--text-muted);">No output scenarios found in <code>output/</code> folder.</div>';
      return;
    }

    const rootElement = this.createTreeNode(this.scenariosTree, true);
    this.container.appendChild(rootElement);
  }

  createTreeNode(node, isRoot = false) {
    const nodeDiv = document.createElement('div');
    nodeDiv.className = 'tree-node';

    // If node is a folder containing children
    if (node.children && node.children.length > 0) {
      const folderHeader = document.createElement('div');
      folderHeader.className = `tree-folder ${isRoot ? 'open' : ''}`;
      folderHeader.innerHTML = `
        <i class="fa-solid fa-chevron-right folder-icon"></i>
        <i class="fa-solid fa-folder${isRoot ? '-open' : ''}" style="color: var(--accent-amber);"></i>
        <span>${isRoot ? 'Output Root' : node.name}</span>
      `;

      const childrenContainer = document.createElement('div');
      childrenContainer.className = `tree-children ${isRoot ? 'open' : ''}`;

      // Render children recursively
      node.children.forEach(child => {
        childrenContainer.appendChild(this.createTreeNode(child, false));
      });

      folderHeader.addEventListener('click', (e) => {
        e.stopPropagation();
        folderHeader.classList.toggle('open');
        childrenContainer.classList.toggle('open');
      });

      nodeDiv.appendChild(folderHeader);
      nodeDiv.appendChild(childrenContainer);
    } 
    // If node is a scenario containing CSV files directly
    else if (node.isScenario) {
      const scenarioDiv = document.createElement('div');
      scenarioDiv.className = 'tree-scenario';
      scenarioDiv.dataset.path = node.relativePath;
      
      const readableName = node.name.replace(/_/g, ' ');
      scenarioDiv.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: space-between;">
          <span><i class="fa-solid fa-cube" style="color: var(--primary-cyan); margin-right: 6px;"></i> ${readableName}</span>
          ${node.hasConvergenceInfo ? '<i class="fa-solid fa-circle-check" style="color: var(--accent-emerald); font-size: 11px;" title="Convergence info available"></i>' : ''}
        </div>
      `;

      scenarioDiv.addEventListener('click', (e) => {
        e.stopPropagation();
        document.querySelectorAll('.tree-scenario').forEach(el => el.classList.remove('active'));
        scenarioDiv.classList.add('active');
        this.selectScenario(node);
      });

      nodeDiv.appendChild(scenarioDiv);
    }

    return nodeDiv;
  }

  renderFallbackUI() {
    this.container.innerHTML = `
      <div style="padding: 16px;">
        <div style="color: var(--accent-amber); font-weight: 600; margin-bottom: 8px;">
          <i class="fa-solid fa-triangle-exclamation"></i> Offline Mode
        </div>
        <p style="font-size: 12px; color: var(--text-muted);">
          To enable dynamic folder browsing, run <code>npm start</code> or <code>node server.js</code> inside the <code>Graphics</code> folder.
        </p>
      </div>
    `;
  }

  async selectScenario(scenarioNode) {
    this.activeScenarioPath = scenarioNode.relativePath;
    
    // Default model pick
    let defaultCsv = scenarioNode.csvFiles.find(f => f.includes('no_delay')) || scenarioNode.csvFiles[0];
    this.activeModel = defaultCsv.replace('agent_positions_', '').replace('.csv', '');

    // Load Convergence Info if present
    this.convergenceInfo = null;
    if (scenarioNode.hasConvergenceInfo) {
      try {
        const jsonUrl = `/api/file?path=${encodeURIComponent(scenarioNode.relativePath + '/convergence_info.json')}`;
        const jsonRes = await fetch(jsonUrl);
        if (jsonRes.ok) {
          this.convergenceInfo = await jsonRes.json();
        }
      } catch (e) {}
    }

    await this.loadModelData(scenarioNode.relativePath, defaultCsv);
  }

  async loadModelData(scenarioRelPath, csvFileName) {
    const csvUrl = `/api/file?path=${encodeURIComponent(scenarioRelPath + '/' + csvFileName)}`;
    try {
      const response = await fetch(csvUrl);
      if (!response.ok) throw new Error('Failed to download CSV');
      const csvText = await response.text();
      
      this.parsedDataset = this.parseCSV(csvText);

      if (this.onSelectScenario) {
        this.onSelectScenario({
          scenarioPath: scenarioRelPath,
          modelName: this.activeModel,
          availableModels: this.availableModelsList,
          dataset: this.parsedDataset,
          convergenceInfo: this.convergenceInfo
        });
      }
    } catch (err) {
      console.error('Error loading CSV dataset:', err);
    }
  }

  parseCSV(csvText) {
    const lines = csvText.trim().split('\n');
    if (lines.length < 2) return null;

    const headers = lines[0].split(',').map(h => h.trim());
    const timeIdx = headers.indexOf('Time');
    const agentIdx = headers.indexOf('AgentID');
    const xIdx = headers.indexOf('X');
    const yIdx = headers.indexOf('Y');
    const zIdx = headers.indexOf('Z');
    const vxIdx = headers.indexOf('VX');
    const vyIdx = headers.indexOf('VY');
    const vzIdx = headers.indexOf('VZ');

    const framesMap = new Map(); // Time -> Array of agent objects

    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i].split(',').map(c => parseFloat(c.trim()));
      if (cols.length < headers.length || isNaN(cols[timeIdx])) continue;

      const t = cols[timeIdx];
      const agentData = {
        AgentID: cols[agentIdx],
        X: cols[xIdx],
        Y: cols[yIdx],
        Z: cols[zIdx],
        VX: cols[vxIdx],
        VY: cols[vyIdx],
        VZ: cols[vzIdx]
      };

      if (!framesMap.has(t)) {
        framesMap.set(t, []);
      }
      framesMap.get(t).push(agentData);
    }

    // Convert to sorted array of frames
    const times = Array.from(framesMap.keys()).sort((a, b) => a - b);
    const frames = times.map(t => ({
      time: t,
      agents: framesMap.get(t).sort((a, b) => a.AgentID - b.AgentID)
    }));

    return {
      times: times,
      frames: frames,
      totalDuration: times[times.length - 1] - times[0],
      agentCount: frames[0] ? frames[0].agents.length : 0
    };
  }
}
