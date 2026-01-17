"""
MIDAS Migration Visualization Package

Python-based visualization system for MIDAS agent-based migration model.
Reads MATLAB output files and generates high-quality animated GIFs.

Modules:
- extract_midas_data: Load and parse MATLAB .mat files
- load_madagascar_shapefile: Shapefile handling with geopandas
- visualize_migration: Create visualization frames
- create_animation: Generate animated GIFs
- run_visualization: Command-line interface

Usage:
    python run_visualization.py test --output file.mat
    python run_visualization.py animate --output file.mat --gif animation.gif

For detailed documentation, see README.md
"""

__version__ = '1.0.0'
__author__ = 'MIDAS Team'
__all__ = [
    'extract_midas_data',
    'load_madagascar_shapefile',
    'visualize_migration',
    'create_animation',
]

