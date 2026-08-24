function video_path = generate_comparison_video(output_dir)
% GENERATE_COMPARISON_VIDEO Overlays all agent trajectories into one video.
% Optimized to avoid arrow clutter and improve rendering speed.

% Find all simulation CSVs
files = dir(fullfile(output_dir, 'agent_positions_*.csv'));
if isempty(files)
    error('No simulation CSVs found in %s', output_dir);
end

num_models = length(files);
model_data = cell(1, num_models);
model_names = cell(1, num_models);

for i = 1:num_models
    csv_path = fullfile(output_dir, files(i).name);
    model_data{i} = readtable(csv_path);
    tokens = regexp(files(i).name, 'agent_positions_(.*)\.csv', 'tokens');
    if ~isempty(tokens)
        model_names{i} = tokens{1}{1};
    else
        model_names{i} = sprintf('Model %d', i);
    end
end

% Pre-process CSV tables into fast numerical 3D position matrices (N x K)
pos_mats = cell(1, num_models);
for m = 1:num_models
    df = model_data{m};
    u_times = unique(df.Time);
    u_agents = unique(df.AgentID);
    N_m = length(u_agents);
    K_m = length(u_times);
    
    X_m = zeros(N_m, K_m);
    Y_m = zeros(N_m, K_m);
    Z_m = zeros(N_m, K_m);
    
    [~, agent_indices] = ismember(df.AgentID, u_agents);
    [~, time_indices] = ismember(df.Time, u_times);
    linear_idx = sub2ind([N_m, K_m], agent_indices, time_indices);
    
    X_m(linear_idx) = df.X;
    Y_m(linear_idx) = df.Y;
    Z_m(linear_idx) = df.Z;
    
    pos_mats{m}.X = X_m;
    pos_mats{m}.Y = Y_m;
    pos_mats{m}.Z = Z_m;
    pos_mats{m}.N = N_m;
    pos_mats{m}.times = u_times;
end

% Get time steps
all_times = [];
for m = 1:num_models
    all_times = unique([all_times; pos_mats{m}.times]);
end
all_times = sort(all_times);
num_steps = length(all_times);

video_path = fullfile(output_dir, 'comparison_video.avi');
v = VideoWriter(video_path, 'Uncompressed AVI');

% Sync video duration with simulation time T (Video Duration = T seconds)
if all_times(end) > 0.001
    v.FrameRate = num_steps / all_times(end);
else
    v.FrameRate = 10;
end

open(v);

% Read convergence info metadata if present
json_path = fullfile(output_dir, 'convergence_info.json');
t_conv_vec = nan(1, num_models);
v_conv_vec = nan(1, num_models);
if exist(json_path, 'file')
    try
        txt = fileread(json_path);
        if ~isempty(strtrim(txt))
            info_json = jsondecode(txt);
            for m = 1:num_models
                m_key = model_names{m};
                if isfield(info_json, m_key)
                    m_info = info_json.(m_key);
                    if isfield(m_info, 't_conv') && ~isempty(m_info.t_conv) && m_info.t_conv >= 0
                        t_conv_vec(m) = m_info.t_conv;
                    end
                    if isfield(m_info, 'v_conv') && ~isempty(m_info.v_conv) && m_info.v_conv >= 0
                        v_conv_vec(m) = m_info.v_conv;
                    end
                end
            end
        end
    catch
    end
end

colors = {'r', 'b', 'g', 'm', 'c', 'k'};
fig = figure;
rotate3d on;
grid on; view(3); axis tight; hold on;
xlabel('X'); ylabel('Y'); zlabel('Z');

% Legend setup
h_models = zeros(1, num_models + 1);
for m = 1:num_models
    model_color = colors{mod(m-1, length(colors))+1};
    readable_name = strrep(model_names{m}, '_', ' ');
    readable_name = regexprep(readable_name, '(^| )(\w)', '${upper($2)}');
    if ~isnan(t_conv_vec(m)) && t_conv_vec(m) >= 0
        if isnan(v_conv_vec(m))
            [~, idx_c] = min(abs(pos_mats{m}.times - t_conv_vec(m)));
            t_c = pos_mats{m}.times(idx_c);
            df_m = model_data{m};
            df_c = df_m(df_m.Time == t_c, :);
            v_conv_vec(m) = norm([mean(df_c.VX), mean(df_c.VY), mean(df_c.VZ)]);
        end
        disp_name = sprintf('%s (t_{conv} = %.2fs, v_{conv} = %.2f)', readable_name, t_conv_vec(m), v_conv_vec(m));
    else
        disp_name = sprintf('%s (No Conv)', readable_name);
    end
    h_models(m) = plot3(NaN, NaN, NaN, 'Color', model_color, 'LineWidth', 2, 'DisplayName', disp_name);
end
h_models(num_models + 1) = plot3(NaN, NaN, NaN, 'd', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'DisplayName', 'Convergence Point');
legend(h_models, 'Location', 'northeastoutside', 'AutoUpdate', 'off');

% Pre-allocate graphic handles for trajectories and heads
h_lines = cell(1, num_models);
h_heads = cell(1, num_models);
for m = 1:num_models
    model_color = colors{mod(m-1, length(colors))+1};
    N_m = pos_mats{m}.N;
    h_lines{m} = zeros(1, N_m);
    h_heads{m} = zeros(1, N_m);
    for i = 1:N_m
        h_lines{m}(i) = plot3(NaN, NaN, NaN, 'Color', model_color, 'LineWidth', 0.8, 'HandleVisibility', 'off');
        h_heads{m}(i) = plot3(NaN, NaN, NaN, '.', 'Color', model_color, 'MarkerSize', 20, 'HandleVisibility', 'off');
    end
end

conv_marked = false(1, num_models);

try
    for k = 1:num_steps
        t = all_times(k);
        title(sprintf('Multi-Model Comparison (t = %.2f)', t));
        
        for m = 1:num_models
            X_m = pos_mats{m}.X;
            Y_m = pos_mats{m}.Y;
            Z_m = pos_mats{m}.Z;
            N_m = pos_mats{m}.N;
            model_color = colors{mod(m-1, length(colors))+1};
            
            if k <= size(X_m, 2)
                for i = 1:N_m
                    set(h_lines{m}(i), 'XData', X_m(i, 1:k), 'YData', Y_m(i, 1:k), 'ZData', Z_m(i, 1:k));
                    set(h_heads{m}(i), 'XData', X_m(i, k), 'YData', Y_m(i, k), 'ZData', Z_m(i, k));
                end
            end
            
            % Mark convergence point on each agent's trajectory line when time reaches t_conv
            if ~conv_marked(m) && ~isnan(t_conv_vec(m)) && t >= t_conv_vec(m)
                [~, idx_conv] = min(abs(pos_mats{m}.times - t_conv_vec(m)));
                if idx_conv <= size(X_m, 2)
                    for i = 1:N_m
                        plot3(X_m(i, idx_conv), Y_m(i, idx_conv), Z_m(i, idx_conv), 'd', ...
                              'MarkerSize', 7, 'MarkerFaceColor', model_color, ...
                              'MarkerEdgeColor', 'k', 'LineWidth', 0.8, 'HandleVisibility', 'off');
                    end
                    conv_marked(m) = true;
                end
            end
        end
        drawnow;
        pause(0.01); % Allow UI interaction (rotate, zoom)
        writeVideo(v, getframe(fig));
    end
    
    % Save final frame as image (using modern exportgraphics for higher quality)
    exportgraphics(fig, fullfile(output_dir, 'final_comparison_visual.png'), 'Resolution', 300);
    fprintf('Final comparison frame saved to: %s\n', fullfile(output_dir, 'final_comparison_visual.png'));
catch ME
    fprintf('Comparison video generation interrupted: %s\n', ME.message);
end

hold off; close(v); close(fig);
end
