function results = cs_model_fixed_delay(x0, y0, z0, vx0, vy0, vz0, h, tau, alpha, beta, convergence_thresh, target_k_limit)
% CS_MODEL_FIXED_DELAY Core physics model for Delayed Cucker-Smale system.
% This function performs the simulation and returns result data.

if nargin < 12 || isempty(target_k_limit)
    target_k_limit = 0;
end

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
if target_k_limit > 0
    k_limit = min(max_iterations, target_k_limit);
end
consensus_reached = false;
t_conv = NaN;
k_conv = NaN;
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
           t_del_v = t(k) - tau(i,j);
           
           % Fast O(1) delay interpolation for uniform time grid
           if t_del_v <= 0
               vx_j = vx(j,1); vy_j = vy(j,1); vz_j = vz(j,1);
           elseif t_del_v >= t(k)
               vx_j = vx(j,k); vy_j = vy(j,k); vz_j = vz(j,k);
           else
               idx_v = 1 + t_del_v / h;
               i_v = floor(idx_v); f_v = idx_v - i_v;
               vx_j = (1-f_v)*vx(j,i_v) + f_v*vx(j,i_v+1);
               vy_j = (1-f_v)*vy(j,i_v) + f_v*vy(j,i_v+1);
               vz_j = (1-f_v)*vz(j,i_v) + f_v*vz(j,i_v+1);
           end

           vx(i,k+1) = vx(i,k+1) + h*alpha*ax(i,j)*(vx_j - vx(i,k)); 
           vy(i,k+1) = vy(i,k+1) + h*alpha*ay(i,j)*(vy_j - vy(i,k)); 
           vz(i,k+1) = vz(i,k+1) + h*alpha*az(i,j)*(vz_j - vz(i,k)); 
           
           if t(k+1) < tau(i,j) || i == j
               ax(i,j) = 0; ay(i,j) = 0; az(i,j) = 0;
           else
               t_del_x = t(k+1) - tau(i,j);
               if t_del_x <= 0
                   xj_del = x(j,1); yj_del = y(j,1); zj_del = z(j,1);
               elseif t_del_x >= t(k+1)
                   xj_del = x(j,k+1); yj_del = y(j,k+1); zj_del = z(j,k+1);
               else
                   idx_x = 1 + t_del_x / h;
                   i_x = floor(idx_x); f_x = idx_x - i_x;
                   xj_del = (1-f_x)*x(j,i_x) + f_x*x(j,i_x+1);
                   yj_del = (1-f_x)*y(j,i_x) + f_x*y(j,i_x+1);
                   zj_del = (1-f_x)*z(j,i_x) + f_x*z(j,i_x+1);
               end

               ax(i,j) = phi(abs(xj_del - x(i,k+1)))/N;
               ay(i,j) = phi(abs(yj_del - y(i,k+1)))/N;
               az(i,j) = phi(abs(zj_del - z(i,k+1)))/N;
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
                k_conv = k + 1;
                t_conv = t(k+1);
                fprintf('[Fixed-Delay] Global stability reached at t=%.2f (step %d)\n', t_conv, k_conv);
                
                if var(vx(:, k+1)) > variance_threshold
                    fprintf('[Fixed-Delay] Multi-flocking detected.\n');
                else
                    fprintf('[Fixed-Delay] Single flock consensus reached.\n');
                end
                
                % Extend simulation for more frames (double the time to reach consensus, or target)
                k_limit = min(max_iterations, max(k + k, target_k_limit));
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
results.consensus_reached = consensus_reached;
results.t_conv = t_conv;
results.k_conv = k_conv;
results.k_limit = k;
end
