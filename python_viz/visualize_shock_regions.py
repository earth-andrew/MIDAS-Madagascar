#!/usr/bin/env python3
"""
Specialized visualization for drought shock scenario.
Shocked regions in ORANGE, non-shocked regions in GREY.
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from extract_midas_data import load_midas_output
from load_madagascar_shapefile import load_shapefile
from visualize_migration import create_frame
from create_animation import create_gif
import geopandas as gpd
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import time


# Drought-affected regions in southern Madagascar
# Names must match the shapefile NAME_2 column
DROUGHT_REGIONS = [
    'ANDROY',
    'ANOSY', 
    'ATSIMO-ANDREFANA',
    'ATSIMO-ATSINANA',  # Note: ONE 'n' in shapefile, not two
    'VATOVAVY',  # This will match "Vatovavy Fitovinany"
    'IHOROMBE'
]


def assign_shock_colors(gdf):
    """
    Assign orange to drought-shocked regions, grey to others.
    Matches regions by NAME_2 column in shapefile (original approach).
    
    Parameters:
    -----------
    gdf : geopandas.GeoDataFrame
        Shapefile data with NAME_2 column
        
    Returns:
    --------
    geopandas.GeoDataFrame with 'color' column
    """
    print("\n=== ASSIGNING SHOCK REGION COLORS (from shapefile NAME_2) ===")
    print(f"Total regions: {len(gdf)}")
    
    # Check available column names
    print(f"\nAvailable columns: {gdf.columns.tolist()}")
    
    # Try to find region name column
    name_col = None
    for col in ['NAME_2', 'NAME', 'ADM2_NAME', 'REGION', 'name', 'adm2_name', 'region']:
        if col in gdf.columns:
            name_col = col
            break
    
    if name_col is None:
        print("Warning: Could not find region name column, falling back to location-based matching")
        return None  # Signal to use location-based matching
    
    print(f"Using column: {name_col}")
    
    # Assign colors
    shocked_count = 0
    colors = []
    
    for idx, row in gdf.iterrows():
        region_name = str(row[name_col]).upper()
        
        # Check if this region is in drought-affected list
        is_shocked = any(drought_region in region_name for drought_region in DROUGHT_REGIONS)
        
        if is_shocked:
            colors.append('#FF8C00')  # Dark orange for shocked regions
            shocked_count += 1
            print(f"  Shocked: {region_name}")
        else:
            colors.append('#CCCCCC')  # Grey for non-shocked regions
    
    gdf['color'] = colors
    
    print(f"\nShocked regions: {shocked_count}")
    print(f"Non-shocked regions: {len(gdf) - shocked_count}")
    
    return gdf


def assign_shock_colors_from_locations(gdf, locations_df, admin2_gdf=None):
    """
    Assign orange to drought-shocked regions, grey to others.
    Matches regions by mapping Admin_2 NAME_2 regions to 44 locations via ADM2_PCODE.
    
    If admin2_gdf is provided, uses NAME_2 matching to find drought regions,
    then maps those to 44 locations by matching ADM2_PCODE.
    
    Parameters:
    -----------
    gdf : geopandas.GeoDataFrame
        Shapefile data (44 regions)
    locations_df : pandas.DataFrame
        Location data with ADM2_PCODE and URBAN_RURAL columns
    admin2_gdf : geopandas.GeoDataFrame, optional
        Admin_2 shapefile with NAME_2 and ADM2_PCODE columns
        
    Returns:
    --------
    geopandas.GeoDataFrame with 'color' column
    """
    print("\n=== ASSIGNING SHOCK REGION COLORS ===")
    print(f"Total regions: {len(gdf)}")
    print(f"Total locations: {len(locations_df)}")
    
    # Create mapping: location_id -> base ADM2_PCODE
    location_base_codes = {}
    for idx, row in locations_df.iterrows():
        location_id = row['location_id']
        pcode = str(row.get('ADM2_PCODE', ''))
        
        # Extract base code (remove -U or -R suffix)
        if pcode.endswith('-U') or pcode.endswith('-R'):
            base_code = pcode[:-2]  # Remove '-U' or '-R'
        else:
            base_code = pcode
        
        location_base_codes[location_id] = base_code
    
    # Find drought-affected base codes
    drought_base_codes = set()
    
    if admin2_gdf is not None and 'ADM2_PCODE' in admin2_gdf.columns and 'NAME_2' in admin2_gdf.columns:
        # Use Admin_2 shapefile to find drought regions by NAME_2, then match by ADM2_PCODE
        print("  Using Admin_2 shapefile to identify drought regions...")
        for idx, row in admin2_gdf.iterrows():
            region_name = str(row['NAME_2']).upper()
            admin2_pcode = str(row.get('ADM2_PCODE', ''))
            
            # Check if this Admin_2 region is a drought region
            is_drought = any(drought_region in region_name for drought_region in DROUGHT_REGIONS)
            
            if is_drought:
                # Extract base code from Admin_2 ADM2_PCODE (might be different format)
                # Try to match with our location base codes
                admin2_base = admin2_pcode
                if admin2_pcode.endswith('-U') or admin2_pcode.endswith('-R'):
                    admin2_base = admin2_pcode[:-2]
                
                # Find all locations that match this base code
                for loc_id, loc_base in location_base_codes.items():
                    if loc_base == admin2_base or admin2_pcode.startswith(loc_base) or loc_base.startswith(admin2_base):
                        drought_base_codes.add(loc_base)
                        print(f"    Matched {region_name} ({admin2_pcode}) to location {loc_id} ({loc_base})")
    
    # Fallback: use region code calculation if Admin_2 matching didn't work
    if len(drought_base_codes) == 0:
        print("  Using region code calculation as fallback...")
        for location_id, base_code in location_base_codes.items():
            if len(base_code) >= 7 and base_code.startswith('MDG'):
                try:
                    province = int(base_code[3:5])
                    district = int(base_code[5:7])
                    region_code = province * 10 + district
                    
                    if region_code in [15, 19, 20, 21, 22, 24]:
                        drought_base_codes.add(base_code)
                except (ValueError, IndexError):
                    pass
    
    print(f"Found {len(drought_base_codes)} drought-affected base codes: {sorted(drought_base_codes)}")
    
    # Assign colors based on location_id (1-based, matching gdf index)
    colors = []
    shocked_count = 0
    
    for i in range(len(gdf)):
        location_id = i + 1  # 1-based location ID
        base_code = location_base_codes.get(location_id, '')
        
        # Check if this location's base code is in drought regions
        is_shocked = base_code in drought_base_codes
        
        if is_shocked:
            colors.append('#FF8C00')  # Dark orange for shocked regions
            shocked_count += 1
            pcode = locations_df[locations_df['location_id'] == location_id]['ADM2_PCODE'].iloc[0] if len(locations_df[locations_df['location_id'] == location_id]) > 0 else 'N/A'
            print(f"  Shocked location {location_id}: {pcode} (base: {base_code})")
        else:
            colors.append('#CCCCCC')  # Grey for non-shocked regions
    
    gdf['color'] = colors
    
    print(f"\nShocked regions: {shocked_count}")
    print(f"Non-shocked regions: {len(gdf) - shocked_count}")
    
    return gdf


def create_shock_visualization(json_file, shp_file, output_gif, fps=3, dpi=150):
    """
    Create GIF visualization with orange shocked regions and grey non-shocked.
    
    Parameters:
    -----------
    json_file : str or Path
        Path to JSON file exported from MATLAB
    shp_file : str or Path
        Path to Madagascar shapefile
    output_gif : str or Path
        Output GIF filename
    fps : int
        Frames per second
    dpi : int
        Resolution
    """
    print("\n=== CREATING SHOCK SCENARIO VISUALIZATION ===\n")
    
    # Load data
    print("Loading MIDAS data...")
    data = load_midas_output(json_file)
    
    print("\nLoading shapefile...")
    gdf = load_shapefile(shp_file)
    
    # Assign shock colors
    gdf = assign_shock_colors(gdf)
    
    # Create output directory for frames
    frame_dir = Path('frames_shock_temp')
    frame_dir.mkdir(exist_ok=True)
    
    print(f"\n=== GENERATING FRAMES ===\n")
    
    from extract_midas_data import get_agent_locations_at_timestep, get_recent_migrations
    
    total_steps = data['timesteps']
    start_time = time.time()
    
    for t in range(1, total_steps + 1):
        # Get data for this timestep
        agent_locs = get_agent_locations_at_timestep(data['agents'], t)
        migrations = get_recent_migrations(data['agents'], t, lookback=4)
        
        # Create frame
        frame_path = frame_dir / f'frame_{t:03d}.png'
        create_frame(
            gdf=gdf,
            locations_df=data['locations'],
            agent_locs_df=agent_locs,
            migrations=migrations,
            timestep=t,
            total_steps=total_steps,
            output_path=frame_path,
            dpi=dpi
        )
        
        # Progress update
        if t % 5 == 0 or t == total_steps:
            elapsed = time.time() - start_time
            avg_time = elapsed / t
            remaining = avg_time * (total_steps - t)
            print(f"  Frame {t}/{total_steps} ({t/total_steps*100:.1f}%) - "
                  f"{elapsed:.1f}s elapsed, ~{remaining:.1f}s remaining")
    
    elapsed = time.time() - start_time
    print(f"\n✓ All frames generated in {elapsed:.1f}s")
    print(f"  Output: {frame_dir}")
    print(f"  Average: {elapsed/total_steps:.2f}s per frame")
    
    # Create GIF
    print(f"\nCreating GIF animation...")
    gif_path = create_gif(
        frame_dir=frame_dir,
        output_gif=Path(output_gif),
        fps=fps,
        loop=0
    )
    
    # Clean up frames
    import shutil
    shutil.rmtree(frame_dir)
    print(f"✓ Cleaned up temporary frames")
    
    return gif_path


def main():
    """Command-line interface."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Visualize drought shock scenario')
    parser.add_argument('--output', required=True, help='Input JSON file')
    parser.add_argument('--shapefile', required=True, help='Madagascar shapefile')
    parser.add_argument('--gif', required=True, help='Output GIF filename')
    parser.add_argument('--fps', type=int, default=3, help='Frames per second')
    parser.add_argument('--dpi', type=int, default=150, help='Resolution (DPI)')
    
    args = parser.parse_args()
    
    gif_path = create_shock_visualization(
        json_file=args.output,
        shp_file=args.shapefile,
        output_gif=args.gif,
        fps=args.fps,
        dpi=args.dpi
    )
    
    print(f"\n✓ Shock scenario visualization complete!")
    print(f"  Output: {gif_path}")


if __name__ == '__main__':
    main()

