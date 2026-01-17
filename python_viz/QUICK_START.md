# Quick Start Guide - Python Visualization

## 1. Install (One Time)

```bash
cd python_viz
pip install -r requirements.txt
```

## 2. Verify Installation

```bash
python3 check_dependencies.py
```

## 3. Test Single Frame

```bash
python run_visualization.py test \
    --output ../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat \
    --timestep 15
```

**Output:** `test_frame.png`

## 4. Create Animation

```bash
python run_visualization.py animate \
    --output ../Outputs/Madagascar_PA_Shock_Full_Run001_2025-11-12_18-00-32.mat \
    --gif animation.gif \
    --fps 3
```

**Output:** `animation.gif`

## 5. Batch Process All Scenarios

```bash
python run_visualization.py batch \
    --input-dir ../Outputs \
    --pattern "*_Run001_*.mat"
```

**Output:** One GIF per file

---

## Common Options

- `--timestep N` - Which frame to render (test mode)
- `--fps N` - Frames per second (default: 3)
- `--dpi N` - Resolution (default: 150)
- `--keep-frames` - Keep PNG frames after GIF
- `--shapefile PATH` - Custom shapefile location

---

## Help

```bash
python run_visualization.py --help
python run_visualization.py test --help
python run_visualization.py animate --help
python run_visualization.py batch --help
```

---

**See `README.md` for full documentation**

