function compare_scenarios_with_without_PA(baseline_file, baseline_pa_file, shock_r_file, shock_r_pa_file, shock_ur_file, shock_ur_pa_file)
% COMPARE_SCENARIOS_WITH_WITHOUT_PA Compare scenarios side-by-side with and without PA
%
% Creates stacked bar charts showing rural-urban migration split as percentages,
% comparing each scenario type with and without Place Attachment
%
% Args:
%   baseline_file, baseline_pa_file: Baseline scenario files (no PA, with PA)
%   shock_r_file, shock_r_pa_file: Shock_R scenario files (no PA, with PA)
%   shock_ur_file, shock_ur_pa_file: Shock_UR scenario files (no PA, with PA)
%
% Outputs:
%   - Analysis/Figures/rural_urban_stacked_with_without_PA.png
%   - Analysis/Data/rural_urban_stacked_with_without_PA.csv

fprintf('\n=== COMPARING SCENARIOS WITH AND WITHOUT PA (SIDE-BY-SIDE) ===\n\n');

% Load all scenarios
fprintf('Loading scenarios...\n');
data_baseline = load(baseline_file);
data_baseline_pa = load(baseline_pa_file);
data_shock_r = load(shock_r_file);
data_shock_r_pa = load(shock_r_pa_file);
data_shock_ur = load(shock_ur_file);
data_shock_ur_pa = load(shock_ur_pa_file);

% Get urban/rural classification
locations_table = data_baseline.output.mapVariables.locations;
urban_rural_map = containers.Map('KeyType', 'double', 'ValueType', 'char');
for i = 1:height(locations_table)
    loc_id = i;
    urban_rural_map(loc_id) = locations_table.URBAN_RURAL{i}(1);
end

fprintf('\nClassifying movements...\n');

% Classify movements for all scenarios
totals_baseline = classify_movements_total(data_baseline.output.agentSummary, urban_rural_map);
totals_baseline_pa = classify_movements_total(data_baseline_pa.output.agentSummary, urban_rural_map);
totals_shock_r = classify_movements_total(data_shock_r.output.agentSummary, urban_rural_map);
totals_shock_r_pa = classify_movements_total(data_shock_r_pa.output.agentSummary, urban_rural_map);
totals_shock_ur = classify_movements_total(data_shock_ur.output.agentSummary, urban_rural_map);
totals_shock_ur_pa = classify_movements_total(data_shock_ur_pa.output.agentSummary, urban_rural_map);

% Calculate totals and percentages
total_baseline = totals_baseline.RR + totals_baseline.RU + totals_baseline.UR + totals_baseline.UU;
total_baseline_pa = totals_baseline_pa.RR + totals_baseline_pa.RU + totals_baseline_pa.UR + totals_baseline_pa.UU;
total_shock_r = totals_shock_r.RR + totals_shock_r.RU + totals_shock_r.UR + totals_shock_r.UU;
total_shock_r_pa = totals_shock_r_pa.RR + totals_shock_r_pa.RU + totals_shock_r_pa.UR + totals_shock_r_pa.UU;
total_shock_ur = totals_shock_ur.RR + totals_shock_ur.RU + totals_shock_ur.UR + totals_shock_ur.UU;
total_shock_ur_pa = totals_shock_ur_pa.RR + totals_shock_ur_pa.RU + totals_shock_ur_pa.UR + totals_shock_ur_pa.UU;

% Prepare percentage data for stacked bar chart
% 6 bars: Baseline, Baseline_PA, Shock_R, Shock_R_PA, Shock_UR, Shock_UR_PA
bar_data_percent = [
    totals_baseline.RR/total_baseline*100, totals_baseline_pa.RR/total_baseline_pa*100, ...
    totals_shock_r.RR/total_shock_r*100, totals_shock_r_pa.RR/total_shock_r_pa*100, ...
    totals_shock_ur.RR/total_shock_ur*100, totals_shock_ur_pa.RR/total_shock_ur_pa*100;  % R→R
    totals_baseline.RU/total_baseline*100, totals_baseline_pa.RU/total_baseline_pa*100, ...
    totals_shock_r.RU/total_shock_r*100, totals_shock_r_pa.RU/total_shock_r_pa*100, ...
    totals_shock_ur.RU/total_shock_ur*100, totals_shock_ur_pa.RU/total_shock_ur_pa*100;  % R→U
    totals_baseline.UR/total_baseline*100, totals_baseline_pa.UR/total_baseline_pa*100, ...
    totals_shock_r.UR/total_shock_r*100, totals_shock_r_pa.UR/total_shock_r_pa*100, ...
    totals_shock_ur.UR/total_shock_ur*100, totals_shock_ur_pa.UR/total_shock_ur_pa*100;  % U→R
    totals_baseline.UU/total_baseline*100, totals_baseline_pa.UU/total_baseline_pa*100, ...
    totals_shock_r.UU/total_shock_r*100, totals_shock_r_pa.UU/total_shock_r_pa*100, ...
    totals_shock_ur.UU/total_shock_ur*100, totals_shock_ur_pa.UU/total_shock_ur_pa*100   % U→U
];

% Create stacked bar chart
fprintf('\nCreating stacked bar chart...\n');
figure('Position', [100 100 1400 700]);

h = bar(bar_data_percent', 'stacked');

% Set colors for each migration type
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

% Set x-axis labels with spacing between groups
x_labels = {'Baseline', 'Baseline+PA', 'Shock_R', 'Shock_R+PA', 'Shock_UR', 'Shock_UR+PA'};
set(gca, 'XTickLabel', x_labels);
xlabel('Scenario', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Percentage of Total Migrations (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Rural-Urban Migration Split: With vs Without Place Attachment', ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({'R→R (Rural to Rural)', 'R→U (Rural to Urban)', 'U→R (Urban to Rural)', 'U→U (Urban to Urban)'}, ...
    'Location', 'best', 'FontSize', 11);
grid on;
grid minor;
ylim([0 100]);

% Add value labels on segments > 1%
cumulative_heights = cumsum(bar_data_percent, 1);
for i = 1:6  % For each scenario
    for j = 1:4  % For each migration type
        value_percent = bar_data_percent(j, i);
        if value_percent > 1
            y_pos = cumulative_heights(j, i) - value_percent/2;
            text(i, y_pos, sprintf('%.1f%%', value_percent), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 8, ...
                'FontWeight', 'bold', ...
                'Color', 'white');
        end
    end
end

% Add vertical lines to separate groups
hold on;
for x = [2.5, 4.5]
    plot([x, x], [0, 100], 'k--', 'LineWidth', 1);
end
hold off;

% Save figure
fig_file = 'Analysis/Figures/rural_urban_stacked_with_without_PA.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table(x_labels', ...
    [totals_baseline.RR; totals_baseline_pa.RR; totals_shock_r.RR; totals_shock_r_pa.RR; totals_shock_ur.RR; totals_shock_ur_pa.RR], ...
    [totals_baseline.RU; totals_baseline_pa.RU; totals_shock_r.RU; totals_shock_r_pa.RU; totals_shock_ur.RU; totals_shock_ur_pa.RU], ...
    [totals_baseline.UR; totals_baseline_pa.UR; totals_shock_r.UR; totals_shock_r_pa.UR; totals_shock_ur.UR; totals_shock_ur_pa.UR], ...
    [totals_baseline.UU; totals_baseline_pa.UU; totals_shock_r.UU; totals_shock_r_pa.UU; totals_shock_ur.UU; totals_shock_ur_pa.UU], ...
    [total_baseline; total_baseline_pa; total_shock_r; total_shock_r_pa; total_shock_ur; total_shock_ur_pa], ...
    bar_data_percent(1,:)', bar_data_percent(2,:)', bar_data_percent(3,:)', bar_data_percent(4,:)', ...
    'VariableNames', {'Scenario', 'RR_Count', 'RU_Count', 'UR_Count', 'UU_Count', 'Total_Count', ...
    'RR_Percent', 'RU_Percent', 'UR_Percent', 'UU_Percent'});

csv_file = 'Analysis/Data/rural_urban_stacked_with_without_PA.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Side-by-side PA comparison complete!\n\n');

end


function totals = classify_movements_total(agentSummary, urban_rural_map)
% Classify all movements as R→R, R→U, U→R, or U→U (total counts, not per timestep)

totals = struct('RR', 0, 'RU', 0, 'UR', 0, 'UU', 0);

for i = 1:height(agentSummary)
    moveHistory = agentSummary.moveHistory{i};
    
    if isempty(moveHistory)
        continue;
    end
    
    for m = 1:size(moveHistory, 1)
        from_loc = moveHistory(m, 2);
        to_loc = moveHistory(m, 3);
        
        if isKey(urban_rural_map, from_loc) && isKey(urban_rural_map, to_loc)
            from_type = urban_rural_map(from_loc);
            to_type = urban_rural_map(to_loc);
            
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

