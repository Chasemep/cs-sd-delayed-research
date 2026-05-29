function results = cs_model_fixed_delay(x0, y0, z0, vx0, vy0, vz0, h, tau, alpha, beta, convergence_thresh)
% CS_MODEL_FIXED_DELAY Core physics model for Delayed Cucker-Smale system.
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
ax = zeros(N, N);
ay = zeros(N, N);
az = zeros(N, N);

% Set initial conditions
x(:,1) = x0; y(:,1) = y0; z(:,1) = z0;
vx(:,1) = vx0; vy(:,1) = vy0; vz(:,1) = vz0;
vx(:,2) = vx0; vy(:,2) = vy0; vz(:,2) = vz0;

% Initialize 2nd step
for i = 1:N 
    x(i,2) = x(i,1) + h*vx(i,1); 
    y(i,2) = y(i,1) + h*vy(i,1); 
    z(i,2) = z(i,1) + h*vz(i,1);
end

% Adaptive simulation loop
k = 2;
max_iterations = 10000;
k_limit = max_iterations;
consensus_reached = false;
convergence_window = 10;
convergence_threshold = convergence_thresh;
variance_threshold = convergence_thresh;

while k <= k_limit
    % Euler step
    for i = 1:N
       x(i,k+1) = x(i,k) + h*vx(i,k); 
       y(i,k+1) = y(i,k) + h*vy(i,k);
       z(i,k+1) = z(i,k) + h*vz(i,k);
    end
    
    for i = 1:N
       vx(i,k+1) = vx(i,k);
       vy(i,k+1) = vy(i,k);
       vz(i,k+1) = vz(i,k);
       for j = 1:N
           % Use spline interpolation for delays
           vx(i,k+1) = vx(i,k+1) + h*alpha*ax(i,j)*(spline(t(1:k),vx(j,1:k),t(k)-tau(i,j))-vx(i,k)); 
           vy(i,k+1) = vy(i,k+1) + h*alpha*ay(i,j)*(spline(t(1:k),vy(j,1:k),t(k)-tau(i,j))-vy(i,k)); 
           vz(i,k+1) = vz(i,k+1) + h*alpha*az(i,j)*(spline(t(1:k),vz(j,1:k),t(k)-tau(i,j))-vz(i,k)); 
           
           if t(k+1) < tau(i,j) || i == j
               ax(i,j) = 0; ay(i,j) = 0; az(i,j) = 0;
           else
               ax(i,j) = phi(abs(spline(t(1:k+1),x(j,1:k+1),t(k+1)-tau(i,j))-x(i,k+1)))/N;
               ay(i,j) = phi(abs(spline(t(1:k+1),y(j,1:k+1),t(k+1)-tau(i,j))-y(i,k+1)))/N;
               az(i,j) = phi(abs(spline(t(1:k+1),z(j,1:k+1),t(k+1)-tau(i,j))-z(i,k+1)))/N;
           end
       end
    end
    
    if mod(k, 500) == 0
        fprintf('Iteration %d, t = %.2f...\n', k, t(k));
    end
    
    if ~consensus_reached && k >= convergence_window + 1
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
                fprintf('[Fixed-Delay] Global stability reached at t=%.2f (step %d)\n', t(k+1), k+1);
                
                if var(vx(:, k+1)) > variance_threshold
                    fprintf('[Fixed-Delay] Multi-flocking detected.\n');
                else
                    fprintf('[Fixed-Delay] Single flock consensus reached.\n');
                end
                
                % Extend simulation for more frames (double the time to reach consensus)
                k_limit = min(max_iterations, k + k);
                fprintf('[Fixed-Delay] Continuing simulation until step %d for extended visualization.\n', k_limit);
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
results.tau = tau;
results.convergence_thresh = convergence_thresh;
results.variance_threshold = variance_threshold;
end
