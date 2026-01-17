function compare_total_migrations()
% COMPARE_TOTAL_MIGRATIONS Compare total migration counts over time
%
% Compares baseline (PA+Shock Run012) vs shock (MADA_shock_south) scenarios
%
% Outputs:
%   - Analysis/Figures/total_migrations_comparison.png
%   - Analysis/Data/total_migrations_comparison.csv

fprintf('\n=== COMPARING TOTAL MIGRATIONS ===\n\n');

% File paths
baseline_file = 'Outputs/Madagascar_PA_Shock_Full_Run012_2025-11-13_00-29-17.mat';
shock_file = 'Outputs/MADA_shock_south.mat';

% Load baseline scenario
fprintf('Loading baseline scenario: %s\n', baseline_file);
baseline_data = load(baseline_file);

% Load shock scenario
fprintf('Loading shock scenario: %s\n', shock_file);
shock_data = load(shock_file);

% Extract migration counts per timestep
% output.migrations is a vector (timeSteps x 1)
baseline_migrations = baseline_data.output.migrations;
shock_migrations = shock_data.output.migrations;

% Ensure same length
num_timesteps = max(length(baseline_migrations), length(shock_migrations));
if length(baseline_migrations) < num_timesteps
    baseline_migrations(end+1:num_timesteps) = 0;
end
if length(shock_migrations) < num_timesteps
    shock_migrations(end+1:num_timesteps) = 0;
end

fprintf('\nExtracting migration counts...\n');

fprintf('  Baseline total migrations: %d\n', sum(baseline_migrations));
fprintf('  Shock total migrations: %d\n', sum(shock_migrations));

% Create figure
fprintf('\nCreating figure...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, baseline_migrations, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(1:num_timesteps, shock_migrations, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Number of Migrations', 'FontSize', 12, 'FontWeight', 'bold');
title('Total Migrations Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;

% Save figure
fig_file = 'Analysis/Figures/total_migrations_comparison.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', baseline_migrations, shock_migrations, ...
    'VariableNames', {'Timestep', 'Baseline_Migrations', 'Shock_Migrations'});

csv_file = 'Analysis/Data/total_migrations_comparison.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Total migrations comparison complete!\n\n');

end

