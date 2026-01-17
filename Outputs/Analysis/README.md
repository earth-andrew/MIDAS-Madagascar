# Madagascar Migration Analysis

This directory contains analysis scripts for the Madagascar MIDAS factorial experiment (Place Attachment × Drought Shock).

## Quick Start

**Run the complete analysis pipeline:**

```matlab
cd Outputs/Analysis
run_migration_analysis
```

This will:
1. Load all 20 experimental output files
2. Calculate migration metrics for each run
3. Aggregate metrics by scenario (average across 5 replications)
4. Generate 5 PNG plots
5. Export 3 CSV data files

**Expected runtime:** 2-5 minutes

## Analysis Scripts

### Main Runner
- **`run_migration_analysis.m`** - Orchestrates the entire analysis workflow

### Component Scripts
- **`load_experiment_data.m`** - Loads and organizes all 20 output files by scenario
- **`calculate_migration_metrics.m`** - Computes migration count, total distance, and average distance per timestep
- **`aggregate_scenarios.m`** - Aggregates metrics across 5 replications per scenario (mean ± std)
- **`plot_migration_timeseries.m`** - Creates time series visualizations
- **`export_results_csv.m`** - Exports aggregated data to CSV files

## Output Files

### Figures (PNG)
All figures contain 3 subplots:
- Top: Migration count over time
- Middle: Total distance traveled over time
- Bottom: Average distance per migration over time

**Individual scenario plots (with mean ± std shading):**
- `migration_timeseries_Control.png` - Control scenario (No PA, No Shock)
- `migration_timeseries_Shock.png` - Shock Only scenario (No PA, Shock)
- `migration_timeseries_PA.png` - PA Only scenario (PA, No Shock)
- `migration_timeseries_PA_Shock.png` - PA + Shock scenario (PA, Shock)

**Comparison plot:**
- `migration_timeseries_Comparison.png` - All 4 scenarios overlaid for direct comparison

### Data (CSV)
Each CSV contains columns: `Timestep, Control_Mean, Control_Std, Shock_Mean, Shock_Std, PA_Mean, PA_Std, PA_Shock_Mean, PA_Shock_Std`

- `migration_count_timeseries.csv` - Number of migrations per timestep
- `total_distance_timeseries.csv` - Total distance traveled by all agents per timestep (km)
- `avg_distance_timeseries.csv` - Average distance per migration per timestep (km)

## Experimental Design

### Scenarios
| Scenario | Place Attachment | Drought Shock | Replications |
|----------|-----------------|---------------|--------------|
| Control | OFF (0) | OFF (0) | 5 |
| Shock | OFF (0) | ON (1) | 5 |
| PA | ON (1) | OFF (0) | 5 |
| PA_Shock | ON (1) | ON (1) | 5 |

**Total runs:** 20 (4 scenarios × 5 replications)

### Metrics Calculated

1. **Migration Count**: Number of agents who changed locations per timestep
   - Source: `output.migrations` (pre-computed in model)

2. **Total Distance Traveled**: Sum of distances traveled by all migrating agents per timestep
   - Calculated by: Parsing `agentSummary.moveHistory` for each agent, looking up distances in `output.mapVariables.distanceMatrix`, and summing by timestep

3. **Average Distance per Migration**: Mean distance traveled per migration
   - Calculated by: Total Distance / Migration Count per timestep

## Data Sources

The analysis reads from:
- **Input files**: `../Madagascar_PA_Shock_Full_Run*.mat` (20 files)
- **Key data structures**:
  - `output.migrations`: Migration counts per timestep
  - `agentSummary.moveHistory`: Individual agent movement history `[timestep, location, visX, visY]`
  - `output.mapVariables.distanceMatrix`: Distance matrix between all location pairs

## Customization

### Modify Metrics
Edit `calculate_migration_metrics.m` to add new metrics based on available output data.

### Change Plotting
Edit `plot_migration_timeseries.m` to:
- Adjust colors (lines 16-19)
- Change plot dimensions (line 30)
- Modify subplot layouts
- Add additional visualizations

### Export Different Data
Edit `export_results_csv.m` to export additional metrics or change CSV format.

## Troubleshooting

### "No output files found"
- Check that you're in the `Outputs/Analysis/` directory
- Verify that output files exist in `../` (parent directory)
- Files should match pattern: `Madagascar_PA_Shock_Full_Run*.mat`

### "Distance matrix not found"
- Some runs may not have saved distance matrix
- Analysis will continue but distance metrics will be zero
- Check individual run outputs to verify data structure

### Figures not displaying
- Figures are saved as PNG files but not displayed during analysis (set to invisible)
- Open PNG files after analysis completes
- To display during analysis, edit `plot_migration_timeseries.m` line 30: change `'Visible', 'off'` to `'Visible', 'on'`

## Summary Statistics

After running the analysis, summary statistics are displayed in the console:
- Total migrations across all timesteps
- Average migrations per timestep
- Average distance traveled per migration

These provide a quick comparison across the 4 experimental scenarios.

## File Organization

```
Outputs/
├── Analysis/
│   ├── README.md (this file)
│   ├── run_migration_analysis.m (main runner)
│   ├── load_experiment_data.m
│   ├── calculate_migration_metrics.m
│   ├── aggregate_scenarios.m
│   ├── plot_migration_timeseries.m
│   ├── export_results_csv.m
│   ├── *.png (generated figures)
│   └── *.csv (generated data)
└── Madagascar_PA_Shock_Full_Run*.mat (20 experimental outputs)
```

## Next Steps

After generating the outputs, you can:
1. Open PNG files to visualize migration patterns
2. Import CSV files into R, Python, or Excel for further analysis
3. Compare patterns across scenarios
4. Perform statistical tests on aggregated data
5. Create additional custom visualizations

---

**Questions or Issues?** Refer to the main project documentation or experiment run guide.

