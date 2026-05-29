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

colorstring = 'rgbcmk'; 
fig = figure;
rotate3d on;
grid on; view(3); axis tight; hold on;
xlabel('X'); ylabel('Y'); zlabel('Z');

% Store handles for plot tails and heads
h_tail = zeros(1, N);
h_head = zeros(1, N);

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
