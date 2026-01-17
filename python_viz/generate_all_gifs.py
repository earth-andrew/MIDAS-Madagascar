#!/usr/bin/env python3
"""
Generate GIFs for all 6 experiment runs with appropriate color schemes.

- Non-shock scenarios: Normal distinct region colors
- Shock scenarios: Orange shocked regions, grey others
- All scenarios: Different bubble colors for urban vs rural
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from extract_midas_data import load_midas_output, get_agent_locations_at_timestep, get_recent_migrations
from load_madagascar_shapefile import load_shapefile, assign_region_colors, create_color_column
from visualize_migration import create_frame
from visualize_shock_regions import assign_shock_colors, assign_shock_colors_from_locations
from create_animation import create_gif
import pandas as pd
import numpy as np
import time
import shutil


# Drought-affected regions in southern Madagascar
DROUGHT_REGIONS = [
    'ANDROY',
    'ANOSY', 
    'ATSIMO-ANDREFANA',
    'ATSIMO-ATSINANA',
    'VATOVAVY',
    'IHOROMBE'
]


def create_gif_for_scenario(json_file, shp_file, output_gif, fps=3, dpi=150):
    """
    Create GIF visualization for a single scenario.
    
    Automatically detects scenario type and applies appropriate color scheme:
    - Shock scenarios: Orange/grey regions
    - Non-shock scenarios: Normal distinct colors
    
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
    print(f"\n{'='*60}")
    print(f"Processing: {Path(json_file).name}")
    print(f"{'='*60}\n")
    
    # Load data
    print("Loading MIDAS data...")
    data = load_midas_output(json_file)
    
    # Check scenario metadata
    has_shock = data.get('meta', {}).get('has_shock', False)
    shock_type = data.get('meta', {}).get('shock_type', 'none')
    scenario_name = data.get('meta', {}).get('scenario', 'Unknown')
    
    print(f"  Scenario: {scenario_name}")
    print(f"  Has shock: {has_shock}")
    print(f"  Shock type: {shock_type}")
    
    # Load shapefile - use Admin_2 for shock scenarios (has NAME_2), 44-region for baseline
    locations_df = pd.DataFrame(data['locations'])
    
    if has_shock:
        # For shock scenarios, load Admin_2 to get region names, then map to 44 locations
        print("\nIdentifying shock regions...")
        # shp_file is ../Data/Madagascar_44_UrbanRural.shp, so parent is ../Data
        admin2_shp = Path(shp_file).parent / "Mada Boundary Files Admin 2" / "Admin_2_lat_lon.shp"
        
        # Load 44-region shapefile for visualization
        gdf = load_shapefile(shp_file)
        
        # Try to get drought region names from Admin_2 shapefile
        drought_region_names = set()
        if admin2_shp.exists():
            try:
                import geopandas as gpd
                import os
                os.environ['SHAPE_RESTORE_SHX'] = 'YES'
                admin2_gdf = gpd.read_file(str(admin2_shp))
                if 'NAME_2' in admin2_gdf.columns:
                    for idx, row in admin2_gdf.iterrows():
                        region_name = str(row['NAME_2']).upper()
                        for drought_region in DROUGHT_REGIONS:
                            if drought_region in region_name:
                                drought_region_names.add(region_name)
                                break
                    print(f"  Found {len(drought_region_names)} drought regions in Admin_2: {sorted(drought_region_names)}")
            except Exception as e:
                print(f"  Could not load Admin_2: {e}")
        
        # Map drought regions to 44 locations using ADM2_PCODE matching
        print("\nAssigning shock region colors (orange/grey)...")
        # Load Admin_2 if available for better matching
        admin2_gdf = None
        if admin2_shp.exists():
            try:
                import geopandas as gpd
                import os
                os.environ['SHAPE_RESTORE_SHX'] = 'YES'
                admin2_gdf = gpd.read_file(str(admin2_shp))
            except Exception:
                pass
        gdf = assign_shock_colors_from_locations(gdf, locations_df, admin2_gdf=admin2_gdf)
    else:
        # For baseline scenarios, use 44-region shapefile with normal colors
        print("\nLoading shapefile...")
        gdf = load_shapefile(shp_file)
        print("\nAssigning normal region colors...")
        color_map = assign_region_colors(gdf, locations_df)
        gdf = create_color_column(gdf, color_map, locations_df)
    
    # Create output directory for frames
    frame_dir = Path('frames_temp') / Path(json_file).stem
    frame_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n=== GENERATING FRAMES ===\n")
    
    total_steps = data['timesteps']
    start_time = time.time()
    
    for t in range(1, total_steps + 1):
        # Get data for this timestep
        agent_locs = get_agent_locations_at_timestep(data['agents'], t)
        migrations = get_recent_migrations(data['agents'], t, lookback=4)
        
        # Create frame
        frame_path = frame_dir / f'frame_{t:03d}.png'
        locations_full_df = pd.DataFrame(data['locations'])
        create_frame(
            gdf=gdf,
            locations_df=locations_full_df,
            agent_locs_df=agent_locs,
            migrations=migrations,
            timestep=t,
            total_steps=total_steps,
            output_path=frame_path,
            dpi=dpi,
            locations_full_df=locations_full_df
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
    print(f"  Average: {elapsed/total_steps:.2f}s per frame")
    
    # Create GIF with proper naming based on scenario
    print(f"\nCreating GIF animation...")
    
    # Use scenario short_name for filename if available
    short_name = data.get('meta', {}).get('short_name', '')
    if short_name:
        # Create properly named GIF file
        gif_dir = Path(output_gif).parent
        gif_filename = f"{short_name}.gif"
        output_gif_named = gif_dir / gif_filename
        print(f"  Using scenario name: {short_name}")
        print(f"  Output file: {gif_filename}")
    else:
        output_gif_named = Path(output_gif)
        print(f"  Using original filename: {Path(output_gif).name}")
    
    gif_path = create_gif(
        frame_dir=frame_dir,
        output_gif=output_gif_named,
        fps=fps,
        loop=0
    )
    
    # Clean up frames
    print(f"Cleaning up temporary frames...")
    shutil.rmtree(frame_dir)
    print(f"✓ Cleaned up temporary frames")
    
    return gif_path


def find_experiment_json_files(output_dir):
    """
    Find all experiment JSON files (Run001 through Run006).
    
    Parameters:
    -----------
    output_dir : str or Path
        Directory containing JSON files
        
    Returns:
    --------
    list of Path objects, sorted by run number
    """
    output_dir = Path(output_dir)
    
    # Find all JSON files matching the pattern
    json_files = list(output_dir.glob('Madagascar_test_sweep_Run*.json'))
    
    # Filter out design files
    json_files = [f for f in json_files if 'design' not in f.name]
    
    # Extract run numbers and sort
    run_data = []
    for f in json_files:
        # Extract run number from filename
        import re
        match = re.search(r'Run(\d+)', f.name)
        if match:
            run_num = int(match.group(1))
            run_data.append((run_num, f))
    
    # Sort by run number
    run_data.sort(key=lambda x: x[0])
    
    return [f for _, f in run_data]


def main():
    """Main function to generate GIFs for all 6 runs."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate GIFs for all experiment runs')
    parser.add_argument('--output-dir', default='../Outputs', 
                       help='Directory containing JSON files (default: ../Outputs)')
    parser.add_argument('--shapefile', default='../Data/Madagascar_44_UrbanRural.shp',
                       help='Path to Madagascar shapefile')
    parser.add_argument('--gif-dir', default='../Outputs',
                       help='Directory to save GIF files (default: ../Outputs)')
    parser.add_argument('--fps', type=int, default=3, help='Frames per second')
    parser.add_argument('--dpi', type=int, default=150, help='Resolution (DPI)')
    
    args = parser.parse_args()
    
    # Convert to Path objects
    output_dir = Path(args.output_dir).resolve()
    shp_file = Path(args.shapefile).resolve()
    gif_dir = Path(args.gif_dir).resolve()
    
    # Check directories exist
    if not output_dir.exists():
        print(f"Error: Output directory not found: {output_dir}")
        return 1
    
    if not shp_file.exists():
        print(f"Error: Shapefile not found: {shp_file}")
        return 1
    
    gif_dir.mkdir(parents=True, exist_ok=True)
    
    # Find all JSON files
    print(f"\n{'='*60}")
    print(f"FINDING EXPERIMENT FILES")
    print(f"{'='*60}\n")
    print(f"Searching in: {output_dir}")
    
    json_files = find_experiment_json_files(output_dir)
    
    if len(json_files) == 0:
        print("⚠ No experiment JSON files found!")
        print("  Make sure you've exported the .mat files to JSON first:")
        print("  In MATLAB: export_experiment_runs()")
        return 1
    
    print(f"\n✓ Found {len(json_files)} experiment files:")
    for i, f in enumerate(json_files, 1):
        print(f"  {i}. {f.name}")
    
    if len(json_files) != 6:
        print(f"\n⚠ Warning: Expected 6 files, found {len(json_files)}")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            return 1
    
    # Process each file
    print(f"\n{'='*60}")
    print(f"GENERATING GIFS")
    print(f"{'='*60}\n")
    
    success_count = 0
    error_count = 0
    error_files = []
    
    total_start = time.time()
    
    for i, json_file in enumerate(json_files, 1):
        try:
            # Load metadata to get scenario name for proper GIF naming
            import json as json_lib
            with open(json_file, 'r') as f:
                json_data = json_lib.load(f)
            short_name = json_data.get('meta', {}).get('short_name', '')
            
            # Generate output GIF filename - use short_name if available
            if short_name:
                gif_name = f"{short_name}.gif"
            else:
                gif_name = json_file.stem + '.gif'
            output_gif = gif_dir / gif_name
            
            print(f"\n[{i}/{len(json_files)}] Processing: {json_file.name}")
            print(f"  Scenario: {short_name if short_name else 'Unknown'}")
            print(f"  Output: {output_gif.name}\n")
            
            # Create GIF
            gif_path = create_gif_for_scenario(
                json_file=json_file,
                shp_file=shp_file,
                output_gif=output_gif,
                fps=args.fps,
                dpi=args.dpi
            )
            
            success_count += 1
            print(f"\n✓ Success: {gif_path.name}")
            
        except Exception as e:
            error_count += 1
            error_files.append(json_file.name)
            print(f"\n✗ ERROR processing {json_file.name}:")
            print(f"  {str(e)}")
            import traceback
            traceback.print_exc()
            continue
    
    total_elapsed = time.time() - total_start
    
    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"{'='*60}\n")
    
    print(f"Total files: {len(json_files)}")
    print(f"  ✓ Successful: {success_count}")
    print(f"  ✗ Errors: {error_count}")
    print(f"Total time: {total_elapsed:.1f}s ({total_elapsed/60:.1f} minutes)")
    
    if error_count > 0:
        print(f"\nFiles with errors:")
        for f in error_files:
            print(f"  - {f}")
    
    if success_count > 0:
        print(f"\n✓ GIF files saved to: {gif_dir}")
        print(f"\nGenerated GIFs:")
        for json_file in json_files:
            gif_name = json_file.stem + '.gif'
            gif_path = gif_dir / gif_name
            if gif_path.exists():
                size_mb = gif_path.stat().st_size / (1024 * 1024)
                print(f"  ✓ {gif_name} ({size_mb:.2f} MB)")
    
    return 0 if error_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())

