function export_rural_urban_csv(aggregated)
% EXPORT_RURAL_URBAN_CSV Export rural-urban flow data to CSV files
%
% Inputs:
%   aggregated - Struct from aggregate_rural_urban_flows
%
% Creates 5 CSV files:
%   - rural_rural_migrations.csv (time series)
%   - rural_urban_migrations.csv (time series)
%   - urban_rural_migrations.csv (time series)
%   - urban_urban_migrations.csv (time series)
%   - rural_urban_totals.csv (summary totals)

fprintf('=== EXPORTING RURAL-URBAN DATA TO CSV ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};

% Determine number of timesteps
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

%% Export R→R time series
fprintf('Exporting Rural→Rural migrations...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).RR_mean;
        T.(stdCol) = aggregated.(scenarioName).RR_std;
    end
end

writetable(T, 'rural_rural_migrations.csv');
fprintf('  Saved: rural_rural_migrations.csv\n');

%% Export R→U time series
fprintf('Exporting Rural→Urban migrations...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).RU_mean;
        T.(stdCol) = aggregated.(scenarioName).RU_std;
    end
end

writetable(T, 'rural_urban_migrations.csv');
fprintf('  Saved: rural_urban_migrations.csv\n');

%% Export U→R time series
fprintf('Exporting Urban→Rural migrations...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).UR_mean;
        T.(stdCol) = aggregated.(scenarioName).UR_std;
    end
end

writetable(T, 'urban_rural_migrations.csv');
fprintf('  Saved: urban_rural_migrations.csv\n');

%% Export U→U time series
fprintf('Exporting Urban→Urban migrations...\n');
T = table(timesteps, 'VariableNames', {'Timestep'});

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        meanCol = sprintf('%s_Mean', scenarioName);
        stdCol = sprintf('%s_Std', scenarioName);
        T.(meanCol) = aggregated.(scenarioName).UU_mean;
        T.(stdCol) = aggregated.(scenarioName).UU_std;
    end
end

writetable(T, 'urban_urban_migrations.csv');
fprintf('  Saved: urban_urban_migrations.csv\n');

%% Export summary totals
fprintf('Exporting summary totals...\n');

% Create table with totals for each scenario
Scenario = scenarios';
RR_Total = zeros(length(scenarios), 1);
RR_Std = zeros(length(scenarios), 1);
RU_Total = zeros(length(scenarios), 1);
RU_Std = zeros(length(scenarios), 1);
UR_Total = zeros(length(scenarios), 1);
UR_Std = zeros(length(scenarios), 1);
UU_Total = zeros(length(scenarios), 1);
UU_Std = zeros(length(scenarios), 1);

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        RR_Total(s) = aggregated.(scenarioName).RR_total;
        RR_Std(s) = aggregated.(scenarioName).RR_total_std;
        RU_Total(s) = aggregated.(scenarioName).RU_total;
        RU_Std(s) = aggregated.(scenarioName).RU_total_std;
        UR_Total(s) = aggregated.(scenarioName).UR_total;
        UR_Std(s) = aggregated.(scenarioName).UR_total_std;
        UU_Total(s) = aggregated.(scenarioName).UU_total;
        UU_Std(s) = aggregated.(scenarioName).UU_total_std;
    end
end

T = table(Scenario, RR_Total, RR_Std, RU_Total, RU_Std, ...
    UR_Total, UR_Std, UU_Total, UU_Std);

writetable(T, 'rural_urban_totals.csv');
fprintf('  Saved: rural_urban_totals.csv\n');

fprintf('\n✓ CSV export complete\n\n');

end

