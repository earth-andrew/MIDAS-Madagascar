function visualize_madagascar_shapefile(agentList, locations, timestep)
% visualize_madagascar_shapefile - High-quality Madagascar visualization
%
% Uses shapefile with Mapping Toolbox for smooth boundaries
% Shows:
% - 44 administrative regions with distinct colors
% - Agent positions as red dots
% - Movement trails between regions

persistent figHandle shapeData regionColors

% Load shapefile on first call
if isempty(shapeData)
    try
        shapeData = shaperead('./Data/Madagascar_44_UrbanRural.shp');
        fprintf('✓ Loaded shapefile with %d regions\n', length(shapeData));
        
        % Create distinct colors for each region (44 regions)
        nRegions = length(shapeData);
        % Combine multiple colormaps for maximum distinction
        cmap1 = hsv(ceil(nRegions/3));
        cmap2 = jet(ceil(nRegions/3));
        cmap3 = parula(ceil(nRegions/3));
        cmap = [cmap1; cmap2; cmap3];
        rng(42); % Fixed seed for consistency
        indices = randperm(size(cmap, 1), nRegions);
        regionColors = cmap(indices, :);
    catch ME
        error('Failed to load shapefile: %s', ME.message);
    end
end

% Create figure on first call
if isempty(figHandle) || ~isvalid(figHandle)
    figHandle = figure('Position', [100 100 1400 900]);
end

figure(figHandle);
clf;
hold on;

% Draw all 44 regions with distinct colors
for i = 1:length(shapeData)
    % Get polygon coordinates
    x = shapeData(i).X;
    y = shapeData(i).Y;
    
    % Color this region
    faceColor = regionColors(i, :);
    
    % Draw the polygon with white boundaries
    fill(x, y, faceColor, ...
        'EdgeColor', 'white', ...
        'LineWidth', 2, ...
        'FaceAlpha', 0.8);
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
            % Get location coordinates (Longitude, Latitude)
            lon = locations.Longitude(locIdx);
            lat = locations.Latitude(locIdx);
            
            % Plot agents as red dots sized by count
            markerSize = max(80, min(300, 50 + nAgents*3));
            
            scatter(lon, lat, markerSize, 'r', 'filled', ...
                'MarkerEdgeColor', 'k', ...
                'LineWidth', 2);
            
            % Add text label for agent counts
            if nAgents > 15
                text(lon, lat, sprintf('%d', nAgents), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontWeight', 'bold', ...
                    'FontSize', 11, ...
                    'Color', 'white');
            end
        end
    end
    
    % Draw movement lines for recent migrations
    % moveHistory format: [timestep, matrixLocation, visX, visY]
    if nargin >= 3
        moveFadeSteps = 8; % Show last 8 timesteps of movement
        
        for i = 1:length(agentList)
            agent = agentList(i);
            
            % Check if agent has movement history
            if isfield(agent, 'moveHistory') && size(agent.moveHistory, 1) > 1
                % Filter moves to recent timesteps only
                recentIdx = agent.moveHistory(:,1) >= (timestep - moveFadeSteps);
                recentMoves = agent.moveHistory(recentIdx, :);
                
                % Draw lines between consecutive locations
                for j = 2:size(recentMoves, 1)
                    fromLoc = recentMoves(j-1, 2);
                    toLoc = recentMoves(j, 2);
                    moveTime = recentMoves(j, 1);
                    
                    if fromLoc ~= toLoc && fromLoc > 0 && toLoc > 0 && ...
                       fromLoc <= height(locations) && toLoc <= height(locations)
                        
                        % Get coordinates
                        fromLon = locations.Longitude(fromLoc);
                        fromLat = locations.Latitude(fromLoc);
                        toLon = locations.Longitude(toLoc);
                        toLat = locations.Latitude(toLoc);
                        
                        % Calculate fade based on how recent the move was
                        fade = (moveFadeSteps - (timestep - moveTime)) / moveFadeSteps;
                        fade = max(0.3, fade); % Minimum visibility
                        
                        % Draw movement line (black with fade)
                        plot([fromLon toLon], [fromLat toLat], ...
                            'Color', [0 0 0 fade], ...
                            'LineWidth', 2.5);
                        
                        % Add arrow to show direction
                        dx = toLon - fromLon;
                        dy = toLat - fromLat;
                        midLon = fromLon + dx*0.6;
                        midLat = fromLat + dy*0.6;
                        quiver(midLon, midLat, dx*0.3, dy*0.3, 0, ...
                            'Color', [0 0 0 fade], ...
                            'LineWidth', 2, ...
                            'MaxHeadSize', 1.2);
                    end
                end
            end
        end
    end
end

% Format plot
axis equal tight;
xlabel('Longitude (°E)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Latitude (°S)', 'FontSize', 13, 'FontWeight', 'bold');
set(gca, 'FontSize', 11);

% Add grid
grid on;
set(gca, 'GridAlpha', 0.3, 'GridLineStyle', ':');

% Title with info
if nargin >= 3
    title(sprintf('Madagascar MIDAS Model - Timestep %d | %d Active Agents', ...
        timestep, length(agentList)), ...
        'FontSize', 16, 'FontWeight', 'bold');
else
    title('Madagascar MIDAS - Agent Distribution', ...
        'FontSize', 16, 'FontWeight', 'bold');
end

% Add subtle background color
set(gca, 'Color', [0.95 0.95 1]); % Very light blue for ocean

hold off;
drawnow;

end

