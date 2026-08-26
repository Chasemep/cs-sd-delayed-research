import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

def plot_clean_3d(output_dir):
    """
    Generates a 2x2 grid of 3D trajectory plots for Cucker-Smale model comparison.
    - Subplot 1 (top-left): Standard Model (No Delay) - Blue
    - Subplot 2 (top-right): Fixed Delay Model - Red
    - Subplot 3 (bottom-left): State-Dependent Delay Model - Green
    - Subplot 4 (bottom-right): Combined Multi-Model Comparison (Blue, Red, Green with legend)
    Saves to final_comparison_visual_clean.png in output_dir.
    """
    output_path = os.path.join(output_dir, "final_comparison_visual_clean.png")

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
                model_data[cfg['key']] = df
                loaded_any = True
            except Exception as e:
                print(f"Error reading {csv_path}: {e}")

    if not loaded_any:
        print(f"No simulation CSVs found in {output_dir}")
        return

    fig = plt.figure(figsize=(14, 11))

    axes_3d = [
        fig.add_subplot(2, 2, 1, projection='3d'),
        fig.add_subplot(2, 2, 2, projection='3d'),
        fig.add_subplot(2, 2, 3, projection='3d'),
    ]

    # Individual model subplots (1, 2, 3)
    for idx, cfg in enumerate(model_configs):
        ax = axes_3d[idx]
        key = cfg['key']

        if key in model_data:
            df = model_data[key]
            for agent_id, group in df.groupby('AgentID'):
                group_sorted = group.sort_values('Time')
                ax.plot(group_sorted['X'], group_sorted['Y'], group_sorted['Z'],
                        color=cfg['color'], linewidth=1.0, alpha=0.85)
                last_pt = group_sorted.iloc[-1]
                ax.scatter(last_pt['X'], last_pt['Y'], last_pt['Z'],
                           color=cfg['color'], s=20)

        ax.set_title(cfg['title'], fontsize=11, fontweight='bold', pad=6)
        ax.set_xlabel('X', fontsize=9, labelpad=4)
        ax.set_ylabel('Y', fontsize=9, labelpad=4)
        ax.set_zlabel('Z', fontsize=9, labelpad=4)
        ax.tick_params(labelsize=7)

    # Combined subplot (4)
    ax_comb = fig.add_subplot(2, 2, 4, projection='3d')

    for cfg in model_configs:
        key = cfg['key']
        if key in model_data:
            df = model_data[key]
            plotted_label = False
            for agent_id, group in df.groupby('AgentID'):
                group_sorted = group.sort_values('Time')
                label = cfg['title'] if not plotted_label else None
                ax_comb.plot(group_sorted['X'], group_sorted['Y'], group_sorted['Z'],
                             color=cfg['color'], linewidth=0.9, alpha=0.75, label=label)
                plotted_label = True
                last_pt = group_sorted.iloc[-1]
                ax_comb.scatter(last_pt['X'], last_pt['Y'], last_pt['Z'],
                                color=cfg['color'], s=15)

    ax_comb.set_title('Multi-Model Comparison', fontsize=11, fontweight='bold', pad=6)
    ax_comb.set_xlabel('X', fontsize=9, labelpad=4)
    ax_comb.set_ylabel('Y', fontsize=9, labelpad=4)
    ax_comb.set_zlabel('Z', fontsize=9, labelpad=4)
    ax_comb.tick_params(labelsize=7)
    ax_comb.legend(loc='upper left', fontsize=8, frameon=True)

    plt.suptitle('Agent 3D Trajectory Analysis', fontsize=14, fontweight='bold')
    plt.tight_layout()

    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"Clean 3D graph saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_clean_3d.py <output_dir>")
    else:
        plot_clean_3d(sys.argv[1])
