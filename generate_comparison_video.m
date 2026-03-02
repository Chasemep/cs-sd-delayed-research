function video_path = generate_comparison_video(output_dir)
% GENERATE_COMPARISON_VIDEO Overlays all agent CSVs in a folder into one video.

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
    % Extract model name from filename (e.g., fixed_delay from agent_positions_fixed_delay.csv)
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
open(v);

% Visual settings per model
markers = {'o', '>', 's', '^', 'd', 'v'};
colors = {'r', 'b', 'g', 'm', 'c', 'k'};

figure;
grid on
view(3)
axis tight
hold on

% Create dummy plots for the legend
h_models = zeros(1, num_models);
for m = 1:num_models
    model_color = colors{mod(m-1, length(colors))+1};
    % Format model name for legend (e.g., fixed_delay -> Fixed Delay)
    readable_name = strrep(model_names{m}, '_', ' ');
    readable_name = regexprep(readable_name, '(^| )(\w)', '${upper($2)}');
    h_models(m) = plot3(NaN, NaN, NaN, 'Color', model_color, 'LineWidth', 1.5, 'DisplayName', readable_name);
end
legend(h_models, 'Location', 'northeastoutside', 'AutoUpdate', 'off');

try
    for k = 1:num_steps
        t = all_times(k);
        
        for m = 1:num_models
            df = model_data{m};
            step_data = df(df.Time == t, :);
            if isempty(step_data), continue; end
            
            % Unique color for the whole model
            model_color = colors{mod(m-1, length(colors))+1};
            
            % Match the incremental feel: write a frame for each agent plotted
            for i = 1:size(step_data, 1)
                agent_row = step_data(i, :);
                quiver3(agent_row.X, agent_row.Y, agent_row.Z, ...
                        agent_row.VX, agent_row.VY, agent_row.VZ, ...
                        1, 'Color', model_color, 'HandleVisibility', 'off');
                
                title(sprintf('Multi-Model Comparison (t = %.2f)', t));
                xlabel('X'); ylabel('Y'); zlabel('Z');
                
                A = getframe(gcf);
                writeVideo(v, A);
            end
        end
    end
catch ME
    fprintf('Comparison video generation interrupted: %s\n', ME.message);
end

hold off
close(v);
close(gcf);
end
