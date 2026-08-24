/**
 * 3D Bird & Scene WebGL Renderer using Three.js
 */
class BirdRenderer {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.controls = null;
    
    this.birds = [];           // Array of THREE.Mesh objects for active birds
    this.trailLines = [];      // Array of THREE.Line objects for trailing trajectories
    this.trailHistories = [];  // Array of position history arrays per bird

    this.showTrails = true;
    this.followCentroid = false;
    this.colorPalette = [
      0x06b6d4, 0x8b5cf6, 0xf59e0b, 0x10b981, 0xef4444,
      0xec4899, 0x3b82f6, 0x84cc16, 0x6366f1, 0x14b8a6
    ];

    this.birdGeometry = this.createBirdGeometry();
    this.initScene();
  }

  initScene() {
    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;

    // Scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x070a12);
    this.scene.fog = new THREE.FogExp2(0x070a12, 0.002);

    // Camera
    this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 2000);
    this.camera.position.set(60, 60, 100);

    // WebGL Renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.container.appendChild(this.renderer.domElement);

    // Orbit Controls
    this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 0.9);
    dirLight.position.set(100, 200, 100);
    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 2048;
    dirLight.shadow.mapSize.height = 2048;
    this.scene.add(dirLight);

    const pointLight = new THREE.PointLight(0x06b6d4, 1.5, 300);
    pointLight.position.set(0, 50, 0);
    this.scene.add(pointLight);

    // Floor Grid & Helpers
    const gridHelper = new THREE.GridHelper(300, 30, 0x1e293b, 0x0f172a);
    gridHelper.position.y = -40;
    this.scene.add(gridHelper);

    // Handle Window Resize
    window.addEventListener('resize', () => this.onWindowResize(), false);
  }

  createBirdGeometry() {
    // Sleek low-poly aerodynamic 3D bird geometry
    const geometry = new THREE.BufferGeometry();
    
    // 3D Bird Vertices (Nose at +Z)
    const vertices = new Float32Array([
      // Nose / Beak tip
       0.0,  0.0,  2.5,  // 0
      // Left Wing Tip
      -3.0,  0.0, -0.5,  // 1
      // Right Wing Tip
       3.0,  0.0, -0.5,  // 2
      // Tail Tip
       0.0,  0.5, -2.0,  // 3
      // Belly / Bottom center
       0.0, -0.8,  0.0   // 4
    ]);

    const indices = [
      // Top Body / Wings
      0, 1, 3, // Left Wing
      0, 3, 2, // Right Wing
      // Bottom Body
      0, 4, 1,
      0, 2, 4,
      // Back / Tail Base
      1, 4, 3,
      2, 3, 4
    ];

    geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
    geometry.setIndex(indices);
    geometry.computeVertexNormals();
    return geometry;
  }

  setupAgents(agentCount) {
    // Clear existing bird meshes and trails
    this.birds.forEach(b => this.scene.remove(b));
    this.trailLines.forEach(t => this.scene.remove(t));
    this.birds = [];
    this.trailLines = [];
    this.trailHistories = [];

    for (let i = 0; i < agentCount; i++) {
      const colorHex = this.colorPalette[i % this.colorPalette.length];
      const material = new THREE.MeshStandardMaterial({
        color: colorHex,
        roughness: 0.3,
        metalness: 0.6,
        flatShading: true
      });

      const birdMesh = new THREE.Mesh(this.birdGeometry, material);
      birdMesh.castShadow = true;
      birdMesh.receiveShadow = true;
      this.scene.add(birdMesh);
      this.birds.push(birdMesh);

      // Trailing ribbon / line geometry
      const maxTrailLength = 50;
      const lineGeo = new THREE.BufferGeometry();
      const positions = new Float32Array(maxTrailLength * 3);
      lineGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      lineGeo.setDrawRange(0, 0);

      const lineMat = new THREE.LineBasicMaterial({
        color: colorHex,
        transparent: true,
        opacity: 0.5,
        linewidth: 2
      });

      const lineMesh = new THREE.Line(lineGeo, lineMat);
      this.scene.add(lineMesh);
      this.trailLines.push(lineMesh);
      this.trailHistories.push([]);
    }
  }

  updateFrame(frameData) {
    if (!frameData || frameData.length === 0) return;

    if (this.birds.length !== frameData.length) {
      this.setupAgents(frameData.length);
    }

    const centroid = new THREE.Vector3(0, 0, 0);

    for (let i = 0; i < frameData.length; i++) {
      const agent = frameData[i];
      const bird = this.birds[i];

      const pos = new THREE.Vector3(agent.X, agent.Y, agent.Z);
      const vel = new THREE.Vector3(agent.VX, agent.VY, agent.VZ);

      bird.position.copy(pos);
      centroid.add(pos);

      // Align bird orientation with velocity vector
      if (vel.lengthSq() > 0.0001) {
        const heading = pos.clone().add(vel);
        bird.lookAt(heading);
      }

      // Update Trail History
      const history = this.trailHistories[i];
      history.push(pos.clone());
      if (history.length > 50) history.shift();

      if (this.showTrails) {
        const lineGeo = this.trailLines[i].geometry;
        const posAttr = lineGeo.attributes.position;
        for (let j = 0; j < history.length; j++) {
          posAttr.setXYZ(j, history[j].x, history[j].y, history[j].z);
        }
        posAttr.needsUpdate = true;
        lineGeo.setDrawRange(0, history.length);
        this.trailLines[i].visible = true;
      } else {
        this.trailLines[i].visible = false;
      }
    }

    centroid.divideScalar(frameData.length);

    // Follow Centroid Camera Mode
    if (this.followCentroid) {
      this.controls.target.lerp(centroid, 0.05);
    }

    this.controls.update();
  }

  toggleTrails() {
    this.showTrails = !this.showTrails;
    return this.showTrails;
  }

  toggleCameraMode() {
    this.followCentroid = !this.followCentroid;
    return this.followCentroid ? "Follow Centroid" : "Free Orbit";
  }

  onWindowResize() {
    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  }

  render() {
    this.renderer.render(this.scene, this.camera);
  }
}
