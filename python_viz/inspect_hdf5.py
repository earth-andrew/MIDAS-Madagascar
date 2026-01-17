#!/usr/bin/env python3
"""
Inspect HDF5 structure of MATLAB v7.3 output file.
"""

import h5py
import numpy as np
import sys

def print_structure(name, obj, indent=0):
    """Recursively print HDF5 structure."""
    prefix = "  " * indent
    
    if isinstance(obj, h5py.Dataset):
        print(f"{prefix}{name}: Dataset, shape={obj.shape}, dtype={obj.dtype}")
    elif isinstance(obj, h5py.Group):
        print(f"{prefix}{name}: Group")
        # Don't recurse too deep
        if indent < 4:
            for key in obj.keys():
                print_structure(key, obj[key], indent + 1)
    else:
        print(f"{prefix}{name}: {type(obj)}")


def inspect_file(filename):
    """Inspect HDF5 file structure."""
    print(f"\n=== Inspecting HDF5 File ===")
    print(f"File: {filename}\n")
    
    try:
        with h5py.File(filename, 'r') as f:
            print("Top-level keys:")
            for key in f.keys():
                print(f"  - {key}")
            
            # Check #refs# group
            if '#refs#' in f:
                print("\n=== #refs# group ===")
                refs_group = f['#refs#']
                print(f"Number of objects: {len(refs_group.keys())}")
                print(f"Sample keys: {list(refs_group.keys())[:10]}")
                
                # Check what's in these
                for key in list(refs_group.keys())[:3]:
                    obj = refs_group[key]
                    print(f"  {key}: {type(obj)}", end="")
                    if isinstance(obj, h5py.Dataset):
                        print(f", shape={obj.shape}, dtype={obj.dtype}")
                    elif isinstance(obj, h5py.Group):
                        print(f", keys={list(obj.keys())[:5]}")
                    else:
                        print()
            
            if 'output' in f:
                print("\n=== output structure ===")
                output = f['output']
                print(f"Type: {type(output)}")
                print(f"Keys: {list(output.keys())}")
                
                # Check agentSummary
                if 'agentSummary' in output:
                    print("\n=== output.agentSummary ===")
                    agent_summary = output['agentSummary']
                    print(f"Type: {type(agent_summary)}")
                    print(f"Shape: {agent_summary.shape if hasattr(agent_summary, 'shape') else 'N/A'}")
                    print(f"Dtype: {agent_summary.dtype if hasattr(agent_summary, 'dtype') else 'N/A'}")
                    
                    # MATLAB stores tables as (1, N) arrays of references
                    # Each reference points to a field's data
                    if hasattr(agent_summary, 'shape'):
                        print(f"  Contains {agent_summary.shape[1]} field references")
                        print(f"  Checking dtype: {agent_summary.dtype}")
                        
                        # Check if it's an HDF5 object reference type
                        if h5py.check_dtype(ref=agent_summary.dtype):
                            print("  Detected HDF5 object reference dtype")
                            
                            # Try dereferencing each field
                            for i in range(min(3, agent_summary.shape[1])):  # Just first 3
                                ref = agent_summary[0, i]
                                print(f"\n  Field {i}:")
                                try:
                                    # Dereference using the file object
                                    field_data = f[ref]
                                    print(f"    Type: {type(field_data)}")
                                    if isinstance(field_data, h5py.Dataset):
                                        print(f"    Shape: {field_data.shape}")
                                        print(f"    Dtype: {field_data.dtype}")
                                        # Show first few values
                                        if field_data.size < 10:
                                            print(f"    Values: {field_data[:]}")
                                    elif isinstance(field_data, h5py.Group):
                                        print(f"    Keys: {list(field_data.keys())}")
                                except Exception as e:
                                    print(f"    Error: {e}")
                                    import traceback
                                    traceback.print_exc()
                        else:
                            print("  Not an HDF5 reference dtype")
                            print("  These are likely object IDs pointing to #refs# group")
                            
                            # Try accessing via #refs# group
                            if '#refs#' in f:
                                refs_group = f['#refs#']
                                for i in range(min(3, agent_summary.shape[1])):
                                    obj_id = agent_summary[0, i]
                                    # Convert to hex address format that MATLAB uses
                                    hex_id = f'#{obj_id:x}'
                                    print(f"\n  Field {i}: ID={obj_id}, hex={hex_id}")
                                    
                                    if hex_id in refs_group:
                                        print(f"    Found in #refs#!")
                                        field_data = refs_group[hex_id]
                                        print(f"    Type: {type(field_data)}")
                                        if isinstance(field_data, h5py.Dataset):
                                            print(f"    Shape: {field_data.shape}")
                                            print(f"    Dtype: {field_data.dtype}")
                                        elif isinstance(field_data, h5py.Group):
                                            print(f"    Keys: {list(field_data.keys())}")
                                    else:
                                        print(f"    Not found in #refs# (tried {hex_id})")
                        
                        # Try to find the moveHistory field
                        # MATLAB v7.3 tables store field names separately
                        print("\n  Looking for field names...")
                        # Check if there's a Properties group
                        parent_group = output
                        for key in parent_group.keys():
                            if 'Properties' in key or 'VariableNames' in key:
                                print(f"  Found metadata: {key}")
                
                # Check mapVariables
                if 'mapVariables' in output:
                    print("\n=== output.mapVariables ===")
                    map_vars = output['mapVariables']
                    print(f"Type: {type(map_vars)}")
                    print(f"Shape: {map_vars.shape if hasattr(map_vars, 'shape') else 'N/A'}")
                    
                    if hasattr(map_vars, 'shape') and map_vars.shape == (1, 1):
                        print("  It's a (1,1) reference dataset")
                        ref = map_vars[0, 0]
                        try:
                            dereferenced = f[ref]
                            print(f"  Dereferenced type: {type(dereferenced)}")
                            if isinstance(dereferenced, h5py.Group):
                                print(f"  Dereferenced keys: {list(dereferenced.keys())}")
                        except Exception as e:
                            print(f"  Error dereferencing: {e}")
            
            print("\n✓ Inspection complete")
    
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        filename = '../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat'
    
    inspect_file(filename)

