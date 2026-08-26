"""
combine_scenario_images.py
Combines the final_comparison_visual.png (left) and comparison_pca.png (right)
for each of the Scenario folders in the output directory.
Saves the combined image as ScenarioN.png in the ScenariosCombined folder.

Usage:
  py combine_scenario_images.py            -- processes all Scenario folders
  py combine_scenario_images.py 11         -- processes only Scenario11
  py combine_scenario_images.py 1 5 11     -- processes specific scenarios
"""

import os
import sys
from PIL import Image

import os
import sys
from PIL import Image

# --- Paths ---
base_output = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "output")
combined_dir = os.path.join(base_output, "ScenariosCombined")
os.makedirs(combined_dir, exist_ok=True)

PADDING = 20                      # pixels of white space between the two images
BACKGROUND = (255, 255, 255, 255) # white background (RGBA)

def resize_to_height(img, height):
    ratio = height / img.height
    new_w = int(img.width * ratio)
    return img.resize((new_w, height), Image.LANCZOS)

def combine_scenario_folder(scenario_folder, out_name):
    traj_path = os.path.join(scenario_folder, "final_comparison_visual.png")
    if not os.path.exists(traj_path):
        traj_path = os.path.join(scenario_folder, "final_comparison_visual_clean.png")

    pca_path  = os.path.join(scenario_folder, "comparison_pca.png")

    if not os.path.exists(traj_path):
        print(f"[SKIP] {out_name}: missing trajectory visual PNG")
        return
    if not os.path.exists(pca_path):
        print(f"[SKIP] {out_name}: missing comparison_pca.png")
        return

    img_traj = Image.open(traj_path).convert("RGBA")
    img_pca  = Image.open(pca_path).convert("RGBA")

    # Match heights
    target_height = max(img_traj.height, img_pca.height)
    img_traj = resize_to_height(img_traj, target_height)
    img_pca  = resize_to_height(img_pca,  target_height)

    total_width  = img_traj.width + PADDING + img_pca.width

    combined = Image.new("RGBA", (total_width, target_height), BACKGROUND)
    combined.paste(img_traj, (0, 0))
    combined.paste(img_pca,  (img_traj.width + PADDING, 0))

    out_path = os.path.join(combined_dir, f"{out_name}.png")
    combined.convert("RGB").save(out_path, "PNG")
    print(f"[OK] Saved {out_name}.png  ({total_width}x{target_height} px)  ->  {out_path}")

# Determine which scenarios to process
search_dirs = [base_output]
paper_dir = os.path.join(base_output, "PaperScenarios")
if os.path.exists(paper_dir):
    search_dirs.append(paper_dir)

for sdir in search_dirs:
    if len(sys.argv) > 1:
        indices = [int(a) for a in sys.argv[1:]]
        for i in indices:
            scen_path = os.path.join(sdir, f"Scenario{i}")
            if os.path.exists(scen_path):
                combine_scenario_folder(scen_path, f"Scenario{i}")
    else:
        for name in sorted(os.listdir(sdir)):
            scen_path = os.path.join(sdir, name)
            if name.startswith("Scenario") and os.path.isdir(scen_path):
                combine_scenario_folder(scen_path, name)

print(f"\nDone. Combined images saved to: {combined_dir}")

