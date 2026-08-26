import os
import sys
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def find_flock_asymptotes(df, tol=2.0):
    """
    Finds the limiting velocity magnitudes for each flock in the dataframe.
    """
    if 'Time' not in df.columns or 'Velocity' not in df.columns:
        return []
    t_max = df['Time'].max()
    final_df = df[df['Time'] == t_max]
    velocities = sorted(final_df['Velocity'].tolist())
    if not velocities:
        return []
    
    clusters = []
    current_cluster = [velocities[0]]
    for v in velocities[1:]:
        if abs(v - current_cluster[-1]) <= tol:
            current_cluster.append(v)
        else:
            clusters.append(current_cluster)
            current_cluster = [v]
    clusters.append(current_cluster)
    
    return [float(np.mean(c)) for c in clusters]

def plot_velocity_grid(output_dir):
    """
    Generates a 2x2 grid of agent velocity graphs for comparative Cucker-Smale models.
    - Subplot 1 (0,0): Standard Model (No Delay) - Blue
    - Subplot 2 (0,1): Fixed Delay Model - Red
    - Subplot 3 (1,0): State-Dependent Delay Model - Green
    - Subplot 4 (1,1): Combined Multi-Model Comparison overlapping all 3 models
    Includes dotted asymptote lines for limiting velocities of each flock.
    """
    output_path = os.path.join(output_dir, "velocity_convergence_grid.png")

    model_configs = [
        {
            'key': 'no_delay',
            'filename': 'agent_positions_no_delay.csv',
            'title': 'Standard Model (No Delay)',
            'short_title': 'No Delay',
            'color': '#1f77b4'  # Blue
        },
        {
            'key': 'fixed_delay',
            'filename': 'agent_positions_fixed_delay.csv',
            'title': 'Fixed Delay Model',
            'short_title': 'Fixed Delay',
            'color': '#d62728'  # Red
        },
        {
            'key': 'state_delay',
            'filename': 'agent_positions_state_delay.csv',
            'title': 'State-Dependent Delay Model',
            'short_title': 'State Delay',
            'color': '#2ca02c'  # Green
        }
    ]

    model_data = {}
    loaded_any = False

    for cfg in model_configs:
        csv_path = os.path.join(output_dir, cfg['filename'])
        if os.path.exists(csv_path):
            try:
                df = pd.read_csv(csv_path)
                df['Velocity'] = np.sqrt(df['VX']**2 + df['VY']**2 + df['VZ']**2)
                model_data[cfg['key']] = df
                loaded_any = True
            except Exception as e:
                print(f"Error reading {csv_path}: {e}")

    if not loaded_any:
        print(f"No simulation CSVs found in {output_dir} to generate velocity grid.")
        return

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    axes_list = [axes[0, 0], axes[0, 1], axes[1, 0]]

    # Individual Model Subplots (Subplots 1, 2, 3)
    for idx, cfg in enumerate(model_configs):
        ax = axes_list[idx]
        key = cfg['key']

        if key in model_data:
            df = model_data[key]
            for agent_id, agent_group in df.groupby('AgentID'):
                ax.plot(agent_group['Time'], agent_group['Velocity'],
                        color=cfg['color'], alpha=0.8, linewidth=1.2)
            
            asymptotes = find_flock_asymptotes(df)
            for f_idx, asym_val in enumerate(asymptotes):
                label_text = f"Flock {f_idx+1} Asymptote ({asym_val:.2f})" if len(asymptotes) > 1 else f"Limiting Velocity ({asym_val:.2f})"
                ax.axhline(y=asym_val, color=cfg['color'], linestyle=':', linewidth=1.8, alpha=0.9, label=label_text)
            
            if asymptotes:
                ax.legend(loc='best', fontsize=9)

        ax.set_title(cfg['title'], fontsize=12, fontweight='bold')
        ax.set_xlabel('Time (t)', fontsize=10)
        ax.set_ylabel('Velocity Magnitude ||v||', fontsize=10)
        ax.grid(True, linestyle='--', alpha=0.5)

    # Combined Subplot (Subplot 4)
    ax_comb = axes[1, 1]
    for cfg in model_configs:
        key = cfg['key']
        if key in model_data:
            df = model_data[key]
            for agent_id, agent_group in df.groupby('AgentID'):
                ax_comb.plot(agent_group['Time'], agent_group['Velocity'],
                             color=cfg['color'], alpha=0.5, linewidth=1.0)
            # Dummy plot line for custom legend
            ax_comb.plot([], [], color=cfg['color'], linewidth=2.0, label=cfg['title'])

            asymptotes = find_flock_asymptotes(df)
            for f_idx, asym_val in enumerate(asymptotes):
                asym_label = f"{cfg['short_title']} Flock {f_idx+1} ({asym_val:.1f})" if len(asymptotes) > 1 else f"{cfg['short_title']} Asym ({asym_val:.1f})"
                ax_comb.axhline(y=asym_val, color=cfg['color'], linestyle=':', linewidth=1.5, alpha=0.85, label=asym_label)

    ax_comb.set_title('Multi-Model Comparison', fontsize=12, fontweight='bold')
    ax_comb.set_xlabel('Time (t)', fontsize=10)
    ax_comb.set_ylabel('Velocity Magnitude ||v||', fontsize=10)
    ax_comb.grid(True, linestyle='--', alpha=0.5)
    ax_comb.legend(loc='best', fontsize=8, frameon=True)

    plt.suptitle('Agent Velocity Convergence Analysis', fontsize=15, fontweight='bold')
    plt.tight_layout()

    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"Velocity convergence grid saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_velocity_grid.py <output_dir>")
    else:
        plot_velocity_grid(sys.argv[1])

