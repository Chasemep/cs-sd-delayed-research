function results = cs_model_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh)
% CS_MODEL_STATE_DEPENDENT_DELAY Cucker-Smale model with distance-dependent delay.
% Formula: aij = phi(dist(t - tau * dist_current))
% Delay: tau_ij = tau_factor * dist_current

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

% Initialize 2nd step
for i = 1:N 
    x(i,2) = x(i,1) + h*vx(i,1); 
    y(i,2) = y(i,1) + h*vy(i,1); 
    z(i,2) = z(i,1) + h*vz(i,1);
    vx(i,2) = vx0(i); vy(i,2) = vy0(i); vz(i,2) = vz0(i);
end

% Adaptive simulation loop
k = 2;
max_iterations = 10000;
k_limit = max_iterations;
consensus_reached = false;
convergence_window = 10;
variance_threshold = convergence_thresh;

while k <= k_limit
    % Euler step for positions
    for i = 1:N
       x(i,k+1) = x(i,k) + h*vx(i,k); 
       y(i,k+1) = y(i,k) + h*vy(i,k);
       z(i,k+1) = z(i,k) + h*vz(i,k);
    end
    
    % Temporary storage for next step velocities to ensure synchronous update
    next_vx = vx(:,k);
    next_vy = vy(:,k);
    next_vz = vz(:,k);
    
    for i = 1:N
       for j = 1:N
           if i == j, continue; end
           
           % 1. Calculate current distance
           dist_curr = sqrt((x(i,k)-x(j,k))^2 + (y(i,k)-y(j,k))^2 + (z(i,k)-z(j,k))^2);
           
           % 2. Calculate state-dependent delay
           tau_ij = tau_factor * dist_curr;
           
           % 3. Evaluate interaction at delayed time
           lookback_t = t(k) - tau_ij;
           
           if lookback_t <= t(1)
               % No delay effect yet if lookback is before start
               vj_delayed = vx(j,1);
               vj_delayed_y = vy(j,1);
               vj_delayed_z = vz(j,1);
               dist_delayed = dist_curr;
           else
               % Interpolate delayed states
               vj_delayed = spline(t(1:k), vx(j,1:k), lookback_t);
               vj_delayed_y = spline(t(1:k), vy(j,1:k), lookback_t);
               vj_delayed_z = spline(t(1:k), vz(j,1:k), lookback_t);
               
               xj_delayed = spline(t(1:k), x(j,1:k), lookback_t);
               yj_delayed = spline(t(1:k), y(j,1:k), lookback_t);
               zj_delayed = spline(t(1:k), z(j,1:k), lookback_t);
               dist_delayed = sqrt((x(i,k)-xj_delayed)^2 + (y(i,k)-yj_delayed)^2 + (z(i,k)-zj_delayed)^2);
           end
           
           % 4. Interaction weight (Adjacency)
           aij = phi(dist_delayed) / N;
           
           % 5. Update acceleration components
           next_vx(i) = next_vx(i) + h * alpha * aij * (vj_delayed - vx(i,k));
           next_vy(i) = next_vy(i) + h * alpha * aij * (vj_delayed_y - vy(i,k));
           next_vz(i) = next_vz(i) + h * alpha * aij * (vj_delayed_z - vz(i,k));
       end
    end
    
    vx(:,k+1) = next_vx;
    vy(:,k+1) = next_vy;
    vz(:,k+1) = next_vz;
    
    if mod(k, 500) == 0
        fprintf('Iteration %d, t = %.2f...\n', k, t(k));
    end
    
    % Convergence check
    if ~consensus_reached && k >= convergence_window + 1
        if mod(k, 5) == 0
            recent_vx = vx(:, k-convergence_window+1:k+1);
            vx_change_max = max(abs(diff(recent_vx, 1, 2)), [], 'all');
            
            if vx_change_max < (convergence_thresh / 5)
                consensus_reached = true;
                fprintf('[SD-Delay] State-dependent consensus stability reached at t=%.2f\n', t(k+1));
                
                % Extend simulation for more frames (double the time to reach consensus)
                k_limit = min(max_iterations, k + k);
                fprintf('[SD-Delay] Continuing simulation until step %d for extended visualization.\n', k_limit);
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
results.tau_factor = tau_factor;
results.convergence_thresh = convergence_thresh;
results.variance_threshold = variance_threshold;
end
