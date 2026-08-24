function video_path = generate_simulation_video(csv_path, output_dir)
% GENERATE_SIMULATION_VIDEO Creates a 3D trajectory video from agent_positions.csv
% Uses plot3 for paths and quiver3 only for the current head to avoid clutter.

try
    df = readtable(csv_path);
catch ME
    error('Could not read CSV file: %s', ME.message);
end

times = unique(df.Time);
agent_ids = unique(df.AgentID);
N = length(agent_ids);
num_steps = length(times);

% Pre-process CSV table into numerical 3D position matrices (N x K)
X_mat = zeros(N, num_steps);
Y_mat = zeros(N, num_steps);
Z_mat = zeros(N, num_steps);

[~, agent_indices] = ismember(df.AgentID, agent_ids);
[~, time_indices] = ismember(df.Time, times);
linear_idx = sub2ind([N, num_steps], agent_indices, time_indices);

X_mat(linear_idx) = df.X;
Y_mat(linear_idx) = df.Y;
Z_mat(linear_idx) = df.Z;

video_path = fullfile(output_dir, 'simulation_video.avi');
v = VideoWriter(video_path, 'Uncompressed AVI');

% Sync video duration with simulation time T (Video Duration = T seconds)
if times(end) > 0.001
    v.FrameRate = num_steps / times(end);
else
    v.FrameRate = 10;
end

open(v);

% Read convergence info metadata if present
json_path = fullfile(output_dir, 'convergence_info.json');
t_conv_val = NaN;
v_conv_val = NaN;
if exist(json_path, 'file')
    try
        tokens = regexp(csv_path, 'agent_positions_(.*)\.csv', 'tokens');
        if ~isempty(tokens)
            m_name = tokens{1}{1};
            txt = fileread(json_path);
            if ~isempty(strtrim(txt))
                info_json = jsondecode(txt);
                if isfield(info_json, m_name)
                    m_info = info_json.(m_name);
                    if isfield(m_info, 't_conv') && ~isempty(m_info.t_conv) && m_info.t_conv >= 0
                        t_conv_val = m_info.t_conv;
                    end
                    if isfield(m_info, 'v_conv') && ~isempty(m_info.v_conv) && m_info.v_conv >= 0
                        v_conv_val = m_info.v_conv;
                    end
                end
            end
        end
    catch
    end
end

colorstring = 'rgbcmk'; 
fig = figure;
rotate3d on;
grid on; view(3); axis tight; hold on;
xlabel('X'); ylabel('Y'); zlabel('Z');

% Pre-allocate handles for plot tails and heads
h_tail = zeros(1, N);
h_head = zeros(1, N);
for i = 1:N
    c = colorstring(mod(i-1, length(colorstring)) + 1);
    h_tail(i) = plot3(NaN, NaN, NaN, 'Color', c, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    h_head(i) = plot3(NaN, NaN, NaN, '.', 'Color', c, 'MarkerSize', 20, 'HandleVisibility', 'off');
end
conv_marked = false;

try
    for k = 1:num_steps
        for i = 1:N
            set(h_tail(i), 'XData', X_mat(i, 1:k), 'YData', Y_mat(i, 1:k), 'ZData', Z_mat(i, 1:k));
            set(h_head(i), 'XData', X_mat(i, k), 'YData', Y_mat(i, k), 'ZData', Z_mat(i, k));
        end
        
        % Mark convergence point on each agent trajectory line when time reaches t_conv
        if ~conv_marked && ~isnan(t_conv_val) && times(k) >= t_conv_val
            [~, idx_conv] = min(abs(times - t_conv_val));
            if idx_conv <= num_steps
                for i = 1:N
                    c = colorstring(mod(i-1, length(colorstring)) + 1);
                    plot3(X_mat(i, idx_conv), Y_mat(i, idx_conv), Z_mat(i, idx_conv), 'd', ...
                          'MarkerSize', 8, 'MarkerFaceColor', c, ...
                          'MarkerEdgeColor', 'k', 'LineWidth', 1.0, 'HandleVisibility', 'off');
                end
                
                if isnan(v_conv_val)
                    t_c = times(idx_conv);
                    df_c = df(df.Time == t_c, :);
                    v_conv_val = norm([mean(df_c.VX), mean(df_c.VY), mean(df_c.VZ)]);
                end
                
                % Dummy handle for legend entry
                plot3(NaN, NaN, NaN, 'd', 'MarkerSize', 8, 'MarkerFaceColor', 'k', ...
                      'MarkerEdgeColor', 'k', 'DisplayName', sprintf('Convergence (t_{conv} = %.2fs, v_{conv} = %.2f)', t_conv_val, v_conv_val));
                legend('Location', 'northeastoutside');
                
                conv_marked = true;
            end
        end
        
        title(sprintf('Cucker-Smale Simulation (t = %.2f)', times(k)));
        drawnow;
        pause(0.01); % Allow UI interaction (rotate, zoom)
        writeVideo(v, getframe(fig));
    end
    
    % Save final frame as image (using modern exportgraphics for higher quality)
    exportgraphics(fig, fullfile(output_dir, 'final_state_visual.png'), 'Resolution', 300);
    fprintf('Final frame saved to: %s\n', fullfile(output_dir, 'final_state_visual.png'));
catch ME
    fprintf('Video generation interrupted: %s\n', ME.message);
end

hold off; close(v); close(fig);
end
