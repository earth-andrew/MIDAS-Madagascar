function compare_three_scenarios_return_origin(file1, file2, file3, name1, name2, name3, output_suffix)
% COMPARE_THREE_SCENARIOS_RETURN_ORIGIN Analyze return migration to original location for 3 scenarios
%
% Args:
%   file1, file2, file3: Paths to .mat output files
%   name1, name2, name3: Scenario names for legend
%   output_suffix: Suffix for output files (e.g., 'noPA' or 'withPA')
%
% Outputs:
%   - Analysis/Figures/three_way_return_origin_total_<suffix>.png
%   - Analysis/Figures/three_way_return_origin_distribution_<suffix>.png
%   - Analysis/Figures/three_way_return_origin_timeseries_<suffix>.png
%   - Analysis/Data/three_way_return_origin_<suffix>.csv

fprintf('\n=== COMPARING RETURN TO ORIGIN PATTERNS (3 SCENARIOS) ===\n\n');

% Load scenarios
fprintf('Loading scenario 1: %s\n', file1);
data1 = load(file1);

fprintf('Loading scenario 2: %s\n', file2);
data2 = load(file2);

fprintf('Loading scenario 3: %s\n', file3);
data3 = load(file3);

fprintf('\nAnalyzing return-to-origin patterns...\n');

% Analyze each scenario
[total1, dist1, timeseries1] = analyze_returns(data1.output.agentSummary);
[total2, dist2, timeseries2] = analyze_returns(data2.output.agentSummary);
[total3, dist3, timeseries3] = analyze_returns(data3.output.agentSummary);

fprintf('  %s: Total returns = %d\n', name1, total1);
fprintf('  %s: Total returns = %d\n', name2, total2);
fprintf('  %s: Total returns = %d\n', name3, total3);

% Plot 1: Cumulative Total Count Comparison (Time Series)
fprintf('\nCreating Plot 1: Cumulative Total Count Comparison...\n');
figure('Position', [100 100 1000 600]);

num_timesteps = max([length(timeseries1), length(timeseries2), length(timeseries3)]);

% Pad if necessary
if length(timeseries1) < num_timesteps
    timeseries1(end+1:num_timesteps) = 0;
end
if length(timeseries2) < num_timesteps
    timeseries2(end+1:num_timesteps) = 0;
end
if length(timeseries3) < num_timesteps
    timeseries3(end+1:num_timesteps) = 0;
end

% Calculate cumulative sums
cumulative1 = cumsum(timeseries1);
cumulative2 = cumsum(timeseries2);
cumulative3 = cumsum(timeseries3);

plot(1:num_timesteps, cumulative1, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
hold on;
plot(1:num_timesteps, cumulative2, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(1:num_timesteps, cumulative3, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Cumulative Return Events', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Cumulative Return to Origin Events Over Time: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = sprintf('Analysis/Figures/three_way_return_origin_total_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Plot 2: Distribution Comparison (Grouped Histogram)
fprintf('Creating Plot 2: Distribution Comparison...\n');
figure('Position', [100 100 1000 600]);

% Get all keys from all distributions
keys1 = [];
if ~isempty(dist1.keys)
    keys1 = cell2mat(dist1.keys);
end
keys2 = [];
if ~isempty(dist2.keys)
    keys2 = cell2mat(dist2.keys);
end
keys3 = [];
if ~isempty(dist3.keys)
    keys3 = cell2mat(dist3.keys);
end

if isempty(keys1) && isempty(keys2) && isempty(keys3)
    max_returns = 0;
else
    all_keys = [];
    if ~isempty(keys1), all_keys = [all_keys, keys1]; end
    if ~isempty(keys2), all_keys = [all_keys, keys2]; end
    if ~isempty(keys3), all_keys = [all_keys, keys3]; end
    max_returns = max(all_keys);
end

return_counts1 = zeros(1, max_returns + 1);
return_counts2 = zeros(1, max_returns + 1);
return_counts3 = zeros(1, max_returns + 1);

for i = 0:max_returns
    if isKey(dist1, i)
        return_counts1(i+1) = dist1(i);
    end
    if isKey(dist2, i)
        return_counts2(i+1) = dist2(i);
    end
    if isKey(dist3, i)
        return_counts3(i+1) = dist3(i);
    end
end

bar_data = [return_counts1; return_counts2; return_counts3]';
bar(0:max_returns, bar_data);
xlabel('Number of Returns', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Number of Agents', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Distribution of Return-to-Origin Events: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = sprintf('Analysis/Figures/three_way_return_origin_distribution_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Plot 3: Time Series Comparison
fprintf('Creating Plot 3: Time Series Comparison...\n');
figure('Position', [100 100 1000 600]);

plot(1:num_timesteps, timeseries1, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
hold on;
plot(1:num_timesteps, timeseries2, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
plot(1:num_timesteps, timeseries3, 'g-^', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
hold off;

xlabel('Timestep', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Return Events per Timestep', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Return to Origin Events Per Timestep: %s vs %s vs %s', name1, name2, name3), ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({name1, name2, name3}, 'Location', 'best', 'FontSize', 11);
grid on;

fig_file = sprintf('Analysis/Figures/three_way_return_origin_timeseries_%s.png', output_suffix);
saveas(gcf, fig_file);
fprintf('✓ Figure saved: %s\n', fig_file);

% Export to CSV
fprintf('Exporting data to CSV...\n');
csv_data = table((1:num_timesteps)', cumulative1, cumulative2, cumulative3, ...
    timeseries1, timeseries2, timeseries3, ...
    'VariableNames', {'Timestep', ...
    [name1 '_Cumulative'], [name2 '_Cumulative'], [name3 '_Cumulative'], ...
    [name1 '_PerTimestep'], [name2 '_PerTimestep'], [name3 '_PerTimestep']});

csv_file = sprintf('Analysis/Data/three_way_return_origin_%s.csv', output_suffix);
writetable(csv_data, csv_file);
fprintf('✓ Data saved: %s\n', csv_file);

fprintf('\n✓ Return to origin comparison complete!\n\n');

end


function [total_returns, distribution, timeseries] = analyze_returns(agentSummary)
% Analyze return-to-origin patterns for a scenario

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
        if isKey(distribution, 0)
            distribution(0) = distribution(0) + 1;
        else
            distribution(0) = 1;
        end
        continue;
    end
    
    initial_location = moveHistory(1, 2);  % from_location of first move
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

