function results = cs_model_no_delay(x0, y0, z0, vx0, vy0, vz0, h, alpha, beta, convergence_thresh)
% CS_MODEL_NO_DELAY Core physics model for standard Cucker-Smale system (no delay).
% This function performs the simulation and returns result data.

phi = @(z) 1./(1+z.^beta);
N = length(x0);

% Initialize buffers
initial_size = 100;
t = h * (0:initial_size-1);
x = zeros(N, initial_size);
y = zeros(N, initial_size);
z = zeros(N, initial_size);
vx = zeros(N, initial_size);
vy = zeros(N, initial_size);
vz = zeros(N, initial_size);

% Set initial conditions
x(:,1) = x0; y(:,1) = y0; z(:,1) = z0;
vx(:,1) = vx0; vy(:,1) = vy0; vz(:,1) = vz0;

% Adaptive simulation loop
k = 1;
max_iterations = 10000;
k_limit = max_iterations;
consensus_reached = false;
convergence_window = 10;
convergence_threshold = convergence_thresh;
variance_threshold = convergence_thresh;

while k < k_limit
    % 1. Spatial Update (Euler)
    x(:,k+1) = x(:,k) + h*vx(:,k); 
    y(:,k+1) = y(:,k) + h*vy(:,k);
    z(:,k+1) = z(:,k) + h*vz(:,k);
    
    % 2. Velocity Update (Physics)
    % Standard Cucker-Smale: v_i' = alpha/N * sum( phi(||x_j - x_i||) * (v_j - v_i) )
    for i = 1:N
        dvx = 0; dvy = 0; dvz = 0;
        for j = 1:N
            if i == j, continue; end
            dist = sqrt((x(j,k)-x(i,k))^2 + (y(j,k)-y(i,k))^2 + (z(j,k)-z(i,k))^2);
            weight = phi(dist) / N;
            dvx = dvx + weight * (vx(j,k) - vx(i,k));
            dvy = dvy + weight * (vy(j,k) - vy(i,k));
            dvz = dvz + weight * (vz(j,k) - vz(i,k));
        end
        vx(i,k+1) = vx(i,k) + h * alpha * dvx;
        vy(i,k+1) = vy(i,k) + h * alpha * dvy;
        vz(i,k+1) = vz(i,k) + h * alpha * dvz;
    end
    
    if mod(k, 500) == 0
        fprintf('Iteration %d, t = %.2f...\n', k, t(k));
    end
    
    % Check for convergence
    if ~consensus_reached && k >= convergence_window
        if mod(k, 5) == 0
            recent_vx = vx(:, k-convergence_window+1:k+1);
            recent_vy = vy(:, k-convergence_window+1:k+1);
            recent_vz = vz(:, k-convergence_window+1:k+1);
            
            vx_change_max = max(abs(diff(recent_vx, 1, 2)), [], 'all');
            vy_change_max = max(abs(diff(recent_vy, 1, 2)), [], 'all');
            vz_change_max = max(abs(diff(recent_vz, 1, 2)), [], 'all');
            
            stability_limit = convergence_threshold / 5;
            
            if (vx_change_max < stability_limit) && ...
               (vy_change_max < stability_limit) && ...
               (vz_change_max < stability_limit)
                consensus_reached = true;
                fprintf('[No-Delay] Global stability reached at t=%.2f (step %d)\n', t(k+1), k+1);
                
                % Extend simulation for more frames (double the time to reach consensus)
                k_limit = min(max_iterations, k + k);
                fprintf('[No-Delay] Continuing simulation until step %d for extended visualization.\n', k_limit);
            end
        end
    end
    
    k = k + 1;
    if k+1 > size(x, 2)
        x = [x, zeros(N, 100)]; y = [y, zeros(N, 100)]; z = [z, zeros(N, 100)];
        vx = [vx, zeros(N, 100)]; vy = [vy, zeros(N, 100)]; vz = [vz, zeros(N, 100)];
        t = [t, t(end) + h*(1:100)];
    end
end

% Finalize data
results.x = x(:, 1:k);
results.y = y(:, 1:k);
results.z = z(:, 1:k);
results.vx = vx(:, 1:k);
results.vy = vy(:, 1:k);
results.vz = vz(:, 1:k);
results.t = t(1:k);
results.N = N;
results.h = h;
results.alpha = alpha;
results.beta = beta;
results.convergence_thresh = convergence_thresh;
results.variance_threshold = convergence_thresh;
end
