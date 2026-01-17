function compare_gini_coefficient()
% COMPARE_GINI_COEFFICIENT Compare Gini coefficient of income over time
%
% Calculates income inequality using Gini coefficient
% Compares baseline vs shock scenarios
%
% Outputs:
%   - Analysis/Figures/gini_coefficient_comparison.png
%   - Analysis/Data/gini_coefficient_comparison.csv

fprintf('\n=== COMPARING GINI COEFFICIENT ===\n\n');

% File paths
baseline_file = 'Outputs/Madagascar_PA_Shock_Full_Run012_2025-11-13_00-29-17.mat';
shock_file = 'Outputs/MADA_shock_south.mat';

% Load scenarios
fprintf('Loading baseline scenario: %s\n', baseline_file);
baseline_data = load(baseline_file);

fprintf('Loading shock scenario: %s\n', shock_file);
shock_data = load(shock_file);

% Extract income history
baseline_incomeHistory = baseline_data.output.agentSummary.incomeHistory;
shock_incomeHistory = shock_data.output.agentSummary.incomeHistory;

fprintf('\nCalculating Gini coefficient per timestep...\n');

% Convert cell array to matrix if needed
if iscell(baseline_incomeHistory)
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

% Calculate Gini coefficient for each timestep
baseline_gini = zeros(num_timesteps, 1);
shock_gini = zeros(num_timesteps, 1);

for t = 1:num_timesteps
    baseline_gini(t) = calculate_gini(baseline_income_matrix(:, t));
    shock_gini(t) = calculate_gini(shock_income_matrix(:, t));
end

fprintf('  Baseline mean Gini: %.4f\n', mean(baseline_gini));
fprintf('  Shock mean Gini: %.4f\n', mean(shock_gini));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, baseline_gini, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(1:num_timesteps, shock_gini, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Gini Coefficient', 'FontSize', 12, 'FontWeight', 'bold');
title('Income Inequality (Gini Coefficient) Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;
ylim([0 1]);  % Gini coefficient ranges from 0 to 1

% Save figure
fig_file = 'Analysis/Figures/gini_coefficient_comparison.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', baseline_gini, shock_gini, ...
    'VariableNames', {'Timestep', 'Baseline_Gini', 'Shock_Gini'});

csv_file = 'Analysis/Data/gini_coefficient_comparison.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Gini coefficient comparison complete!\n\n');

end


function gini = calculate_gini(incomes)
% Calculate Gini coefficient for a vector of incomes
% 
% Formula: G = sum(sum(|income_i - income_j|)) / (2 * N^2 * mean(income))
%
% Args:
%   incomes: vector of income values
%
% Returns:
%   gini: Gini coefficient (0 = perfect equality, 1 = perfect inequality)

% Remove NaN values if any
incomes = incomes(~isnan(incomes));

% Handle edge cases
if isempty(incomes) || all(incomes == 0)
    gini = 0;
    return;
end

N = length(incomes);
mean_income = mean(incomes);

% Calculate sum of absolute differences
total_diff = 0;
for i = 1:N
    for j = 1:N
        total_diff = total_diff + abs(incomes(i) - incomes(j));
    end
end

% Gini coefficient
if mean_income > 0
    gini = total_diff / (2 * N^2 * mean_income);
else
    gini = 0;
end

% Ensure Gini is in [0, 1]
gini = min(max(gini, 0), 1);

end

