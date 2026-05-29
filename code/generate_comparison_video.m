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

% Get time steps
all_times = [];
for i = 1:num_models
    all_times = unique([all_times; model_data{i}.Time]);
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

colors = {'r', 'b', 'g', 'm', 'c', 'k'};
fig = figure;
rotate3d on;
grid on; view(3); axis tight; hold on;
xlabel('X'); ylabel('Y'); zlabel('Z');

% Legend setup
h_models = zeros(1, num_models);
for m = 1:num_models
    model_color = colors{mod(m-1, length(colors))+1};
    readable_name = strrep(model_names{m}, '_', ' ');
    readable_name = regexprep(readable_name, '(^| )(\w)', '${upper($2)}');
    h_models(m) = plot3(NaN, NaN, NaN, 'Color', model_color, 'LineWidth', 2, 'DisplayName', readable_name);
end
legend(h_models, 'Location', 'northeastoutside', 'AutoUpdate', 'off');

% Store head handles to delete them in next frame
h_heads = cell(1, num_models);

try
    for k = 1:num_steps
        t = all_times(k);
        title(sprintf('Multi-Model Comparison (t = %.2f)', t));
        
        for m = 1:num_models
            df = model_data{m};
            step_data = df(df.Time == t, :);
            if isempty(step_data), continue; end
            
            model_color = colors{mod(m-1, length(colors))+1};
            
            % Delete previous heads for this model
            for head_idx = 1:length(h_heads{m})
                if h_heads{m}(head_idx) ~= 0 && ishandle(h_heads{m}(head_idx))
                    delete(h_heads{m}(head_idx));
                end
            end
            h_heads{m} = []; 
            
            % Draw paths and current heads
            for i = 1:size(step_data, 1)
                agent_row = step_data(i, :);
                
                % Path segment
                if k > 1
                    prev_step_data = df(df.Time == all_times(k-1) & df.AgentID == agent_row.AgentID, :);
                    if ~isempty(prev_step_data)
                        plot3([prev_step_data.X, agent_row.X], ...
                              [prev_step_data.Y, agent_row.Y], ...
                              [prev_step_data.Z, agent_row.Z], ...
                              'Color', model_color, 'LineWidth', 0.8, 'HandleVisibility', 'off');
                    end
                end
                
                % Current head (Distinct large point for visibility)
                h_heads{m}(end+1) = plot3(agent_row.X, agent_row.Y, agent_row.Z, ...
                                          '.', 'Color', model_color, 'MarkerSize', 20, ...
                                          'HandleVisibility', 'off');
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
