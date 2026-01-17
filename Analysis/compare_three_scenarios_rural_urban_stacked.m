function compare_three_scenarios_rural_urban_stacked(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_RURAL_URBAN_STACKED Compare rural-urban migration split using stacked bars
%
% Creates a stacked bar chart showing total migrations split by type (R→R, R→U, U→R, U→U)
% for 3 scenarios side-by-side
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for x-axis labels
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_rural_urban_stacked_<suffix>.png
%   - Analysis/Data/three_way_rural_urban_stacked_<suffix>.csv

fprintf('\n=== COMPARING RURAL-URBAN MIGRATION SPLIT (STACKED BARS) ===\n\n');

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

fprintf('\nClassifying movements...\n');

% Classify all movements for each scenario (not per timestep, but total)
totals1 = classify_movements_total(data1.output.agentSummary, urban_rural_map);
totals2 = classify_movements_total(data2.output.agentSummary, urban_rural_map);
totals3 = classify_movements_total(data3.output.agentSummary, urban_rural_map);

% Calculate totals for each scenario
total1 = totals1.RR + totals1.RU + totals1.UR + totals1.UU;
total2 = totals2.RR + totals2.RU + totals2.UR + totals2.UU;
total3 = totals3.RR + totals3.RU + totals3.UR + totals3.UU;

fprintf('  %s total: R→R=%d (%.1f%%), R→U=%d (%.1f%%), U→R=%d (%.1f%%), U→U=%d (%.1f%%), Total=%d\n', ...
    name1, totals1.RR, (totals1.RR/total1*100), totals1.RU, (totals1.RU/total1*100), ...
    totals1.UR, (totals1.UR/total1*100), totals1.UU, (totals1.UU/total1*100), total1);
fprintf('  %s total: R→R=%d (%.1f%%), R→U=%d (%.1f%%), U→R=%d (%.1f%%), U→U=%d (%.1f%%), Total=%d\n', ...
    name2, totals2.RR, (totals2.RR/total2*100), totals2.RU, (totals2.RU/total2*100), ...
    totals2.UR, (totals2.UR/total2*100), totals2.UU, (totals2.UU/total2*100), total2);
fprintf('  %s total: R→R=%d (%.1f%%), R→U=%d (%.1f%%), U→R=%d (%.1f%%), U→U=%d (%.1f%%), Total=%d\n', ...
    name3, totals3.RR, (totals3.RR/total3*100), totals3.RU, (totals3.RU/total3*100), ...
    totals3.UR, (totals3.UR/total3*100), totals3.UU, (totals3.UU/total3*100), total3);

% Create stacked bar chart
fprintf('\nCreating stacked bar chart (percentages)...\n');
figure('Position', [100 100 1200 700]);

% Calculate percentages for each scenario
% Each column is a scenario, each row is a migration type
bar_data_percent = [
    totals1.RR/total1*100, totals2.RR/total2*100, totals3.RR/total3*100;  % R→R
    totals1.RU/total1*100, totals2.RU/total2*100, totals3.RU/total3*100;  % R→U
    totals1.UR/total1*100, totals2.UR/total2*100, totals3.UR/total3*100;  % U→R
    totals1.UU/total1*100, totals2.UU/total2*100, totals3.UU/total3*100   % U→U
];

% Keep absolute counts for CSV export
bar_data_absolute = [
    totals1.RR, totals2.RR, totals3.RR;  % R→R
    totals1.RU, totals2.RU, totals3.RU;  % R→U
    totals1.UR, totals2.UR, totals3.UR;  % U→R
    totals1.UU, totals2.UU, totals3.UU   % U→U
];

% Create stacked bar chart with percentages
h = bar(bar_data_percent', 'stacked');

% Set colors for each migration type
% R→R: brown/orange, R→U: green, U→R: blue, U→U: purple
colors = [
    0.8 0.4 0.2;  % R→R: orange/brown
    0.2 0.8 0.4;  % R→U: green
    0.2 0.4 0.8;  % U→R: blue
    0.6 0.2 0.8   % U→U: purple
];

for i = 1:length(h)
    h(i).FaceColor = colors(i, :);
    h(i).EdgeColor = 'k';
    h(i).LineWidth = 1.5;
end

% Set x-axis labels
set(gca, 'XTickLabel', {name1, name2, name3});
xlabel('Scenario', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Percentage of Total Migrations (%)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Rural-Urban Migration Split (Percentage): %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
ylim([0 100]);  % Set y-axis to 0-100%

% Add legend
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 11);

grid on;
grid minor;

% Add value labels on top of each bar segment (show percentages)
% Calculate cumulative heights for each scenario
cumulative_heights = cumsum(bar_data_percent, 1);
for i = 1:3  % For each scenario (column)
    for j = 1:4  % For each migration type (row)
        value_percent = bar_data_percent(j, i);
        if value_percent > 1  % Only label if > 1% (to avoid clutter)
            y_pos = cumulative_heights(j, i) - value_percent/2;  % Middle of segment
            text(i, y_pos, sprintf('%.1f%%', value_percent), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 9, ...
                'FontWeight', 'bold', ...
                'Color', 'white');
        end
    end
end

% Save figure
fig_file = sprintf('Analysis/Figures/three_way_rural_urban_stacked_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV (with both absolute counts and percentages)
fprintf('Exporting data to CSV...\n');
csv_data = table({name1; name2; name3}, ...
    [totals1.RR; totals2.RR; totals3.RR], ...
    [totals1.RU; totals2.RU; totals3.RU], ...
    [totals1.UR; totals2.UR; totals3.UR], ...
    [totals1.UU; totals2.UU; totals3.UU], ...
    [total1; total2; total3], ...
    [bar_data_percent(1,1); bar_data_percent(1,2); bar_data_percent(1,3)], ...  % RR %
    [bar_data_percent(2,1); bar_data_percent(2,2); bar_data_percent(2,3)], ...  % RU %
    [bar_data_percent(3,1); bar_data_percent(3,2); bar_data_percent(3,3)], ...  % UR %
    [bar_data_percent(4,1); bar_data_percent(4,2); bar_data_percent(4,3)], ...  % UU %
    'VariableNames', {'Scenario', 'RR_Count', 'RU_Count', 'UR_Count', 'UU_Count', 'Total_Count', ...
    'RR_Percent', 'RU_Percent', 'UR_Percent', 'UU_Percent'});

csv_file = sprintf('Analysis/Data/three_way_rural_urban_stacked_%s.csv', output_suffix);
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Stacked bar chart comparison complete!\n\n');

end


function totals = classify_movements_total(agentSummary, urban_rural_map)
% Classify all movements as R→R, R→U, U→R, or U→U (total counts, not per timestep)

totals = struct('RR', 0, 'RU', 0, 'UR', 0, 'UU', 0);

% Iterate through all agents
for i = 1:height(agentSummary)
    moveHistory = agentSummary.moveHistory{i};
    
    if isempty(moveHistory)
        continue;
    end
    
    % Each row in moveHistory: [timestep, from_location, to_location, distance]
    for m = 1:size(moveHistory, 1)
        from_loc = moveHistory(m, 2);
        to_loc = moveHistory(m, 3);
        
        % Get urban/rural status
        if isKey(urban_rural_map, from_loc) && isKey(urban_rural_map, to_loc)
            from_type = urban_rural_map(from_loc);
            to_type = urban_rural_map(to_loc);
            
            % Classify movement and increment counter
            if from_type == 'R' && to_type == 'R'
                totals.RR = totals.RR + 1;
            elseif from_type == 'R' && to_type == 'U'
                totals.RU = totals.RU + 1;
            elseif from_type == 'U' && to_type == 'R'
                totals.UR = totals.UR + 1;
            elseif from_type == 'U' && to_type == 'U'
                totals.UU = totals.UU + 1;
            end
        end
    end
end

end

