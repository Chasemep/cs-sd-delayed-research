function run_simulation(x0, y0, z0, vx0, vy0, vz0, h, tau, tau_factor, alpha, beta, convergence_thresh)
% RUN_SIMULATION Master orchestrator for Comparative Cucker-Smale Research.
% This runs all available models (No-Delay, Fixed-Delay, State-Dependent) and generates comparative analysis.

% 1. Create a Shared Output Directory
t_str = datestr(datetime('now'), 'dd-mmm-yyyy HH-MM-SS');
output_dir = fullfile(pwd, 'output', strcat('multi_model_sim_', regexprep(t_str, '[: ]', '_')));
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

fprintf('Starting Comparative Simulation in: %s\n', output_dir);

% 1.5 Save master run command for reproducibility
command_str = sprintf('run_simulation(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n', ...
    mat2str(x0), mat2str(y0), mat2str(z0), ...
    mat2str(vx0), mat2str(vy0), mat2str(vz0), ...
    num2str(h), mat2str(tau), num2str(tau_factor), num2str(alpha), num2str(beta), num2str(convergence_thresh));

fid = fopen(fullfile(output_dir, 'run_command_multi_model.txt'), 'w');
if fid ~= -1
    fprintf(fid, '%s', command_str);
    fclose(fid);
end

% 2. Run Standard model (No Delay)
fprintf('--- Running Standard Model (No Delay) ---\n');
run_simulation_no_delay(x0, y0, z0, vx0, vy0, vz0, h, alpha, beta, convergence_thresh, output_dir);

% 3. Run Delayed model (Fixed Delay)
fprintf('--- Running Delayed Model (Fixed Delay) ---\n');
run_simulation_fixed_delay(x0, y0, z0, vx0, vy0, vz0, h, tau, alpha, beta, convergence_thresh, output_dir);

% 3.5 Run State-Dependent Delayed model
fprintf('--- Running State-Dependent Delayed Model ---\n');
run_simulation_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh, output_dir);

% 4. Generate Comparative Analysis
if exist('generate_comparison_video.m', 'file')
    fprintf('--- Generating Comparison Video ---\n');
    generate_comparison_video(output_dir);
end

python_script = 'compare_pca.py';
if exist(python_script, 'file')
    fprintf('--- Generating Comparison PCA Plot ---\n');
    py_commands = {'python', 'python3', 'py'};
    for i = 1:length(py_commands)
        command = sprintf('%s "%s" "%s"', py_commands{i}, python_script, output_dir);
        [status, ~] = system(command);
        if status == 0, break; end
    end
end

fprintf('Comparative Simulation Complete.\nResults saved in: %s\n', output_dir);
end
