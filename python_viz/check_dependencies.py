#!/usr/bin/env python3
"""
Check if all required dependencies are installed.
"""

def check_package(name, import_name=None):
    """Check if a package is installed."""
    if import_name is None:
        import_name = name
    
    try:
        __import__(import_name)
        print(f"✓ {name:20s} - installed")
        return True
    except ImportError:
        print(f"✗ {name:20s} - MISSING")
        return False


def main():
    print("\n=== Checking Python Dependencies ===\n")
    
    packages = [
        ('scipy', 'scipy'),
        ('geopandas', 'geopandas'),
        ('matplotlib', 'matplotlib'),
        ('pandas', 'pandas'),
        ('numpy', 'numpy'),
        ('imageio', 'imageio'),
        ('Pillow', 'PIL'),
        ('shapely', 'shapely'),
        ('h5py', 'h5py'),
        ('mat73', 'mat73'),
    ]
    
    all_installed = True
    for name, import_name in packages:
        if not check_package(name, import_name):
            all_installed = False
    
    print()
    
    if all_installed:
        print("✓ All dependencies installed!")
        print("\nYou can now run:")
        print("  python run_visualization.py test --output ../Outputs/<file>.mat")
    else:
        print("✗ Some dependencies are missing.")
        print("\nTo install all dependencies:")
        print("  pip install -r requirements.txt")
        print("\nOr install individually:")
        print("  pip install scipy geopandas matplotlib pandas numpy imageio Pillow shapely h5py")


if __name__ == '__main__':
    main()

