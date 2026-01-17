#!/usr/bin/env python3
"""
Batch create GIF animations for all MIDAS scenarios.

Usage:
    python batch_create_gifs.py
    
This will:
1. Find all *Run001*.json files in ../Outputs/
2. Create a GIF animation for each one
3. Save GIFs in the current directory
"""

import sys
from pathlib import Path
import subprocess

def main():
    print("\n=== BATCH GIF CREATION ===\n")
    
    # Configuration
    outputs_dir = Path(__file__).parent.parent / 'Outputs'
    shapefile = Path(__file__).parent.parent / 'Data' / 'Mada Boundary Files Admin 2' / 'Admin_2_lat_lon.shp'
    fps = 3
    dpi = 150
    
    # Verify shapefile exists
    if not shapefile.exists():
        print(f"❌ Shapefile not found: {shapefile}")
        return 1
    
    # Find all JSON files
    json_files = sorted(outputs_dir.glob('*Run001*.json'))
    
    if not json_files:
        print("❌ No *Run001*.json files found in Outputs/")
        print("\nTip: Export MATLAB files to JSON first using:")
        print("  In MATLAB: batch_export_for_python('Outputs/', '*Run001*.mat')")
        return 1
    
    print(f"Found {len(json_files)} scenario files:\n")
    for f in json_files:
        print(f"  - {f.name}")
    
    print("\n" + "="*60 + "\n")
    
    # Create GIF for each file
    success_count = 0
    
    for i, json_file in enumerate(json_files, 1):
        print(f"[{i}/{len(json_files)}] Processing: {json_file.name}")
        
        # Create GIF name from JSON filename
        gif_name = json_file.stem + '_animation.gif'
        gif_path = Path(__file__).parent / gif_name
        
        # Build command
        cmd = [
            sys.executable,
            'run_visualization.py',
            'animate',
            '--output', str(json_file),
            '--shapefile', str(shapefile),
            '--gif', gif_name,
            '--fps', str(fps),
            '--dpi', str(dpi)
        ]
        
        try:
            # Run the command
            result = subprocess.run(
                cmd,
                cwd=Path(__file__).parent,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0 and gif_path.exists():
                size_mb = gif_path.stat().st_size / (1024 * 1024)
                print(f"  ✓ Created: {gif_name} ({size_mb:.1f} MB)\n")
                success_count += 1
            else:
                print(f"  ✗ Failed to create GIF")
                if result.stderr:
                    print(f"  Error: {result.stderr[:200]}")
                print()
                
        except subprocess.TimeoutExpired:
            print(f"  ✗ Timeout (> 5 minutes)\n")
        except Exception as e:
            print(f"  ✗ Error: {e}\n")
    
    # Summary
    print("="*60)
    print(f"\n✓ Successfully created {success_count}/{len(json_files)} GIF animations\n")
    
    if success_count > 0:
        print("Output GIFs:")
        for gif in sorted(Path(__file__).parent.glob('*_animation.gif')):
            size_mb = gif.stat().st_size / (1024 * 1024)
            print(f"  - {gif.name} ({size_mb:.1f} MB)")
    
    print("\n=== DONE ===\n")
    
    return 0 if success_count == len(json_files) else 1


if __name__ == '__main__':
    sys.exit(main())

