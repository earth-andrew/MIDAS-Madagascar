function compare_return_to_origin()
% COMPARE_RETURN_TO_ORIGIN Analyze return migration to original location
%
% Counts how many times agents return to their initial location
% Creates 3 types of plots:
%   1. Cumulative total count comparison (time series)
%   2. Distribution comparison (grouped histogram)
%   3. Time series comparison (line plot - returns per timestep)
%
% Outputs:
%   - Analysis/Figures/return_to_origin_total.png
%   - Analysis/Figures/return_to_origin_distribution.png
%   - Analysis/Figures/return_to_origin_timeseries.png
%   - Analysis/Data/return_to_origin_comparison.csv

fprintf('\n=== COMPARING RETURN TO ORIGIN PATTERNS ===\n\n');

% File paths
baseline_file = 'Outputs/Madagascar_PA_Shock_Full_Run012_2025-11-13_00-29-17.mat';
shock_file = 'Outputs/MADA_shock_south.mat';

% Load scenarios
fprintf('Loading baseline scenario: %s\n', baseline_file);
baseline_data = load(baseline_file);

fprintf('Loading shock scenario: %s\n', shock_file);
shock_data = load(shock_file);

fprintf('\nAnalyzing return-to-origin patterns...\n');

% Analyze baseline
[baseline_total, baseline_dist, baseline_timeseries] = analyze_returns(baseline_data.output.agentSummary);
fprintf('  Baseline: Total returns = %d\n', baseline_total);

% Analyze shock
[shock_total, shock_dist, shock_timeseries] = analyze_returns(shock_data.output.agentSummary);
fprintf('  Shock: Total returns = %d\n', shock_total);

% Plot 1: Cumulative Total Count Comparison (Time Series)
fprintf('\nCreating Plot 1: Cumulative Total Count Comparison (Time Series)...\n');
figure('Position', [100 100 1000 600]);

% Calculate cumulative returns over time
num_timesteps = max([length(baseline_timeseries), length(shock_timeseries)]);

% Pad if necessary
if length(baseline_timeseries) < num_timesteps
    baseline_timeseries(end+1:num_timesteps) = 0;
end
if length(shock_timeseries) < num_timesteps
    shock_timeseries(end+1:num_timesteps) = 0;
end

% Calculate cumulative sums
baseline_cumulative = cumsum(baseline_timeseries);
shock_cumulative = cumsum(shock_timeseries);

plot(1:num_timesteps, baseline_cumulative, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(1:num_timesteps, shock_cumulative, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Cumulative Return Events', 'FontSize', 12, 'FontWeight', 'bold');
title('Cumulative Return to Origin Events Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = 'Analysis/Figures/return_to_origin_total.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Plot 2: Distribution Comparison (Grouped Histogram)
fprintf('Creating Plot 2: Distribution Comparison...\n');
figure('Position', [100 100 1000 600]);

% Create grouped bar chart
% Get all keys from both distributions
baseline_keys = [];
if ~isempty(baseline_dist.keys)
    baseline_keys = cell2mat(baseline_dist.keys);
end
shock_keys = [];
if ~isempty(shock_dist.keys)
    shock_keys = cell2mat(shock_dist.keys);
end

if isempty(baseline_keys) && isempty(shock_keys)
    max_returns = 0;
elseif isempty(baseline_keys)
    max_returns = max(shock_keys);
elseif isempty(shock_keys)
    max_returns = max(baseline_keys);
else
    max_returns = max([max(baseline_keys), max(shock_keys)]);
end
return_counts_baseline = zeros(1, max_returns + 1);
return_counts_shock = zeros(1, max_returns + 1);

for i = 0:max_returns
    if isKey(baseline_dist, i)
        return_counts_baseline(i + 1) = baseline_dist(i);
    end
    if isKey(shock_dist, i)
        return_counts_shock(i + 1) = shock_dist(i);
    end
end

bar_data = [return_counts_baseline', return_counts_shock'];
bar(0:max_returns, bar_data);
xlabel('Number of Returns per Agent', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Number of Agents', 'FontSize', 12, 'FontWeight', 'bold');
title('Distribution of Return to Origin Events: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = 'Analysis/Figures/return_to_origin_distribution.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Plot 3: Time Series Comparison (Line Plot)
fprintf('Creating Plot 3: Time Series Comparison...\n');
figure('Position', [100 100 1000 600]);

num_timesteps = max([length(baseline_timeseries), length(shock_timeseries)]);

% Pad if necessary
if length(baseline_timeseries) < num_timesteps
    baseline_timeseries(end+1:num_timesteps) = 0;
end
if length(shock_timeseries) < num_timesteps
    shock_timeseries(end+1:num_timesteps) = 0;
end

plot(1:num_timesteps, baseline_timeseries, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(1:num_timesteps, shock_timeseries, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Number of Return Events', 'FontSize', 12, 'FontWeight', 'bold');
title('Return to Origin Events Over Time: Baseline vs Shock', 'FontSize', 14, 'FontWeight', 'bold');
legend({'Baseline (PA+Shock Run012)', 'Shock (South)'}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = 'Analysis/Figures/return_to_origin_timeseries.png';
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export data to CSV
fprintf('Exporting data to CSV...\n');

% Prepare time series data for CSV
csv_data = table((1:num_timesteps)', baseline_timeseries, baseline_cumulative, ...
    shock_timeseries, shock_cumulative, ...
    'VariableNames', {'Timestep', 'Baseline_Returns_Per_Timestep', 'Baseline_Cumulative_Returns', ...
    'Shock_Returns_Per_Timestep', 'Shock_Cumulative_Returns'});

csv_file = 'Analysis/Data/return_to_origin_comparison.csv';
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Return to origin comparison complete!\n\n');

end


function [total_returns, distribution, timeseries] = analyze_returns(agentSummary)
% Analyze return-to-origin patterns for a scenario
%
% Returns:
%   total_returns: total number of return events
%   distribution: containers.Map with key=num_returns, value=num_agents
%   timeseries: vector of return events per timestep

% Initialize
distribution = containers.Map('KeyType', 'double', 'ValueType', 'double');
num_agents = height(agentSummary);

% Determine max timesteps
max_timestep = 0;
for i = 1:num_agents
    moveHistory = agentSummary.moveHistory{i};
    if ~isempty(moveHistory)
        max_timestep = max(max_timestep, max(moveHistory(:, 1)));
    end
end

timeseries = zeros(max_timestep, 1);
total_returns = 0;

% Analyze each agent
for i = 1:num_agents
    moveHistory = agentSummary.moveHistory{i};
    
    if isempty(moveHistory)
        % Agent never moved
        if isKey(distribution, 0)
            distribution(0) = distribution(0) + 1;
        else
            distribution(0) = 1;
        end
        continue;
    end
    
    % Initial location is the destination of the first "move" (initialization)
    % or we can use the first from_location
    % Assuming moveHistory format: [timestep, from_location, to_location, distance]
    initial_location = moveHistory(1, 2);  % from_location of first move
    
    % Count returns to initial location
    agent_returns = 0;
    
    for m = 1:size(moveHistory, 1)
        to_loc = moveHistory(m, 3);
        timestep = moveHistory(m, 1);
        
        % Check if moved back to initial location
        if to_loc == initial_location && m > 1  % Don't count initial placement
            agent_returns = agent_returns + 1;
            total_returns = total_returns + 1;
            
            % Record in timeseries
            if timestep <= length(timeseries)
                timeseries(timestep) = timeseries(timestep) + 1;
            end
        end
    end
    
    % Update distribution
    if isKey(distribution, agent_returns)
        distribution(agent_returns) = distribution(agent_returns) + 1;
    else
        distribution(agent_returns) = 1;
    end
end

end

