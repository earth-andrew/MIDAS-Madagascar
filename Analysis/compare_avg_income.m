function compare_avg_income()
% COMPARE_AVG_INCOME Compare average income over time
%
% Compares baseline vs shock scenarios
%
% Outputs:
%   - Analysis/Figures/avg_income_comparison.png
%   - Analysis/Data/avg_income_comparison.csv

fprintf('\n=== COMPARING AVERAGE INCOME ===\n\n');

% File paths
baseline_file = 'Outputs/Madagascar_PA_Shock_Full_Run012_2025-11-13_00-29-17.mat';
shock_file = 'Outputs/MADA_shock_south.mat';

% Load scenarios
fprintf('Loading baseline scenario: %s\n', baseline_file);
baseline_data = load(baseline_file);

fprintf('Loading shock scenario: %s\n', shock_file);
shock_data = load(shock_file);

% Extract income history
% incomeHistory is in agentSummary table
baseline_incomeHistory = baseline_data.output.agentSummary.incomeHistory;
shock_incomeHistory = shock_data.output.agentSummary.incomeHistory;

fprintf('\nCalculating average income per timestep...\n');

% Convert cell array to matrix if needed
if iscell(baseline_incomeHistory)
    % If it's a cell array, each cell contains income history for one agent
    % Need to handle variable lengths
    num_agents_baseline = length(baseline_incomeHistory);
    max_timesteps_baseline = 0;
    for i = 1:num_agents_baseline
        if ~isempty(baseline_incomeHistory{i})
            max_timesteps_baseline = max(max_timesteps_baseline, length(baseline_incomeHistory{i}));
        end
    end
    
    baseline_income_matrix = zeros(num_agents_baseline, max_timesteps_baseline);
    for i = 1:num_agents_baseline
        if ~isempty(baseline_incomeHistory{i})
            hist = baseline_incomeHistory{i};
            if isrow(hist)
                baseline_income_matrix(i, 1:length(hist)) = hist;
            else
                baseline_income_matrix(i, 1:length(hist)) = hist';
            end
        end
    end
else
    baseline_income_matrix = baseline_incomeHistory;
    max_timesteps_baseline = size(baseline_income_matrix, 2);
end

if iscell(shock_incomeHistory)
    num_agents_shock = length(shock_incomeHistory);
    max_timesteps_shock = 0;
    for i = 1:num_agents_shock
        if ~isempty(shock_incomeHistory{i})
            max_timesteps_shock = max(max_timesteps_shock, length(shock_incomeHistory{i}));
        end
    end
    
    shock_income_matrix = zeros(num_agents_shock, max_timesteps_shock);
    for i = 1:num_agents_shock
        if ~isempty(shock_incomeHistory{i})
            hist = shock_incomeHistory{i};
            if isrow(hist)
                shock_income_matrix(i, 1:length(hist)) = hist;
            else
                shock_income_matrix(i, 1:length(hist)) = hist';
            end
        end
    end
else
    shock_income_matrix = shock_incomeHistory;
    max_timesteps_shock = size(shock_income_matrix, 2);
end

% Ensure same number of timesteps
num_timesteps = max(max_timesteps_baseline, max_timesteps_shock);
if size(baseline_income_matrix, 2) < num_timesteps
    baseline_income_matrix(:, end+1:num_timesteps) = 0;
end
if size(shock_income_matrix, 2) < num_timesteps
    shock_income_matrix(:, end+1:num_timesteps) = 0;
end

% Calculate mean income per timestep (mean across agents)
% Rows are agents, columns are timesteps
baseline_avg_income = mean(baseline_income_matrix, 1);
shock_avg_income = mean(shock_income_matrix, 1);

fprintf('  Baseline mean income: %.2f\n', mean(baseline_avg_income));
fprintf('  Shock mean income: %.2f\n', mean(shock_avg_income));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, baseline_avg_income, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(1:num_timesteps, shock_avg_income, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Income', 'FontSize', 12, 'FontWeight', 'bold');
title('Average Income Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;

% Save figure
fig_file = 'Analysis/Figures/avg_income_comparison.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', baseline_avg_income', shock_avg_income', ...
    'VariableNames', {'Timestep', 'Baseline_Avg_Income', 'Shock_Avg_Income'});

csv_file = 'Analysis/Data/avg_income_comparison.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Average income comparison complete!\n\n');

end

