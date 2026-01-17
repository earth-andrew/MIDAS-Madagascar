#!/usr/bin/env python3
"""Test script to see what region names are in the shapefile."""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import geopandas as gpd

# Load shapefile
shp_file = "../Data/Mada Boundary Files Admin 2/Admin_2_lat_lon.shp"
gdf = gpd.read_file(shp_file)

print("=== SHAPEFILE REGION NAMES ===\n")
print(f"Total regions: {len(gdf)}\n")
print(f"Available columns: {gdf.columns.tolist()}\n")

# Try to find region name column
name_col = None
for col in ['NAME', 'ADM2_NAME', 'REGION', 'name', 'adm2_name', 'region', 'ADM2_EN', 'NAME_2']:
    if col in gdf.columns:
        name_col = col
        print(f"Found name column: {name_col}\n")
        break

if name_col:
    print("All region names:")
    for idx, row in gdf.iterrows():
        print(f"  {idx}: {row[name_col]}")
else:
    print("ERROR: No region name column found!")
    print("Available columns:", gdf.columns.tolist())

