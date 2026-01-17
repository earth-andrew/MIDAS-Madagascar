function [metrics] = calculate_migration_metrics(experimentData)
% CALCULATE_MIGRATION_METRICS Compute migration metrics for all runs
%
% Inputs:
%   experimentData - Struct array from load_experiment_data
%
% Returns:
%   metrics - Struct array with fields:
%     .runID: Run identifier
%     .scenario: Scenario name
%     .migrationCount: Vector of migration counts per timestep
%     .totalDistance: Vector of total distance traveled per timestep
%     .avgDistance: Vector of average distance per migration per timestep
%     .numTimesteps: Number of timesteps

fprintf('=== CALCULATING MIGRATION METRICS ===\n\n');

% Initialize metrics structure
metrics = struct('runID', {}, 'scenario', {}, 'migrationCount', {}, ...
    'totalDistance', {}, 'avgDistance', {}, 'numTimesteps', {});

for i = 1:length(experimentData)
    fprintf('  [%2d/%2d] Processing %s (%s)...\n', i, length(experimentData), ...
        experimentData(i).runID, experimentData(i).scenario);
    
    output = experimentData(i).output;
    
    % Extract migration count (already computed in output)
    migrationCount = output.migrations;  % Vector: timesteps x 1
    numTimesteps = length(migrationCount);
    
    % Initialize distance vectors
    totalDistance = zeros(numTimesteps, 1);
    avgDistance = zeros(numTimesteps, 1);
    
    % Get distance matrix
    if isfield(output, 'mapVariables') && isfield(output.mapVariables, 'distanceMatrix')
        distanceMatrix = output.mapVariables.distanceMatrix;
    else
        warning('  Distance matrix not found for run %d, distances will be zero', i);
        distanceMatrix = [];
    end
    
    % Calculate total distance traveled per timestep from agentSummary.moveHistory
    if isfield(experimentData(i), 'agentSummary') && ~isempty(experimentData(i).agentSummary)
        agentSummary = experimentData(i).agentSummary;
        
        if istable(agentSummary) && ismember('moveHistory', agentSummary.Properties.VariableNames)
            % Process each agent's move history
            for agentIdx = 1:height(agentSummary)
                moveHistory = agentSummary.moveHistory{agentIdx};
                
                % moveHistory format: [timestep, location, visX, visY]
                if ~isempty(moveHistory) && size(moveHistory, 1) > 1
                    % Iterate through consecutive moves
                    for moveIdx = 2:size(moveHistory, 1)
                        timestep = moveHistory(moveIdx, 1);
                        fromLoc = moveHistory(moveIdx-1, 2);
                        toLoc = moveHistory(moveIdx, 2);
                        
                        % Only count actual location changes
                        if fromLoc ~= toLoc && timestep <= numTimesteps
                            % Look up distance if available
                            if ~isempty(distanceMatrix) && ...
                               fromLoc > 0 && toLoc > 0 && ...
                               fromLoc <= size(distanceMatrix, 1) && ...
                               toLoc <= size(distanceMatrix, 2)
                                
                                distance = distanceMatrix(fromLoc, toLoc);
                                totalDistance(timestep) = totalDistance(timestep) + distance;
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Calculate average distance per migration
    for t = 1:numTimesteps
        if migrationCount(t) > 0
            avgDistance(t) = totalDistance(t) / migrationCount(t);
        else
            avgDistance(t) = 0;
        end
    end
    
    % Store metrics
    metrics(i).runID = experimentData(i).runID;
    metrics(i).scenario = experimentData(i).scenario;
    metrics(i).migrationCount = migrationCount;
    metrics(i).totalDistance = totalDistance;
    metrics(i).avgDistance = avgDistance;
    metrics(i).numTimesteps = numTimesteps;
    
    fprintf('    Timesteps: %d, Total migrations: %d, Max distance/timestep: %.1f\n', ...
        numTimesteps, sum(migrationCount), max(totalDistance));
end

fprintf('\n✓ Metrics calculation complete\n\n');

end

