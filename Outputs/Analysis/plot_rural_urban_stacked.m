function plot_rural_urban_stacked(aggregated)
% PLOT_RURAL_URBAN_STACKED Create stacked bar chart comparing scenarios
%
% Inputs:
%   aggregated - Struct from aggregate_rural_urban_flows
%
% Creates 1 PNG file:
%   - rural_urban_migrations_stacked_comparison.png

fprintf('=== CREATING STACKED BAR CHART COMPARISON ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
scenarioLabels = {'Control', 'Shock Only', 'PA Only', 'PA + Shock'};

% Color scheme for migration types (matching time series plots)
colors = [0.2 0.7 0.3;    % Green (R→R)
          0.9 0.5 0.1;    % Orange (R→U)
          0.2 0.5 0.8;    % Blue (U→R)
          0.6 0.2 0.7];   % Purple (U→U)

% Collect data for stacked bar chart
data_matrix = zeros(4, 4);  % 4 scenarios × 4 migration types

for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    
    if isfield(aggregated, scenarioName)
        data_matrix(s, 1) = aggregated.(scenarioName).RR_total;
        data_matrix(s, 2) = aggregated.(scenarioName).RU_total;
        data_matrix(s, 3) = aggregated.(scenarioName).UR_total;
        data_matrix(s, 4) = aggregated.(scenarioName).UU_total;
    end
end

fprintf('Creating stacked bar chart...\n');

% Create figure
fig = figure('Position', [100 100 1000 700], 'Visible', 'off');

% Create stacked bar chart
b = bar(data_matrix, 'stacked', 'BarWidth', 0.7);

% Apply colors to each migration type
b(1).FaceColor = colors(1, :);  % R→R
b(2).FaceColor = colors(2, :);  % R→U
b(3).FaceColor = colors(3, :);  % U→R
b(4).FaceColor = colors(4, :);  % U→U

% Format plot
set(gca, 'XTickLabel', scenarioLabels, 'FontSize', 12);
xlabel('Scenario', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Total Migrations', 'FontSize', 13, 'FontWeight', 'bold');
title('Rural-Urban Migration Flows by Scenario', ...
    'FontSize', 15, 'FontWeight', 'bold');
legend({'Rural → Rural', 'Rural → Urban', 'Urban → Rural', 'Urban → Urban'}, ...
    'Location', 'northeast', 'FontSize', 11);
grid on;
set(gca, 'YMinorGrid', 'on');

% Add value labels on bars for better readability
for s = 1:size(data_matrix, 1)
    y_cumsum = cumsum(data_matrix(s, :));
    for t = 1:size(data_matrix, 2)
        if data_matrix(s, t) > 0  % Only label if non-zero
            if t == 1
                y_pos = data_matrix(s, t) / 2;
            else
                y_pos = y_cumsum(t-1) + data_matrix(s, t) / 2;
            end
            
            % Add text label if bar segment is large enough
            if data_matrix(s, t) > max(max(data_matrix)) * 0.03
                text(s, y_pos, sprintf('%.0f', data_matrix(s, t)), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'white');
            end
        end
    end
end

% Save figure
filename = 'rural_urban_migrations_stacked_comparison.png';
saveas(fig, filename);
fprintf('  Saved: %s\n', filename);
close(fig);

fprintf('\n✓ Stacked bar chart complete\n\n');

end

