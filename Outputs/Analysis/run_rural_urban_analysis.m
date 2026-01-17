% RUN_RURAL_URBAN_ANALYSIS - Rural-Urban Migration Flow Analysis
%
% This script analyzes rural-urban migration patterns from the Madagascar
% factorial experiment (Place Attachment × Drought Shock).
%
% Workflow:
%   1. Load all 20 experimental output files
%   2. Classify migrations by flow type (R→R, R→U, U→R, U→U)
%   3. Aggregate by scenario (average across 5 replications)
%   4. Create time series visualizations (4 PNG files)
%   5. Create stacked bar chart comparison (1 PNG file)
%   6. Export data to CSV files (5 CSV files)
%
% Usage:
%   cd Outputs/Analysis
%   run_rural_urban_analysis
%
% Outputs:
%   Figures (5 PNG):
%     - rural_urban_migrations_Control.png
%     - rural_urban_migrations_Shock.png
%     - rural_urban_migrations_PA.png
%     - rural_urban_migrations_PA_Shock.png
%     - rural_urban_migrations_stacked_comparison.png
%   Data (5 CSV):
%     - rural_rural_migrations.csv
%     - rural_urban_migrations.csv
%     - urban_rural_migrations.csv
%     - urban_urban_migrations.csv
%     - rural_urban_totals.csv

clear; close all;

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║   MADAGASCAR RURAL-URBAN MIGRATION FLOW ANALYSIS           ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

%% Step 1: Load experiment data
fprintf('STEP 1/6: Loading experiment data\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    experimentData = load_experiment_data();
catch ME
    fprintf('✗ ERROR loading data: %s\n', ME.message);
    return;
end

%% Step 2: Calculate rural-urban migrations
fprintf('STEP 2/6: Calculating rural-urban migration flows\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    ruMigrations = calculate_rural_urban_migrations(experimentData);
catch ME
    fprintf('✗ ERROR calculating migrations: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Step 3: Aggregate by scenario
fprintf('STEP 3/6: Aggregating flows by scenario\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    aggregated = aggregate_rural_urban_flows(ruMigrations);
catch ME
    fprintf('✗ ERROR aggregating flows: %s\n', ME.message);
    return;
end

%% Step 4: Create time series plots
fprintf('STEP 4/6: Creating time series visualizations\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    plot_rural_urban_migrations(aggregated);
catch ME
    fprintf('✗ ERROR creating time series plots: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
    return;
end

%% Step 5: Create stacked bar chart
fprintf('STEP 5/6: Creating stacked bar chart comparison\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    plot_rural_urban_stacked(aggregated);
catch ME
    fprintf('✗ ERROR creating stacked chart: %s\n', ME.message);
    return;
end

%% Step 6: Export to CSV
fprintf('STEP 6/6: Exporting data to CSV\n');
fprintf('─────────────────────────────────────────────────────────────\n');
try
    export_rural_urban_csv(aggregated);
catch ME
    fprintf('✗ ERROR exporting CSV: %s\n', ME.message);
    return;
end

%% Summary
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║              RURAL-URBAN ANALYSIS COMPLETE                  ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

fprintf('Generated Files:\n');
fprintf('\n');
fprintf('  Time Series Plots (PNG):\n');
fprintf('    • rural_urban_migrations_Control.png\n');
fprintf('    • rural_urban_migrations_Shock.png\n');
fprintf('    • rural_urban_migrations_PA.png\n');
fprintf('    • rural_urban_migrations_PA_Shock.png\n');
fprintf('\n');
fprintf('  Comparison Plot (PNG):\n');
fprintf('    • rural_urban_migrations_stacked_comparison.png\n');
fprintf('\n');
fprintf('  Time Series Data (CSV):\n');
fprintf('    • rural_rural_migrations.csv\n');
fprintf('    • rural_urban_migrations.csv\n');
fprintf('    • urban_rural_migrations.csv\n');
fprintf('    • urban_urban_migrations.csv\n');
fprintf('\n');
fprintf('  Summary Data (CSV):\n');
fprintf('    • rural_urban_totals.csv\n');
fprintf('\n');

% Display summary table
fprintf('Summary Statistics (Total Migrations):\n');
fprintf('─────────────────────────────────────────────────────────────\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
scenarioNames = {'Control', 'Shock Only', 'PA Only', 'PA + Shock'};

% Create summary table
fprintf('\n%-15s %8s %8s %8s %8s %10s\n', 'Scenario', 'R→R', 'R→U', 'U→R', 'U→U', 'Total');
fprintf('%s\n', repmat('─', 1, 70));

for s = 1:length(scenarios)
    if isfield(aggregated, scenarios{s})
        data = aggregated.(scenarios{s});
        total = data.RR_total + data.RU_total + data.UR_total + data.UU_total;
        
        fprintf('%-15s %8.0f %8.0f %8.0f %8.0f %10.0f\n', ...
            scenarioNames{s}, data.RR_total, data.RU_total, ...
            data.UR_total, data.UU_total, total);
    end
end

fprintf('\n');
fprintf('Migration Type Definitions:\n');
fprintf('  R→R: Rural to Rural migration\n');
fprintf('  R→U: Rural to Urban migration (urbanization)\n');
fprintf('  U→R: Urban to Rural migration (rural return)\n');
fprintf('  U→U: Urban to Urban migration\n');
fprintf('\n');
fprintf('✓ All files saved in: %s\n', pwd);
fprintf('\n');

