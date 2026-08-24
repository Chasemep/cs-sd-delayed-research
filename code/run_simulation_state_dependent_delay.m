function run_simulation_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh, output_dir, target_k_limit)
% RUN_SIMULATION_STATE_DEPENDENT_DELAY Orchestrator for State-Dependent Delay CS simulation.

if nargin < 13
    target_k_limit = 0;
end

% 1. Add script directory to path and determine Project Root
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
    script_dir = pwd;
end
addpath(script_dir);

[parent_dir, last_dir] = fileparts(script_dir);
if strcmp(last_dir, 'code')
    project_root = parent_dir;
else
    project_root = script_dir;
end

% 1.5 Run the model
results = cs_model_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh, target_k_limit);

% 2. Handle Output Directory
if nargin < 12 || isempty(output_dir)
    t_str = datestr(datetime('now'), 'dd-mmm-yyyy HH-MM-SS');
    output_dir = fullfile(project_root, 'output', strcat('sim_state_delay_', regexprep(t_str, '[: ]', '_')));
    if ~exist(output_dir, 'dir'), mkdir(output_dir); end
end

% 3. Save run command
command_str = sprintf('run_simulation_state_dependent_delay(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)', ...
    mat2str(x0), mat2str(y0), mat2str(z0), ...
    mat2str(vx0), mat2str(vy0), mat2str(vz0), ...
    num2str(h), num2str(tau_factor), num2str(alpha), num2str(beta), num2str(convergence_thresh));

fid = fopen(fullfile(output_dir, 'run_command_state_delay.txt'), 'w');
if fid ~= -1
    fprintf(fid, '%s', command_str);
    fclose(fid);
end

% 4. Export to CSV
csv_path = write_simulation_csv(results, output_dir, 'state_delay');

% 5. Generate Video
generate_simulation_video(csv_path, output_dir);
movefile(fullfile(output_dir, 'simulation_video.avi'), fullfile(output_dir, 'simulation_video_state_delay.avi'));

% 6. Automate PCA Visualization
python_script = fullfile(script_dir, 'visualize_pca.py');
if exist(python_script, 'file')
    py_commands = {'python', 'python3', 'py'};
    for i = 1:length(py_commands)
        command = sprintf('%s "%s" "%s" %f', py_commands{i}, python_script, csv_path, results.variance_threshold);
        [status, ~] = system(command);
        if status == 0
            movefile(fullfile(output_dir, 'pca_visualization.png'), fullfile(output_dir, 'pca_visualization_state_delay.png'));
            break;
        end
    end
end

% 7. Generate Markdown Summary
generate_simulation_markdown(output_dir, 'state_dependent_delay', length(x0), h, alpha, beta, tau_factor, convergence_thresh);
end
