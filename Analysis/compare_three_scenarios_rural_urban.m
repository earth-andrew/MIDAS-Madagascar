function compare_three_scenarios_rural_urban(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_RURAL_URBAN Compare rural-urban migration patterns for 3 scenarios
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for legend
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_rural_urban_<suffix>.png
%   - Analysis/Data/three_way_rural_urban_<suffix>.csv

fprintf('\n=== COMPARING RURAL-URBAN MIGRATION PATTERNS (3 SCENARIOS) ===\n\n');

% Load scenarios
fprintf('Loading scenario 1: %s\n', file1);
data1 = load(file1);

fprintf('Loading scenario 2: %s\n', file2);
data2 = load(file2);

fprintf('Loading scenario 3: %s\n', file3);
data3 = load(file3);

% Get urban/rural classification (use first scenario's locations)
locations_table = data1.output.mapVariables.locations;

% Create mapping from location ID to urban/rural status
urban_rural_map = containers.Map('KeyType', 'double', 'ValueType', 'char');
for i = 1:height(locations_table)
    loc_id = i;
    urban_rural_map(loc_id) = locations_table.URBAN_RURAL{i}(1);  % 'R' or 'U'
end

% Determine number of timesteps
num_timesteps1 = length(data1.output.migrations);
num_timesteps2 = length(data2.output.migrations);
num_timesteps3 = length(data3.output.migrations);
num_timesteps = max([num_timesteps1, num_timesteps2, num_timesteps3]);

fprintf('\nClassifying movements per timestep...\n');

% Classify movements per timestep for each scenario
timeseries1 = classify_movements_timeseries(data1.output.agentSummary, urban_rural_map, num_timesteps);
timeseries2 = classify_movements_timeseries(data2.output.agentSummary, urban_rural_map, num_timesteps);
timeseries3 = classify_movements_timeseries(data3.output.agentSummary, urban_rural_map, num_timesteps);

fprintf('  %s total: R→R=%d, R→U=%d, U→R=%d, U→U=%d\n', name1, ...
    sum(timeseries1.RR), sum(timeseries1.RU), sum(timeseries1.UR), sum(timeseries1.UU));
fprintf('  %s total: R→R=%d, R→U=%d, U→R=%d, U→U=%d\n', name2, ...
    sum(timeseries2.RR), sum(timeseries2.RU), sum(timeseries2.UR), sum(timeseries2.UU));
fprintf('  %s total: R→R=%d, R→U=%d, U→R=%d, U→U=%d\n', name3, ...
    sum(timeseries3.RR), sum(timeseries3.RU), sum(timeseries3.UR), sum(timeseries3.UU));

% Ensure all vectors are column vectors and same length
RR1 = timeseries1.RR(:); RU1 = timeseries1.RU(:); UR1 = timeseries1.UR(:); UU1 = timeseries1.UU(:);
RR2 = timeseries2.RR(:); RU2 = timeseries2.RU(:); UR2 = timeseries2.UR(:); UU2 = timeseries2.UU(:);
RR3 = timeseries3.RR(:); RU3 = timeseries3.RU(:); UR3 = timeseries3.UR(:); UU3 = timeseries3.UU(:);

% Pad to same length if needed
if length(RR1) < num_timesteps
    RR1(end+1:num_timesteps) = 0; RU1(end+1:num_timesteps) = 0;
    UR1(end+1:num_timesteps) = 0; UU1(end+1:num_timesteps) = 0;
end
if length(RR2) < num_timesteps
    RR2(end+1:num_timesteps) = 0; RU2(end+1:num_timesteps) = 0;
    UR2(end+1:num_timesteps) = 0; UU2(end+1:num_timesteps) = 0;
end
if length(RR3) < num_timesteps
    RR3(end+1:num_timesteps) = 0; RU3(end+1:num_timesteps) = 0;
    UR3(end+1:num_timesteps) = 0; UU3(end+1:num_timesteps) = 0;
end

% Create stacked area time series plot
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1400 1200]);

% Subplot 1: Scenario 1
subplot(3, 1, 1);
area(1:num_timesteps, [RR1, RU1, UR1, UU1]);
xlabel('Timestep', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 11, 'FontWeight', 'bold');
title(name1, 'FontSize', 12, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 10);
grid on;
xlim([1 num_timesteps]);

% Subplot 2: Scenario 2
subplot(3, 1, 2);
area(1:num_timesteps, [RR2, RU2, UR2, UU2]);
xlabel('Timestep', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 11, 'FontWeight', 'bold');
title(name2, 'FontSize', 12, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 10);
grid on;
xlim([1 num_timesteps]);

% Subplot 3: Scenario 3
subplot(3, 1, 3);
area(1:num_timesteps, [RR3, RU3, UR3, UU3]);
xlabel('Timestep', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 11, 'FontWeight', 'bold');
title(name3, 'FontSize', 12, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 10);
grid on;
xlim([1 num_timesteps]);

sgtitle(sprintf('Rural-Urban Migration Patterns Over Time: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');

% Save figure
fig_file = sprintf('Analysis/Figures/three_way_rural_urban_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', ...
    RR1, RU1, UR1, UU1, ...
    RR2, RU2, UR2, UU2, ...
    RR3, RU3, UR3, UU3, ...
    'VariableNames', {'Timestep', ...
    [name1 '_RR'], [name1 '_RU'], [name1 '_UR'], [name1 '_UU'], ...
    [name2 '_RR'], [name2 '_RU'], [name2 '_UR'], [name2 '_UU'], ...
    [name3 '_RR'], [name3 '_RU'], [name3 '_UR'], [name3 '_UU']});

csv_file = sprintf('Analysis/Data/three_way_rural_urban_%s.csv', output_suffix);
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

