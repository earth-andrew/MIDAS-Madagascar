function run_three_way_analysis()
% RUN_THREE_WAY_ANALYSIS Main orchestrator for three-way comparative analysis
%
% Compares 3 scenarios at a time for two groups:
%   Group 1 (No PA): Baseline vs Shock_R vs Shock_UR
%   Group 2 (With PA): Baseline_PA vs Shock_R_PA vs Shock_UR_PA
%
% Outputs saved to:
%   - Analysis/Figures/three_way_*_noPA.png
%   - Analysis/Figures/three_way_*_withPA.png
%   - Analysis/Data/three_way_*_noPA.csv
%   - Analysis/Data/three_way_*_withPA.csv

fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║        THREE-WAY COMPARATIVE ANALYSIS                        ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

% Get project root directory (where this script is located)
% This script is in Analysis/, so go up one level
script_path = mfilename('fullpath');
[project_root, ~, ~] = fileparts(fileparts(script_path));

% Change to project root directory
cd(project_root);
fprintf('Changed to project root: %s\n\n', project_root);

% Start timer
tic;

% Create output directories if they don't exist
if ~exist('Analysis/Figures', 'dir')
    mkdir('Analysis/Figures');
end
if ~exist('Analysis/Data', 'dir')
    mkdir('Analysis/Data');
end

% Add Analysis folder to path
addpath('./Analysis');

% File mapping based on experiment design
% Run001: Baseline (no PA, no shock)
% Run002: Baseline_PA (PA on, no shock)
% Run003: Shock_UR (no PA, shock urban+rural)
% Run004: Shock_UR_PA (PA on, shock urban+rural)
% Run005: Shock_R (no PA, shock rural only)
% Run006: Shock_R_PA (PA on, shock rural only)

% Find the most recent output files matching the pattern
% Look for files in Outputs/ directory
output_dir = fullfile(project_root, 'Outputs');
output_files = dir(fullfile(output_dir, 'Madagascar_test_sweep_Run*.mat'));

if isempty(output_files)
    error('No output files found in Outputs/ directory. Please run the experiment first.');
end

% Sort by modification date (most recent first)
[~, idx] = sort([output_files.datenum], 'descend');
output_files = output_files(idx);

% Extract run numbers from filenames
run_numbers = zeros(length(output_files), 1);
for i = 1:length(output_files)
    filename = output_files(i).name;
    % Extract RunXXX from filename
    run_match = regexp(filename, 'Run(\d+)', 'tokens');
    if ~isempty(run_match)
        run_numbers(i) = str2double(run_match{1}{1});
    end
end

% Map run numbers to files
file_map = containers.Map('KeyType', 'double', 'ValueType', 'char');
for i = 1:length(output_files)
    file_map(run_numbers(i)) = fullfile(output_dir, output_files(i).name);
end

% Group 1 (No PA): Baseline vs Shock_R vs Shock_UR
% Run001: Baseline, Run005: Shock_R, Run003: Shock_UR
if ~isKey(file_map, 1) || ~isKey(file_map, 5) || ~isKey(file_map, 3)
    error('Missing required files: Run001 (Baseline), Run003 (Shock_UR), or Run005 (Shock_R)');
end

group1_files = {
    file_map(1),  % Baseline
    file_map(5),  % Shock_R
    file_map(3)   % Shock_UR
};
group1_names = {'Baseline', 'Shock_R (Rural Only)', 'Shock_UR (Urban+Rural)'};

% Group 2 (With PA): Baseline_PA vs Shock_R_PA vs Shock_UR_PA
% Run002: Baseline_PA, Run006: Shock_R_PA, Run004: Shock_UR_PA
if ~isKey(file_map, 2) || ~isKey(file_map, 6) || ~isKey(file_map, 4)
    error('Missing required files: Run002 (Baseline_PA), Run004 (Shock_UR_PA), or Run006 (Shock_R_PA)');
end

group2_files = {
    file_map(2),  % Baseline_PA
    file_map(6),  % Shock_R_PA
    file_map(4)   % Shock_UR_PA
};
group2_names = {'Baseline_PA', 'Shock_R_PA (Rural Only)', 'Shock_UR_PA (Urban+Rural)'};

fprintf('Group 1 (No PA):\n');
fprintf('  • %s\n', group1_names{1});
fprintf('  • %s\n', group1_names{2});
fprintf('  • %s\n\n', group1_names{3});

fprintf('Group 2 (With PA):\n');
fprintf('  • %s\n', group2_names{1});
fprintf('  • %s\n', group2_names{2});
fprintf('  • %s\n\n', group2_names{3});

fprintf('═══════════════════════════════════════════════════════════════\n\n');

% Analyze Group 1 (No PA)
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║              GROUP 1: NO PLACE ATTACHMENT                    ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Analysis 1: Total Migrations
fprintf('[1/5] Running total migrations comparison (No PA)...\n');
try
    compare_three_scenarios_migrations(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 2: Rural-Urban Stacked (Time Series)
fprintf('[2/6] Running rural-urban stacked time series comparison (No PA)...\n');
try
    compare_three_scenarios_rural_urban(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 3: Rural-Urban Stacked Bar Chart
fprintf('[3/6] Running rural-urban stacked bar chart comparison (No PA)...\n');
try
    compare_three_scenarios_rural_urban_stacked(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 4: Average Income
fprintf('[4/6] Running average income comparison (No PA)...\n');
try
    compare_three_scenarios_income(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 5: Gini Coefficient
fprintf('[5/6] Running Gini coefficient comparison (No PA)...\n');
try
    compare_three_scenarios_gini(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 6: Return to Origin
fprintf('[6/6] Running return to origin comparison (No PA)...\n');
try
    compare_three_scenarios_return_origin(group1_files{1}, group1_files{2}, group1_files{3}, ...
        group1_names{1}, group1_names{2}, group1_names{3}, 'noPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

fprintf('═══════════════════════════════════════════════════════════════\n\n');

% Analyze Group 2 (With PA)
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║              GROUP 2: WITH PLACE ATTACHMENT                ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Analysis 1: Total Migrations
fprintf('[1/5] Running total migrations comparison (With PA)...\n');
try
    compare_three_scenarios_migrations(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 2: Rural-Urban Stacked (Time Series)
fprintf('[2/6] Running rural-urban stacked time series comparison (With PA)...\n');
try
    compare_three_scenarios_rural_urban(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 3: Rural-Urban Stacked Bar Chart
fprintf('[3/6] Running rural-urban stacked bar chart comparison (With PA)...\n');
try
    compare_three_scenarios_rural_urban_stacked(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 4: Average Income
fprintf('[4/6] Running average income comparison (With PA)...\n');
try
    compare_three_scenarios_income(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 5: Gini Coefficient
fprintf('[5/6] Running Gini coefficient comparison (With PA)...\n');
try
    compare_three_scenarios_gini(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis 6: Return to Origin
fprintf('[6/6] Running return to origin comparison (With PA)...\n');
try
    compare_three_scenarios_return_origin(group2_files{1}, group2_files{2}, group2_files{3}, ...
        group2_names{1}, group2_names{2}, group2_names{3}, 'withPA');
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

fprintf('═══════════════════════════════════════════════════════════════\n\n');

% Additional Cross-Group Analyses
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║         CROSS-GROUP COMPARISONS                               ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Analysis: Side-by-Side PA Comparison
fprintf('[Additional] Running side-by-side PA comparison...\n');
try
    compare_scenarios_with_without_PA(...
        group1_files{1}, group2_files{1}, ...  % Baseline, Baseline_PA
        group1_files{2}, group2_files{2}, ...  % Shock_R, Shock_R_PA
        group1_files{3}, group2_files{3} ...   % Shock_UR, Shock_UR_PA
    );
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% Analysis: Return Migration Percentage
fprintf('[Additional] Running return migration percentage analysis...\n');
try
    compare_return_migration_percentage(...
        group1_files{1}, group2_files{1}, ...  % Baseline, Baseline_PA
        group1_files{2}, group2_files{2}, ...  % Shock_R, Shock_R_PA
        group1_files{3}, group2_files{3} ...   % Shock_UR, Shock_UR_PA
    );
    fprintf('      ✓ Complete\n\n');
catch ME
    fprintf('      ✗ Error: %s\n\n', ME.message);
end

% End timer
elapsed_time = toc;

fprintf('═══════════════════════════════════════════════════════════════\n\n');

% Summary
fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║                    ANALYSIS COMPLETE!                        ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

fprintf('Time elapsed: %.1f seconds\n\n', elapsed_time);

fprintf('Output Files Generated:\n\n');
fprintf('Group 1 (No PA) - Figures:\n');
fprintf('  1. Analysis/Figures/three_way_migrations_noPA.png\n');
fprintf('  2. Analysis/Figures/three_way_rural_urban_noPA.png\n');
fprintf('  3. Analysis/Figures/three_way_rural_urban_stacked_noPA.png\n');
fprintf('  4. Analysis/Figures/three_way_income_noPA.png\n');
fprintf('  5. Analysis/Figures/three_way_gini_noPA.png\n');
fprintf('  6. Analysis/Figures/three_way_return_origin_total_noPA.png\n');
fprintf('  7. Analysis/Figures/three_way_return_origin_distribution_noPA.png\n');
fprintf('  8. Analysis/Figures/three_way_return_origin_timeseries_noPA.png\n\n');

fprintf('Group 2 (With PA) - Figures:\n');
fprintf('  1. Analysis/Figures/three_way_migrations_withPA.png\n');
fprintf('  2. Analysis/Figures/three_way_rural_urban_withPA.png\n');
fprintf('  3. Analysis/Figures/three_way_rural_urban_stacked_withPA.png\n');
fprintf('  4. Analysis/Figures/three_way_income_withPA.png\n');
fprintf('  5. Analysis/Figures/three_way_gini_withPA.png\n');
fprintf('  6. Analysis/Figures/three_way_return_origin_total_withPA.png\n');
fprintf('  7. Analysis/Figures/three_way_return_origin_distribution_withPA.png\n');
fprintf('  8. Analysis/Figures/three_way_return_origin_timeseries_withPA.png\n\n');

fprintf('Cross-Group Figures:\n');
fprintf('  1. Analysis/Figures/rural_urban_stacked_with_without_PA.png\n');
fprintf('  2. Analysis/Figures/return_migration_percentage_all.png\n');
fprintf('  3. Analysis/Figures/return_migration_percentage_paired.png\n\n');

fprintf('Data Files (CSV):\n');
fprintf('  - Analysis/Data/three_way_migrations_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_rural_urban_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_rural_urban_stacked_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_income_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_gini_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_return_origin_noPA.csv\n');
fprintf('  - Analysis/Data/three_way_migrations_withPA.csv\n');
fprintf('  - Analysis/Data/three_way_rural_urban_withPA.csv\n');
fprintf('  - Analysis/Data/three_way_rural_urban_stacked_withPA.csv\n');
fprintf('  - Analysis/Data/three_way_income_withPA.csv\n');
fprintf('  - Analysis/Data/three_way_gini_withPA.csv\n');
fprintf('  - Analysis/Data/three_way_return_origin_withPA.csv\n');
fprintf('  - Analysis/Data/rural_urban_stacked_with_without_PA.csv\n');
fprintf('  - Analysis/Data/return_migration_percentage.csv\n\n');

fprintf('All analyses complete! Review the figures and data files.\n\n');

end

