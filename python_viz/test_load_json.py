#!/usr/bin/env python3
"""
Test loading JSON exports from MATLAB.

This script verifies that JSON files exported by export_for_python.m
can be loaded and used for visualization.
"""

import json
import sys
from pathlib import Path

# Add parent directory to path to import extract_midas_data
sys.path.insert(0, str(Path(__file__).parent))

from extract_midas_data import load_midas_output


def test_json_loading(json_file):
    """Test loading a JSON file."""
    print(f"\n=== Testing JSON Loading ===\n")
    print(f"File: {json_file}\n")
    
    try:
        # Load using our function
        data = load_midas_output(json_file)
        
        # Verify structure
        print("\n=== Verification ===\n")
        
        assert 'agents' in data, "Missing 'agents' key"
        assert 'locations' in data, "Missing 'locations' key"
        assert 'timesteps' in data, "Missing 'timesteps' key"
        assert 'num_agents' in data, "Missing 'num_agents' key"
        
        print(f"✓ All required keys present")
        
        agents_df = data['agents']
        locations_df = data['locations']
        
        print(f"✓ Agents DataFrame: {len(agents_df)} rows")
        print(f"✓ Locations DataFrame: {len(locations_df)} rows")
        print(f"✓ Timesteps: {data['timesteps']}")
        print(f"✓ Num agents: {data['num_agents']}")
        
        # Check agent structure
        if len(agents_df) > 0:
            first_agent = agents_df.iloc[0]
            print(f"\n✓ First agent:")
            print(f"  - ID: {first_agent['id']}")
            print(f"  - Move history length: {len(first_agent['moveHistory'])}")
            
            if len(first_agent['moveHistory']) > 0:
                first_move = first_agent['moveHistory'][0]
                print(f"  - First move: timestep={first_move[0]}, location={first_move[1]}, "
                      f"lon={first_move[2]:.2f}, lat={first_move[3]:.2f}")
        
        # Check location structure
        if len(locations_df) > 0:
            first_loc = locations_df.iloc[0]
            print(f"\n✓ First location:")
            print(f"  - ID: {first_loc['location_id']}")
            print(f"  - Longitude: {first_loc['Longitude']:.4f}")
            print(f"  - Latitude: {first_loc['Latitude']:.4f}")
            print(f"  - ADM2_PCODE: {first_loc['ADM2_PCODE']}")
        
        print(f"\n{'='*50}")
        print("✓ All tests passed!")
        print(f"{'='*50}\n")
        
        print("Ready for visualization!")
        print("\nTry:")
        print(f"  python run_visualization.py test --output {json_file} --timestep 15")
        print()
        
        return True
        
    except Exception as e:
        print(f"\n{'='*50}")
        print("✗ Test failed!")
        print(f"{'='*50}\n")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def find_test_file():
    """Find a JSON file to test."""
    # Look in Outputs directory
    outputs_dir = Path('../Outputs')
    
    if outputs_dir.exists():
        json_files = list(outputs_dir.glob('*Run001*.json'))
        if json_files:
            return json_files[0]
    
    # Look in current directory
    json_files = list(Path('.').glob('*.json'))
    if json_files:
        return json_files[0]
    
    return None


def main():
    """Main test function."""
    if len(sys.argv) > 1:
        json_file = sys.argv[1]
    else:
        print("No JSON file specified, searching for one...")
        json_file = find_test_file()
        
        if json_file is None:
            print("\n✗ No JSON files found!")
            print("\nPlease:")
            print("1. Export a .mat file to JSON using MATLAB:")
            print("   export_for_python('Outputs/your_file.mat')")
            print("2. Run this test:")
            print("   python test_load_json.py Outputs/your_file.json")
            return False
        
        print(f"Found: {json_file}\n")
    
    success = test_json_loading(json_file)
    return success


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)

