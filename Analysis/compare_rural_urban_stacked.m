function compare_rural_urban_stacked()
% COMPARE_RURAL_URBAN_STACKED Compare rural-urban migration patterns over time
%
% Compares baseline vs shock scenarios using stacked area time series
% Classifies movements as R→R, R→U, U→R, U→U per timestep
%
% Outputs:
%   - Analysis/Figures/rural_urban_stacked_comparison.png
%   - Analysis/Data/rural_urban_comparison.csv

fprintf('\n=== COMPARING RURAL-URBAN MIGRATION PATTERNS (TIME SERIES) ===\n\n');

% File paths
baseline_file = 'Outputs/Madagascar_PA_Shock_Full_Run012_2025-11-13_00-29-17.mat';
shock_file = 'Outputs/MADA_shock_south.mat';

% Load scenarios
fprintf('Loading baseline scenario: %s\n', baseline_file);
baseline_data = load(baseline_file);

fprintf('Loading shock scenario: %s\n', shock_file);
shock_data = load(shock_file);

% Get urban/rural classification
locations_table = baseline_data.output.mapVariables.locations;

% Create mapping from location ID to urban/rural status
urban_rural_map = containers.Map('KeyType', 'double', 'ValueType', 'char');
for i = 1:height(locations_table)
    loc_id = i;  % Assuming location ID is the row index
    urban_rural_map(loc_id) = locations_table.URBAN_RURAL{i}(1);  % 'R' or 'U'
end

% Determine number of timesteps (use max of both to ensure compatibility)
num_timesteps_baseline = length(baseline_data.output.migrations);
num_timesteps_shock = length(shock_data.output.migrations);
num_timesteps = max(num_timesteps_baseline, num_timesteps_shock);

fprintf('\nClassifying movements per timestep...\n');

% Classify baseline movements per timestep
baseline_timeseries = classify_movements_timeseries(baseline_data.output.agentSummary, urban_rural_map, num_timesteps);

% Classify shock movements per timestep
shock_timeseries = classify_movements_timeseries(shock_data.output.agentSummary, urban_rural_map, num_timesteps);

fprintf('  Baseline total: R→R=%d, R→U=%d, U→R=%d, U→U=%d\n', ...
    sum(baseline_timeseries.RR), sum(baseline_timeseries.RU), ...
    sum(baseline_timeseries.UR), sum(baseline_timeseries.UU));
fprintf('  Shock total: R→R=%d, R→U=%d, U→R=%d, U→U=%d\n', ...
    sum(shock_timeseries.RR), sum(shock_timeseries.RU), ...
    sum(shock_timeseries.UR), sum(shock_timeseries.UU));

% Create stacked area time series plot
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1400 800]);

% Ensure all vectors are column vectors and same length
baseline_RR = baseline_timeseries.RR(:);
baseline_RU = baseline_timeseries.RU(:);
baseline_UR = baseline_timeseries.UR(:);
baseline_UU = baseline_timeseries.UU(:);

shock_RR = shock_timeseries.RR(:);
shock_RU = shock_timeseries.RU(:);
shock_UR = shock_timeseries.UR(:);
shock_UU = shock_timeseries.UU(:);

% Pad to same length if needed
if length(baseline_RR) < num_timesteps
    baseline_RR(end+1:num_timesteps) = 0;
    baseline_RU(end+1:num_timesteps) = 0;
    baseline_UR(end+1:num_timesteps) = 0;
    baseline_UU(end+1:num_timesteps) = 0;
end
if length(shock_RR) < num_timesteps
    shock_RR(end+1:num_timesteps) = 0;
    shock_RU(end+1:num_timesteps) = 0;
    shock_UR(end+1:num_timesteps) = 0;
    shock_UU(end+1:num_timesteps) = 0;
end

% Subplot 1: Baseline
subplot(2, 1, 1);
area(1:num_timesteps, [baseline_RR, baseline_RU, baseline_UR, baseline_UU]);
xlabel('Timestep', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 11, 'FontWeight', 'bold');
title('Baseline (PA+Shock Run012)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 10);
grid on;
xlim([1 num_timesteps]);

% Subplot 2: Shock
subplot(2, 1, 2);
area(1:num_timesteps, [shock_RR, shock_RU, shock_UR, shock_UU]);
xlabel('Timestep', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 11, 'FontWeight', 'bold');
title('Shock (South)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 10);
grid on;
xlim([1 num_timesteps]);

sgtitle('Rural-Urban Migration Patterns Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');

% Save figure
fig_file = 'Analysis/Figures/rural_urban_stacked_comparison.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', ...
    baseline_RR, baseline_RU, baseline_UR, baseline_UU, ...
    shock_RR, shock_RU, shock_UR, shock_UU, ...
    'VariableNames', {'Timestep', 'Baseline_RR', 'Baseline_RU', 'Baseline_UR', 'Baseline_UU', ...
    'Shock_RR', 'Shock_RU', 'Shock_UR', 'Shock_UU'});

csv_file = 'Analysis/Data/rural_urban_comparison.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Rural-urban comparison complete!\n\n');

end


function timeseries = classify_movements_timeseries(agentSummary, urban_rural_map, num_timesteps)
% Classify movements as R→R, R→U, U→R, or U→U per timestep

timeseries = struct('RR', zeros(num_timesteps, 1), 'RU', zeros(num_timesteps, 1), ...
    'UR', zeros(num_timesteps, 1), 'UU', zeros(num_timesteps, 1));

% Iterate through all agents
for i = 1:height(agentSummary)
    moveHistory = agentSummary.moveHistory{i};
    
    if isempty(moveHistory)
        continue;
    end
    
    % Each row in moveHistory: [timestep, from_location, to_location, distance]
    for m = 1:size(moveHistory, 1)
        timestep = moveHistory(m, 1);
        from_loc = moveHistory(m, 2);
        to_loc = moveHistory(m, 3);
        
        % Skip if timestep is out of range
        if timestep < 1 || timestep > num_timesteps
            continue;
        end
        
        % Get urban/rural status
        if isKey(urban_rural_map, from_loc) && isKey(urban_rural_map, to_loc)
            from_type = urban_rural_map(from_loc);
            to_type = urban_rural_map(to_loc);
            
            % Classify movement and add to appropriate timestep
            if from_type == 'R' && to_type == 'R'
                timeseries.RR(timestep) = timeseries.RR(timestep) + 1;
            elseif from_type == 'R' && to_type == 'U'
                timeseries.RU(timestep) = timeseries.RU(timestep) + 1;
            elseif from_type == 'U' && to_type == 'R'
                timeseries.UR(timestep) = timeseries.UR(timestep) + 1;
            elseif from_type == 'U' && to_type == 'U'
                timeseries.UU(timestep) = timeseries.UU(timestep) + 1;
            end
        end
    end
end

end

