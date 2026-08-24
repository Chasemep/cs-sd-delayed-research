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

% Store handles for plot tails and heads
h_tail = zeros(1, N);
h_head = zeros(1, N);
conv_marked = false;

try
    for k = 1:num_steps
        current_step_data = df(df.Time == times(k), :);
        
        for i = 1:N
            agent_data = current_step_data(current_step_data.AgentID == agent_ids(i), :);
            if isempty(agent_data), continue; end
            
            c = colorstring(mod(i-1, length(colorstring)) + 1);
            
            % Draw segment of path
            if k > 1
                prev_step_data = df(df.Time == times(k-1), :);
                prev_agent = prev_step_data(prev_step_data.AgentID == agent_ids(i), :);
                if ~isempty(prev_agent)
                    plot3([prev_agent.X, agent_data.X], ...
                          [prev_agent.Y, agent_data.Y], ...
                          [prev_agent.Z, agent_data.Z], ...
                          'Color', c, 'LineWidth', 1.0);
                end
            end
            
            % Update head (remove old, draw new large point)
            if h_head(i) ~= 0 && ishandle(h_head(i)), delete(h_head(i)); end
            
            % Plot current position as a large distinct point
            h_head(i) = plot3(agent_data.X, agent_data.Y, agent_data.Z, ...
                              '.', 'Color', c, 'MarkerSize', 20);
        end
        
        % Mark convergence point on each agent trajectory line when time reaches t_conv
        if ~conv_marked && ~isnan(t_conv_val) && times(k) >= t_conv_val
            [~, idx_conv] = min(abs(times - t_conv_val));
            conv_data = df(df.Time == times(idx_conv), :);
            if ~isempty(conv_data)
                for i = 1:size(conv_data, 1)
                    c = colorstring(mod(i-1, length(colorstring)) + 1);
                    plot3(conv_data.X(i), conv_data.Y(i), conv_data.Z(i), 'd', ...
                          'MarkerSize', 8, 'MarkerFaceColor', c, ...
                          'MarkerEdgeColor', 'k', 'LineWidth', 1.0, 'HandleVisibility', 'off');
                end
                
                % Dummy handles for legend entry
                plot3(NaN, NaN, NaN, 'd', 'MarkerSize', 8, 'MarkerFaceColor', 'k', ...
                      'MarkerEdgeColor', 'k', 'DisplayName', sprintf('Convergence (t_{conv} = %.2fs)', t_conv_val));
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
