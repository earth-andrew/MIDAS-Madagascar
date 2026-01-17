function visualize_madagascar_simple(agentList, locations, map, timestep)
% visualize_madagascar_simple - Madagascar visualization WITHOUT Mapping Toolbox
%
% Uses cached map raster data instead of shapefile
% Shows:
% - Region boundaries with distinct colors
% - Agent positions as red dots
% - Movement trails between regions

persistent figHandle

% Create figure on first call
if isempty(figHandle) || ~isvalid(figHandle)
    figHandle = figure('Position', [100 100 1200 800]);
end

figure(figHandle);
clf;
hold on;

% Get the regional map (last layer)
if ndims(map) == 3
    currentMap = map(:,:,end);
else
    currentMap = map;
end

% Create colormap with distinct colors for regions
maxRegion = max(currentMap(:));
if maxRegion > 0
    % Generate distinct colors using HSV
    nColors = maxRegion + 10; % Extra colors for safety
    cmap = hsv(nColors);
    
    % Shuffle for better visual distinction
    rng(42);
    cmap = cmap(randperm(nColors), :);
    
    % Set background/ocean to white
    cmap(1,:) = [1 1 1];
    
    % Display the map with colors
    imagesc(currentMap);
    colormap(cmap);
    axis equal tight;
    
    % Add contour lines for region boundaries
    hold on;
    [C, h] = contour(currentMap, 'LineColor', 'white', 'LineWidth', 1.5);
else
    % If no map data, just create blank canvas
    imagesc(zeros(600,600));
    colormap([1 1 1]);
end

% Convert locations to table if needed
if isstruct(locations)
    locations = struct2table(locations);
end

% Plot agents if provided
if nargin > 0 && ~isempty(agentList)
    % Get agent location counts
    agentLocs = [agentList.matrixLocation];
    
    % For each location with agents
    for locIdx = 1:height(locations)
        nAgents = sum(agentLocs == locIdx);
        
        if nAgents > 0
            % Get location pixel coordinates
            if isfield(locations, 'locationX') || ismember('locationX', locations.Properties.VariableNames)
                x = locations.locationX(locIdx);
                y = locations.locationY(locIdx);
            elseif isfield(locations, 'LocationIndex') || ismember('LocationIndex', locations.Properties.VariableNames)
                % Use LocationIndex to convert to x,y
                locIdx_val = locations.LocationIndex(locIdx);
                [y, x] = ind2sub(size(currentMap), locIdx_val);
            else
                continue; % Skip if no coordinates
            end
            
            % Plot agents as red dots sized by count
            markerSize = max(8, min(30, 5 + nAgents/5));
            
            plot(x, y, 'o', ...
                'MarkerSize', markerSize, ...
                'MarkerFaceColor', 'r', ...
                'MarkerEdgeColor', 'k', ...
                'LineWidth', 1.5);
            
            % Add text label for large agent counts
            if nAgents > 20
                text(x, y, sprintf('%d', nAgents), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontWeight', 'bold', ...
                    'FontSize', 8, ...
                    'Color', 'white');
            end
        end
    end
    
    % Draw movement lines for recent migrations
    if nargin > 0
        for i = 1:length(agentList)
            agent = agentList(i);
            
            % Check if agent has movement history
            if isfield(agent, 'moveHistory') && size(agent.moveHistory, 1) > 1
                % Get last few moves
                nMoves = min(3, size(agent.moveHistory, 1));
                recentMoves = agent.moveHistory(end-nMoves+1:end, :);
                
                % Draw lines between consecutive locations
                for j = 2:size(recentMoves, 1)
                    fromLoc = recentMoves(j-1, 2);
                    toLoc = recentMoves(j, 2);
                    
                    if fromLoc ~= toLoc && fromLoc > 0 && toLoc > 0 && ...
                       fromLoc <= height(locations) && toLoc <= height(locations)
                        
                        % Get pixel coordinates
                        if ismember('locationX', locations.Properties.VariableNames)
                            fromX = locations.locationX(fromLoc);
                            fromY = locations.locationY(fromLoc);
                            toX = locations.locationX(toLoc);
                            toY = locations.locationY(toLoc);
                        elseif ismember('LocationIndex', locations.Properties.VariableNames)
                            [fromY, fromX] = ind2sub(size(currentMap), locations.LocationIndex(fromLoc));
                            [toY, toX] = ind2sub(size(currentMap), locations.LocationIndex(toLoc));
                        else
                            continue;
                        end
                        
                        % Draw movement line with fade
                        fade = (nMoves - j + 1) / nMoves;
                        plot([fromX toX], [fromY toY], ...
                            'Color', [0 0 0 fade*0.6], ...
                            'LineWidth', 2);
                    end
                end
            end
        end
    end
end

% Format plot
set(gca, 'YDir', 'normal'); % Flip Y axis to match map orientation

if nargin >= 4
    title(sprintf('Madagascar MIDAS - Timestep %d | %d Agents', ...
        timestep, length(agentList)), ...
        'FontSize', 14, 'FontWeight', 'bold');
else
    title('Madagascar MIDAS - Agent Distribution', ...
        'FontSize', 14, 'FontWeight', 'bold');
end

hold off;
drawnow;

end

