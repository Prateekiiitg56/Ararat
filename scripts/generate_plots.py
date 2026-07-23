import matplotlib.pyplot as plt
import numpy as np
import csv
import os

# Set professional font and style settings
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 10,
    'axes.labelsize': 10,
    'axes.titlesize': 11,
    'xtick.labelsize': 9,
    'ytick.labelsize': 9,
    'legend.fontsize': 9,
    'grid.alpha': 0.3,
    'grid.linestyle': '--'
})

# Locate the CSV file dynamically (prefer scripts/ folder, fallback if run from within scripts/)
search_paths = [
    'scripts/evaluation_metrics.csv',
    'evaluation_metrics.csv',
    '../scripts/evaluation_metrics.csv',
    '../../scripts/evaluation_metrics.csv'
]
csv_path = None
for path in search_paths:
    if os.path.exists(path):
        csv_path = path
        break

if csv_path is None:
    raise FileNotFoundError("Could not find scripts/evaluation_metrics.csv in search paths.")

# Load data from the CSV file
segments = []
ararat_bitrates = []
ararat_stalls = []
centralized_bitrates = []
centralized_stalls = []
core_cost = 15.0
edge_cost = 8.0

with open(csv_path, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        segments.append(int(row['segment']))
        ararat_bitrates.append(float(row['ararat_bitrate']))
        ararat_stalls.append(float(row['ararat_stall']))
        centralized_bitrates.append(float(row['centralized_bitrate']))
        centralized_stalls.append(float(row['centralized_stall']))
        core_cost = float(row['core_cost'])
        edge_cost = float(row['edge_cost'])

segments = np.array(segments)
ararat_bitrates = np.array(ararat_bitrates)
ararat_stalls = np.array(ararat_stalls)
centralized_bitrates = np.array(centralized_bitrates)
centralized_stalls = np.array(centralized_stalls)

alpha = 1.0
beta = 1.0
gamma = 4.3

def calculate_qoe(bitrates, stalls):
    qoe_scores = []
    prev_r = 0.0
    for r, t in zip(bitrates, stalls):
        safe_r = r if r > 0 else 1.0
        val = alpha * np.log(safe_r)
        if prev_r > 0:
            safe_prev_r = prev_r if prev_r > 0 else 1.0
            val -= beta * np.abs(np.log(safe_r) - np.log(safe_prev_r))
        val -= gamma * t
        qoe_scores.append(val)
        prev_r = safe_r
    return qoe_scores


ararat_qoe = calculate_qoe(ararat_bitrates, ararat_stalls)
centralized_qoe = calculate_qoe(centralized_bitrates, centralized_stalls)

# Create a figure with 2 subplots (1 row, 2 columns)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(8.0, 1.95))

# Subplot 1: QoE Comparison over segments
ax1.plot(segments, ararat_qoe, marker='o', linewidth=1.5, color='#1f77b4', label='Ararat (Edge)')
ax1.plot(segments, centralized_qoe, marker='s', linewidth=1.5, color='#d62728', linestyle='--', label='Centralized (Core)')
ax1.set_xlabel('Execution Segment')
ax1.set_ylabel('Quality of Experience (QoE)')
ax1.set_title('(a) QoE Performance Stability')
ax1.set_xticks(segments)
ax1.grid(True)
ax1.legend(loc='lower left')

# Subplot 2: Network Cost Bar Chart
categories = ['Centralized\nCore-Served', 'Ararat\nEdge-Served']
costs = [core_cost, edge_cost]
bars = ax2.bar(categories, costs, color=['#d62728', '#1f77b4'], width=0.45)
ax2.set_ylabel('Operational Cost (Units)')
ax2.set_title('(b) Core Network Cost')
ax2.set_ylim(0, 18)
ax2.grid(True, axis='y')

# Add values on top of the bars
for bar in bars:
    height = bar.get_height()
    ax2.annotate(f'{height:.1f}',
                xy=(bar.get_x() + bar.get_width() / 2, height),
                xytext=(0, 3),  # 3 points vertical offset
                textcoords="offset points",
                ha='center', va='bottom', fontsize=9, fontweight='bold')

plt.tight_layout()

# Locate/determine output directory (prefer scripts/ folder, fallback if run from within scripts/)
plot_dir = 'scripts'
if not os.path.exists(plot_dir):
    if os.path.exists('../scripts'):
        plot_dir = '../scripts'
    else:
        plot_dir = '.'

plot_filename = os.path.join(plot_dir, 'evaluation_results.pdf')
plt.savefig(plot_filename, bbox_inches='tight')
print(f"Successfully generated {plot_filename} from {csv_path}")

