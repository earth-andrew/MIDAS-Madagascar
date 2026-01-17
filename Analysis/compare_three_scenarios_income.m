function compare_three_scenarios_income(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_INCOME Compare average income over time for 3 scenarios
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for legend
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_income_<suffix>.png
%   - Analysis/Data/three_way_income_<suffix>.csv

fprintf('\n=== COMPARING AVERAGE INCOME (3 SCENARIOS) ===\n\n');

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

fprintf('\nCalculating average income per timestep...\n');

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

% Calculate mean income per timestep
avg_income1 = mean(income_matrix1, 1);
avg_income2 = mean(income_matrix2, 1);
avg_income3 = mean(income_matrix3, 1);

fprintf('  %s mean income: %.2f\n', name1, mean(avg_income1));
fprintf('  %s mean income: %.2f\n', name2, mean(avg_income2));
fprintf('  %s mean income: %.2f\n', name3, mean(avg_income3));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, avg_income1, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
hold on;
plot(1:num_timesteps, avg_income2, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(1:num_timesteps, avg_income3, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Income', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Average Income Over Time: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;

% Save figure
fig_file = sprintf('Analysis/Figures/three_way_income_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', avg_income1', avg_income2', avg_income3', ...
    'VariableNames', {'Timestep', name1, name2, name3});

csv_file = sprintf('Analysis/Data/three_way_income_%s.csv', output_suffix);
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Average income comparison complete!\n\n');

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

