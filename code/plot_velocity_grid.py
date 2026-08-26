import os
import sys
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def plot_velocity_grid(output_dir):
    """
    Generates a 2x2 grid of agent velocity graphs for comparative Cucker-Smale models.
    - Subplot 1 (0,0): Standard Model (No Delay) - Blue
    - Subplot 2 (0,1): Fixed Delay Model - Red
    - Subplot 3 (1,0): State-Dependent Delay Model - Green
    - Subplot 4 (1,1): Combined Multi-Model Comparison overlapping all 3 models
    """
    output_path = os.path.join(output_dir, "velocity_convergence_grid.png")

    model_configs = [
        {
            'key': 'no_delay',
            'filename': 'agent_positions_no_delay.csv',
            'title': 'Standard Model (No Delay)',
            'color': '#1f77b4'  # Blue
        },
        {
            'key': 'fixed_delay',
            'filename': 'agent_positions_fixed_delay.csv',
            'title': 'Fixed Delay Model',
            'color': '#d62728'  # Red
        },
        {
            'key': 'state_delay',
            'filename': 'agent_positions_state_delay.csv',
            'title': 'State-Dependent Delay Model',
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
                             color=cfg['color'], alpha=0.6, linewidth=1.0)
            # Dummy plot line for custom legend
            ax_comb.plot([], [], color=cfg['color'], linewidth=2.0, label=cfg['title'])

    ax_comb.set_title('Multi-Model Comparison', fontsize=12, fontweight='bold')
    ax_comb.set_xlabel('Time (t)', fontsize=10)
    ax_comb.set_ylabel('Velocity Magnitude ||v||', fontsize=10)
    ax_comb.grid(True, linestyle='--', alpha=0.5)
    ax_comb.legend(loc='upper right', frameon=True)

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
