% RUN_MIGRATION_ANALYSIS - Main script for migration time series analysis
%
% This script orchestrates the complete migration analysis workflow:
%   1. Load all 20 experimental output files
%   2. Calculate migration metrics (count, total distance, avg distance)
%   3. Aggregate metrics by scenario (average across 5 replications)
%   4. Create time series visualizations (5 PNG files)
%   5. Export data to CSV files (3 CSV files)
%
% Usage:
%   cd Outputs/Analysis
%   run_migration_analysis
%
% Outputs:
%   Figures (PNG):
%     - migration_timeseries_Control.png
%     - migration_timeseries_Shock.png
%     - migration_timeseries_PA.png
%     - migration_timeseries_PA_Shock.png
%     - migration_timeseries_Comparison.png
%   Data (CSV):
%     - migration_count_timeseries.csv
%     - total_distance_timeseries.csv
%     - avg_distance_timeseries.csv

clear; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║     MADAGASCAR MIGRATION ANALYSIS - Time Series Study       ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% Step 1: Load experiment data
fprintf('STEP 1/5: Loading experiment data\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    experimentData = load_experiment_data();
catch ME
    fprintf('✗ ERROR loading data: %s\n', ME.message);
    return;
end

%% Step 2: Calculate migration metrics
fprintf('STEP 2/5: Calculating migration metrics\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    metrics = calculate_migration_metrics(experimentData);
catch ME
    fprintf('✗ ERROR calculating metrics: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Step 3: Aggregate by scenario
fprintf('STEP 3/5: Aggregating scenarios\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    aggregated = aggregate_scenarios(metrics);
catch ME
    fprintf('✗ ERROR aggregating scenarios: %s\n', ME.message);
    return;
end

%% Step 4: Create visualizations
fprintf('STEP 4/5: Creating visualizations\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    plot_migration_timeseries(aggregated);
catch ME
    fprintf('✗ ERROR creating plots: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Step 5: Export to CSV
fprintf('STEP 5/5: Exporting data to CSV\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    export_results_csv(aggregated);
catch ME
    fprintf('✗ ERROR exporting CSV: %s\n', ME.message);
    return;
end

%% Summary
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ANALYSIS COMPLETE                        ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

fprintf('Generated Files:\n');
fprintf('\n');
fprintf('  Figures (PNG):\n');
fprintf('    • migration_timeseries_Control.png\n');
fprintf('    • migration_timeseries_Shock.png\n');
fprintf('    • migration_timeseries_PA.png\n');
fprintf('    • migration_timeseries_PA_Shock.png\n');
fprintf('    • migration_timeseries_Comparison.png\n');
fprintf('\n');
fprintf('  Data (CSV):\n');
fprintf('    • migration_count_timeseries.csv\n');
fprintf('    • total_distance_timeseries.csv\n');
fprintf('    • avg_distance_timeseries.csv\n');
fprintf('\n');

% Display summary statistics
fprintf('Summary Statistics:\n');
fprintf('─────────────────────────────────────────────────────────────\n');
scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
scenarioNames = {'Control', 'Shock Only', 'PA Only', 'PA + Shock'};

for s = 1:length(scenarios)
    if isfield(aggregated, scenarios{s})
        data = aggregated.(scenarios{s});
        fprintf('\n%s:\n', scenarioNames{s});
        fprintf('  Total migrations: %.0f ± %.0f\n', ...
            sum(data.migrationCount_mean), ...
            sqrt(sum(data.migrationCount_std.^2)));
        fprintf('  Avg migrations/timestep: %.1f ± %.1f\n', ...
            mean(data.migrationCount_mean), ...
            mean(data.migrationCount_std));
        fprintf('  Avg distance traveled: %.1f ± %.1f km\n', ...
            mean(data.avgDistance_mean(data.avgDistance_mean > 0)), ...
            mean(data.avgDistance_std(data.avgDistance_std > 0)));
    end
end

fprintf('\n');
fprintf('✓ All files saved in: %s\n', pwd);
fprintf('\n');

