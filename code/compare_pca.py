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

def compare_pca(output_dir):
    # Find all CSVs
    csv_files = glob.glob(os.path.join(output_dir, "agent_positions_*.csv"))
    if not csv_files:
        print(f"No CSVs found in {output_dir}")
        return

    # Read convergence info metadata if present
    json_path = os.path.join(output_dir, "convergence_info.json")
    conv_info = {}
    if os.path.exists(json_path):
        try:
            with open(json_path, 'r') as f:
                conv_info = json.load(f)
        except Exception as e:
            print(f"Error reading convergence_info.json: {e}")

    model_results = []
    all_pos_for_pca = []
    
    # 1. Load data and prepare for PCA
    for csv_file in csv_files:
        df = pd.read_csv(csv_file)
        model_name = os.path.basename(csv_file).replace("agent_positions_", "").replace(".csv", "")
        
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
        if model_name in conv_info:
            m_info = conv_info[model_name]
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

        model_results.append({
            'name': model_name,
            'init_pos': init_pos,
            'final_pos': final_pos,
            'final_vels': final_vels,
            't_conv': t_conv,
            'v_conv': v_conv,
            'conv_pos': conv_pos
        })
        
        all_pos_for_pca.append(init_pos)
        all_pos_for_pca.append(final_pos)

    X_all = np.vstack(all_pos_for_pca)
    pca = PCA(n_components=2)
    pca.fit(X_all)
    
    # 2. Plotting
    plt.figure(figsize=(12, 10))
    colors = plt.cm.tab10(np.linspace(0, 1, 10))
    
    all_pca_points = []
    drawn_label_coords = [] # Track label positions to avoid overlaps
    
    for idx, model in enumerate(model_results):
        model_color = colors[idx % 10]
        name = model['name']
        readable_name = name.replace('_', ' ').title()
        
        init_pca = pca.transform(model['init_pos'])
        final_pca = pca.transform(model['final_pos'])
        all_pca_points.append(init_pca)
        all_pca_points.append(final_pca)
        
        # Trajectories
        for i in range(len(init_pca)):
            plt.plot([init_pca[i,0], final_pca[i,0]], [init_pca[i,1], final_pca[i,1]], 
                     color=model_color, alpha=0.3, linestyle='-', lw=1, zorder=1)
        
        # Initial (X)
        plt.scatter(init_pca[:, 0], init_pca[:, 1], marker='x', s=80, 
                    color=model_color, alpha=0.6, zorder=2)
        
        # Final (Dot)
        plt.scatter(final_pca[:, 0], final_pca[:, 1], marker='o', s=100, 
                    color=model_color, edgecolors='white', linewidths=1.0, zorder=10)

        # Convergence Point Marker on actual plot (no text label on canvas)
        if model['conv_pos'] is not None and model['t_conv'] is not None:
            conv_pca = pca.transform(model['conv_pos'])
            all_pca_points.append(conv_pca)
            plt.scatter(conv_pca[:, 0], conv_pca[:, 1], marker='*', s=160, 
                        color=model_color, edgecolors='black', linewidths=0.8, zorder=15)

        # Clustering
        vels = model['final_vels']
        distances = pdist(vels)
        if len(vels) > 1:
            Z = linkage(distances, method='complete')
            labels = fcluster(Z, t=0.3, criterion='distance')
        else:
            labels = np.array([1])
            
        unique_labels = np.unique(labels)
        for label in unique_labels:
            mask = (labels == label)
            cluster_pca = final_pca[mask]
            
            # Hulls
            if len(cluster_pca) >= 3:
                try:
                    hull = ConvexHull(cluster_pca)
                    hull_pts = cluster_pca[hull.vertices]
                    hull_pts = np.vstack([hull_pts, hull_pts[0]])
                    plt.plot(hull_pts[:, 0], hull_pts[:, 1], color=model_color, lw=2, alpha=0.5, zorder=5)
                    plt.fill(hull_pts[:, 0], hull_pts[:, 1], color=model_color, alpha=0.1, zorder=1)
                except: pass
            elif len(cluster_pca) == 2:
                plt.plot(cluster_pca[:, 0], cluster_pca[:, 1], color=model_color, lw=2, alpha=0.4, zorder=5)

            # --- Label Overlap Avoidance ---
            mean_v = np.mean(vels[mask], axis=0)
            v_mag = np.linalg.norm(mean_v)
            centroid = np.mean(cluster_pca, axis=0)
            
            text_x, text_y = centroid[0], centroid[1] + 0.1
            
            # Search for non-overlapping spot
            collision = True
            attempts = 0
            while collision and attempts < 15:
                collision = False
                for prev_x, prev_y in drawn_label_coords:
                    if abs(text_x - prev_x) < 0.4 and abs(text_y - prev_y) < 0.2:
                        collision = True
                        text_y += 0.15 # Bump up
                        text_x += 0.05 # Slight jitter
                        break
                attempts += 1
            
            drawn_label_coords.append((text_x, text_y))
            
            plt.text(text_x, text_y, f"v={v_mag:.2f}", 
                     fontsize=9, fontweight='bold', color='black', ha='center',
                     bbox=dict(facecolor='white', alpha=0.9, edgecolor=model_color, 
                               boxstyle='round,pad=0.2', lw=1.2),
                     zorder=20)

    # Dynamic Zoom
    X_plot = np.vstack(all_pca_points)
    x_min, x_max = X_plot[:, 0].min(), X_plot[:, 0].max()
    y_min, y_max = X_plot[:, 1].min(), X_plot[:, 1].max()
    x_pad = (x_max - x_min) * 0.15 if x_max != x_min else 2.0
    y_pad = (y_max - y_min) * 0.15 if y_max != y_min else 2.0
    plt.xlim(x_min - x_pad, x_max + x_pad)
    plt.ylim(y_min - y_pad, y_max + y_pad)

    plt.title("Comparative PCA Architecture Analysis", fontsize=14, fontweight='bold')
    plt.xlabel(f"PCA 1 ({pca.explained_variance_ratio_[0]*100:.1f}%)", fontsize=12)
    plt.ylabel(f"PCA 2 ({pca.explained_variance_ratio_[1]*100:.1f}%)", fontsize=12)
    
    # Custom Legend containing Model Names, Convergence Times & Velocities
    from matplotlib.lines import Line2D
    custom_legend = []
    for i, m in enumerate(model_results):
        model_title = m['name'].replace('_', ' ').title()
        if m['t_conv'] is not None and m['t_conv'] >= 0:
            if m.get('v_conv') is not None:
                label_str = f"{model_title} (t_conv = {m['t_conv']:.2f}s, v_conv = {m['v_conv']:.2f})"
            else:
                label_str = f"{model_title} (t_conv = {m['t_conv']:.2f}s)"
        else:
            label_str = f"{model_title} (No Conv)"
        custom_legend.append(Line2D([0], [0], marker='o', color='w', label=label_str, 
                            markerfacecolor=colors[i % 10], markersize=10))
    
    custom_legend.append(Line2D([0], [0], marker='x', color='black', label='Initial State (t=0)', linestyle='None', markersize=8))
    custom_legend.append(Line2D([0], [0], marker='*', color='black', label='Convergence Point (*)', linestyle='None', markersize=10))
    custom_legend.append(Line2D([0], [0], marker='o', color='black', label='Final State', linestyle='None', markersize=8))
    
    plt.legend(handles=custom_legend, title="Models & Convergence Info", bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.tight_layout()
    
    output_path = os.path.join(output_dir, "comparison_pca.png")
    plt.savefig(output_path)
    plt.close()
    print(f"Comparison PCA saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python compare_pca.py <output_dir>")
    else:
        compare_pca(sys.argv[1])
