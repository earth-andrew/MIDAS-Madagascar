"""
Extract MIDAS migration data from MATLAB output files.
"""

import scipy.io
import json
try:
    import mat73
    HAS_MAT73 = True
except ImportError:
    HAS_MAT73 = False
    
import numpy as np
import pandas as pd
from pathlib import Path


def load_midas_output(mat_file):
    """
    Load MIDAS output from .mat or .json file.
    
    Automatically detects JSON exports and loads them preferentially.
    Falls back to .mat file loading if needed.
    
    Parameters:
    -----------
    mat_file : str or Path
        Path to MATLAB .mat file (or .json file)
        
    Returns:
    --------
    dict : Extracted data with keys:
        - 'agents': pd.DataFrame with agent data
        - 'locations': pd.DataFrame with location coordinates
        - 'timesteps': int, maximum timestep
        - 'num_agents': int, total number of agents
    """
    print(f"\n=== Loading MIDAS Output ===")
    print(f"File: {mat_file}")
    
    # Check if it's already a JSON file
    mat_path = Path(mat_file)
    if mat_path.suffix == '.json':
        print("Detected JSON file, loading directly...")
        return load_from_json(mat_file)
    
    # Check for JSON version of .mat file
    json_file = str(mat_path).replace('.mat', '.json')
    json_path = Path(json_file)
    
    if json_path.exists():
        print(f"Found JSON export: {json_path.name}")
        print("Loading from JSON (faster and more reliable)...")
        return load_from_json(json_file)
    
    print("No JSON export found, attempting to load .mat file...")
    print("Tip: Export to JSON first using MATLAB for faster loading:")
    print("  export_for_python('{}')".format(mat_file))
    
    # Try loading as MATLAB v7.3 using mat73 first
    if HAS_MAT73:
        try:
            print("Attempting to load as MATLAB v7.3 (HDF5) format using mat73...")
            mat_data = mat73.loadmat(str(mat_file))
            
            if 'output' not in mat_data:
                raise ValueError("MAT file does not contain 'output' structure")
            
            output = mat_data['output']
            
            # Extract agent data
            print("Extracting agent data...")
            agents_df = extract_agent_data_mat73(output)
            
            # Extract locations
            print("Extracting location data...")
            locations_df = extract_locations_mat73(output)
            
            # Calculate max timestep
            max_timestep = calculate_max_timestep(agents_df)
            
            print(f"\n✓ Data loaded successfully (MATLAB v7.3 format)!")
            print(f"  Agents: {len(agents_df)}")
            print(f"  Locations: {len(locations_df)}")
            print(f"  Timesteps: {max_timestep}")
            
            return {
                'agents': agents_df,
                'locations': locations_df,
                'timesteps': max_timestep,
                'num_agents': len(agents_df),
                'meta': {}  # No metadata available from .mat files
            }
        except Exception as e:
            print(f"mat73 loading failed: {e}")
            print("Falling back to legacy format...")
    
    # Try older MATLAB format
    print("Loading as legacy MATLAB format...")
    mat_data = scipy.io.loadmat(str(mat_file), struct_as_record=False, squeeze_me=True)
    
    # Extract output structure
    if 'output' not in mat_data:
        raise ValueError("MAT file does not contain 'output' structure")
    
    output = mat_data['output']
    
    # Extract agent data
    print("Extracting agent data...")
    agents_df = extract_agent_data(output)
    
    # Extract locations
    print("Extracting location data...")
    locations_df = extract_locations(output)
    
    # Calculate max timestep
    max_timestep = calculate_max_timestep(agents_df)
    
    print(f"\n✓ Data loaded successfully (legacy format)!")
    print(f"  Agents: {len(agents_df)}")
    print(f"  Locations: {len(locations_df)}")
    print(f"  Timesteps: {max_timestep}")
    
    # Extract metadata if available
    meta = {}
    if 'meta' in json_data:
        meta = json_data['meta']
    
    result = {
        'agents': agents_df,
        'locations': locations_df,
        'timesteps': max_timestep,
        'num_agents': len(agents_df),
        'meta': meta
    }
    
    return result


def load_from_json(json_file):
    """
    Load MIDAS data from JSON export.
    
    Parameters:
    -----------
    json_file : str or Path
        Path to JSON file exported by export_for_python.m
        
    Returns:
    --------
    dict : Extracted data with keys:
        - 'agents': pd.DataFrame with agent data
        - 'locations': pd.DataFrame with location coordinates
        - 'timesteps': int, maximum timestep
        - 'num_agents': int, total number of agents
    """
    print("Loading JSON file...")
    
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    # Check structure
    if 'agents' not in data or 'locations' not in data or 'meta' not in data:
        raise ValueError("JSON file missing required fields (agents, locations, meta)")
    
    print(f"Loaded {len(data['agents'])} agents, {len(data['locations'])} locations")
    
    # Convert agents to DataFrame
    agents_list = []
    for agent in data['agents']:
        # Convert moveHistory from list of lists to list of tuples
        move_list = [tuple(move) for move in agent['moveHistory']]
        agents_list.append({
            'id': agent['id'],
            'moveHistory': move_list
        })
    
    agents_df = pd.DataFrame(agents_list)
    
    # Convert locations to DataFrame
    locations_df = pd.DataFrame(data['locations'])
    
    # Get metadata
    meta = data['meta']
    
    print(f"\n✓ Data loaded successfully from JSON!")
    print(f"  Agents: {len(agents_df)}")
    print(f"  Locations: {len(locations_df)}")
    print(f"  Timesteps: {meta['num_timesteps']}")
    
    return {
        'agents': agents_df,
        'locations': locations_df,
        'timesteps': meta['num_timesteps'],
        'num_agents': meta['num_agents'],
        'meta': meta
    }


def extract_agent_data_mat73(output):
    """
    Extract agent data from mat73-loaded output structure.
    
    Returns pd.DataFrame with columns:
    - id: agent ID
    - moveHistory: list of moves [(timestep, location, lon, lat), ...]
    """
    # mat73 converts MATLAB tables to dictionaries or structured arrays
    agent_summary = output['agentSummary']
    
    print(f"DEBUG: agent Summary type: {type(agent_summary)}")
    print(f"DEBUG: agentSummary shape/len: {agent_summary.shape if hasattr(agent_summary, 'shape') else len(agent_summary) if hasattr(agent_summary, '__len__') else 'N/A'}")
    
    # Check if it's a dict (field-based) or array
    if isinstance(agent_summary, dict):
        # It's a dict of fields
        move_history_data = agent_summary.get('moveHistory', [])
        ids = agent_summary.get('id', range(1, len(move_history_data) + 1))
    elif isinstance(agent_summary, np.ndarray):
        # It's a numpy array - mat73 returned the table as an array
        # MATLAB tables might be returned as object arrays with None values
        # or as structured arrays
        print(f"DEBUG: numpy array dtype: {agent_summary.dtype}")
        
        # mat73 couldn't parse the table, so use None as signal to try legacy
        raise ValueError(f"mat73 returned unparsed array (dtype={agent_summary.dtype}). Trying legacy loader...")
    else:
        # It's something else
        raise ValueError(f"Unexpected agentSummary format from mat73: {type(agent_summary)}")
    
    # Build agent list
    agent_list = []
    num_agents = len(move_history_data) if isinstance(move_history_data, list) else move_history_data.shape[0]
    
    print(f"Found {num_agents} agents")
    
    for i in range(num_agents):
        agent_id = ids[i] if hasattr(ids, '__getitem__') else i + 1
        
        # Get move history for this agent
        if isinstance(move_history_data, list):
            moves_array = move_history_data[i]
        else:
            moves_array = move_history_data[i]
        
        # Convert to list of tuples
        if isinstance(moves_array, np.ndarray) and moves_array.size > 0:
            if moves_array.ndim == 1:
                moves_array = moves_array.reshape(-1, 4)  # Reshape to N x 4
            move_list = [tuple(row) for row in moves_array]
        else:
            move_list = []
        
        agent_list.append({
            'id': int(agent_id) if not isinstance(agent_id, (int, np.integer)) else agent_id,
            'moveHistory': move_list
        })
        
        # Progress indicator
        if (i + 1) % 200 == 0 or i == num_agents - 1:
            print(f"  Processed {i+1}/{num_agents} agents...")
    
    return pd.DataFrame(agent_list)


def extract_locations_mat73(output):
    """
    Extract location coordinates from mat73-loaded output.
    
    Returns pd.DataFrame with columns:
    - location_id: index (1-based like MATLAB)
    - Longitude: float
    - Latitude: float
    - ADM2_PCODE: str (if available)
    """
    # Navigate to locations
    map_vars = output['mapVariables']
    locations = map_vars['locations']
    
    # mat73 should convert these to numpy arrays or dicts
    if isinstance(locations, dict):
        longitudes = np.array(locations['Longitude']).flatten()
        latitudes = np.array(locations['Latitude']).flatten()
        adm_codes = locations.get('ADM2_PCODE', [''] * len(longitudes))
        
        # Handle cell arrays of strings
        if not isinstance(adm_codes, list):
            if isinstance(adm_codes, np.ndarray):
                adm_codes = [str(code) if code else '' for code in adm_codes.flatten()]
            else:
                adm_codes = [''] * len(longitudes)
    else:
        # Structured array
        longitudes = np.array(locations['Longitude']).flatten()
        latitudes = np.array(locations['Latitude']).flatten()
        adm_codes = [''] * len(longitudes)
    
    num_locations = len(longitudes)
    print(f"Found {num_locations} locations")
    
    return pd.DataFrame({
        'location_id': range(1, num_locations + 1),
        'Longitude': longitudes,
        'Latitude': latitudes,
        'ADM2_PCODE': adm_codes
    })


def extract_agent_data_hdf5(f, output):
    """
    Extract agent data from HDF5 output structure.
    
    Returns pd.DataFrame with columns:
    - id: agent ID
    - moveHistory: list of moves [(timestep, location, lon, lat), ...]
    """
    # Navigate through HDF5 structure - MATLAB stores tables as struct arrays
    # output.agentSummary is a reference to the actual table
    agent_summary_ref = output['agentSummary']
    
    # Dereference to get the actual table
    if isinstance(agent_summary_ref, h5py.Dataset):
        # It's a reference dataset
        ref = agent_summary_ref[0, 0]
        agent_summary = f[f[ref]]
    else:
        agent_summary = agent_summary_ref
    
    # Get the moveHistory field
    move_history_field = agent_summary['moveHistory']
    
    # Extract move histories for each agent
    agent_list = []
    num_agents = move_history_field.shape[1]  # MATLAB stores in column-major
    
    print(f"Found {num_agents} agents in HDF5 file")
    
    for i in range(num_agents):
        agent_id = i + 1
        
        # Get moveHistory reference for this agent
        move_ref = move_history_field[0, i]
        
        if move_ref:
            try:
                # Dereference to get the actual move data
                moves = f[move_ref][:]
                
                # MATLAB stores as column-major, so transpose
                # moveHistory is [timestep, location, visX, visY]
                if moves.shape[0] == 4:  # 4 columns
                    moves = moves.T  # Now rows are moves
                
                move_list = [tuple(row) for row in moves]
            except (KeyError, ValueError, TypeError):
                move_list = []
        else:
            move_list = []
        
        agent_list.append({
            'id': agent_id,
            'moveHistory': move_list
        })
        
        # Progress indicator
        if (i + 1) % 200 == 0 or i == num_agents - 1:
            print(f"  Processed {i+1}/{num_agents} agents...")
    
    return pd.DataFrame(agent_list)


def extract_locations_hdf5(f, output):
    """
    Extract location coordinates from HDF5 output.mapVariables.locations.
    
    Returns pd.DataFrame with columns:
    - location_id: index (1-based like MATLAB)
    - Longitude: float
    - Latitude: float
    - ADM2_PCODE: str (if available)
    """
    # Navigate to mapVariables
    map_vars_ref = output['mapVariables']
    
    # Dereference if needed
    if isinstance(map_vars_ref, h5py.Dataset):
        ref = map_vars_ref[0, 0]
        map_vars = f[ref]
    else:
        map_vars = map_vars_ref
    
    # Get locations
    locations_ref = map_vars['locations']
    
    # Dereference if needed
    if isinstance(locations_ref, h5py.Dataset):
        ref = locations_ref[0, 0]
        locations = f[ref]
    else:
        locations = locations_ref
    
    # Get Longitude field
    lon_field = locations['Longitude']
    if isinstance(lon_field, h5py.Dataset):
        if lon_field.shape == (1, 1):
            # It's a reference
            longitudes = f[lon_field[0, 0]][:].flatten()
        else:
            longitudes = lon_field[:].flatten()
    else:
        longitudes = np.array([])
    
    # Get Latitude field
    lat_field = locations['Latitude']
    if isinstance(lat_field, h5py.Dataset):
        if lat_field.shape == (1, 1):
            # It's a reference
            latitudes = f[lat_field[0, 0]][:].flatten()
        else:
            latitudes = lat_field[:].flatten()
    else:
        latitudes = np.array([])
    
    num_locations = len(longitudes)
    print(f"Found {num_locations} locations")
    
    # Get ADM2_PCODE if available
    adm_codes = []
    if 'ADM2_PCODE' in locations:
        pcode_field = locations['ADM2_PCODE']
        
        # MATLAB stores cell arrays of strings as references
        for i in range(num_locations):
            try:
                # Get reference for this string
                if pcode_field.ndim == 2 and pcode_field.shape[0] == 1:
                    str_ref = pcode_field[0, i]
                elif pcode_field.ndim == 2 and pcode_field.shape[1] == 1:
                    str_ref = pcode_field[i, 0]
                else:
                    str_ref = pcode_field[i]
                
                # Dereference to get the character array
                char_array = f[str_ref][:]
                
                # Convert uint16 array to string
                if char_array.ndim == 2:
                    char_array = char_array[:, 0]  # Take first column
                
                code_str = ''.join([chr(int(c)) for c in char_array if c != 0])
                adm_codes.append(code_str)
            except (KeyError, ValueError, TypeError, IndexError):
                adm_codes.append('')
    else:
        adm_codes = [''] * num_locations
    
    return pd.DataFrame({
        'location_id': range(1, num_locations + 1),
        'Longitude': longitudes,
        'Latitude': latitudes,
        'ADM2_PCODE': adm_codes
    })


def extract_agent_data(output):
    """
    Extract agent data from output structure (legacy MATLAB format).
    
    Returns pd.DataFrame with columns:
    - id: agent ID
    - moveHistory: list of moves [(timestep, location, lon, lat), ...]
    """
    # Get agentSummary (MATLAB table becomes structured array)
    agent_summary = output.agentSummary
    
    # Convert to list of dicts
    agent_list = []
    
    for i in range(len(agent_summary)):
        agent = agent_summary[i]
        
        # Get ID
        agent_id = int(agent.id) if hasattr(agent, 'id') else i
        
        # Get moveHistory (numpy array: [timestep, location, visX, visY])
        move_hist = agent.moveHistory if hasattr(agent, 'moveHistory') else np.array([])
        
        # Convert to list of tuples for easier handling
        if move_hist.size > 0:
            move_list = [tuple(row) for row in move_hist]
        else:
            move_list = []
        
        agent_list.append({
            'id': agent_id,
            'moveHistory': move_list
        })
    
    return pd.DataFrame(agent_list)


def extract_locations(output):
    """
    Extract location coordinates from output.mapVariables.locations.
    
    Returns pd.DataFrame with columns:
    - location_id: index (1-based like MATLAB)
    - Longitude: float
    - Latitude: float
    - ADM2_PCODE: str (if available)
    """
    locations = output.mapVariables.locations
    
    # Check if it's a structured array (MATLAB table)
    if isinstance(locations, np.ndarray):
        # Structured array
        location_list = []
        
        for i in range(len(locations)):
            loc = locations[i]
            
            loc_dict = {
                'location_id': i + 1,  # 1-based indexing
                'Longitude': float(loc.Longitude) if hasattr(loc, 'Longitude') else 0.0,
                'Latitude': float(loc.Latitude) if hasattr(loc, 'Latitude') else 0.0,
            }
            
            # Add ADM2_PCODE if available
            if hasattr(loc, 'ADM2_PCODE'):
                pcode = loc.ADM2_PCODE
                # Handle cell arrays and strings
                if isinstance(pcode, np.ndarray):
                    loc_dict['ADM2_PCODE'] = str(pcode[0]) if len(pcode) > 0 else ''
                else:
                    loc_dict['ADM2_PCODE'] = str(pcode)
            else:
                loc_dict['ADM2_PCODE'] = ''
            
            location_list.append(loc_dict)
        
        return pd.DataFrame(location_list)
    
    else:
        # Simple array (just coordinates)
        return pd.DataFrame({
            'location_id': range(1, len(locations) + 1),
            'Longitude': locations[:, 0] if locations.shape[1] > 0 else 0,
            'Latitude': locations[:, 1] if locations.shape[1] > 1 else 0,
            'ADM2_PCODE': ''
        })


def calculate_max_timestep(agents_df):
    """Calculate maximum timestep from all agent move histories."""
    max_t = 0
    
    for move_list in agents_df['moveHistory']:
        if len(move_list) > 0:
            # Each move is (timestep, location, lon, lat)
            timesteps = [move[0] for move in move_list]
            max_t = max(max_t, max(timesteps))
    
    return int(max_t)


def get_agent_locations_at_timestep(agents_df, timestep):
    """
    Get agent locations at a specific timestep.
    
    Parameters:
    -----------
    agents_df : pd.DataFrame
        Agent data with moveHistory column
    timestep : int
        Target timestep
        
    Returns:
    --------
    pd.DataFrame with columns:
    - agent_id: int
    - location: int (1-based location ID)
    - lon: float
    - lat: float
    """
    results = []
    
    for idx, row in agents_df.iterrows():
        move_list = row['moveHistory']
        
        if len(move_list) == 0:
            continue
        
        # Find most recent move up to this timestep
        valid_moves = [m for m in move_list if m[0] <= timestep]
        
        if len(valid_moves) > 0:
            # Get last valid move: (timestep, location, lon, lat)
            last_move = valid_moves[-1]
            
            results.append({
                'agent_id': row['id'],
                'location': int(last_move[1]),  # location ID
                'lon': float(last_move[2]) if len(last_move) > 2 else 0.0,
                'lat': float(last_move[3]) if len(last_move) > 3 else 0.0
            })
    
    return pd.DataFrame(results)


def get_recent_migrations(agents_df, current_timestep, lookback=3):
    """
    Get migrations that occurred in recent timesteps.
    
    Parameters:
    -----------
    agents_df : pd.DataFrame
        Agent data
    current_timestep : int
        Current timestep
    lookback : int
        How many timesteps back to look
        
    Returns:
    --------
    list of dicts with keys:
    - from_location: int
    - to_location: int
    - count: int (number of agents)
    - recency: int (timesteps ago)
    """
    migrations = {}
    
    for idx, row in agents_df.iterrows():
        move_list = row['moveHistory']
        
        if len(move_list) < 2:
            continue
        
        # Find moves in the window
        recent_moves = [m for m in move_list 
                       if current_timestep - lookback < m[0] <= current_timestep]
        
        # Check consecutive moves
        for i in range(len(move_list) - 1):
            move_from = move_list[i]
            move_to = move_list[i + 1]
            
            # Check if this move is in our window
            if not (current_timestep - lookback < move_to[0] <= current_timestep):
                continue
            
            from_loc = int(move_from[1])
            to_loc = int(move_to[1])
            
            # Skip if no actual move
            if from_loc == to_loc:
                continue
            
            # Create key
            key = (from_loc, to_loc)
            recency = current_timestep - int(move_to[0])
            
            if key in migrations:
                migrations[key]['count'] += 1
                migrations[key]['recency'] = min(migrations[key]['recency'], recency)
            else:
                migrations[key] = {
                    'from_location': from_loc,
                    'to_location': to_loc,
                    'count': 1,
                    'recency': recency
                }
    
    return list(migrations.values())


def test_load():
    """Test loading a MIDAS output file."""
    test_file = Path('../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat')
    
    if not test_file.exists():
        print(f"Test file not found: {test_file}")
        return
    
    data = load_midas_output(test_file)
    
    print("\n=== Testing agent location extraction ===")
    locs_t15 = get_agent_locations_at_timestep(data['agents'], 15)
    print(f"Agents at timestep 15: {len(locs_t15)}")
    print(locs_t15.head())
    
    print("\n=== Testing migration extraction ===")
    migs = get_recent_migrations(data['agents'], 15, lookback=3)
    print(f"Recent migrations: {len(migs)}")
    if len(migs) > 0:
        print("Sample migrations:")
        for mig in migs[:5]:
            print(f"  {mig['from_location']} -> {mig['to_location']}: {mig['count']} agents")


if __name__ == '__main__':
    test_load()
