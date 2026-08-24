/**
 * Minimal, high-performance OrbitControls implementation for Three.js
 * Supports mouse drag orbit (left button), panning (right button), and wheel zoom.
 */
(function() {
  if (typeof THREE === 'undefined') return;

  THREE.OrbitControls = function(camera, domElement) {
    this.camera = camera;
    this.domElement = domElement || document;

    // API settings
    this.enabled = true;
    this.target = new THREE.Vector3(0, 0, 0);
    this.enableDamping = true;
    this.dampingFactor = 0.08;
    this.rotateSpeed = 0.8;
    this.zoomSpeed = 1.2;
    this.panSpeed = 0.8;

    this.minDistance = 1;
    this.maxDistance = 2000;
    this.minPolarAngle = 0.01;
    this.maxPolarAngle = Math.PI - 0.01;

    // Spherical state
    const spherical = new THREE.Spherical();
    const sphericalDelta = new THREE.Spherical();
    const panOffset = new THREE.Vector3();
    let zoomScale = 1;

    let state = -1; // 0 = ROTATE, 1 = PAN, 2 = ZOOM
    const STATE = { NONE: -1, ROTATE: 0, PAN: 1, ZOOM: 2 };

    const rotateStart = new THREE.Vector2();
    const rotateEnd = new THREE.Vector2();
    const rotateDelta = new THREE.Vector2();

    const panStart = new THREE.Vector2();
    const panEnd = new THREE.Vector2();
    const panDelta = new THREE.Vector2();

    const scope = this;

    function getZoomScale() {
      return Math.pow(0.95, scope.zoomSpeed);
    }

    function panLeft(distance, objectMatrix) {
      const v = new THREE.Vector3();
      v.setFromMatrixColumn(objectMatrix, 0);
      v.multiplyScalar(-distance);
      panOffset.add(v);
    }

    function panUp(distance, objectMatrix) {
      const v = new THREE.Vector3();
      v.setFromMatrixColumn(objectMatrix, 1);
      v.multiplyScalar(distance);
      panOffset.add(v);
    }

    function pan(deltaX, deltaY) {
      const element = scope.domElement;
      if (scope.camera.isPerspectiveCamera) {
        const position = scope.camera.position;
        const offset = new THREE.Vector3().copy(position).sub(scope.target);
        let targetDistance = offset.length();
        targetDistance *= Math.tan((scope.camera.fov / 2) * Math.PI / 180.0);

        panLeft(2 * deltaX * targetDistance / element.clientHeight, scope.camera.matrix);
        panUp(2 * deltaY * targetDistance / element.clientHeight, scope.camera.matrix);
      }
    }

    this.update = function() {
      const position = scope.camera.position;
      const offset = new THREE.Vector3().copy(position).sub(scope.target);

      spherical.setFromVector3(offset);

      spherical.theta += sphericalDelta.theta;
      spherical.phi += sphericalDelta.phi;
      spherical.phi = Math.max(scope.minPolarAngle, Math.min(scope.maxPolarAngle, spherical.phi));
      spherical.radius *= zoomScale;
      spherical.radius = Math.max(scope.minDistance, Math.min(scope.maxDistance, spherical.radius));

      scope.target.add(panOffset);

      offset.setFromSpherical(spherical);
      position.copy(scope.target).add(offset);
      scope.camera.lookAt(scope.target);

      if (scope.enableDamping) {
        sphericalDelta.theta *= (1 - scope.dampingFactor);
        sphericalDelta.phi *= (1 - scope.dampingFactor);
        panOffset.multiplyScalar(1 - scope.dampingFactor);
      } else {
        sphericalDelta.set(0, 0, 0);
        panOffset.set(0, 0, 0);
      }

      zoomScale = 1;
    };

    function onMouseDown(event) {
      if (!scope.enabled) return;
      event.preventDefault();

      if (event.button === 0) {
        state = STATE.ROTATE;
        rotateStart.set(event.clientX, event.clientY);
      } else if (event.button === 2 || event.button === 1) {
        state = STATE.PAN;
        panStart.set(event.clientX, event.clientY);
      }

      document.addEventListener('mousemove', onMouseMove, false);
      document.addEventListener('mouseup', onMouseUp, false);
    }

    function onMouseMove(event) {
      if (!scope.enabled) return;
      event.preventDefault();

      if (state === STATE.ROTATE) {
        rotateEnd.set(event.clientX, event.clientY);
        rotateDelta.subVectors(rotateEnd, rotateStart).multiplyScalar(scope.rotateSpeed);

        const element = scope.domElement;
        sphericalDelta.theta -= (2 * Math.PI * rotateDelta.x / element.clientHeight);
        sphericalDelta.phi -= (2 * Math.PI * rotateDelta.y / element.clientHeight);

        rotateStart.copy(rotateEnd);
      } else if (state === STATE.PAN) {
        panEnd.set(event.clientX, event.clientY);
        panDelta.subVectors(panEnd, panStart).multiplyScalar(scope.panSpeed);

        pan(panDelta.x, panDelta.y);
        panStart.copy(panEnd);
      }

      scope.update();
    }

    function onMouseUp() {
      state = STATE.NONE;
      document.removeEventListener('mousemove', onMouseMove, false);
      document.removeEventListener('mouseup', onMouseUp, false);
    }

    function onMouseWheel(event) {
      if (!scope.enabled) return;
      event.preventDefault();

      if (event.deltaY < 0) {
        zoomScale /= getZoomScale();
      } else if (event.deltaY > 0) {
        zoomScale *= getZoomScale();
      }

      scope.update();
    }

    function onContextMenu(event) {
      event.preventDefault();
    }

    this.domElement.addEventListener('mousedown', onMouseDown, false);
    this.domElement.addEventListener('wheel', onMouseWheel, { passive: false });
    this.domElement.addEventListener('contextmenu', onContextMenu, false);

    this.update();
  };
})();
