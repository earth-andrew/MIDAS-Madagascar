function export_results_csv(aggregated)
% EXPORT_RESULTS_CSV Export aggregated time series data to CSV files
%
% Inputs:
%   aggregated - Struct from aggregate_scenarios
%
% Creates 3 CSV files:
%   - migration_count_timeseries.csv
%   - total_distance_timeseries.csv
%   - avg_distance_timeseries.csv
%
% Each CSV has columns: Timestep, Control_Mean, Control_Std, Shock_Mean,
% Shock_Std, PA_Mean, PA_Std, PA_Shock_Mean, PA_Shock_Std

fprintf('=== EXPORTING DATA TO CSV ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};

% Determine number of timesteps (from first available scenario)
numTimesteps = 0;
for s = 1:length(scenarios)
    if isfield(aggregated, scenarios{s})
        numTimesteps = aggregated.(scenarios{s}).numTimesteps;
        break;
    end
end

if numTimesteps == 0
    error('No scenarios found in aggregated data');
end

timesteps = (1:numTimesteps)';

%% Export Migration Count
fprintf('Exporting migration count data...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).migrationCount_mean;
        T.(stdCol) = aggregated.(scenarioName).migrationCount_std;
    end
end

writetable(T, 'migration_count_timeseries.csv');
fprintf('  Saved: migration_count_timeseries.csv\n');

%% Export Total Distance
fprintf('Exporting total distance data...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).totalDistance_mean;
        T.(stdCol) = aggregated.(scenarioName).totalDistance_std;
    end
end

writetable(T, 'total_distance_timeseries.csv');
fprintf('  Saved: total_distance_timeseries.csv\n');

%% Export Average Distance
fprintf('Exporting average distance data...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).avgDistance_mean;
        T.(stdCol) = aggregated.(scenarioName).avgDistance_std;
    end
end

writetable(T, 'avg_distance_timeseries.csv');
fprintf('  Saved: avg_distance_timeseries.csv\n');

fprintf('\n✓ CSV export complete\n\n');

end

