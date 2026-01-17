function compare_three_scenarios_migrations(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_MIGRATIONS Compare total migration counts over time for 3 scenarios
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for legend
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_migrations_<suffix>.png
%   - Analysis/Data/three_way_migrations_<suffix>.csv

fprintf('\n=== COMPARING TOTAL MIGRATIONS (3 SCENARIOS) ===\n\n');

% Load scenarios
fprintf('Loading scenario 1: %s\n', file1);
data1 = load(file1);

fprintf('Loading scenario 2: %s\n', file2);
data2 = load(file2);

fprintf('Loading scenario 3: %s\n', file3);
data3 = load(file3);

% Extract migration counts per timestep
migrations1 = data1.output.migrations;
migrations2 = data2.output.migrations;
migrations3 = data3.output.migrations;

% Ensure same length
num_timesteps = max([length(migrations1), length(migrations2), length(migrations3)]);
if length(migrations1) < num_timesteps
    migrations1(end+1:num_timesteps) = 0;
end
if length(migrations2) < num_timesteps
    migrations2(end+1:num_timesteps) = 0;
end
if length(migrations3) < num_timesteps
    migrations3(end+1:num_timesteps) = 0;
end

fprintf('\nExtracting migration counts...\n');
fprintf('  %s total migrations: %d\n', name1, sum(migrations1));
fprintf('  %s total migrations: %d\n', name2, sum(migrations2));
fprintf('  %s total migrations: %d\n', name3, sum(migrations3));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, migrations1, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
hold on;
plot(1:num_timesteps, migrations2, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(1:num_timesteps, migrations3, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Total Migrations Over Time: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;

% Save figure
fig_file = sprintf('Analysis/Figures/three_way_migrations_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', migrations1, migrations2, migrations3, ...
    'VariableNames', {'Timestep', name1, name2, name3});

csv_file = sprintf('Analysis/Data/three_way_migrations_%s.csv', output_suffix);
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Total migrations comparison complete!\n\n');

end

