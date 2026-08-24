function generate_simulation_markdown(output_dir, model_type, num_agents, h, alpha, beta, delay_val, convergence_thresh)
% GENERATE_SIMULATION_MARKDOWN Generates a Markdown summary of the simulation run.

    md_filename = fullfile(output_dir, sprintf('simulation_summary_%s.md', model_type));
    fid = fopen(md_filename, 'w');
    if fid == -1
        warning('Could not open markdown file for writing: %s', md_filename);
        return;
    end
    
    % Default values
    traj_file = '';
    
    switch model_type
        case 'no_delay'
            title_str = 'Standard Model (No Delay)';
            desc = 'Simulation with standard Cucker-Smale model without communication delay.';
            command_file = 'run_command_no_delay.txt';
            pca_file = 'pca_visualization_no_delay.png';
            
        case 'fixed_delay'
            title_str = 'Delayed Model (Fixed Delay)';
            desc = sprintf('Simulation with fixed communication delay ($\\tau = %.3f$).', delay_val(1));
            command_file = 'run_command_fixed_delay.txt';
            pca_file = 'pca_visualization_fixed_delay.png';
            
        case 'state_dependent_delay'
            title_str = 'State-Dependent Delayed Model';
            desc = sprintf('Simulation with distance-dependent delay ($\\tau_{factor} = %.4f$).', delay_val(1));
            command_file = 'run_command_state_delay.txt';
            pca_file = 'pca_visualization_state_delay.png';
            
        case 'comparison'
            title_str = 'Multi-Model Comparison';
            desc = 'Comparison of No Delay, Fixed Delay, and State-Dependent Delay models.';
            command_file = 'run_command_multi_model.txt';
            pca_file = 'comparison_pca.png';
            traj_file = 'final_comparison_visual.png';
    end

    fprintf(fid, '# %s\n\n', title_str);
    fprintf(fid, '%s\n\n', desc);
    
    fprintf(fid, '### Function Call\n');
    fprintf(fid, '```matlab\n');
    command_path = fullfile(output_dir, command_file);
    if exist(command_path, 'file')
        txt = fileread(command_path);
        if ~isempty(txt) && txt(end) == sprintf('\n')
            fprintf(fid, '%s', txt);
        else
            fprintf(fid, '%s\n', txt);
        end
    else
        fprintf(fid, '%% Command log not found.\n');
    end
    fprintf(fid, '```\n\n');

    if strcmp(model_type, 'comparison')
        fprintf(fid, '### General Parameters\n');
    else
        fprintf(fid, '### Parameter Breakdown\n');
    end
    fprintf(fid, '| Parameter | Value | Description |\n');
    fprintf(fid, '| :--- | :--- | :--- |\n');
    fprintf(fid, '| **Agents ($N$)** | %d | Number of agents in the simulation. |\n', num_agents);
    fprintf(fid, '| **Step ($h$)** | %.3f | Temporal integration step size. |\n', h);
    fprintf(fid, '| **Gain ($\\alpha$)** | %.3f | Interaction strength. |\n', alpha);
    fprintf(fid, '| **Decay ($\\beta$)** | %.3f | Spatial communication decay. |\n', beta);
    if strcmp(model_type, 'fixed_delay')
        fprintf(fid, '| **Delay ($\\tau$)** | %.3f | Fixed delay value. |\n', delay_val(1));
    elseif strcmp(model_type, 'state_dependent_delay')
        fprintf(fid, '| **Delay Factor** | %.4f | Distance-to-latency scaling. |\n', delay_val(1));
    elseif strcmp(model_type, 'comparison') && length(delay_val) >= 2
        fprintf(fid, '| **Delay ($\\tau$)** | %.3f | Fixed delay value. |\n', delay_val(1));
        fprintf(fid, '| **Delay Factor** | %.4f | Distance-to-latency scaling. |\n', delay_val(2));
    end
    fprintf(fid, '| **Tolerance** | %.5f | Threshold for precise convergence. |\n\n', convergence_thresh);
    
    % Convergence summary table if metadata exists
    json_path = fullfile(output_dir, 'convergence_info.json');
    if exist(json_path, 'file')
        try
            txt = fileread(json_path);
            if ~isempty(strtrim(txt))
                info_json = jsondecode(txt);
                fprintf(fid, '### Convergence Breakdown\n');
                fprintf(fid, '| Model | Convergence Time ($t_{conv}$) | Consensus Reached |\n');
                fprintf(fid, '| :--- | :--- | :--- |\n');
                fields = fieldnames(info_json);
                for f = 1:length(fields)
                    fname = fields{f};
                    m_info = info_json.(fname);
                    rname = strrep(fname, '_', ' ');
                    rname = regexprep(rname, '(^| )(\w)', '${upper($2)}');
                    if isfield(m_info, 't_conv') && ~isempty(m_info.t_conv) && m_info.t_conv >= 0
                        t_str = sprintf('%.2f s', m_info.t_conv);
                    else
                        t_str = 'N/A';
                    end
                    if isfield(m_info, 'consensus_reached') && m_info.consensus_reached
                        c_str = 'Yes';
                    else
                        c_str = 'No';
                    end
                    fprintf(fid, '| **%s** | %s | %s |\n', rname, t_str, c_str);
                end
                fprintf(fid, '\n');
            end
        catch
        end
    end
    
    fprintf(fid, '### Mathematical Formulas\n');
    fprintf(fid, '1. **Standard Model**:\n');
    fprintf(fid, '$$\\frac{d\\mathbf{v}_i(t)}{dt} = \\frac{%.3f}{%d} \\sum_{j=1}^{%d} \\frac{1}{1 + \\Vert \\mathbf{x}_j(t) - \\mathbf{x}_i(t) \\Vert^{%.3f}} (\\mathbf{v}_j(t) - \\mathbf{v}_i(t))$$\n\n', alpha, num_agents, num_agents, beta);
    
    if strcmp(model_type, 'fixed_delay') || strcmp(model_type, 'comparison')
        tval = delay_val(1);
        fprintf(fid, '2. **Fixed Delay**: ($\\tau_{ij} = %.3f$)\n', tval);
        fprintf(fid, '$$\\frac{d\\mathbf{v}_i(t)}{dt} = \\frac{%.3f}{%d} \\sum_{j=1}^{%d} \\frac{1}{1 + \\Vert \\mathbf{x}_j(t-%.3f) - \\mathbf{x}_i(t-%.3f) \\Vert^{%.3f}} (\\mathbf{v}_j(t-%.3f) - \\mathbf{v}_i(t))$$\n\n', alpha, num_agents, num_agents, tval, tval, beta, tval);
    end
    if strcmp(model_type, 'state_dependent_delay') || strcmp(model_type, 'comparison')
        if strcmp(model_type, 'comparison') && length(delay_val) >= 2
            tfac = delay_val(2);
        else
            tfac = delay_val(1);
        end
        fprintf(fid, '3. **State-Dependent Delay**: ($\\tau_{factor} = %.4f$)\n', tfac);
        fprintf(fid, '$$\\tau_{ij}(t) = %.4f \\cdot \\Vert \\mathbf{x}_j(t) - \\mathbf{x}_i(t) \\Vert$$\n', tfac);
        fprintf(fid, '$$\\frac{d\\mathbf{v}_i(t)}{dt} = \\frac{%.3f}{%d} \\sum_{j=1}^{%d} \\frac{1}{1 + \\Vert \\mathbf{x}_j(t-\\tau_{ij}(t)) - \\mathbf{x}_i(t) \\Vert^{%.3f}} (\\mathbf{v}_j(t-\\tau_{ij}(t)) - \\mathbf{v}_i(t))$$\n\n', alpha, num_agents, num_agents, beta);
    end

    fprintf(fid, '### Visual Results\n');
    fprintf(fid, '![PCA Stability](%s)\n', pca_file);
    if ~isempty(traj_file)
        fprintf(fid, '![Simulation Trajectory](%s)\n', traj_file);
    end
    
    fclose(fid);
end
