function plot_migration_timeseries(aggregated)
% PLOT_MIGRATION_TIMESERIES Create time series plots for migration metrics
%
% Inputs:
%   aggregated - Struct from aggregate_scenarios
%
% Creates 5 PNG files:
%   - migration_timeseries_Control.png
%   - migration_timeseries_Shock.png
%   - migration_timeseries_PA.png
%   - migration_timeseries_PA_Shock.png
%   - migration_timeseries_Comparison.png

fprintf('=== CREATING VISUALIZATIONS ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
scenarioTitles = {'Control (No PA, No Shock)', 'Shock Only (No PA, Shock)', ...
    'Place Attachment Only (PA, No Shock)', 'PA + Shock (PA, Shock)'};

% Color scheme for scenarios
colors = struct('Control', [0.2 0.2 0.2], ...  % Dark gray
                'Shock', [0.8 0.2 0.2], ...     % Red
                'PA', [0.2 0.6 0.8], ...        % Blue
                'PA_Shock', [0.8 0.5 0.2]);     % Orange

%% Create individual scenario plots
for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    
    if ~isfield(aggregated, scenarioName)
        warning('Scenario %s not found in aggregated data', scenarioName);
        continue;
    end
    
    fprintf('Creating plot for %s...\n', scenarioName);
    
    data = aggregated.(scenarioName);
    timesteps = 1:data.numTimesteps;
    
    % Create figure with 3 subplots
    fig = figure('Position', [100 100 1000 900], 'Visible', 'off');
    
    % Subplot 1: Migration Count
    subplot(3, 1, 1);
    hold on;
    % Shaded area for ±1 std
    fill([timesteps, fliplr(timesteps)], ...
        [data.migrationCount_mean' + data.migrationCount_std', ...
         fliplr(data.migrationCount_mean' - data.migrationCount_std')], ...
        colors.(scenarioName), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    % Mean line
    plot(timesteps, data.migrationCount_mean, 'Color', colors.(scenarioName), ...
        'LineWidth', 2.5);
    xlabel('Timestep', 'FontSize', 11);
    ylabel('Number of Migrations', 'FontSize', 11);
    title(sprintf('Migration Count - %s', scenarioTitles{s}), 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    hold off;
    
    % Subplot 2: Total Distance
    subplot(3, 1, 2);
    hold on;
    fill([timesteps, fliplr(timesteps)], ...
        [data.totalDistance_mean' + data.totalDistance_std', ...
         fliplr(data.totalDistance_mean' - data.totalDistance_std')], ...
        colors.(scenarioName), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(timesteps, data.totalDistance_mean, 'Color', colors.(scenarioName), ...
        'LineWidth', 2.5);
    xlabel('Timestep', 'FontSize', 11);
    ylabel('Total Distance (km)', 'FontSize', 11);
    title('Total Distance Traveled', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    hold off;
    
    % Subplot 3: Average Distance
    subplot(3, 1, 3);
    hold on;
    fill([timesteps, fliplr(timesteps)], ...
        [data.avgDistance_mean' + data.avgDistance_std', ...
         fliplr(data.avgDistance_mean' - data.avgDistance_std')], ...
        colors.(scenarioName), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(timesteps, data.avgDistance_mean, 'Color', colors.(scenarioName), ...
        'LineWidth', 2.5);
    xlabel('Timestep', 'FontSize', 11);
    ylabel('Avg Distance per Migration (km)', 'FontSize', 11);
    title('Average Distance per Migration', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    hold off;
    
    % Save figure
    filename = sprintf('migration_timeseries_%s.png', scenarioName);
    saveas(fig, filename);
    fprintf('  Saved: %s\n', filename);
    close(fig);
end

%% Create comparison plot with all scenarios
fprintf('Creating comparison plot...\n');

fig = figure('Position', [100 100 1200 900], 'Visible', 'off');

% Subplot 1: Migration Count - All scenarios
subplot(3, 1, 1);
hold on;
for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        data = aggregated.(scenarioName);
        timesteps = 1:data.numTimesteps;
        plot(timesteps, data.migrationCount_mean, 'Color', colors.(scenarioName), ...
            'LineWidth', 2.5, 'DisplayName', scenarioTitles{s});
    end
end
xlabel('Timestep', 'FontSize', 11);
ylabel('Number of Migrations', 'FontSize', 11);
title('Migration Count - Scenario Comparison', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
hold off;

% Subplot 2: Total Distance - All scenarios
subplot(3, 1, 2);
hold on;
for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        data = aggregated.(scenarioName);
        timesteps = 1:data.numTimesteps;
        plot(timesteps, data.totalDistance_mean, 'Color', colors.(scenarioName), ...
            'LineWidth', 2.5, 'DisplayName', scenarioTitles{s});
    end
end
xlabel('Timestep', 'FontSize', 11);
ylabel('Total Distance (km)', 'FontSize', 11);
title('Total Distance Traveled - Scenario Comparison', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
hold off;

% Subplot 3: Average Distance - All scenarios
subplot(3, 1, 3);
hold on;
for s = 1:length(scenarios)
    scenarioName = scenarios{s};
    if isfield(aggregated, scenarioName)
        data = aggregated.(scenarioName);
        timesteps = 1:data.numTimesteps;
        plot(timesteps, data.avgDistance_mean, 'Color', colors.(scenarioName), ...
            'LineWidth', 2.5, 'DisplayName', scenarioTitles{s});
    end
end
xlabel('Timestep', 'FontSize', 11);
ylabel('Avg Distance per Migration (km)', 'FontSize', 11);
title('Average Distance per Migration - Scenario Comparison', 'FontSize', 13, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
hold off;

% Save comparison figure
filename = 'migration_timeseries_Comparison.png';
saveas(fig, filename);
fprintf('  Saved: %s\n', filename);
close(fig);

fprintf('\n✓ Visualization complete\n\n');

end

