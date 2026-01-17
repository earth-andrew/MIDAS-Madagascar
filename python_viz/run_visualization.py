#!/usr/bin/env python3
"""
Command-line interface for MIDAS migration visualization.

Usage:
    python run_visualization.py test --output <file.mat> [--timestep N]
    python run_visualization.py animate --output <file.mat> --gif <output.gif> [options]
    python run_visualization.py batch --input-dir <dir> --pattern <pattern>
"""

import argparse
from pathlib import Path
import sys


def cmd_test(args):
    """Test with single frame."""
    from extract_midas_data import load_midas_output, get_agent_locations_at_timestep, get_recent_migrations
    from load_madagascar_shapefile import load_shapefile, assign_region_colors, create_color_column
    from visualize_migration import create_frame
    
    # Default paths
    shp_file = Path(args.shapefile) if args.shapefile else Path('../Data/Madagascar_44_UrbanRural.shp')
    timestep = args.timestep if args.timestep else 15
    
    print(f"\n=== TESTING SINGLE FRAME ===")
    print(f"Output file: {args.output}")
    print(f"Timestep: {timestep}")
    
    # Load data
    data = load_midas_output(args.output)
    gdf = load_shapefile(shp_file)
    color_map = assign_region_colors(gdf, data['locations'])
    gdf = create_color_column(gdf, color_map, data['locations'])
    
    # Get data for timestep
    agent_locs = get_agent_locations_at_timestep(data['agents'], timestep)
    migrations = get_recent_migrations(data['agents'], timestep, lookback=3)
    
    print(f"  Agents at timestep {timestep}: {len(agent_locs)}")
    print(f"  Recent migrations: {len(migrations)}")
    
    # Create frame
    output_path = args.save_frame if args.save_frame else 'test_frame.png'
    create_frame(
        gdf=gdf,
        locations_df=data['locations'],
        agent_locs_df=agent_locs,
        migrations=migrations,
        timestep=timestep,
        total_steps=data['timesteps'],
        output_path=output_path,
        dpi=args.dpi
    )
    
    print(f"\n✓ Test frame saved: {output_path}")


def cmd_animate(args):
    """Generate full animation."""
    from create_animation import generate_animation
    
    # Default paths
    shp_file = Path(args.shapefile) if args.shapefile else Path('../Data/Madagascar_44_UrbanRural.shp')
    frame_dir = Path(args.frames) if args.frames else Path('frames_temp')
    
    print(f"\n=== GENERATING ANIMATION ===")
    print(f"Output file: {args.output}")
    print(f"GIF output: {args.gif}")
    print(f"Frame directory: {frame_dir}")
    print(f"FPS: {args.fps}")
    print(f"DPI: {args.dpi}")
    
    # Generate animation
    gif_path = generate_animation(
        mat_file=args.output,
        shp_file=shp_file,
        output_gif=args.gif,
        frame_dir=frame_dir,
        fps=args.fps,
        dpi=args.dpi,
        keep_frames=args.keep_frames
    )
    
    print(f"\n✓ Animation complete: {gif_path}")


def cmd_batch(args):
    """Batch process multiple files."""
    from create_animation import generate_animation
    
    input_dir = Path(args.input_dir)
    pattern = args.pattern
    shp_file = Path(args.shapefile) if args.shapefile else Path('../Data/Madagascar_44_UrbanRural.shp')
    
    print(f"\n=== BATCH PROCESSING ===")
    print(f"Input directory: {input_dir}")
    print(f"Pattern: {pattern}")
    
    # Find matching files
    mat_files = sorted(input_dir.glob(pattern))
    
    if len(mat_files) == 0:
        print(f"No files found matching pattern: {pattern}")
        return
    
    print(f"Found {len(mat_files)} files")
    
    # Process each file
    for i, mat_file in enumerate(mat_files, 1):
        print(f"\n--- Processing {i}/{len(mat_files)}: {mat_file.name} ---")
        
        # Determine output name
        gif_name = mat_file.stem + '_animation.gif'
        frame_dir = Path(f'frames_{mat_file.stem}')
        
        try:
            generate_animation(
                mat_file=mat_file,
                shp_file=shp_file,
                output_gif=gif_name,
                frame_dir=frame_dir,
                fps=args.fps,
                dpi=args.dpi,
                keep_frames=args.keep_frames
            )
            print(f"✓ Completed: {gif_name}")
        except Exception as e:
            print(f"✗ Failed: {e}")
            continue
    
    print(f"\n✓ Batch processing complete: {len(mat_files)} files")


def main():
    parser = argparse.ArgumentParser(
        description='MIDAS Migration Visualization Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to run')
    
    # Test command
    test_parser = subparsers.add_parser('test', help='Test with single frame')
    test_parser.add_argument('--output', required=True, help='MIDAS output .mat file')
    test_parser.add_argument('--timestep', type=int, default=15, help='Timestep to render (default: 15)')
    test_parser.add_argument('--shapefile', help='Shapefile path (default: ../Data/Madagascar_44_UrbanRural.shp)')
    test_parser.add_argument('--save-frame', help='Output PNG filename (default: test_frame.png)')
    test_parser.add_argument('--dpi', type=int, default=150, help='Resolution (default: 150)')
    
    # Animate command
    animate_parser = subparsers.add_parser('animate', help='Generate full animation')
    animate_parser.add_argument('--output', required=True, help='MIDAS output .mat file')
    animate_parser.add_argument('--gif', required=True, help='Output GIF filename')
    animate_parser.add_argument('--shapefile', help='Shapefile path (default: ../Data/Madagascar_44_UrbanRural.shp)')
    animate_parser.add_argument('--frames', help='Frame directory (default: frames_temp)')
    animate_parser.add_argument('--fps', type=int, default=3, help='Frames per second (default: 3)')
    animate_parser.add_argument('--dpi', type=int, default=150, help='Resolution (default: 150)')
    animate_parser.add_argument('--keep-frames', action='store_true', help='Keep PNG frames after GIF creation')
    
    # Batch command
    batch_parser = subparsers.add_parser('batch', help='Batch process multiple files')
    batch_parser.add_argument('--input-dir', required=True, help='Directory containing .mat files')
    batch_parser.add_argument('--pattern', default='*_Run001.mat', help='File pattern (default: *_Run001.mat)')
    batch_parser.add_argument('--shapefile', help='Shapefile path (default: ../Data/Madagascar_44_UrbanRural.shp)')
    batch_parser.add_argument('--fps', type=int, default=3, help='Frames per second (default: 3)')
    batch_parser.add_argument('--dpi', type=int, default=150, help='Resolution (default: 150)')
    batch_parser.add_argument('--keep-frames', action='store_true', help='Keep PNG frames')
    
    args = parser.parse_args()
    
    if args.command == 'test':
        cmd_test(args)
    elif args.command == 'animate':
        cmd_animate(args)
    elif args.command == 'batch':
        cmd_batch(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()

