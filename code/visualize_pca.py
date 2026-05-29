import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
from scipy.spatial import ConvexHull
import matplotlib.pyplot as plt
import sys
import os
from scipy.cluster.hierarchy import linkage, fcluster
from scipy.spatial.distance import pdist

def visualize_pca(csv_path, variance_threshold=0.1):
    # Load data
    try:
        df = pd.read_csv(csv_path)
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return

    # Filter for the initial and final time steps
    max_time = df['Time'].max()
    min_time = df['Time'].min()
    
    final_positions = df[df['Time'] == max_time]
    initial_positions = df[df['Time'] == min_time]

    # Sort by AgentID to ensure correct matching
    final_positions = final_positions.sort_values('AgentID')
    initial_positions = initial_positions.sort_values('AgentID')
    
    # Extract coordinates
    final_data = final_positions[['X', 'Y', 'Z']].values
    initial_data = initial_positions[['X', 'Y', 'Z']].values
    
    # Extract velocities
    final_velocities = final_positions[['VX', 'VY', 'VZ']].values
    
    # Check if we have enough data points
    if final_data.shape[0] < 3:
        print("Not enough agents to perform PCA (need at least 3).")
        return

    # Perform PCA (fit on final positions)
    pca = PCA(n_components=2)
    final_pca = pca.fit_transform(final_data)
    
    # Transform initial positions using the same PCA projection
    initial_pca = pca.transform(initial_data)
    
    # --- Velocity-Based Hierarchical Grouping ---
    def get_velocity_groups(velocity_data):
        """
        Group agents based on velocity similarity using hierarchical 
        clustering with a distance threshold derived from the 
        variance threshold.
        """
        N = len(velocity_data)
        if N < 2:
            return np.array([0])
        
        # Calculate pairwise Euclidean distances in velocity space
        distances = pdist(velocity_data)
        
        # Perform hierarchical clustering (use 'complete' to ensure all pairs
        # in a cluster are within the distance threshold)
        Z = linkage(distances, method='complete')
        
        # Use variance_threshold to decide the distance cutoff
        # In a tight cluster, dist approx sqrt(variance). 
        # We'll use sqrt(variance_threshold) as the cluster diameter limit.
        t_dist = np.sqrt(variance_threshold)
        
        # If the threshold is too small, ensure a floor for numerical stability
        t_dist = max(t_dist, 0.05)
        
        # Assign clusters
        labels = fcluster(Z, t=t_dist, criterion='distance')
        
        # Standardize labels to 0-indexed
        labels = labels - 1
        return labels
    
    def detect_stationary_groups(velocity_data, labels):
        """
        Detect which groups are stationary (velocity magnitude ≈ 0)
        """
        stationary_threshold = 0.05  # Velocity magnitude threshold
        unique_labels = np.unique(labels)
        stationary_groups = set()
        
        for label in unique_labels:
            group_mask = (labels == label)
            group_velocities = velocity_data[group_mask]
            mean_velocity = np.mean(group_velocities, axis=0)
            velocity_magnitude = np.linalg.norm(mean_velocity)
            
            if velocity_magnitude < stationary_threshold:
                stationary_groups.add(label)
        
        return stationary_groups
    
    # Group based on velocity similarity
    final_labels = get_velocity_groups(final_velocities)
    stationary_groups = detect_stationary_groups(final_velocities, final_labels)
    
    print(f"Groups found: {len(np.unique(final_labels))}")
    print(f"Stationary groups: {len(stationary_groups)}")
    if stationary_groups:
        print(f"Stationary group IDs: {stationary_groups}")
    
    # Plotting
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # Helper to draw cluster convex hulls
    def draw_cluster_hulls(data_2d, labels, velocity_data, stationary_set):
        unique_labels = sorted(set(labels))
        # Use a colormap for moving groups
        cmap = plt.get_cmap('tab10')
        
        for idx, k in enumerate(unique_labels):
            if k == -1: continue # Noise
            
            class_member_mask = (labels == k)
            xy = data_2d[class_member_mask]
            group_vels = velocity_data[class_member_mask]
            
            # Compute mean velocity for labeling
            mean_v = np.mean(group_vels, axis=0)
            v_mag = np.linalg.norm(mean_v)
            
            # Choose color based on whether group is stationary
            if k in stationary_set:
                color = 'red'
                style = '--'
                group_type = "Stationary"
            else:
                color = cmap(idx % 10)
                style = '-'
                group_type = "Moving"
            
            if len(xy) >= 3:
                try:
                    hull = ConvexHull(xy)
                    vertices = xy[hull.vertices]
                    vertices = np.append(vertices, [vertices[0]], axis=0)
                    
                    ax.plot(vertices[:,0], vertices[:,1], linestyle=style, color=color, linewidth=2, alpha=0.6)
                    ax.fill(vertices[:,0], vertices[:,1], color=color, alpha=0.15)
                except Exception as e:
                    print(f"Hull failed for cluster {k}: {e}")
                    pass
            elif len(xy) == 2:
                # Just draw a line between them
                ax.plot(xy[:,0], xy[:,1], linestyle=style, color=color, linewidth=2, alpha=0.6)

            # Label the group with its velocity magnitude
            # Place label at the centroid of the cluster in PCA space
            centroid = np.mean(xy, axis=0)
            ax.text(centroid[0], centroid[1], f"v={v_mag:.2f}", 
                    color=color, fontsize=10, fontweight='bold',
                    bbox=dict(facecolor='white', alpha=0.7, edgecolor=color, boxstyle='round,pad=0.3'))
            
            print(f"Group {k} ({group_type}): Agents {np.where(class_member_mask)[0]}, Mean Vel Mag: {v_mag:.4f}")

    # Draw hulls for velocity groups
    draw_cluster_hulls(final_pca, final_labels, final_velocities, stationary_groups)

    # Plot final positions
    ax.scatter(final_pca[:, 0], final_pca[:, 1], c='blue', alpha=0.7, edgecolors='k', label='Final Position')
    
    # Plot initial positions
    ax.scatter(initial_pca[:, 0], initial_pca[:, 1], c='red', marker='x', alpha=0.7, label='Initial Position')
    
    # Draw arrows from initial to final positions
    for i in range(len(final_pca)):
        ax.arrow(initial_pca[i, 0], initial_pca[i, 1], 
                  final_pca[i, 0] - initial_pca[i, 0], 
                  final_pca[i, 1] - initial_pca[i, 1],
                  color='gray', alpha=0.5, length_includes_head=True, 
                  head_width=0.05, head_length=0.1)
    
    ax.set_title('PCA Visualization with Velocity Threshold Grouping\n(Blue: Moving Groups, Red: Stationary Groups)')
    ax.set_xlabel('Principal Component 1')
    ax.set_ylabel('Principal Component 2')
    
    # Deduplicate legend labels
    handles, labels = ax.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    # Filter out cluster labels to keep legend clean? Or keep them? 
    # Let's keep just the main points and maybe one generic "Cluster" entry if possible, 
    # but simplest is to just show points. The title explains the circles.
    simple_legend = {k: v for k, v in by_label.items() if 'Position' in k}
    ax.legend(simple_legend.values(), simple_legend.keys())
    
    ax.grid(True)
    
    # Save the plot in the same directory as the CSV
    output_dir = os.path.dirname(csv_path)
    output_path = os.path.join(output_dir, 'pca_visualization.png')
    plt.savefig(output_path)
    print(f"PCA plot saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python visualize_pca.py <path_to_agent_positions.csv> [variance_threshold]")
    else:
        csv_path = sys.argv[1]
        variance_threshold = 0.1 # Default
        if len(sys.argv) >= 3:
            try:
                variance_threshold = float(sys.argv[2])
            except ValueError:
                print(f"Warning: Could not parse variance_threshold '{sys.argv[2]}'. Using default 0.1.")
        
        visualize_pca(csv_path, variance_threshold)
