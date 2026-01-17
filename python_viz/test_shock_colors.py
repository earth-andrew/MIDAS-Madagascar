#!/usr/bin/env python3
"""Test the shock color assignment."""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from visualize_shock_regions import assign_shock_colors
import geopandas as gpd

# Load shapefile
shp_file = "../Data/Mada Boundary Files Admin 2/Admin_2_lat_lon.shp"
gdf = gpd.read_file(shp_file)

print("=== TESTING SHOCK COLOR ASSIGNMENT ===\n")

# Assign colors
gdf = assign_shock_colors(gdf)

print("\n=== FINAL COLOR ASSIGNMENT ===\n")

orange_count = 0
grey_count = 0

for idx, row in gdf.iterrows():
    name = row['NAME_2']
    color = row['color']
    
    if color == '#FF8C00':
        print(f"🟠 ORANGE: {name}")
        orange_count += 1
    else:
        print(f"⚪ GREY:   {name}")
        grey_count += 1

print(f"\n=== SUMMARY ===")
print(f"🟠 Orange (shocked): {orange_count}")
print(f"⚪ Grey (non-shocked): {grey_count}")
print(f"Total: {len(gdf)}")

if orange_count == 6:
    print("\n✅ SUCCESS! All 6 drought regions correctly identified!")
else:
    print(f"\n❌ ERROR: Expected 6 orange regions, got {orange_count}")

