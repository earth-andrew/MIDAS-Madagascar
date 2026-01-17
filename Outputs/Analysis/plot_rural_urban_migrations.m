function plot_rural_urban_migrations(aggregated)
% PLOT_RURAL_URBAN_MIGRATIONS Create time series plots for rural-urban migration flows
%
% Inputs:
%   aggregated - Struct from aggregate_rural_urban_flows
%
% Creates 4 PNG files (one per scenario):
%   - rural_urban_migrations_Control.png
%   - rural_urban_migrations_Shock.png
%   - rural_urban_migrations_PA.png
%   - rural_urban_migrations_PA_Shock.png

fprintf('=== CREATING RURAL-URBAN TIME SERIES PLOTS ===\n\n');

scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
scenarioTitles = {'Control (No PA, No Shock)', 'Shock Only (No PA, Shock)', ...
    'Place Attachment Only (PA, No Shock)', 'PA + Shock (PA, Shock)'};

% Color scheme for migration types
colors = struct();
colors.RR = [0.2 0.7 0.3];    % Green (Rural→Rural)
colors.RU = [0.9 0.5 0.1];    % Orange (Rural→Urban)
colors.UR = [0.2 0.5 0.8];    % Blue (Urban→Rural)
colors.UU = [0.6 0.2 0.7];    % Purple (Urban→Urban)

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
    
    % Create figure
    fig = figure('Position', [100 100 1200 800], 'Visible', 'off');
    hold on;
    
    % Plot each migration type with shaded std area
    
    % R→R (Green)
    fill([timesteps, fliplr(timesteps)], ...
        [data.RR_mean' + data.RR_std', fliplr(data.RR_mean' - data.RR_std')], ...
        colors.RR, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(timesteps, data.RR_mean, 'Color', colors.RR, 'LineWidth', 2.5, ...
        'DisplayName', 'Rural → Rural');
    
    % R→U (Orange)
    fill([timesteps, fliplr(timesteps)], ...
        [data.RU_mean' + data.RU_std', fliplr(data.RU_mean' - data.RU_std')], ...
        colors.RU, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(timesteps, data.RU_mean, 'Color', colors.RU, 'LineWidth', 2.5, ...
        'DisplayName', 'Rural → Urban');
    
    % U→R (Blue)
    fill([timesteps, fliplr(timesteps)], ...
        [data.UR_mean' + data.UR_std', fliplr(data.UR_mean' - data.UR_std')], ...
        colors.UR, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(timesteps, data.UR_mean, 'Color', colors.UR, 'LineWidth', 2.5, ...
        'DisplayName', 'Urban → Rural');
    
    % U→U (Purple)
    fill([timesteps, fliplr(timesteps)], ...
        [data.UU_mean' + data.UU_std', fliplr(data.UU_mean' - data.UU_std')], ...
        colors.UU, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(timesteps, data.UU_mean, 'Color', colors.UU, 'LineWidth', 2.5, ...
        'DisplayName', 'Urban → Urban');
    
    % Format plot
    xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Number of Migrations', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Rural-Urban Migration Flows - %s', scenarioTitles{s}), ...
        'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    set(gca, 'FontSize', 11);
    hold off;
    
    % Save figure
    filename = sprintf('rural_urban_migrations_%s.png', scenarioName);
    saveas(fig, filename);
    fprintf('  Saved: %s\n', filename);
    close(fig);
end

fprintf('\n✓ Time series visualization complete\n\n');

end

