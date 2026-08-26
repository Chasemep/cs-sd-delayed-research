import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import sys
import os
import glob
import json
from scipy.cluster.hierarchy import linkage, fcluster
from scipy.spatial.distance import pdist
from scipy.spatial import ConvexHull
from matplotlib.lines import Line2D

def compare_pca(output_dir):
    """
    Generates a 2x2 grid of PCA projection plots for comparative Cucker-Smale models.
    - Subplot 1 (0,0): Standard Model (No Delay) - Blue (#1f77b4)
    - Subplot 2 (0,1): Fixed Delay Model - Red (#d62728)
    - Subplot 3 (1,0): State-Dependent Delay Model - Green (#2ca02c)
    - Subplot 4 (1,1): Multi-Model Comparison overlapping all 3 models with custom legend
    Saves to comparison_pca.png in output_dir.
    """
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

    # Read convergence info metadata if present
    json_path = os.path.join(output_dir, "convergence_info.json")
    conv_info = {}
    if os.path.exists(json_path):
        try:
            with open(json_path, 'r') as f:
                conv_info = json.load(f)
        except Exception as e:
            print(f"Error reading convergence_info.json: {e}")

    model_data = {}
    all_pos_for_pca = []

    for cfg in model_configs:
        csv_path = os.path.join(output_dir, cfg['filename'])
        if os.path.exists(csv_path):
            try:
                df = pd.read_csv(csv_path)
                key = cfg['key']
                
                t_min = df['Time'].min()
                t_max = df['Time'].max()
                
                init_df = df[df['Time'] == t_min].sort_values('AgentID')
                final_df = df[df['Time'] == t_max].sort_values('AgentID')
                
                pos_cols = ['X', 'Y', 'Z']
                vel_cols = ['VX', 'VY', 'VZ']
                
                init_pos = init_df[pos_cols].values
                final_pos = final_df[pos_cols].values
                final_vels = final_df[vel_cols].values
                
                t_conv = None
                v_conv = None
                conv_pos = None
                
                if key in conv_info:
                    m_info = conv_info[key]
                    if isinstance(m_info, dict) and m_info.get('t_conv') is not None and m_info.get('t_conv') >= 0:
                        t_conv = float(m_info['t_conv'])
                        times = df['Time'].unique()
                        closest_t = times[np.argmin(np.abs(times - t_conv))]
                        conv_df = df[df['Time'] == closest_t].sort_values('AgentID')
                        conv_pos = conv_df[pos_cols].values
                        all_pos_for_pca.append(conv_pos)
                        
                        if m_info.get('v_conv') is not None and float(m_info['v_conv']) >= 0:
                            v_conv = float(m_info['v_conv'])
                        else:
                            mean_v = np.mean(conv_df[vel_cols].values, axis=0)
                            v_conv = float(np.linalg.norm(mean_v))

                all_pos_for_pca.append(init_pos)
                all_pos_for_pca.append(final_pos)
                
                model_data[key] = {
                    'cfg': cfg,
                    'df': df,
                    'init_pos': init_pos,
                    'final_pos': final_pos,
                    'final_vels': final_vels,
                    't_conv': t_conv,
                    'v_conv': v_conv,
                    'conv_pos': conv_pos
                }
            except Exception as e:
                print(f"Error reading {csv_path}: {e}")

    if not model_data:
        print(f"No simulation CSVs found in {output_dir}")
        return

    # Fit PCA on all position data across models for consistent axes
    X_all = np.vstack(all_pos_for_pca)
    pca = PCA(n_components=2)
    pca.fit(X_all)

    # Compute global bounds for consistent axis limits across all 4 subplots
    all_pca_pts = []
    for key, data in model_data.items():
        init_pca = pca.transform(data['init_pos'])
        final_pca = pca.transform(data['final_pos'])
        all_pca_pts.append(init_pca)
        all_pca_pts.append(final_pca)
        if data['conv_pos'] is not None:
            conv_pca = pca.transform(data['conv_pos'])
            all_pca_pts.append(conv_pca)

    X_plot = np.vstack(all_pca_pts)
    x_min, x_max = X_plot[:, 0].min(), X_plot[:, 0].max()
    y_min, y_max = X_plot[:, 1].min(), X_plot[:, 1].max()
    x_pad = (x_max - x_min) * 0.15 if x_max != x_min else 2.0
    y_pad = (y_max - y_min) * 0.15 if y_max != y_min else 2.0
    xlims = (x_min - x_pad, x_max + x_pad)
    ylims = (y_min - y_pad, y_max + y_pad)

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    axes_list = [axes[0, 0], axes[0, 1], axes[1, 0]]

    def plot_single_model_pca(ax, data, color, drawn_label_coords):
        init_pca = pca.transform(data['init_pos'])
        final_pca = pca.transform(data['final_pos'])

        # Trajectory lines
        for i in range(len(init_pca)):
            ax.plot([init_pca[i, 0], final_pca[i, 0]], [init_pca[i, 1], final_pca[i, 1]],
                    color=color, alpha=0.35, linestyle='-', lw=1, zorder=1)

        # Initial state (X)
        ax.scatter(init_pca[:, 0], init_pca[:, 1], marker='x', s=70,
                   color=color, alpha=0.7, zorder=2)

        # Final state (Dot)
        ax.scatter(final_pca[:, 0], final_pca[:, 1], marker='o', s=80,
                   color=color, edgecolors='white', linewidths=1.0, zorder=10)

        # Convergence Point Marker
        if data['conv_pos'] is not None and data['t_conv'] is not None:
            conv_pca = pca.transform(data['conv_pos'])
            ax.scatter(conv_pca[:, 0], conv_pca[:, 1], marker='*', s=140,
                       color=color, edgecolors='black', linewidths=0.8, zorder=15)

        # Velocity clustering & hulls
        vels = data['final_vels']
        if len(vels) > 1:
            distances = pdist(vels)
            Z = linkage(distances, method='complete')
            labels = fcluster(Z, t=0.3, criterion='distance')
        else:
            labels = np.array([1])

        unique_labels = np.unique(labels)
        for label in unique_labels:
            mask = (labels == label)
            cluster_pca = final_pca[mask]

            if len(cluster_pca) >= 3:
                try:
                    hull = ConvexHull(cluster_pca)
                    hull_pts = cluster_pca[hull.vertices]
                    hull_pts = np.vstack([hull_pts, hull_pts[0]])
                    ax.plot(hull_pts[:, 0], hull_pts[:, 1], color=color, lw=2, alpha=0.5, zorder=5)
                    ax.fill(hull_pts[:, 0], hull_pts[:, 1], color=color, alpha=0.1, zorder=1)
                except:
                    pass
            elif len(cluster_pca) == 2:
                ax.plot(cluster_pca[:, 0], cluster_pca[:, 1], color=color, lw=2, alpha=0.4, zorder=5)

            # Velocity magnitude text label with collision offset
            mean_v = np.mean(vels[mask], axis=0)
            v_mag = np.linalg.norm(mean_v)
            centroid = np.mean(cluster_pca, axis=0)

            text_x, text_y = centroid[0], centroid[1] + 0.1
            collision = True
            attempts = 0
            while collision and attempts < 15:
                collision = False
                for prev_x, prev_y in drawn_label_coords:
                    if abs(text_x - prev_x) < 0.4 and abs(text_y - prev_y) < 0.2:
                        collision = True
                        text_y += 0.15
                        text_x += 0.05
                        break
                attempts += 1

            drawn_label_coords.append((text_x, text_y))
            ax.text(text_x, text_y, f"v={v_mag:.2f}",
                    fontsize=8, fontweight='bold', color='black', ha='center',
                    bbox=dict(facecolor='white', alpha=0.9, edgecolor=color,
                              boxstyle='round,pad=0.2', lw=1.2),
                    zorder=20)

    # Individual Subplots (Subplots 1, 2, 3)
    for idx, cfg in enumerate(model_configs):
        ax = axes_list[idx]
        key = cfg['key']
        if key in model_data:
            data = model_data[key]
            plot_single_model_pca(ax, data, cfg['color'], [])

        ax.set_title(cfg['title'], fontsize=12, fontweight='bold')
        ax.set_xlabel(f"PCA 1 ({pca.explained_variance_ratio_[0]*100:.1f}%)", fontsize=10)
        ax.set_ylabel(f"PCA 2 ({pca.explained_variance_ratio_[1]*100:.1f}%)", fontsize=10)
        ax.set_xlim(xlims)
        ax.set_ylim(ylims)
        ax.grid(True, linestyle='--', alpha=0.5)

    # Combined Subplot (Subplot 4)
    ax_comb = axes[1, 1]
    drawn_label_coords_comb = []
    for cfg in model_configs:
        key = cfg['key']
        if key in model_data:
            data = model_data[key]
            plot_single_model_pca(ax_comb, data, cfg['color'], drawn_label_coords_comb)

    ax_comb.set_title('Multi-Model Comparison', fontsize=12, fontweight='bold')
    ax_comb.set_xlabel(f"PCA 1 ({pca.explained_variance_ratio_[0]*100:.1f}%)", fontsize=10)
    ax_comb.set_ylabel(f"PCA 2 ({pca.explained_variance_ratio_[1]*100:.1f}%)", fontsize=10)
    ax_comb.set_xlim(xlims)
    ax_comb.set_ylim(ylims)
    ax_comb.grid(True, linestyle='--', alpha=0.5)

    # Custom Legend for Subplot 4
    custom_legend = []
    for cfg in model_configs:
        key = cfg['key']
        if key in model_data:
            m = model_data[key]
            if m['t_conv'] is not None and m['t_conv'] >= 0:
                if m.get('v_conv') is not None:
                    label_str = f"{cfg['title']} (t_conv={m['t_conv']:.2f}s, v_conv={m['v_conv']:.2f})"
                else:
                    label_str = f"{cfg['title']} (t_conv={m['t_conv']:.2f}s)"
            else:
                label_str = f"{cfg['title']} (No Conv)"
            custom_legend.append(Line2D([0], [0], marker='o', color='w', label=label_str,
                                        markerfacecolor=cfg['color'], markersize=8))

    custom_legend.append(Line2D([0], [0], marker='x', color='black', label='Initial (t=0)', linestyle='None', markersize=7))
    custom_legend.append(Line2D([0], [0], marker='*', color='black', label='Convergence (*)', linestyle='None', markersize=9))
    custom_legend.append(Line2D([0], [0], marker='o', color='black', label='Final State', linestyle='None', markersize=7))

    ax_comb.legend(handles=custom_legend, fontsize=8, loc='upper left', frameon=True)

    plt.suptitle('PCA Projection Analysis', fontsize=15, fontweight='bold')
    plt.tight_layout()

    output_path = os.path.join(output_dir, "comparison_pca.png")
    plt.savefig(output_path, dpi=300)
    plt.close()
    print(f"Comparison PCA grid saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python compare_pca.py <output_dir>")
    else:
        compare_pca(sys.argv[1])

