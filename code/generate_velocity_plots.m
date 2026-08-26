function output_path = generate_velocity_plots(output_dir)
% GENERATE_VELOCITY_PLOTS Generates a 2x2 grid of agent velocity graphs.
% Shows each agent's velocity magnitude over time to visually verify convergence.
%
% Subplot 1 (top-left): Standard Model (No Delay) - Blue
% Subplot 2 (top-right): Fixed Delay Model - Red
% Subplot 3 (bottom-left): State-Dependent Delay Model - Green
% Subplot 4 (bottom-right): Combined plot overlapping all 3 models

output_path = fullfile(output_dir, 'velocity_convergence_grid.png');

% Model key configuration: file name pattern, display title, color
model_configs = struct(...
    'no_delay', struct('file', 'agent_positions_no_delay.csv', 'title', 'Standard Model (No Delay)', 'color', [0.12, 0.47, 0.71]), ...
    'fixed_delay', struct('file', 'agent_positions_fixed_delay.csv', 'title', 'Fixed Delay Model', 'color', [0.84, 0.15, 0.16]), ...
    'state_delay', struct('file', 'agent_positions_state_delay.csv', 'title', 'State-Dependent Delay Model', 'color', [0.17, 0.63, 0.17]) ...
);

model_keys = {'no_delay', 'fixed_delay', 'state_delay'};
model_data = struct();
loaded_keys = {};

for i = 1:length(model_keys)
    key = model_keys{i};
    cfg = model_configs.(key);
    csv_path = fullfile(output_dir, cfg.file);
    if exist(csv_path, 'file')
        opts = detectImportOptions(csv_path);
        t_data = readtable(csv_path, opts);
        model_data.(key) = t_data;
        loaded_keys{end+1} = key; %#ok<AGROW>
    end
end

if isempty(loaded_keys)
    warning('No simulation CSVs found in %s to generate velocity plots.', output_dir);
    return;
end

fig = figure('Visible', 'off', 'Position', [100, 100, 1200, 900]);

% Setup 2x2 subplots
subplot_indices = [1, 2, 3];

for i = 1:length(model_keys)
    key = model_keys{i};
    cfg = model_configs.(key);
    subplot(2, 2, subplot_indices(i));
    hold on; grid on; box on;
    
    if isfield(model_data, key)
        df = model_data.(key);
        agents = unique(df.AgentID);
        t_max = max(df.Time);
        for a = 1:length(agents)
            agent_df = df(df.AgentID == agents(a), :);
            v_mag = sqrt(agent_df.VX.^2 + agent_df.VY.^2 + agent_df.VZ.^2);
            plot(agent_df.Time, v_mag, 'Color', cfg.color, 'LineWidth', 1.2);
        end
        
        asymptotes = find_flock_asymptotes(df);
        for f_idx = 1:length(asymptotes)
            asym_val = asymptotes(f_idx);
            if length(asymptotes) > 1
                lbl = sprintf('Flock %d Asymptote (%.2f)', f_idx, asym_val);
            else
                lbl = sprintf('Limiting Velocity (%.2f)', asym_val);
            end
            plot([0, t_max], [asym_val, asym_val], ':', 'Color', cfg.color, 'LineWidth', 1.8, 'DisplayName', lbl);
        end
        legend('Location', 'best');
    end
    
    title(cfg.title, 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time (t)', 'FontSize', 10);
    ylabel('Velocity Magnitude ||v||', 'FontSize', 10);
    hold off;
end

% Subplot 4: Combined Overlap
subplot(2, 2, 4);
hold on; grid on; box on;

legend_handles = [];
legend_labels = {};

for i = 1:length(model_keys)
    key = model_keys{i};
    cfg = model_configs.(key);
    
    if isfield(model_data, key)
        df = model_data.(key);
        agents = unique(df.AgentID);
        t_max = max(df.Time);
        for a = 1:length(agents)
            agent_df = df(df.AgentID == agents(a), :);
            v_mag = sqrt(agent_df.VX.^2 + agent_df.VY.^2 + agent_df.VZ.^2);
            plot(agent_df.Time, v_mag, 'Color', cfg.color, 'LineWidth', 1.0, 'HandleVisibility', 'off');
        end
        h_dummy = plot(NaN, NaN, 'Color', cfg.color, 'LineWidth', 2);
        legend_handles(end+1) = h_dummy; %#ok<AGROW>
        legend_labels{end+1} = cfg.title; %#ok<AGROW>
        
        asymptotes = find_flock_asymptotes(df);
        for f_idx = 1:length(asymptotes)
            asym_val = asymptotes(f_idx);
            if length(asymptotes) > 1
                lbl = sprintf('%s Flock %d (%.1f)', cfg.title, f_idx, asym_val);
            else
                lbl = sprintf('%s Asym (%.1f)', cfg.title, asym_val);
            end
            h_asym = plot([0, t_max], [asym_val, asym_val], ':', 'Color', cfg.color, 'LineWidth', 1.5);
            legend_handles(end+1) = h_asym; %#ok<AGROW>
            legend_labels{end+1} = lbl; %#ok<AGROW>
        end
    end
end

title('Multi-Model Comparison', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (t)', 'FontSize', 10);
ylabel('Velocity Magnitude ||v||', 'FontSize', 10);

if ~isempty(legend_handles)
    legend(legend_handles, legend_labels, 'Location', 'northeast');
end
hold off;

sgtitle('Agent Velocity Convergence Analysis', 'FontSize', 14, 'FontWeight', 'bold');

% Save output graphic
try
    exportgraphics(fig, output_path, 'Resolution', 300);
    fprintf('Velocity convergence grid saved to: %s\n', output_path);
catch
    saveas(fig, output_path);
    fprintf('Velocity convergence grid saved (saveas) to: %s\n', output_path);
end

close(fig);
end

function asymptotes = find_flock_asymptotes(df, tol)
    if nargin < 2, tol = 2.0; end
    t_max = max(df.Time);
    final_df = df(df.Time == t_max, :);
    v_mags = sqrt(final_df.VX.^2 + final_df.VY.^2 + final_df.VZ.^2);
    v_sorted = sort(v_mags);
    if isempty(v_sorted)
        asymptotes = [];
        return;
    end
    
    clusters = {};
    curr_c = v_sorted(1);
    for i = 2:length(v_sorted)
        if abs(v_sorted(i) - curr_c(end)) <= tol
            curr_c(end+1) = v_sorted(i);
        else
            clusters{end+1} = curr_c;
            curr_c = v_sorted(i);
        end
    end
    clusters{end+1} = curr_c;
    
    asymptotes = zeros(1, length(clusters));
    for k = 1:length(clusters)
        asymptotes(k) = mean(clusters{k});
    end
end

