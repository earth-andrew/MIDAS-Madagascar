function [aggregated] = aggregate_scenarios(metrics)
% AGGREGATE_SCENARIOS Aggregate metrics across replications by scenario
%
% Inputs:
%   metrics - Struct array from calculate_migration_metrics
%
% Returns:
%   aggregated - Struct with fields for each scenario:
%     .Control, .Shock, .PA, .PA_Shock - Each containing:
%       .migrationCount_mean: Mean migration count per timestep
%       .migrationCount_std: Std of migration count per timestep
%       .totalDistance_mean: Mean total distance per timestep
%       .totalDistance_std: Std of total distance per timestep
%       .avgDistance_mean: Mean average distance per timestep
%       .avgDistance_std: Std of average distance per timestep
%       .numTimesteps: Number of timesteps
%       .numReplications: Number of replications

fprintf('=== AGGREGATING SCENARIOS ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
aggregated = struct();

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    fprintf('Processing %s scenario...\n', scenarioName);
    
    % Find all runs for this scenario
    scenarioIdx = find(strcmp({metrics.scenario}, scenarioName));
    numReps = length(scenarioIdx);
    
    if numReps == 0
        warning('No runs found for scenario: %s', scenarioName);
        continue;
    end
    
    fprintf('  Found %d replications\n', numReps);
    
    % Get number of timesteps (assuming all runs have same length)
    numTimesteps = metrics(scenarioIdx(1)).numTimesteps;
    
    % Initialize matrices to hold all replications
    migrationCount_all = zeros(numTimesteps, numReps);
    totalDistance_all = zeros(numTimesteps, numReps);
    avgDistance_all = zeros(numTimesteps, numReps);
    
    % Collect data from all replications
    for r = 1:numReps
        idx = scenarioIdx(r);
        migrationCount_all(:, r) = metrics(idx).migrationCount;
        totalDistance_all(:, r) = metrics(idx).totalDistance;
        avgDistance_all(:, r) = metrics(idx).avgDistance;
    end
    
    % Calculate mean and std across replications
    aggregated.(scenarioName).migrationCount_mean = mean(migrationCount_all, 2);
    aggregated.(scenarioName).migrationCount_std = std(migrationCount_all, 0, 2);
    
    aggregated.(scenarioName).totalDistance_mean = mean(totalDistance_all, 2);
    aggregated.(scenarioName).totalDistance_std = std(totalDistance_all, 0, 2);
    
    aggregated.(scenarioName).avgDistance_mean = mean(avgDistance_all, 2);
    aggregated.(scenarioName).avgDistance_std = std(avgDistance_all, 0, 2);
    
    aggregated.(scenarioName).numTimesteps = numTimesteps;
    aggregated.(scenarioName).numReplications = numReps;
    
    % Print summary statistics
    fprintf('  Migration count: mean=%.1f±%.1f, max=%.1f\n', ...
        mean(aggregated.(scenarioName).migrationCount_mean), ...
        mean(aggregated.(scenarioName).migrationCount_std), ...
        max(aggregated.(scenarioName).migrationCount_mean));
    
    fprintf('  Total distance: mean=%.1f±%.1f, max=%.1f\n', ...
        mean(aggregated.(scenarioName).totalDistance_mean), ...
        mean(aggregated.(scenarioName).totalDistance_std), ...
        max(aggregated.(scenarioName).totalDistance_mean));
    
    fprintf('  Avg distance: mean=%.1f±%.1f\n\n', ...
        mean(aggregated.(scenarioName).avgDistance_mean(aggregated.(scenarioName).avgDistance_mean > 0)), ...
        mean(aggregated.(scenarioName).avgDistance_std(aggregated.(scenarioName).avgDistance_std > 0)));
end

fprintf('✓ Aggregation complete\n\n');

end

