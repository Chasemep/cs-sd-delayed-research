function video_path = generate_simulation_video(csv_path, output_dir)
% GENERATE_SIMULATION_VIDEO Creates a 3D quiver video from agent_positions.csv
% This function is modular and can be run independently of the simulation.

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
open(v);

colorstring = 'rgbcmk'; 
figure;
grid on
view(3)
axis tight
hold on

try
    for k = 1:num_steps
        current_step_data = df(df.Time == times(k), :);
        
        for i = 1:N
            agent_data = current_step_data(current_step_data.AgentID == agent_ids(i), :);
            quiver3(agent_data.X, agent_data.Y, agent_data.Z, ...
                    agent_data.VX, agent_data.VY, agent_data.VZ, ...
                    1, 'Color', colorstring(mod(i,6) + 1));
            rotate3d('on');
            A = getframe(gcf);
            writeVideo(v, A);
        end
    end
catch ME
    fprintf('Video generation interrupted: %s\n', ME.message);
end

hold off
close(v);
close(gcf);
end
