function csv_filename = write_simulation_csv(data, output_dir, modelName)
% WRITE_SIMULATION_CSV Writes simulation results to agent_positions_[modelName].csv

if nargin < 3
    modelName = 'results';
end

N = data.N;
num_steps = length(data.t);
% Vectorized column construction
time_col = kron(data.t(:), ones(N, 1));
agent_id_col = repmat((1:N)', num_steps, 1);
x_col = data.x(:);
y_col = data.y(:);
z_col = data.z(:);
vx_col = data.vx(:);
vy_col = data.vy(:);
vz_col = data.vz(:);

output_table = table(time_col, agent_id_col, x_col, y_col, z_col, vx_col, vy_col, vz_col, ...
    'VariableNames', {'Time', 'AgentID', 'X', 'Y', 'Z', 'VX', 'VY', 'VZ'});

csv_filename = fullfile(output_dir, sprintf('agent_positions_%s.csv', modelName));
writetable(output_table, csv_filename);
fprintf('Data exported to %s\n', csv_filename);

% Update convergence_info.json metadata
json_file = fullfile(output_dir, 'convergence_info.json');
info_struct = struct();
if exist(json_file, 'file')
    try
        txt = fileread(json_file);
        if ~isempty(strtrim(txt))
            info_struct = jsondecode(txt);
        end
    catch
        info_struct = struct();
    end
end

entry = struct();
if isfield(data, 't_conv') && ~isnan(data.t_conv)
    entry.t_conv = data.t_conv;
else
    entry.t_conv = -1;
end
if isfield(data, 'k_conv') && ~isnan(data.k_conv)
    entry.k_conv = data.k_conv;
else
    entry.k_conv = -1;
end
if isfield(data, 'consensus_reached')
    entry.consensus_reached = logical(data.consensus_reached);
else
    entry.consensus_reached = false;
end

info_struct.(modelName) = entry;
fid = fopen(json_file, 'w');
if fid ~= -1
    fprintf(fid, '%s', jsonencode(info_struct));
    fclose(fid);
end
end
