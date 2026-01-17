# Madagascar Migration Analysis - Implementation Complete

## Status: ✅ READY TO RUN

All analysis scripts have been created and are ready to execute.

## Quick Start

**In MATLAB:**

```matlab
cd Outputs/Analysis
run_migration_analysis
```

This will generate:
- 5 PNG plots (4 individual scenarios + 1 comparison)
- 3 CSV data files (migration count, total distance, avg distance)

**Expected runtime:** 2-5 minutes

## What Was Created

### Analysis Scripts (in `Outputs/Analysis/`)

1. **`run_migration_analysis.m`** ⭐ Main runner script
   - Orchestrates complete workflow
   - Displays progress and summary statistics
   - Single command to run everything

2. **`load_experiment_data.m`**
   - Loads all 20 output files (`Madagascar_PA_Shock_Full_Run*.mat`)
   - Organizes by scenario (Control, Shock, PA, PA_Shock)
   - Extracts PA and Shock flags from input parameters

3. **`calculate_migration_metrics.m`**
   - Computes migration count per timestep (from `output.migrations`)
   - Calculates total distance traveled (from `agentSummary.moveHistory` + `distanceMatrix`)
   - Calculates average distance per migration

4. **`aggregate_scenarios.m`**
   - Groups runs by scenario (5 replications each)
   - Calculates mean and std across replications
   - Returns aggregated time series with confidence intervals

5. **`plot_migration_timeseries.m`**
   - Creates 5 PNG plots:
     - Individual plots for each scenario (with mean ± std shading)
     - Combined comparison plot (all 4 scenarios overlaid)
   - Each plot has 3 subplots (migration count, total distance, avg distance)

6. **`export_results_csv.m`**
   - Exports 3 CSV files with time series data
   - Includes mean and std for each scenario
   - Format: Timestep, Control_Mean, Control_Std, Shock_Mean, Shock_Std, etc.

7. **`README.md`**
   - Complete documentation for the analysis scripts
   - Usage instructions, troubleshooting, customization guide

## Metrics Calculated

### 1. Migration Count
- **Description**: Number of agents who changed locations per timestep
- **Source**: `output.migrations` (pre-computed in MIDAS model)

### 2. Total Distance Traveled
- **Description**: Sum of distances traveled by all migrating agents per timestep
- **Calculation**: Parse each agent's `moveHistory`, lookup distances in `distanceMatrix`, sum by timestep
- **Units**: kilometers

### 3. Average Distance per Migration
- **Description**: Mean distance traveled per migration event
- **Calculation**: Total Distance / Migration Count per timestep
- **Units**: kilometers per migration

## Output Files

### Figures (PNG)

**Individual Scenario Plots:**
- `migration_timeseries_Control.png`
- `migration_timeseries_Shock.png`
- `migration_timeseries_PA.png`
- `migration_timeseries_PA_Shock.png`

Each shows:
- Migration count over time (top)
- Total distance over time (middle)
- Average distance per migration (bottom)
- Mean line with ± 1 std shading

**Comparison Plot:**
- `migration_timeseries_Comparison.png`
- All 4 scenarios overlaid for direct comparison
- Color-coded: Control (gray), Shock (red), PA (blue), PA+Shock (orange)

### Data (CSV)

- `migration_count_timeseries.csv`
- `total_distance_timeseries.csv`
- `avg_distance_timeseries.csv`

Format: `Timestep, Control_Mean, Control_Std, Shock_Mean, Shock_Std, PA_Mean, PA_Std, PA_Shock_Mean, PA_Shock_Std`

## Workflow Summary

```
run_migration_analysis.m
  │
  ├─► 1. load_experiment_data()
  │      └─ Load 20 .mat files, organize by scenario
  │
  ├─► 2. calculate_migration_metrics()
  │      └─ Compute 3 metrics for each run
  │
  ├─► 3. aggregate_scenarios()
  │      └─ Average across 5 reps per scenario
  │
  ├─► 4. plot_migration_timeseries()
  │      └─ Generate 5 PNG plots
  │
  └─► 5. export_results_csv()
         └─ Export 3 CSV files
```

## Experimental Design

| Scenario | Place Attachment | Drought Shock | Files | Replications |
|----------|-----------------|---------------|-------|--------------|
| Control | OFF (0) | OFF (0) | Run 1-5 | 5 |
| Shock | OFF (0) | ON (1) | Run 6-10 | 5 |
| PA | ON (1) | OFF (0) | Run 11-15 | 5 |
| PA_Shock | ON (1) | ON (1) | Run 16-20 | 5 |

**Total:** 20 runs, 1000 agents each, 30 timesteps

## Example Output

When you run the analysis, you'll see:

```
╔════════════════════════════════════════════════════════════╗
║     MADAGASCAR MIGRATION ANALYSIS - Time Series Study       ║
╚════════════════════════════════════════════════════════════╝

STEP 1/5: Loading experiment data
─────────────────────────────────────────────────────────────
Found 20 output files
...

STEP 2/5: Calculating migration metrics
─────────────────────────────────────────────────────────────
...

Summary Statistics:
─────────────────────────────────────────────────────────────

Control:
  Total migrations: 1234 ± 56
  Avg migrations/timestep: 41.1 ± 1.9
  Avg distance traveled: 123.4 ± 5.6 km

...
```

## Next Steps

### Immediate
1. Run the analysis: `cd Outputs/Analysis; run_migration_analysis`
2. Review PNG plots to visualize migration patterns
3. Open CSV files in Excel/R/Python for further analysis

### Further Analysis
- Compare migration patterns across scenarios
- Examine effect of place attachment on migration distance
- Analyze shock response patterns
- Perform statistical tests (t-tests, ANOVA) on aggregated data
- Create additional custom visualizations

### Customization
- Modify `calculate_migration_metrics.m` to add new metrics
- Edit `plot_migration_timeseries.m` to change colors, layouts, or add plots
- Update `export_results_csv.m` to export additional data

## Files Location

```
MIDAS-Core-dev-MADA/
├── Outputs/
│   ├── Analysis/                              ← Analysis scripts here
│   │   ├── run_migration_analysis.m          ← Run this!
│   │   ├── load_experiment_data.m
│   │   ├── calculate_migration_metrics.m
│   │   ├── aggregate_scenarios.m
│   │   ├── plot_migration_timeseries.m
│   │   ├── export_results_csv.m
│   │   └── README.md
│   │
│   └── Madagascar_PA_Shock_Full_Run*.mat     ← Input data (20 files)
│
└── ANALYSIS_COMPLETE.md                       ← This file
```

## Support

For questions or issues:
- See `Outputs/Analysis/README.md` for detailed documentation
- Check `EXPERIMENT_RUN_GUIDE.md` for experiment setup info
- Review `QUICK_START_GUIDE.md` for general MIDAS guidance

---

**Ready to analyze!** Run `cd Outputs/Analysis; run_migration_analysis` in MATLAB.

