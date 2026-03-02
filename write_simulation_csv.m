function csv_filename = write_simulation_csv(data, output_dir, modelName)
% WRITE_SIMULATION_CSV Writes simulation results to agent_positions_[modelName].csv

if nargin < 3
    modelName = 'results';
end

N = data.N;
num_steps = length(data.t);
total_rows = N * num_steps;

time_col = zeros(total_rows, 1);
agent_id_col = zeros(total_rows, 1);
x_col = zeros(total_rows, 1);
y_col = zeros(total_rows, 1);
z_col = zeros(total_rows, 1);
vx_col = zeros(total_rows, 1);
vy_col = zeros(total_rows, 1);
vz_col = zeros(total_rows, 1);

row_idx = 1;
for k = 1:num_steps
    current_time = data.t(k);
    for agent = 1:N
        time_col(row_idx) = current_time;
        agent_id_col(row_idx) = agent;
        x_col(row_idx) = data.x(agent, k);
        y_col(row_idx) = data.y(agent, k);
        z_col(row_idx) = data.z(agent, k);
        vx_col(row_idx) = data.vx(agent, k);
        vy_col(row_idx) = data.vy(agent, k);
        vz_col(row_idx) = data.vz(agent, k);
        row_idx = row_idx + 1;
    end
end

output_table = table(time_col, agent_id_col, x_col, y_col, z_col, vx_col, vy_col, vz_col, ...
    'VariableNames', {'Time', 'AgentID', 'X', 'Y', 'Z', 'VX', 'VY', 'VZ'});

csv_filename = fullfile(output_dir, sprintf('agent_positions_%s.csv', modelName));
writetable(output_table, csv_filename);
fprintf('Data exported to %s\n', csv_filename);
end
