"""
Generate animation frames and create GIFs from MIDAS data.
"""

import imageio
import numpy as np
from pathlib import Path
import time


def generate_all_frames(mat_file, shp_file, output_dir, frame_prefix='frame', dpi=150):
    """
    Generate PNG frames for all timesteps.
    
    Parameters:
    -----------
    mat_file : str or Path
        MIDAS output .mat file
    shp_file : str or Path
        Madagascar shapefile
    output_dir : str or Path
        Directory to save frames
    frame_prefix : str
        Prefix for frame filenames
    dpi : int
        Resolution
        
    Returns:
    --------
    int : Number of frames generated
    """
    from extract_midas_data import load_midas_output, get_agent_locations_at_timestep, get_recent_migrations
    from load_madagascar_shapefile import load_shapefile, assign_region_colors, create_color_column
    from visualize_migration import create_frame
    
    print("\n=== GENERATING ANIMATION FRAMES ===\n")
    
    # Create output directory
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Load data
    print("Loading MIDAS data...")
    data = load_midas_output(mat_file)
    
    print("Loading shapefile...")
    gdf = load_shapefile(shp_file)
    
    print("Assigning colors...")
    color_map = assign_region_colors(gdf, data['locations'])
    gdf = create_color_column(gdf, color_map, data['locations'])
    
    # Generate frames
    num_timesteps = data['timesteps']
    print(f"\nGenerating {num_timesteps} frames...")
    print("Progress:")
    
    start_time = time.time()
    
    for t in range(1, num_timesteps + 1):
        # Extract data for this timestep
        agent_locs = get_agent_locations_at_timestep(data['agents'], t)
        migrations = get_recent_migrations(data['agents'], t, lookback=3)
        
        # Create frame
        frame_file = output_dir / f'{frame_prefix}_{t:03d}.png'
        
        create_frame(
            gdf=gdf,
            locations_df=data['locations'],
            agent_locs_df=agent_locs,
            migrations=migrations,
            timestep=t,
            total_steps=num_timesteps,
            output_path=frame_file,
            dpi=dpi
        )
        
        # Progress indicator
        if t % 5 == 0 or t == num_timesteps:
            elapsed = time.time() - start_time
            rate = t / elapsed
            remaining = (num_timesteps - t) / rate if rate > 0 else 0
            print(f"  Frame {t}/{num_timesteps} "
                  f"({100*t/num_timesteps:.1f}%) "
                  f"- {elapsed:.1f}s elapsed, ~{remaining:.1f}s remaining")
    
    total_time = time.time() - start_time
    print(f"\n✓ All frames generated in {total_time:.1f}s")
    print(f"  Output: {output_dir}")
    print(f"  Average: {total_time/num_timesteps:.2f}s per frame")
    
    return num_timesteps


def create_gif(frame_dir, output_gif, frame_prefix='frame', fps=3, loop=0):
    """
    Create animated GIF from PNG frames.
    
    Parameters:
    -----------
    frame_dir : str or Path
        Directory containing frames
    output_gif : str or Path
        Output GIF filename
    frame_prefix : str
        Prefix of frame filenames
    fps : int
        Frames per second
    loop : int
        Number of loops (0 = infinite)
        
    Returns:
    --------
    Path : Path to created GIF
    """
    print("\n=== CREATING ANIMATED GIF ===\n")
    
    frame_dir = Path(frame_dir)
    output_gif = Path(output_gif)
    
    # Find all frames
    frame_files = sorted(frame_dir.glob(f'{frame_prefix}_*.png'))
    
    if len(frame_files) == 0:
        raise FileNotFoundError(f"No frames found in {frame_dir} with prefix '{frame_prefix}'")
    
    print(f"Found {len(frame_files)} frames")
    print(f"Frame rate: {fps} FPS")
    print(f"Duration: {len(frame_files)/fps:.1f} seconds")
    
    # Read frames
    print("\nReading frames...")
    images = []
    target_shape = None
    
    for i, frame_file in enumerate(frame_files):
        img = imageio.imread(frame_file)
        
        # Ensure all frames have the same shape
        if target_shape is None:
            target_shape = img.shape
        elif img.shape != target_shape:
            # Resize to match target shape using PIL
            from PIL import Image
            pil_img = Image.fromarray(img)
            pil_img = pil_img.resize((target_shape[1], target_shape[0]), Image.Resampling.LANCZOS)
            img = np.array(pil_img)
        
        images.append(img)
        
        if (i + 1) % 10 == 0 or i == len(frame_files) - 1:
            print(f"  Loaded {i+1}/{len(frame_files)} frames")
    
    # Create GIF
    print("\nCreating GIF...")
    imageio.mimsave(
        output_gif,
        images,
        fps=fps,
        loop=loop
    )
    
    # Get file size
    file_size_mb = output_gif.stat().st_size / (1024 * 1024)
    
    print(f"\n✓ GIF created successfully!")
    print(f"  Output: {output_gif}")
    print(f"  Size: {file_size_mb:.2f} MB")
    print(f"  Frames: {len(frame_files)}")
    print(f"  Duration: {len(frame_files)/fps:.1f}s")
    
    return output_gif


def generate_animation(mat_file, shp_file, output_gif, 
                      frame_dir='frames_temp', fps=3, dpi=150,
                      keep_frames=False):
    """
    Complete workflow: generate frames and create GIF.
    
    Parameters:
    -----------
    mat_file : str or Path
        MIDAS output
    shp_file : str or Path
        Shapefile
    output_gif : str or Path
        Output GIF path
    frame_dir : str or Path
        Temporary frame directory
    fps : int
        Frames per second
    dpi : int
        Resolution
    keep_frames : bool
        Keep PNG frames after creating GIF
        
    Returns:
    --------
    Path : Path to GIF
    """
    frame_dir = Path(frame_dir)
    
    # Generate frames
    num_frames = generate_all_frames(
        mat_file=mat_file,
        shp_file=shp_file,
        output_dir=frame_dir,
        dpi=dpi
    )
    
    # Create GIF
    gif_path = create_gif(
        frame_dir=frame_dir,
        output_gif=output_gif,
        fps=fps
    )
    
    # Clean up frames if requested
    if not keep_frames:
        print("\nCleaning up frames...")
        for frame_file in frame_dir.glob('frame_*.png'):
            frame_file.unlink()
        
        # Remove directory if empty
        if not any(frame_dir.iterdir()):
            frame_dir.rmdir()
            print(f"  Removed {frame_dir}")
    
    return gif_path


def test_animation():
    """Test creating animation."""
    mat_file = Path('../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat')
    shp_file = Path('../Data/Madagascar_44_UrbanRural.shp')
    
    if not mat_file.exists() or not shp_file.exists():
        print("Test files not found")
        return
    
    # Create animation
    generate_animation(
        mat_file=mat_file,
        shp_file=shp_file,
        output_gif='test_animation.gif',
        frame_dir='test_frames',
        fps=3,
        dpi=100,  # Lower resolution for testing
        keep_frames=True
    )


if __name__ == '__main__':
    test_animation()

