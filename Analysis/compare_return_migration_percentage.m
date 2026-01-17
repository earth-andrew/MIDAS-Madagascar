function compare_return_migration_percentage(baseline_file, baseline_pa_file, shock_r_file, shock_r_pa_file, shock_ur_file, shock_ur_pa_file)
% COMPARE_RETURN_MIGRATION_PERCENTAGE Compare return migrations as percentage of total migrations
%
% Calculates return-to-origin migrations as a percentage of total migrations
% for all 6 scenarios and creates comparison charts
%
% Args:
%   baseline_file, baseline_pa_file: Baseline scenario files (no PA, with PA)
%   shock_r_file, shock_r_pa_file: Shock_R scenario files (no PA, with PA)
%   shock_ur_file, shock_ur_pa_file: Shock_UR scenario files (no PA, with PA)
%
% Outputs:
%   - Analysis/Figures/return_migration_percentage_all.png
%   - Analysis/Figures/return_migration_percentage_paired.png
%   - Analysis/Data/return_migration_percentage.csv

fprintf('\n=== COMPARING RETURN MIGRATION PERCENTAGES ===\n\n');

% Load all scenarios
fprintf('Loading scenarios...\n');
data_baseline = load(baseline_file);
data_baseline_pa = load(baseline_pa_file);
data_shock_r = load(shock_r_file);
data_shock_r_pa = load(shock_r_pa_file);
data_shock_ur = load(shock_ur_file);
data_shock_ur_pa = load(shock_ur_pa_file);

% Calculate total migrations for each scenario
total_migrations = [
    sum(data_baseline.output.migrations);
    sum(data_baseline_pa.output.migrations);
    sum(data_shock_r.output.migrations);
    sum(data_shock_r_pa.output.migrations);
    sum(data_shock_ur.output.migrations);
    sum(data_shock_ur_pa.output.migrations)
];

% Analyze return migrations for each scenario
fprintf('\nAnalyzing return migrations...\n');
[total_returns_baseline, ~, ~] = analyze_returns(data_baseline.output.agentSummary);
[total_returns_baseline_pa, ~, ~] = analyze_returns(data_baseline_pa.output.agentSummary);
[total_returns_shock_r, ~, ~] = analyze_returns(data_shock_r.output.agentSummary);
[total_returns_shock_r_pa, ~, ~] = analyze_returns(data_shock_r_pa.output.agentSummary);
[total_returns_shock_ur, ~, ~] = analyze_returns(data_shock_ur.output.agentSummary);
[total_returns_shock_ur_pa, ~, ~] = analyze_returns(data_shock_ur_pa.output.agentSummary);

total_returns = [
    total_returns_baseline;
    total_returns_baseline_pa;
    total_returns_shock_r;
    total_returns_shock_r_pa;
    total_returns_shock_ur;
    total_returns_shock_ur_pa
];

% Calculate percentages
return_percentages = (total_returns ./ total_migrations) * 100;

% Handle division by zero
return_percentages(isnan(return_percentages) | isinf(return_percentages)) = 0;

fprintf('  Baseline: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_baseline, total_migrations(1), return_percentages(1));
fprintf('  Baseline_PA: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_baseline_pa, total_migrations(2), return_percentages(2));
fprintf('  Shock_R: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_shock_r, total_migrations(3), return_percentages(3));
fprintf('  Shock_R_PA: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_shock_r_pa, total_migrations(4), return_percentages(4));
fprintf('  Shock_UR: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_shock_ur, total_migrations(5), return_percentages(5));
fprintf('  Shock_UR_PA: %d returns / %d migrations = %.2f%%\n', ...
    total_returns_shock_ur_pa, total_migrations(6), return_percentages(6));

% Plot 1: All scenarios bar chart
fprintf('\nCreating Plot 1: All scenarios comparison...\n');
figure('Position', [100 100 1200 600]);

scenario_names = {'Baseline', 'Baseline+PA', 'Shock_R', 'Shock_R+PA', 'Shock_UR', 'Shock_UR+PA'};
h1 = bar(return_percentages);
h1.FaceColor = 'flat';
h1.CData = [
    0.2 0.4 0.8;  % Baseline: blue
    0.2 0.6 0.9;  % Baseline+PA: light blue
    0.8 0.2 0.2;  % Shock_R: red
    0.9 0.4 0.4;  % Shock_R+PA: light red
    0.2 0.8 0.4;  % Shock_UR: green
    0.4 0.9 0.6   % Shock_UR+PA: light green
];
h1.EdgeColor = 'k';
h1.LineWidth = 1.5;

set(gca, 'XTickLabel', scenario_names);
xlabel('Scenario', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Return Migrations (% of Total Migrations)', 'FontSize', 12, 'FontWeight', 'bold');
title('Return to Origin Migrations as Percentage of Total Migrations', ...
    'FontSize', 14, 'FontWeight', 'bold');
grid on;
ylim([0 max(return_percentages) * 1.1]);

% Add value labels on bars
for i = 1:6
    text(i, return_percentages(i) + max(return_percentages) * 0.02, ...
        sprintf('%.2f%%', return_percentages(i)), ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 10, ...
        'FontWeight', 'bold');
end

% Add vertical lines to separate groups
hold on;
for x = [2.5, 4.5]
    plot([x, x], [0, max(return_percentages) * 1.1], 'k--', 'LineWidth', 1);
end
hold off;

fig_file = 'Analysis/Figures/return_migration_percentage_all.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Plot 2: Side-by-side comparison (with vs without PA)
fprintf('Creating Plot 2: Side-by-side PA comparison...\n');
figure('Position', [100 100 1000 600]);

% Group data: 3 scenario types, each with 2 bars (no PA, with PA)
grouped_data = [
    return_percentages(1), return_percentages(2);  % Baseline, Baseline_PA
    return_percentages(3), return_percentages(4);  % Shock_R, Shock_R_PA
    return_percentages(5), return_percentages(6)   % Shock_UR, Shock_UR_PA
];

h2 = bar(grouped_data);
h2(1).FaceColor = [0.3 0.3 0.3];  % Dark gray for no PA
h2(1).EdgeColor = 'k';
h2(1).LineWidth = 1.5;
h2(2).FaceColor = [0.7 0.7 0.7];  % Light gray for with PA
h2(2).EdgeColor = 'k';
h2(2).LineWidth = 1.5;

set(gca, 'XTickLabel', {'Baseline', 'Shock_R', 'Shock_UR'});
xlabel('Scenario Type', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Return Migrations (% of Total Migrations)', 'FontSize', 12, 'FontWeight', 'bold');
title('Return Migration Percentage: With vs Without Place Attachment', ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({'Without PA', 'With PA'}, 'Location', 'best', 'FontSize', 11);
grid on;
ylim([0 max(return_percentages) * 1.1]);

% Add value labels
for i = 1:3
    for j = 1:2
        x_pos = i + (j-1.5)*0.2;  % Offset bars slightly
        y_val = grouped_data(i, j);
        text(x_pos, y_val + max(return_percentages) * 0.02, ...
            sprintf('%.2f%%', y_val), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 9, ...
            'FontWeight', 'bold');
    end
end

fig_file = 'Analysis/Figures/return_migration_percentage_paired.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table(scenario_names', total_returns, total_migrations, return_percentages, ...
    'VariableNames', {'Scenario', 'Return_Count', 'Total_Migrations', 'Return_Percentage'});

csv_file = 'Analysis/Data/return_migration_percentage.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Return migration percentage analysis complete!\n\n');

end


function [total_returns, distribution, timeseries] = analyze_returns(agentSummary)
% Analyze return-to-origin patterns for a scenario

distribution = containers.Map('KeyType', 'double', 'ValueType', 'double');
num_agents = height(agentSummary);

max_timestep = 0;
for i = 1:num_agents
    moveHistory = agentSummary.moveHistory{i};
    if ~isempty(moveHistory)
        max_timestep = max(max_timestep, max(moveHistory(:, 1)));
    end
end

timeseries = zeros(max_timestep, 1);
total_returns = 0;

for i = 1:num_agents
    moveHistory = agentSummary.moveHistory{i};
    
    if isempty(moveHistory)
        if isKey(distribution, 0)
            distribution(0) = distribution(0) + 1;
        else
            distribution(0) = 1;
        end
        continue;
    end
    
    initial_location = moveHistory(1, 2);
    agent_returns = 0;
    
    for m = 1:size(moveHistory, 1)
        to_loc = moveHistory(m, 3);
        timestep = moveHistory(m, 1);
        
        if to_loc == initial_location && m > 1
            agent_returns = agent_returns + 1;
            total_returns = total_returns + 1;
            
            if timestep <= length(timeseries)
                timeseries(timestep) = timeseries(timestep) + 1;
            end
        end
    end
    
    if isKey(distribution, agent_returns)
        distribution(agent_returns) = distribution(agent_returns) + 1;
    else
        distribution(agent_returns) = 1;
    end
end

end

