function [ruMigrations] = calculate_rural_urban_migrations(experimentData)
% CALCULATE_RURAL_URBAN_MIGRATIONS Classify migrations by rural/urban flow type
%
% Inputs:
%   experimentData - Struct array from load_experiment_data
%
% Returns:
%   ruMigrations - Struct array with fields:
%     .runID: Run identifier
%     .scenario: Scenario name
%     .RR: Rural→Rural migrations per timestep (vector)
%     .RU: Rural→Urban migrations per timestep (vector)
%     .UR: Urban→Rural migrations per timestep (vector)
%     .UU: Urban→Urban migrations per timestep (vector)
%     .numTimesteps: Number of timesteps

fprintf('=== CALCULATING RURAL-URBAN MIGRATION FLOWS ===\n\n');

% Initialize structure
ruMigrations = struct('runID', {}, 'scenario', {}, 'RR', {}, 'RU', {}, ...
    'UR', {}, 'UU', {}, 'numTimesteps', {});

for i = 1:length(experimentData)
    fprintf('  [%2d/%2d] Processing %s (%s)...\n', i, length(experimentData), ...
        experimentData(i).runID, experimentData(i).scenario);
    
    output = experimentData(i).output;
    
    % Get number of timesteps
    numTimesteps = length(output.migrations);
    
    % Initialize counters for each migration type
    RR = zeros(numTimesteps, 1);  % Rural to Rural
    RU = zeros(numTimesteps, 1);  % Rural to Urban
    UR = zeros(numTimesteps, 1);  % Urban to Rural
    UU = zeros(numTimesteps, 1);  % Urban to Urban
    
    % Get location information
    if isfield(output, 'mapVariables') && isfield(output.mapVariables, 'locations')
        locations = output.mapVariables.locations;
        
        % Convert to table if struct
        if isstruct(locations)
            locations = struct2table(locations);
        end
        
        % Check if URBAN_RURAL field exists
        if ~ismember('URBAN_RURAL', locations.Properties.VariableNames)
            warning('  URBAN_RURAL field not found, skipping this run');
            continue;
        end
        
        % Create urban/rural lookup (1=Rural, 2=Urban for quick indexing)
        numLocations = height(locations);
        isUrban = false(numLocations, 1);
        
        for loc = 1:numLocations
            urbanRuralStr = locations.URBAN_RURAL{loc};
            if contains(lower(urbanRuralStr), 'urban')
                isUrban(loc) = true;
            end
        end
        
    else
        warning('  Location data not found for run %d', i);
        continue;
    end
    
    % Process agent move histories
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
                        
                        % Only count actual location changes within valid timesteps
                        if fromLoc ~= toLoc && timestep <= numTimesteps && ...
                           fromLoc > 0 && toLoc > 0 && ...
                           fromLoc <= numLocations && toLoc <= numLocations
                            
                            % Classify migration type
                            fromUrban = isUrban(fromLoc);
                            toUrban = isUrban(toLoc);
                            
                            if ~fromUrban && ~toUrban
                                % Rural to Rural
                                RR(timestep) = RR(timestep) + 1;
                            elseif ~fromUrban && toUrban
                                % Rural to Urban
                                RU(timestep) = RU(timestep) + 1;
                            elseif fromUrban && ~toUrban
                                % Urban to Rural
                                UR(timestep) = UR(timestep) + 1;
                            else
                                % Urban to Urban
                                UU(timestep) = UU(timestep) + 1;
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Store results
    ruMigrations(i).runID = experimentData(i).runID;
    ruMigrations(i).scenario = experimentData(i).scenario;
    ruMigrations(i).RR = RR;
    ruMigrations(i).RU = RU;
    ruMigrations(i).UR = UR;
    ruMigrations(i).UU = UU;
    ruMigrations(i).numTimesteps = numTimesteps;
    
    % Summary stats
    fprintf('    R→R: %d, R→U: %d, U→R: %d, U→U: %d (total: %d)\n', ...
        sum(RR), sum(RU), sum(UR), sum(UU), sum(RR)+sum(RU)+sum(UR)+sum(UU));
end

fprintf('\n✓ Rural-urban migration calculation complete\n\n');

end

