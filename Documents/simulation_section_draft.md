# Numerical Simulations

**Authors**: CP and GJ

This section presents numerical simulations of the standard Cucker-Smale flocking model alongside its delayed and state-dependent delayed extensions. The main objective of these simulations is to investigate the quantitative and qualitative impacts of communication latencies on the emergence of self-organized behaviors, specifically comparing three cases:
1. **Standard Cucker-Smale Model (No Delay)**: Agents respond instantaneously to the state of their neighbors.
2. **Cucker-Smale Model with Fixed Delay**: Agents interact using a constant processing/communication lag $\tau$.
3. **Cucker-Smale Model with State-Dependent Delay**: The interaction delay $\tau_{ij}(t)$ is proportional to the spatial distance between the interacting agents, modeled as $\tau_{ij}(t) = \tau_{\text{factor}} \cdot \Vert \mathbf{x}_j(t) - \mathbf{x}_i(t) \Vert$.

The ordinary differential equations governing these models are solved numerically using the streamlined orchestrator script `run_comparison_only.m`, which implements Euler integration with a step size of $h = 0.5$. The simulations automatically terminate when the velocity deviation of the group falls below a specified convergence threshold $\epsilon$ (indicating global consensus), or when a maximum simulation time is reached. 

We present five distinct scenarios carefully selected to cover the interaction of delays with variables such as coupling strengths, initial configurations, spatial decay exponents, and flock separation.

---

## Scenario 1: Baseline Consensus (Small Delay, Moderate Interaction)

### 1. Purpose
This scenario serves as a control baseline to evaluate the model behaviors under realistic, low-latency communication conditions. The parameters represent a tight flock with small fixed delay and small distance-dependent delay scaling, under moderate interaction strength. This scenario is designed to verify that for small delays, the qualitative and quantitative behaviors of the three models are essentially identical, and that all three models converge smoothly to a single consensus state.
* **Important Parameters**: 
  * $N = 6$ agents
  * Step size $h = 0.5$
  * Interaction strength $\alpha = 0.25$
  * Decay exponent $\beta = 0.4$
  * Fixed delay $\tau = 0.04$
  * Delay factor $\tau_{\text{factor}} = 0.01$
  * Convergence threshold $\epsilon = 0.01$

### 2. Expectations
* **Global Consensus**: All three models successfully converge to a single, unified flock (global consensus).
* **Minimal Discrepancies**: Due to the small magnitude of the delay ($\tau = 0.04\text{s}$ and $\tau_{\text{factor}} = 0.01$), the trajectories and velocity curves of the Standard, Fixed Delay, and State-Dependent Delay models will be virtually indistinguishable.
* **Convergence Time**: The models will reach the stability threshold in approximately $50$ seconds ($T \approx 50.0\text{s}$).

### 3. MATLAB Code
```matlab
% Scenario 1: Baseline Consensus
x1 = [10.5, 12.2, 11.0, 13.5, 12.0, 14.2];
y1 = [10.2, 11.5, 13.0, 10.8, 12.4, 11.2];
z1 = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0];
vx1 = [1.2, 0.8, 1.1, 0.9, 1.0, 1.3];
vy1 = [1.0, 1.2, 0.9, 1.1, 1.0, 0.8];
vz1 = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
tau1 = 0.04 * ones(6,6);
tau_factor1 = 0.01;
alpha1 = 0.25;
beta1 = 0.4;
thresh1 = 0.01;

run_comparison_only(x1, y1, z1, vx1, vy1, vz1, 0.5, tau1, tau_factor1, alpha1, beta1, thresh1);
```

### 4. Real-World Analogues
* **Avian Dynamics (Tight Bird Flocks)**: A small flock of starlings or pigeons flying in close formation. The communication is visual and local; because the birds are close, the time it takes for a neighbor's movement cue to travel and be processed by another bird is negligible compared to the timescale of their flight adjustments.
* **Fish Schools**: A small cluster of fish (e.g., herrings) swimming together. They sense pressure variations through their lateral line system, where physical signals propagate through water almost instantaneously at small scales.
* **Swarm Robotics**: A group of autonomous drones flying in close proximity, sharing position and velocity vectors over a high-bandwidth local Wi-Fi or radio link, experiencing negligible packet latency.

---

## Scenario 2: Strong Interaction & Rapid Consensus (Chaotic Start)

### 1. Purpose
This scenario evaluates how the delay models behave when starting from a highly disorganized, chaotic state (where agents have large differences in initial positions and velocities) but interact under strong coupling forces. The goal is to determine if strong interactions can quickly pull a scattered system into consensus, overriding the minor latencies.
* **Important Parameters**:
  * $N = 6$ agents
  * Step size $h = 0.5$
  * High interaction strength $\alpha = 0.6$
  * Low communication decay $\beta = 0.2$ (retaining long-range communication)
  * Fixed delay $\tau = 0.01$
  * Delay factor $\tau_{\text{factor}} = 0.005$
  * Convergence threshold $\epsilon = 0.01$

### 2. Expectations
* **Rapid Consensus**: The high coupling coefficient ($\alpha=0.6$) and slow spatial decay ($\beta=0.2$) will quickly pull the agents together, achieving global consensus in roughly $55$ seconds ($T \approx 55.0\text{s}$).
* **Curved Trajectories**: Trajectories will exhibit sharp curves as the strong mutual attraction rapidly rotates the velocity vectors toward alignment.
* **Robustness to Chaotic Starts**: The models will behave similarly, demonstrating that small delays do not prevent or significantly delay consensus even under highly chaotic initial velocities.

### 3. MATLAB Code
```matlab
% Scenario 2: Strong Interaction & Rapid Consensus
x2 = [5.0, 25.0, 10.0, 20.0, 5.0, 25.0];
y2 = [5.0, 5.0, 15.0, 15.0, 25.0, 25.0];
z2 = [0.0, 10.0, 20.0, 0.0, 10.0, 20.0];
vx2 = [2.0, -2.0, 1.5, -1.5, 1.0, -1.0];
vy2 = [0.0, 2.0, -2.0, 1.0, -1.0, 0.5];
vz2 = [1.0, -1.0, 0.5, -0.5, 0.0, 2.0];
tau2 = 0.01 * ones(6,6);
tau_factor2 = 0.005;
alpha2 = 0.6;
beta2 = 0.2;
thresh2 = 0.01;

run_comparison_only(x2, y2, z2, vx2, vy2, vz2, 0.5, tau2, tau_factor2, alpha2, beta2, thresh2);
```

### 4. Real-World Analogues
* **Herding Mammals fleeing a Predator**: A dispersed group of zebras or wildebeests grazing in different directions. Upon detecting a predator, strong fear-driven behavioral coupling causes them to rapidly align their escape velocities.
* **Fish Schools under Attack**: A school of minnows scattered by a sudden splash. The high-risk environment stimulates strong alignment behaviors, causing them to aggregate and orient within fractions of a second.
* **Emergency Robotic Re-grouping**: A search-and-rescue drone swarm scattered across a zone that receives an emergency command to immediately gather at a specific GPS coordinate, executing rapid path corrections.

---

## Scenario 3: Widely Separated Groups & Multi-flocking (Cluster Split)

### 1. Purpose
This scenario tests the limits of cohesive interaction. It simulates a system with weak interaction strength, rapid spatial communication decay, and a large initial spatial separation between two groups of agents moving in opposite directions. The goal is to evaluate if the delay models preserve the "multi-flocking" behavior, where global consensus fails and the flock permanently splits into independent sub-clusters.
* **Important Parameters**:
  * $N = 6$ agents (split into two groups of 3)
  * Initial separation of $\approx 35$ units along the X-axis
  * Opposing initial velocities ($v_{x0} = -1.5$ vs. $+1.5$)
  * Low interaction strength $\alpha = 0.15$
  * High decay rate $\beta = 0.8$ (limiting interactions to close neighbors)
  * Moderate fixed delay $\tau = 0.15$
  * Delay factor $\tau_{\text{factor}} = 0.05$
  * Convergence threshold $\epsilon = 0.01$

### 2. Expectations
* **Multi-Flocking (Split)**: The two groups will fail to reach global consensus. Instead, the system will permanently split into two distinct sub-flocks moving in opposite directions.
* **Local Consensus**: The agents within each group of three will rapidly reach consensus with each other (local consensus) around $75$ to $80$ seconds.
* **Negligible Model Divergence**: The qualitative outcome of splitting and the final velocities of the clusters will remain nearly identical across all three models, as the large spatial gap makes cross-group interactions disappear quickly in all formulations.

### 3. MATLAB Code
```matlab
% Scenario 3: Multi-flocking (Cluster Split)
x3 = [2.0, 4.0, 6.0, 40.0, 42.0, 44.0];
y3 = [10.0, 12.0, 10.0, 10.0, 12.0, 10.0];
z3 = [5.0, 5.0, 5.0, 5.0, 5.0, 5.0];
vx3 = [-1.5, -1.5, -1.5, 1.5, 1.5, 1.5];
vy3 = [0.0, 0.2, -0.2, 0.0, 0.2, -0.2];
vz3 = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
tau3 = 0.15 * ones(6,6);
tau_factor3 = 0.05;
alpha3 = 0.15;
beta3 = 0.8;
thresh3 = 0.01;

run_comparison_only(x3, y3, z3, vx3, vy3, vz3, 0.5, tau3, tau_factor3, alpha3, beta3, thresh3);
```

### 4. Real-World Analogues
* **Migrating Herds splitting**: Two separate herds of caribou starting in separate valleys. Due to distance and the localized nature of mammal interactions, they move in opposing migration paths, remaining completely unaware of the other herd.
* **Separate Avian V-Formations**: Two distinct flocks of geese migrating south at different altitudes or locations. Even if they cross paths at a distance, their localized visual coupling prevents them from merging, maintaining their independent flocking dynamics.
* **Distributed Sensor Networks**: Decentralized sensor nodes in a smart city deployed on opposite sides of a large park. The nodes within each street block synchronize with their immediate neighbors but remain unsynchronized globally due to range limits.

---

## Scenario 4: Large-Delay Communication & Model Divergence

### 1. Purpose
This scenario is designed to test the systems under a large communication delay, showcasing the critical differences in convergence behaviors between the Fixed Delay and State-Dependent (SD) Delay formulations. It represents two opposing groups that start far apart but fly *towards* each other. Because the SD delay is proportional to distance, it dynamically shrinks as the groups converge. This provides a direct comparison of how spatial delay scaling affects consensus speed compared to constant lags.
* **Important Parameters**:
  * $N = 10$ agents (two groups of 5)
  * Initial separation of $\approx 60$ units along the Y-axis, moving towards each other
  * Large fixed delay $\tau = 2.5$
  * Large delay factor $\tau_{\text{factor}} = 0.15$
  * Convergence threshold $\epsilon = 0.02$

### 2. Expectations
* **Global Consensus achieved**: All three models eventually reach global consensus.
* **Significant Model Divergence**: The models will exhibit massive differences in convergence times:
  * **State-Dependent Delay**: Reaches consensus much faster ($T \approx 80.0\text{s}$) than the other models. As the two groups approach each other, the spatial distance shrinks, which automatically drives the interaction delay $\tau_{ij}(t)$ to near-zero. When they finally meet and align, they interact with negligible latency, facilitating rapid consensus.
  * **Fixed Delay**: Convergence is delayed ($T \approx 130.0\text{s}$). The agents are forced to interact with a constant $2.5$-second lag even when they are physically close, slowing down coordinate changes.
  * **Standard (No Delay)**: Reaches consensus at $T \approx 124.5\text{s}$. The delay in the SD model initially alters the approaching trajectories in a manner that increases interaction overlap, resulting in faster alignment than the standard model.

### 3. MATLAB Code
```matlab
% Scenario 4: Large-Delay Communication & Model Divergence
x4 = [-37.6673558868562, -32.7450154433168, -34.2996411787934, -35.598132060666, -34.9542204144967, ...
      -35.5239908699322, -38.5004247368936, -35.5713019431907, -36.6627330231352, -36.9584126103346];
y4 = [27.687196688672, 28.932885781368, 25.9947285282339, 31.9284588452633, 31.0401202029109, ...
      -30.0400557032851, -30.069542172057, -31.5963271691283, -27.9626294357428, -30.2664349590155];
z4 = zeros(1, 10);
vx4 = [3.14273491810642, 4.17569288421333, 3.38761447197371, 3.2054854846396, 3.35312320113229, ...
       3.07603687818103, 2.93993584937814, 4.76299984605915, 4.32774879644367, 3.65376757961913];
vy4 = [-3.62855917967603, -3.4327340152774, -3.08826705711573, -2.60429196918568, -3.66600221065762, ...
       1.83506642209746, 2.27545135358063, 3.1667554165329, 3.19567680221645, 3.22583970946412];
vz4 = zeros(1, 10);
tau4 = 2.5 * ones(10,10);
tau_factor4 = 0.15;
alpha4 = 0.25;
beta4 = 0.4;
thresh4 = 0.02;

run_comparison_only(x4, y4, z4, vx4, vy4, vz4, 0.5, tau4, tau_factor4, alpha4, beta4, thresh4);
```

### 4. Real-World Analogues
* **Autonomous Vehicles at an Intersection**: Two platoons of self-driving cars approaching an intersection from different roads. When far apart, wireless signal routing and network latency are high (represented by a large delay). As they enter the intersection, they transition to dedicated short-range communications (DSRC or C-V2X direct radio links), causing latency to drop to near-zero and allowing safe, rapid speed synchronization.
* **Insect Pheromone Communication**: Foraging ants searching a large area. Communication via pheromone diffusion is slow and subject to large environmental propagation delays across long distances. However, once they gather at a food source or the nest entrance, the physical distance drops, communication becomes instantaneous, and they coordinate behaviors rapidly.
* **Swarm Robotics**: A split team of search robots navigating a cavern. They communicate over long-range acoustic transceivers with high latency due to reflection and distance. When they converge to compile data, they switch to local high-frequency radio links, instantly eliminating lag and coordinating their next search phases.

---

## Scenario 5: Weak Interaction & Slow Convergence (Scenario 8)

### 1. Purpose
This scenario explores a challenging operational regime: weak interaction strength ($\alpha = 0.15$) combined with a very large communication delay ($\tau = 3.0$ and $\tau_{\text{factor}} = 0.20$). The goal is to study how weak coupling and massive delays induce oscillations and instability in flocking systems, and to see if the distance-dependent nature of state-dependent delay can act as a stabilizing mechanism as the group slowly aggregates.
* **Important Parameters**:
  * $N = 12$ agents
  * Weak interaction strength $\alpha = 0.15$
  * Moderate spatial decay $\beta = 0.3$
  * Very large fixed delay $\tau = 3.0$
  * Large delay factor $\tau_{\text{factor}} = 0.20$
  * Convergence threshold $\epsilon = 0.02$

### 2. Expectations
* **Oscillatory Convergence**: The combination of weak coupling and large communication lags will lead to pronounced velocity oscillations as agents constantly over-adjust based on outdated neighbor states.
* **Stabilizing Effect of SD Delay**: The State-Dependent Delay model will reach consensus significantly faster ($T \approx 145.0\text{s}$) than the Fixed Delay model ($T \approx 185.0\text{s}$) and the Standard model ($T \approx 179.5\text{s}$). As the scattered agents slowly align and draw closer together, the delay in the SD model shrinks, suppressing the velocity oscillations and stabilizing the system.
* **Fixed Delay Lag**: The Fixed Delay model will remain trapped in long-term oscillations due to the persistent $3.0$-second latency, leading to very slow convergence.

### 3. MATLAB Code
```matlab
% Scenario 5: Weak Interaction & Slow Convergence
x5 = [-0.204484892170982, -0.482894083214716, 0.638413478331004, 0.625717193274857, 33.2702401653511, ...
      34.9398974076075, 34.6702419615819, 36.2554145750575, -32.813468661921, -32.7814534047712, ...
      -36.7273056439774, -34.8452818177391];
y5 = [37.5717659127692, 37.7729985170265, 39.9863013437933, 43.0652606165695, -21.5393318275074, ...
      -19.2572423744799, -20.4511688045425, -17.7652877223711, -22.1781285901045, -19.9348850716701, ...
      -18.8949459577756, -17.7987795642383];
z5 = zeros(1, 12);
vx5 = [0.772105947751975, 0.0429655665877127, -0.745795155318805, -0.371150918629928, -3.53079086665999, ...
       -1.82477138799898, -3.30780094073345, -2.62596160814801, 2.90379074470587, 3.44430521271036, ...
       2.61757538171606, 2.29886551533062];
vy5 = [-4.71118796254575, -3.75590304507003, -4.08868757830941, -4.09802674390367, 2.70965507532127, ...
       2.14579218699209, 2.09890552673218, 2.79384954498703, 1.59776702182523, 2.3483122079248, ...
       2.41754408253634, 1.87814242981102];
vz5 = zeros(1, 12);
tau5 = 3.0 * ones(12,12);
tau_factor5 = 0.20;
alpha5 = 0.15;
beta5 = 0.3;
thresh5 = 0.02;

run_comparison_only(x5, y5, z5, vx5, vy5, vz5, 0.5, tau5, tau_factor5, alpha5, beta5, thresh5);
```

### 4. Real-World Analogues
* **Deep-Sea Robotic Swarms**: A fleet of autonomous underwater vehicles (AUVs) mapping a hydrothermal vent. Due to the low speed of acoustic waves in water, communication latency is extremely high (several seconds). The weak acoustic signals create slow coordination updates, but as the AUVs return to a central beacon to synchronize, their spatial clustering naturally mitigates the delay, stabilizing the swarm.
* **Distributed Sensor Networks in Forestry**: Sensor nodes scattered across a vast forest tracking wildlife migration. Data is routed over multi-hop, low-bandwidth links with large delays. Synchronization convergence is slow and oscillatory until nodes group their routing paths into localized clusters, reducing the effective delay.
* **Mammalian Infrasound Communication**: A herd of elephants moving through dense savannah terrain, using infrasonic calls to coordinate movement directions over miles. Because the sound waves take time to travel and the calls are spaced far apart (high lag), the alignment of their migration direction is slow and oscillatory, stabilizing only when the family units physically aggregate.
