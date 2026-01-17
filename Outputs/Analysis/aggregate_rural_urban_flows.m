function [aggregated] = aggregate_rural_urban_flows(ruMigrations)
% AGGREGATE_RURAL_URBAN_FLOWS Aggregate rural-urban flows by scenario
%
% Inputs:
%   ruMigrations - Struct array from calculate_rural_urban_migrations
%
% Returns:
%   aggregated - Struct with fields for each scenario:
%     .Control, .Shock, .PA, .PA_Shock - Each containing:
%       Time series (mean ± std):
%         .RR_mean, .RR_std: Rural→Rural per timestep
%         .RU_mean, .RU_std: Rural→Urban per timestep
%         .UR_mean, .UR_std: Urban→Rural per timestep
%         .UU_mean, .UU_std: Urban→Urban per timestep
%       Totals (for stacked bar chart):
%         .RR_total, .RU_total, .UR_total, .UU_total
%       Metadata:
%         .numTimesteps, .numReplications

fprintf('=== AGGREGATING RURAL-URBAN FLOWS ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
aggregated = struct();

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    fprintf('Processing %s scenario...\n', scenarioName);
    
    % Find all runs for this scenario
    scenarioIdx = find(strcmp({ruMigrations.scenario}, scenarioName));
    numReps = length(scenarioIdx);
    
    if numReps == 0
        warning('No runs found for scenario: %s', scenarioName);
        continue;
    end
    
    fprintf('  Found %d replications\n', numReps);
    
    % Get number of timesteps
    numTimesteps = ruMigrations(scenarioIdx(1)).numTimesteps;
    
    % Initialize matrices to hold all replications
    RR_all = zeros(numTimesteps, numReps);
    RU_all = zeros(numTimesteps, numReps);
    UR_all = zeros(numTimesteps, numReps);
    UU_all = zeros(numTimesteps, numReps);
    
    % Collect data from all replications
    for r = 1:numReps
        idx = scenarioIdx(r);
        RR_all(:, r) = ruMigrations(idx).RR;
        RU_all(:, r) = ruMigrations(idx).RU;
        UR_all(:, r) = ruMigrations(idx).UR;
        UU_all(:, r) = ruMigrations(idx).UU;
    end
    
    % Calculate mean and std across replications (for time series)
    aggregated.(scenarioName).RR_mean = mean(RR_all, 2);
    aggregated.(scenarioName).RR_std = std(RR_all, 0, 2);
    
    aggregated.(scenarioName).RU_mean = mean(RU_all, 2);
    aggregated.(scenarioName).RU_std = std(RU_all, 0, 2);
    
    aggregated.(scenarioName).UR_mean = mean(UR_all, 2);
    aggregated.(scenarioName).UR_std = std(UR_all, 0, 2);
    
    aggregated.(scenarioName).UU_mean = mean(UU_all, 2);
    aggregated.(scenarioName).UU_std = std(UU_all, 0, 2);
    
    % Calculate total migrations (sum across all timesteps, then mean across reps)
    % For stacked bar chart
    RR_totals = sum(RR_all, 1);  % Sum across timesteps for each rep
    RU_totals = sum(RU_all, 1);
    UR_totals = sum(UR_all, 1);
    UU_totals = sum(UU_all, 1);
    
    aggregated.(scenarioName).RR_total = mean(RR_totals);
    aggregated.(scenarioName).RU_total = mean(RU_totals);
    aggregated.(scenarioName).UR_total = mean(UR_totals);
    aggregated.(scenarioName).UU_total = mean(UU_totals);
    
    % Also store std of totals
    aggregated.(scenarioName).RR_total_std = std(RR_totals);
    aggregated.(scenarioName).RU_total_std = std(RU_totals);
    aggregated.(scenarioName).UR_total_std = std(UR_totals);
    aggregated.(scenarioName).UU_total_std = std(UU_totals);
    
    aggregated.(scenarioName).numTimesteps = numTimesteps;
    aggregated.(scenarioName).numReplications = numReps;
    
    % Print summary statistics
    total_migrations = aggregated.(scenarioName).RR_total + ...
                      aggregated.(scenarioName).RU_total + ...
                      aggregated.(scenarioName).UR_total + ...
                      aggregated.(scenarioName).UU_total;
    
    fprintf('  Total migrations: %.0f\n', total_migrations);
    fprintf('    R→R: %.0f (%.1f%%)\n', aggregated.(scenarioName).RR_total, ...
        100 * aggregated.(scenarioName).RR_total / total_migrations);
    fprintf('    R→U: %.0f (%.1f%%)\n', aggregated.(scenarioName).RU_total, ...
        100 * aggregated.(scenarioName).RU_total / total_migrations);
    fprintf('    U→R: %.0f (%.1f%%)\n', aggregated.(scenarioName).UR_total, ...
        100 * aggregated.(scenarioName).UR_total / total_migrations);
    fprintf('    U→U: %.0f (%.1f%%)\n\n', aggregated.(scenarioName).UU_total, ...
        100 * aggregated.(scenarioName).UU_total / total_migrations);
end

fprintf('✓ Aggregation complete\n\n');

end

