function run_simulation_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh, output_dir)
% RUN_SIMULATION_STATE_DEPENDENT_DELAY Orchestrator for State-Dependent Delay CS simulation.

% 1. Run the model
results = cs_model_state_dependent_delay(x0, y0, z0, vx0, vy0, vz0, h, tau_factor, alpha, beta, convergence_thresh);

% 2. Handle Output Directory
if nargin < 12 || isempty(output_dir)
    t_str = datestr(datetime('now'), 'dd-mmm-yyyy HH-MM-SS');
    output_dir = fullfile(pwd, 'output', strcat('sim_state_delay_', regexprep(t_str, '[: ]', '_')));
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
python_script = 'visualize_pca.py';
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
end
