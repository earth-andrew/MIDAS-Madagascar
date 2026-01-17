# MIDAS Migration Visualization (Python)

High-quality Python-based visualization system for MIDAS migration simulation data. Creates clean, publication-ready animated GIFs from MATLAB output files.

## Features

✅ **No white gaps** - Proper shapefile rendering with geopandas  
✅ **Urban/rural color pairing** - Matching colors for provinces  
✅ **Curved migration arrows** - Clear movement visualization  
✅ **High resolution** - 1920×1080 @ 150 DPI  
✅ **Fast iteration** - Edit and rerun without MATLAB  
✅ **Easy to use** - Simple command-line interface  

## Installation

### 1. Install Python Dependencies

```bash
cd python_viz
pip install -r requirements.txt
```

**Required packages:**
- scipy (read .mat files)
- geopandas (shapefile handling)
- matplotlib (plotting)
- pandas (data processing)
- numpy (numerical operations)
- imageio (GIF creation)
- Pillow (image processing)

### 2. Verify Installation

```bash
python -c "import geopandas; import scipy.io; print('✓ All packages installed')"
```

## Quick Start

### Test with Single Frame

```bash
python run_visualization.py test \
    --output ../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat \
    --timestep 15
```

**Output:** `test_frame.png` showing timestep 15

### Generate Full Animation

```bash
python run_visualization.py animate \
    --output ../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat \
    --gif my_animation.gif \
    --fps 3
```

**Output:** `my_animation.gif` with all 30 timesteps

### Batch Process Multiple Scenarios

```bash
python run_visualization.py batch \
    --input-dir ../Outputs \
    --pattern "*_Run001_*.mat" \
    --fps 3
```

**Output:** One GIF per matching .mat file

## Usage Examples

### 1. Test Single Frame (Different Timesteps)

```bash
# Early timestep
python run_visualization.py test --output ../Outputs/file.mat --timestep 5

# Mid simulation
python run_visualization.py test --output ../Outputs/file.mat --timestep 15

# End of simulation
python run_visualization.py test --output ../Outputs/file.mat --timestep 30
```

### 2. Custom Resolution and Frame Rate

```bash
# High resolution, slow animation
python run_visualization.py animate \
    --output ../Outputs/file.mat \
    --gif high_quality.gif \
    --dpi 200 \
    --fps 2

# Lower resolution, faster animation
python run_visualization.py animate \
    --output ../Outputs/file.mat \
    --gif fast.gif \
    --dpi 100 \
    --fps 5
```

### 3. Keep Frames for Inspection

```bash
python run_visualization.py animate \
    --output ../Outputs/file.mat \
    --gif animation.gif \
    --keep-frames \
    --frames my_frames/
```

**Result:** GIF + all PNG frames in `my_frames/`

### 4. Custom Shapefile Location

```bash
python run_visualization.py test \
    --output ../Outputs/file.mat \
    --shapefile /custom/path/to/shapefile.shp
```

## Command Reference

### `test` - Test Single Frame

**Required:**
- `--output FILE` - MIDAS output .mat file

**Optional:**
- `--timestep N` - Which timestep to render (default: 15)
- `--shapefile PATH` - Shapefile path (default: ../Data/Madagascar_44_UrbanRural.shp)
- `--save-frame FILE` - Output filename (default: test_frame.png)
- `--dpi N` - Resolution (default: 150)

### `animate` - Generate Full Animation

**Required:**
- `--output FILE` - MIDAS output .mat file
- `--gif FILE` - Output GIF filename

**Optional:**
- `--shapefile PATH` - Shapefile path
- `--frames DIR` - Frame directory (default: frames_temp)
- `--fps N` - Frames per second (default: 3)
- `--dpi N` - Resolution (default: 150)
- `--keep-frames` - Keep PNG frames after GIF creation

### `batch` - Batch Process

**Required:**
- `--input-dir DIR` - Directory containing .mat files

**Optional:**
- `--pattern GLOB` - File pattern (default: *_Run001.mat)
- `--shapefile PATH` - Shapefile path
- `--fps N` - Frames per second (default: 3)
- `--dpi N` - Resolution (default: 150)
- `--keep-frames` - Keep PNG frames

## Visual Style

### Colors
- **22 distinct base colors** for provinces
- **Rural areas**: Full saturation (base color)
- **Urban areas**: Lighter shade (60% base + 40% white)
- **Background**: Light blue-gray (#F5F5F8)
- **Boundaries**: Thin gray lines (0.4pt)

### Agent Markers
- **Color**: Red (#CC3333)
- **Size**: Scaled by agent count (50 + √count × 10)
- **Outline**: Black edge for visibility

### Migration Arrows
- **Color**: Black
- **Style**: Curved (arc3, rad=0.2)
- **Thickness**: Scaled by migration count (0.5 + log(count))
- **Fade**: Temporal fade over 3 timesteps

## File Structure

```
python_viz/
├── requirements.txt               # Python dependencies
├── README.md                      # This file
├── extract_midas_data.py         # Load .mat files
├── load_madagascar_shapefile.py  # Shapefile handling
├── visualize_migration.py        # Frame creation
├── create_animation.py           # GIF generation
└── run_visualization.py          # Command-line interface
```

## Troubleshooting

### Missing Packages

**Error:** `ModuleNotFoundError: No module named 'geopandas'`

**Solution:**
```bash
pip install -r requirements.txt
```

### Cannot Find Shapefile

**Error:** `FileNotFoundError: .../Madagascar_44_UrbanRural.shp`

**Solution:** Provide explicit path:
```bash
python run_visualization.py test \
    --output file.mat \
    --shapefile /full/path/to/shapefile.shp
```

### Out of Memory

**Error:** Memory errors during GIF creation

**Solution:** Reduce resolution:
```bash
python run_visualization.py animate \
    --output file.mat \
    --gif output.gif \
    --dpi 100  # Lower resolution
```

### Slow Performance

**Issue:** Frame generation takes too long

**Solutions:**
1. Lower DPI: `--dpi 100` (faster, smaller file)
2. Test first: Use `test` command before full animation
3. Keep frames: Use `--keep-frames` to avoid regenerating

## Performance

Typical performance on modern hardware:

- **Single frame**: 2-5 seconds
- **30-frame animation**: 1-2 minutes
- **GIF creation**: 10-20 seconds
- **Total**: ~2-3 minutes per scenario

## Advantages Over MATLAB

1. ✅ **No white gaps** - Proper polygon rendering
2. ✅ **Faster iteration** - Edit Python, rerun immediately
3. ✅ **Better colors** - Matplotlib color management
4. ✅ **Easier debugging** - Clear Python error messages
5. ✅ **Vector output** - Can export to PDF/SVG
6. ✅ **No licensing** - Open-source tools only
7. ✅ **Interactive development** - Use in Jupyter notebooks

## Advanced Usage

### Python API

You can also use the modules directly in Python:

```python
from extract_midas_data import load_midas_output
from load_madagascar_shapefile import load_shapefile, assign_region_colors
from visualize_migration import create_frame
from create_animation import generate_animation

# Load data
data = load_midas_output('output.mat')
gdf = load_shapefile('shapefile.shp')

# Generate animation
generate_animation(
    mat_file='output.mat',
    shp_file='shapefile.shp',
    output_gif='animation.gif',
    fps=3,
    dpi=150
)
```

### Jupyter Notebook

Use interactively in a notebook:

```python
from visualize_migration import create_frame
import matplotlib.pyplot as plt

# Create frame (returns figure instead of saving)
fig = create_frame(gdf, locations, agents, migrations, t=15, total=30, output_path=None)
plt.show()
```

## Output Examples

### Single Frame
- **Format**: PNG
- **Size**: 1920×1080 pixels @ 150 DPI
- **File size**: ~500 KB

### Animated GIF
- **Frames**: 30 (for 30 timesteps)
- **Duration**: 10 seconds @ 3 FPS
- **File size**: 5-15 MB (depending on complexity)

## Support

For issues:
1. Check this README
2. Verify all packages installed: `pip install -r requirements.txt`
3. Test with single frame first
4. Check Python version: Python 3.8+ required

## Version

Python Visualization System v1.0  
Created: November 2024  
Compatible with: MIDAS Madagascar outputs

---

**Ready to visualize!** 🎨📊

