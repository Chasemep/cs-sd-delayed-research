# Cucker-Smale Flocking Research (Delay & State-Dependent Delay)

This repository contains MATLAB and Python simulations comparing the standard Cucker-Smale model with fixed-delay and state-dependent delay variations. The research focuses on how communication delays between agents affect consensus and flocking behavior.

## Introduction
The Cucker-Smale model describes the evolution of a flock of $N$ agents. Each agent $i$ adjusts its velocity based on a weighted average of the differences between its velocity and the velocities of its neighbors.

## Mathematical Models

### 1. Standard Cucker-Smale (No Delay)
In the standard model, agents respond instantaneously to the states of their neighbors. The evolution of velocity $\mathbf{v}_i$ for agent $i$ is given by:

$$\frac{d\mathbf{v}_i(t)}{dt} = \frac{\alpha}{N} \sum_{j=1}^{N} \psi(\Vert \mathbf{x}_j(t) - \mathbf{x}_i(t) \Vert) (\mathbf{v}_j(t) - \mathbf{v}_i(t))$$

where the communication weight (influence function) is:

$$\psi(r) = \frac{1}{(1 + r^2)^{\beta}}$$

### 2. Cucker-Smale with Fixed Delay
This model introduces a constant time delay $\tau_{ij}$ in the interactions, representing the time required for information to travel or be processed.

$$\frac{d\mathbf{v}_i(t)}{dt} = \frac{\alpha}{N} \sum_{j=1}^{N} \psi(\Vert \mathbf{x}_j(t-\tau_{ij}) - \mathbf{x}_i(t-\tau_{ij}) \Vert) (\mathbf{v}_j(t-\tau_{ij}) - \mathbf{v}_i(t))$$

### 3. Cucker-Smale with State-Dependent Delay
In this advanced variation, the delay $\tau_{ij}$ is not constant but depends on the current distance between agents, reflecting real-world scenarios where communication latency increases with distance.

$$\tau_{ij}(t) = \tau_{factor} \cdot \Vert \mathbf{x}_j(t) - \mathbf{x}_i(t) \Vert$$

The velocity update follows:

$$\frac{d\mathbf{v}_i(t)}{dt} = \frac{\alpha}{N} \sum_{j=1}^{N} \psi(\Vert \mathbf{x}_j(t-\tau_{ij}(t)) - \mathbf{x}_i(t) \Vert) (\mathbf{v}_j(t-\tau_{ij}(t)) - \mathbf{v}_i(t))$$

## Variable Definitions

| Variable | LaTeX Symbol | Mathematical Meaning | Used In Models | Implementation File Variable |
| :--- | :--- | :--- | :--- | :--- |
| **Couplings** | $\alpha$ | Interaction strength / Gain factor | All | `alpha` |
| **Decay Rate** | $\beta$ | Power-law exponent for communication decay | All | `beta` |
| **Delay** | $\tau_{ij}$ | Time delay in interaction between $i$ and $j$ | Delay, SD-Delay | `tau` (fixed) or `tau_ij` (calculated) |
| **Delay Factor** | $\tau_{factor}$ | Scaling factor for distance-to-delay conversion | SD-Delay | `tau_factor` |
| **Positions** | $\mathbf{x}_i$ | Position vector of agent $i$ | All | `x`, `y`, `z` |
| **Velocities** | $\mathbf{v}_i$ | Velocity vector of agent $i$ | All | `vx`, `vy`, `vz` |
| **Time Step** | $h$ | Incremental step for Euler integration | All | `h` |
| **Influence** | $\psi(r)$ | Communication weight function | All | `phi` |
| **Threshold** | $\epsilon$ | Convergence stability threshold | All | `convergence_thresh` |

## Project Structure

### Core Models (`.m` files)
- `cs_model_no_delay.m`: Standard Cucker-Smale simulation logic.
- `cs_model_fixed_delay.m`: Simulation with constant user-defined delays.
- `cs_model_state_dependent_delay.m`: Simulation where delay is proportional to agent distance.

### Runner Scripts
- `run_simulation_no_delay.m`: Entry point for standard simulation.
- `run_simulation_fixed_delay.m`: Entry point for fixed delay simulation.
- `run_simulation_state_dependent_delay.m`: Entry point for SD-delay simulation.
- `run_comparison_only.m`: Runs all three models and produces comparative data.

### Visualization & Analysis
- `generate_simulation_video.m`: Create animations of the flocking behavior.
- `visualize_pca.py`: Python script for Principal Component Analysis on the results.
- `compare_pca.py`: Compares PCA results across different delay scenarios.

## Usage

The primary entry point for conducting comparative research is the `run_comparison_only.m` script. This orchestrator runs all three model variations (No-Delay, Fixed-Delay, and State-Dependent Delay) and automatically generates comparative CSV data, a side-by-side comparison video, and a PCA stability analysis.

### Function Signature
```matlab
run_comparison_only(x0, y0, z0, vx0, vy0, vz0, h, tau, tau_factor, alpha, beta, convergence_thresh)
```

| Argument | Description |
| :--- | :--- |
| `x0, y0, z0` | Initial position vectors for $N$ agents. |
| `vx0, vy0, vz0` | Initial velocity vectors for $N$ agents. |
| `h` | Integration time step (e.g., 0.5). |
| `tau` | $N \times N$ matrix of fixed delays (used in Fixed-Delay model). |
| `tau_factor` | Scaling constant for distance-to-delay conversion (used in SD-Delay model). |
| `alpha` | Interaction strength constant. |
| `beta` | Communication decay exponent. |
| `convergence_thresh` | Stability threshold for auto-stopping the simulation. |

### Example Simulation
Copy and paste the following code into your MATLAB Command Window to run a benchmark simulation with 10 agents divided into two opposing groups:

```matlab
% 1. Setup Initial Conditions (10 agents)
x = [5+rand(1,5), 15+rand(1,5)]; 
y = 10+rand(1,10); 
z = 10+rand(1,10); 
vx = [ones(1,5), -ones(1,5)]; 
vy = zeros(1,10); 
vz = zeros(1,10);

% 2. Define Parameters
h = 0.5;
tau = 0.05 * rand(10,10); % Random fixed delays up to 0.05s
tau_factor = 0.01;        % SD Delay scaling
alpha = 0.3;              % Interaction strength
beta = 0.4;               % Decay rate
thresh = 0.1;             % Convergence threshold

% 3. Run Comparison
run_comparison_only(x, y, z, vx, vy, vz, h, tau, tau_factor, alpha, beta, thresh)
```

### Post-Simulation Analysis
Once the simulation completes:
1. View the comparison video in the generated `output/comp_only_...` directory.
2. Run `compare_pca.py` (automatically called by MATLAB) to see the stability plot.
3. Access individual agent logs in the `.csv` files for further statistical analysis.
