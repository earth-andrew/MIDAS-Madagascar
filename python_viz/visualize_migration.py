"""
Create individual visualization frames for MIDAS migration data.
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyArrowPatch
import numpy as np
from pathlib import Path


def create_frame(gdf, locations_df, agent_locs_df, migrations, timestep, total_steps, 
                 output_path=None, dpi=150, locations_full_df=None):
    """
    Create a single visualization frame.
    
    Parameters:
    -----------
    gdf : geopandas.GeoDataFrame
        Shapefile with 'color' column
    locations_df : pandas.DataFrame
        Location coordinates
    agent_locs_df : pandas.DataFrame
        Agent locations at this timestep (columns: agent_id, location, lon, lat)
    migrations : list of dict
        Recent migrations with keys: from_location, to_location, count, recency
    timestep : int
        Current timestep
    total_steps : int
        Total number of timesteps
    output_path : str or Path, optional
        Where to save PNG (if None, displays instead)
    dpi : int
        Resolution for saved image
        
    Returns:
    --------
    matplotlib.figure.Figure
    """
    # Create figure (16:9 aspect ratio)
    fig, ax = plt.subplots(figsize=(19.20, 10.80), dpi=dpi)
    
    # Set light background
    ax.set_facecolor('#F5F5F8')
    fig.patch.set_facecolor('white')
    
    # Draw map regions with subtle colors
    draw_map_regions(ax, gdf)
    
    # Draw agent markers (use full locations_df if provided for URBAN_RURAL info)
    if locations_full_df is not None:
        draw_agent_markers(ax, locations_full_df, agent_locs_df)
    else:
        draw_agent_markers(ax, locations_df, agent_locs_df)
    
    # Draw migration arrows
    if len(migrations) > 0:
        draw_migration_arrows(ax, locations_df, migrations)
    
    # Add title and info
    add_title_and_info(ax, timestep, total_steps, len(agent_locs_df))
    
    # Clean up axes
    ax.set_aspect('equal')
    ax.axis('off')
    plt.tight_layout(pad=0.5)
    
    # Save or display
    if output_path:
        plt.savefig(output_path, dpi=dpi, bbox_inches='tight', facecolor='white')
        plt.close(fig)
        return None
    else:
        return fig


def draw_map_regions(ax, gdf):
    """
    Draw map regions with subtle colors and clear boundaries.
    
    NO WHITE GAPS - geopandas handles this correctly!
    """
    # Draw regions with their assigned colors
    gdf.plot(
        ax=ax,
        color=gdf['color'],
        edgecolor='none',  # No edge first
        alpha=0.30,  # Subtle fill
        linewidth=0
    )
    
    # Draw boundaries on top
    gdf.boundary.plot(
        ax=ax,
        color='#A0A0A0',  # Gray
        linewidth=0.4,
        alpha=0.8
    )


def draw_agent_markers(ax, locations_df, agent_locs_df):
    """
    Draw circles for agent locations with different colors for urban vs rural.
    Size is proportional to number of agents.
    
    Urban locations: Blue/cyan shades
    Rural locations: Orange/red shades
    """
    # Count agents per location
    agent_counts = agent_locs_df.groupby('location').size()
    
    for location_id, count in agent_counts.items():
        # Get location coordinates and urban/rural status
        loc_row = locations_df[locations_df['location_id'] == location_id]
        
        if len(loc_row) == 0:
            continue
        
        # Get location data as Series for easier access
        loc_data = loc_row.iloc[0]
        lon = loc_data['Longitude']
        lat = loc_data['Latitude']
        
        # Determine if urban or rural - check URBAN_RURAL column first
        is_urban = False
        if 'URBAN_RURAL' in locations_df.columns:
            try:
                ur_value = str(loc_data['URBAN_RURAL']).strip().upper()
                # Check for Urban - must be exactly 'URBAN' or start with 'U'
                # Also check if it contains 'URBAN' (case-insensitive)
                is_urban = (ur_value == 'URBAN') or (len(ur_value) > 0 and ur_value[0] == 'U') or 'URBAN' in ur_value
            except (KeyError, IndexError, AttributeError, TypeError) as e:
                is_urban = False
        
        # Fallback: check ADM2_PCODE for -U suffix if URBAN_RURAL check failed
        if not is_urban and 'ADM2_PCODE' in locations_df.columns:
            try:
                pcode = str(loc_data['ADM2_PCODE'])
                is_urban = pcode.endswith('-U')
            except (KeyError, IndexError, AttributeError, TypeError):
                is_urban = False
        
        # Scale marker size proportionally to agent count
        marker_size = 6 + np.sqrt(count) * 3.0
        
        # Choose color based on urban/rural
        if is_urban:
            markerfacecolor = '#2E86AB'  # Blue for urban
            markeredgecolor = '#1a1a1a'  # Dark edge
        else:
            markerfacecolor = '#E63946'  # Red/orange for rural
            markeredgecolor = '#1a1a1a'  # Dark edge
        
        # Draw marker
        ax.plot(lon, lat, 'o',
                markersize=marker_size,
                markerfacecolor=markerfacecolor,
                markeredgecolor=markeredgecolor,
                markeredgewidth=2.0,
                zorder=100,
                alpha=1.0)  # Fully opaque


def draw_migration_arrows(ax, locations_df, migrations):
    """
    Draw curved arrows for migrations with clear arrow heads IN THE MIDDLE.
    Line thickness proportional to migration count.
    Arrows fade progressively over time to avoid visual clutter.
    """
    for mig in migrations:
        from_loc = mig['from_location']
        to_loc = mig['to_location']
        count = mig['count']
        recency = mig['recency']  # 0 = this timestep, 1 = one timestep ago, etc.
        
        # Get coordinates
        from_row = locations_df[locations_df['location_id'] == from_loc]
        to_row = locations_df[locations_df['location_id'] == to_loc]
        
        if len(from_row) == 0 or len(to_row) == 0:
            continue
        
        from_lon = from_row.iloc[0]['Longitude']
        from_lat = from_row.iloc[0]['Latitude']
        to_lon = to_row.iloc[0]['Longitude']
        to_lat = to_row.iloc[0]['Latitude']
        
        # Calculate arrow properties - THINNER lines
        base_thickness = 1.5 + np.log(1 + count) * 0.5
        
        # EXTREME fade - old movements completely disappear
        if recency == 0:
            fade = 1.0  # FULLY VISIBLE for current moves
            thickness = base_thickness
            color = '#000000'  # Pure black
        elif recency == 1:
            fade = 0.45  # Quick fade
            thickness = base_thickness * 0.85
            color = '#333333'  # Dark gray
        else:  # recency >= 2
            # OLD MOVEMENTS GONE - don't draw them at all
            continue
        
        # Draw the full line with arrow head EXACTLY IN THE MIDDLE
        # Single arrow patch with arrow in middle using shrinkA and shrinkB
        head_width = 0.7  # Large arrow head
        head_length = 0.9  # Long arrow head
        
        arrow = FancyArrowPatch(
            (from_lon, from_lat),
            (to_lon, to_lat),
            arrowstyle=f'->,head_width={head_width},head_length={head_length}',
            color=color,
            linewidth=thickness,
            alpha=fade,
            connectionstyle='arc3,rad=0.10',
            mutation_scale=25,  # Large, prominent arrow heads
            shrinkA=0,  # Don't shrink at start
            shrinkB=0,  # Don't shrink at end
            zorder=50
        )
        
        # Get the arrow path and place arrow marker at midpoint
        # Create a simple straight line with arrow marker in middle
        from matplotlib.lines import Line2D
        from matplotlib.patches import FancyArrow
        
        # Calculate midpoint
        mid_lon = (from_lon + to_lon) / 2
        mid_lat = (from_lat + to_lat) / 2
        
        # Calculate direction vector for arrow orientation
        dx = to_lon - from_lon
        dy = to_lat - from_lat
        length = np.sqrt(dx**2 + dy**2)
        
        if length > 0:
            # Normalize direction
            dx_norm = dx / length
            dy_norm = dy / length
            
            # Draw base line without arrow
            ax.plot([from_lon, to_lon], [from_lat, to_lat],
                   color=color, linewidth=thickness, alpha=fade,
                   solid_capstyle='round', zorder=50)
            
            # Draw arrow head at midpoint
            arrow_length = 0.15  # Size of arrow head in degrees
            arrow_width = 0.08
            
            arrow_head = FancyArrow(
                mid_lon - dx_norm * arrow_length/2,
                mid_lat - dy_norm * arrow_length/2,
                dx_norm * arrow_length,
                dy_norm * arrow_length,
                width=arrow_width,
                head_width=arrow_width*2.5,
                head_length=arrow_length*0.6,
                fc=color,
                ec=color,
                alpha=fade,
                zorder=51,
                linewidth=0
            )
            ax.add_patch(arrow_head)


def add_title_and_info(ax, timestep, total_steps, num_agents):
    """
    Add title and information text.
    """
    # Convert timestep to years and quarters
    year = (timestep - 1) // 4 + 1
    quarter = (timestep - 1) % 4 + 1
    
    # Title
    title = f'Madagascar Migration Dynamics - Timestep {timestep}/{total_steps}'
    ax.set_title(title, fontsize=18, fontweight='bold', pad=10)
    
    # Info text
    info = f'Year {year}, Quarter {quarter} | {num_agents} Active Agents'
    ax.text(0.5, -0.02, info, 
            transform=ax.transAxes,
            ha='center',
            fontsize=14,
            style='italic')


def test_create_frame():
    """Test creating a single frame."""
    import sys
    sys.path.append(str(Path(__file__).parent))
    
    from extract_midas_data import load_midas_output, get_agent_locations_at_timestep, get_recent_migrations
    from load_madagascar_shapefile import load_shapefile, assign_region_colors, create_color_column
    
    # Load data
    mat_file = Path('../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat')
    shp_file = Path('../Data/Madagascar_44_UrbanRural.shp')
    
    if not mat_file.exists() or not shp_file.exists():
        print("Test files not found")
        return
    
    print("Loading MIDAS data...")
    data = load_midas_output(mat_file)
    
    print("Loading shapefile...")
    gdf = load_shapefile(shp_file)
    
    print("Assigning colors...")
    color_map = assign_region_colors(gdf, data['locations'])
    gdf = create_color_column(gdf, color_map, data['locations'])
    
    # Get data for timestep 15
    timestep = 15
    print(f"\nExtracting data for timestep {timestep}...")
    agent_locs = get_agent_locations_at_timestep(data['agents'], timestep)
    migrations = get_recent_migrations(data['agents'], timestep, lookback=3)
    
    print(f"  Agents: {len(agent_locs)}")
    print(f"  Migrations: {len(migrations)}")
    
    # Create frame
    print("\nCreating frame...")
    create_frame(
        gdf=gdf,
        locations_df=data['locations'],
        agent_locs_df=agent_locs,
        migrations=migrations,
        timestep=timestep,
        total_steps=data['timesteps'],
        output_path='test_frame.png',
        dpi=150
    )
    
    print("✓ Frame saved: test_frame.png")


if __name__ == '__main__':
    test_create_frame()
