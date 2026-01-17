"""
Load and prepare Madagascar shapefile for visualization.
"""

import geopandas as gpd
import pandas as pd
import numpy as np
import matplotlib.colors as mcolors
from pathlib import Path


# 25 highly distinct base colors for provinces (enough for Madagascar's 22 regions)
BASE_COLORS = [
    '#0072B2',  # Blue
    '#D55E00',  # Red-orange
    '#009E73',  # Green
    '#F0E442',  # Yellow
    '#56B4E9',  # Sky blue
    '#E69F00',  # Orange
    '#CC79A7',  # Pink
    '#999999',  # Gray
    '#8B4513',  # Brown
    '#9467BD',  # Purple
    '#2CA02C',  # Forest green
    '#FF7F0E',  # Bright orange
    '#1F77B4',  # Medium blue
    '#FF69B4',  # Hot pink
    '#8B008B',  # Dark magenta
    '#00CED1',  # Dark turquoise
    '#FF4500',  # Orange red
    '#32CD32',  # Lime green
    '#BA55D3',  # Medium orchid
    '#DAA520',  # Goldenrod
    '#DC143C',  # Crimson
    '#4169E1',  # Royal blue
    '#FF1493',  # Deep pink
    '#228B22',  # Forest green dark
    '#FF8C00',  # Dark orange
]


def load_shapefile(shp_path):
    """
    Load Madagascar shapefile.
    
    Parameters:
    -----------
    shp_path : str or Path
        Path to .shp file
        
    Returns:
    --------
    geopandas.GeoDataFrame
    """
    print(f"\n=== Loading Shapefile ===")
    print(f"File: {shp_path}")
    
    # Set environment variable to restore .shx if missing
    import os
    os.environ['SHAPE_RESTORE_SHX'] = 'YES'
    
    # Load the shapefile
    gdf = gpd.read_file(str(shp_path))
    
    print(f"✓ Loaded {len(gdf)} regions")
    print(f"  CRS: {gdf.crs}")
    print(f"  Bounds: {gdf.total_bounds}")
    
    return gdf


def assign_region_colors(gdf, locations_df):
    """
    Assign colors to regions with urban/rural pairing.
    
    Rural areas get base color, urban areas get lighter shade.
    
    Parameters:
    -----------
    gdf : geopandas.GeoDataFrame
        Shapefile data
    locations_df : pandas.DataFrame
        Location data with ADM2_PCODE column
        
    Returns:
    --------
    dict : Mapping of location_id to color (hex string)
    """
    print("\n=== Assigning Colors ===")
    
    # Create mapping: shapefile index -> location_id -> color
    color_map = {}
    
    # Extract base regions and urban/rural status
    base_regions = []
    is_urban_list = []
    
    for idx, row in locations_df.iterrows():
        pcode = row['ADM2_PCODE']
        location_id = row['location_id']
        
        # Check if urban or rural
        if pcode.endswith('-U'):
            is_urban = True
            base_region = pcode[:-2]  # Remove -U
        elif pcode.endswith('-R'):
            is_urban = False
            base_region = pcode[:-2]  # Remove -R
        else:
            is_urban = False
            base_region = pcode
        
        base_regions.append(base_region)
        is_urban_list.append(is_urban)
    
    # Get unique base regions
    unique_regions = sorted(set(base_regions))
    num_base_regions = len(unique_regions)
    
    print(f"  Base provinces: {num_base_regions}")
    print(f"  Total locations: {len(locations_df)}")
    
    # Assign base colors to provinces
    np.random.seed(42)  # For consistency
    base_color_indices = np.random.permutation(len(BASE_COLORS))[:num_base_regions]
    
    region_to_color = {}
    for i, region in enumerate(unique_regions):
        color_idx = base_color_indices[i] % len(BASE_COLORS)
        region_to_color[region] = BASE_COLORS[color_idx]
    
    # Assign colors to each location
    for idx, row in locations_df.iterrows():
        location_id = row['location_id']
        base_region = base_regions[idx]
        is_urban = is_urban_list[idx]
        
        base_color = region_to_color[base_region]
        
        if is_urban:
            # Urban: lighter shade (blend with white)
            color = blend_color_with_white(base_color, 0.4)
        else:
            # Rural: full base color
            color = base_color
        
        color_map[location_id] = color
    
    return color_map


def blend_color_with_white(hex_color, white_amount):
    """
    Blend a hex color with white.
    
    Parameters:
    -----------
    hex_color : str
        Hex color like '#FF0000'
    white_amount : float
        Amount of white to blend (0-1)
        
    Returns:
    --------
    str : Blended hex color
    """
    # Convert hex to RGB
    rgb = mcolors.hex2color(hex_color)
    
    # Blend with white
    blended = tuple(c * (1 - white_amount) + white_amount for c in rgb)
    
    # Convert back to hex
    return mcolors.to_hex(blended)


def create_color_column(gdf, color_map, locations_df):
    """
    Add color column to GeoDataFrame based on matching with locations.
    
    Parameters:
    -----------
    gdf : geopandas.GeoDataFrame
        Shapefile
    color_map : dict
        location_id -> color mapping
    locations_df : pandas.DataFrame
        Location coordinates
        
    Returns:
    --------
    geopandas.GeoDataFrame with 'color' column added
    """
    # Match shapefile features to locations by proximity
    # Assume they're in the same order (44 regions)
    colors = []
    
    for i in range(len(gdf)):
        location_id = i + 1  # 1-based
        color = color_map.get(location_id, '#CCCCCC')  # Default gray
        colors.append(color)
    
    gdf = gdf.copy()
    gdf['color'] = colors
    gdf['location_id'] = range(1, len(gdf) + 1)
    
    return gdf


def test_load():
    """Test loading shapefile."""
    shp_path = Path('../Data/Madagascar_44_UrbanRural.shp')
    
    if not shp_path.exists():
        print(f"Shapefile not found: {shp_path}")
        return
    
    # Load shapefile
    gdf = load_shapefile(shp_path)
    
    print(f"\nColumns: {list(gdf.columns)}")
    print(f"\nFirst feature:")
    print(gdf.iloc[0])
    
    # Test color assignment (create dummy locations)
    locations_df = pd.DataFrame({
        'location_id': range(1, len(gdf) + 1),
        'ADM2_PCODE': [f'MDG{i:04d}-R' if i % 2 == 0 else f'MDG{i:04d}-U' 
                       for i in range(1, len(gdf) + 1)],
        'Longitude': [0] * len(gdf),
        'Latitude': [0] * len(gdf)
    })
    
    color_map = assign_region_colors(gdf, locations_df)
    print(f"\n✓ Color map created: {len(color_map)} colors")
    print("Sample colors:")
    for loc_id, color in list(color_map.items())[:5]:
        print(f"  Location {loc_id}: {color}")


if __name__ == '__main__':
    test_load()
