function run_comparison_only(x0, y0, z0, vx0, vy0, vz0, h, tau, tau_factor, alpha, beta, convergence_thresh)
% RUN_COMPARISON_ONLY Streamlined orchestrator for Comparative Cucker-Smale Research.
% focus: Comparative results only (CSV, Video, PCA). Skips individual model videos/plots.

% 1. Create a Shared Output Directory
t_str = datestr(datetime('now'), 'dd-mmm-yyyy HH-MM-SS');
output_dir = fullfile(pwd, 'output', strcat('comp_only_', regexprep(t_str, '[: ]', '_')));
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

fprintf('Starting Streamlined Comparison in: %s\n', output_dir);

% 2. Save master run command for reproducibility
command_str = sprintf('run_comparison_only(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n', ...
    mat2str(x0), mat2str(y0), mat2str(z0), ...
    mat2str(vx0), mat2str(vy0), mat2str(vz0), ...
    num2str(h), mat2str(tau), num2str(tau_factor), num2str(alpha), num2str(beta), num2str(convergence_thresh));

fid = fopen(fullfile(output_dir, 'run_command_comparison.txt'), 'w');
if fid ~= -1
    fprintf(fid, '%s', command_str);
    fclose(fid);
end

% 3. Run Models and Export CSVs Only
fprintf('--- Running Models ---\n');

% Standard (No Delay)
res_no = cs_model_no_delay(x0, y0, z0, vx0, vy0, vz0, h, alpha, beta, convergence_thresh);
write_simulation_csv(res_no, output_dir, 'no_delay');

% Fixed Delay
res_fixed = cs_model_fixed_delay(x0, y0, z0, vx0, vy0, vz0, h, tau, alpha, beta, convergence_thresh);
write_simulation_csv(res_fixed, output_dir, 'fixed_delay');

% State-Dependent Delay
res_state = cs_model_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh);
write_simulation_csv(res_state, output_dir, 'state_delay');

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

fprintf('Streamlined Comparison Complete: %s\n', output_dir);
end
