function compare_three_scenarios_gini(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_GINI Compare Gini coefficient of income over time for 3 scenarios
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for legend
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_gini_<suffix>.png
%   - Analysis/Data/three_way_gini_<suffix>.csv

fprintf('\n=== COMPARING GINI COEFFICIENT (3 SCENARIOS) ===\n\n');

% Load scenarios
fprintf('Loading scenario 1: %s\n', file1);
data1 = load(file1);

fprintf('Loading scenario 2: %s\n', file2);
data2 = load(file2);

fprintf('Loading scenario 3: %s\n', file3);
data3 = load(file3);

% Extract income history
incomeHistory1 = data1.output.agentSummary.incomeHistory;
incomeHistory2 = data2.output.agentSummary.incomeHistory;
incomeHistory3 = data3.output.agentSummary.incomeHistory;

fprintf('\nCalculating Gini coefficient per timestep...\n');

% Convert cell arrays to matrices
income_matrix1 = convert_income_history(incomeHistory1);
income_matrix2 = convert_income_history(incomeHistory2);
income_matrix3 = convert_income_history(incomeHistory3);

% Ensure same number of timesteps
num_timesteps = max([size(income_matrix1, 2), size(income_matrix2, 2), size(income_matrix3, 2)]);
if size(income_matrix1, 2) < num_timesteps
    income_matrix1(:, end+1:num_timesteps) = 0;
end
if size(income_matrix2, 2) < num_timesteps
    income_matrix2(:, end+1:num_timesteps) = 0;
end
if size(income_matrix3, 2) < num_timesteps
    income_matrix3(:, end+1:num_timesteps) = 0;
end

% Calculate Gini coefficient for each timestep
gini1 = zeros(num_timesteps, 1);
gini2 = zeros(num_timesteps, 1);
gini3 = zeros(num_timesteps, 1);

for t = 1:num_timesteps
    gini1(t) = calculate_gini(income_matrix1(:, t));
    gini2(t) = calculate_gini(income_matrix2(:, t));
    gini3(t) = calculate_gini(income_matrix3(:, t));
end

fprintf('  %s mean Gini: %.4f\n', name1, mean(gini1));
fprintf('  %s mean Gini: %.4f\n', name2, mean(gini2));
fprintf('  %s mean Gini: %.4f\n', name3, mean(gini3));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, gini1, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
hold on;
plot(1:num_timesteps, gini2, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(1:num_timesteps, gini3, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Gini Coefficient', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Income Inequality (Gini Coefficient) Over Time: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;
ylim([0 1]);  % Gini coefficient ranges from 0 to 1

% Save figure
fig_file = sprintf('Analysis/Figures/three_way_gini_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', gini1, gini2, gini3, ...
    'VariableNames', {'Timestep', name1, name2, name3});

csv_file = sprintf('Analysis/Data/three_way_gini_%s.csv', output_suffix);
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Gini coefficient comparison complete!\n\n');

end


function income_matrix = convert_income_history(incomeHistory)
% Convert income history cell array to matrix

if iscell(incomeHistory)
    num_agents = length(incomeHistory);
    max_timesteps = 0;
    for i = 1:num_agents
        if ~isempty(incomeHistory{i})
            max_timesteps = max(max_timesteps, length(incomeHistory{i}));
        end
    end
    
    income_matrix = zeros(num_agents, max_timesteps);
    for i = 1:num_agents
        if ~isempty(incomeHistory{i})
            hist = incomeHistory{i};
            if isrow(hist)
                income_matrix(i, 1:length(hist)) = hist;
            else
                income_matrix(i, 1:length(hist)) = hist';
            end
        end
    end
else
    income_matrix = incomeHistory;
end

end


function gini = calculate_gini(incomes)
% Calculate Gini coefficient for a vector of incomes

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

