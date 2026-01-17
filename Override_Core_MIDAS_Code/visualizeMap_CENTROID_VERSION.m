function [mapHandle] = visualizeMap( agentList, mapVariables, mapParameters, modelParameters )
%visualizeMap - Madagascar enhanced version with better visibility
%
% This override version:
% 1. Shows Madagascar shapefile map clearly
% 2. Uses larger markers for agents
% 3. Aggregates agents at location centroids for clarity
% 4. Shows movement lines more prominently

if(isfield(mapVariables,'mapHandle'))
    mapHandle = mapVariables.mapHandle;
else
    mapHandle = figure;
end

hold off;

% Paint the Madagascar map
currentMap = mapVariables.map(:,:,end);
if(isempty(mapParameters.r1))
    imagesc(currentMap);
else
    currentMap(currentMap ==0) = -Inf; % Oceans are white
    hMap = mapshow(currentMap, mapParameters.r1,'CData',currentMap,'displaytype','surface');
end
hold on;

maxColor = max(max(currentMap));

% Draw movement lines (with enhanced visibility for Madagascar)
for indexI = 1:length(agentList)
    currentAgent = agentList(indexI);
    
    if(modelParameters.showMovesOrNetwork == 1)
        for indexL = 2:size(currentAgent.moveHistory,1)
            endPointsX = [currentAgent.moveHistory(indexL,3)];
            endPointsY = [currentAgent.moveHistory(indexL,4)];
            startPointsX = [currentAgent.moveHistory(indexL-1,3)];
            startPointsY = [currentAgent.moveHistory(indexL-1,4)];
            
            fade = (modelParameters.movesFadeSteps - (mapVariables.indexT - currentAgent.moveHistory(indexL,1)))/modelParameters.movesFadeSteps * modelParameters.edgeAlpha;
            
            if(fade > 0)
                if(~isempty(mapParameters.r1)) % Shapefile
                    [startPointsX,startPointsY] = setltln(currentMap,mapParameters.r1,startPointsX, startPointsY);
                    [endPointsX,endPointsY] = setltln(currentMap,mapParameters.r1,endPointsX, endPointsY);
                    if(~isempty(startPointsX))
                        % Draw movement lines with better visibility
                        plot3([startPointsY endPointsY],[startPointsX endPointsX],...
                            (maxColor+1) * ones(size(startPointsY,1),2),...
                            'Color',[0 0 1 fade],'LineWidth',1.5);  % Blue, thicker lines
                    end
                else % Random map
                    plot([startPointsY endPointsY],[startPointsX endPointsX],...
                        'Color',[0 0 1 fade],'LineWidth',1.5);
                end
            end
        end
    end
end

% Aggregate agents by location for clearer visualization
locations = mapVariables.locations;
agentLocations = [agentList.matrixLocation];

for locIdx = 1:height(locations)
    agentsHere = sum(agentLocations == locIdx);
    
    if agentsHere > 0
        % Get centroid of this location
        if isstruct(locations)
            centX = locations(locIdx).locationX;
            centY = locations(locIdx).locationY;
        else
            centX = locations.locationX(locIdx);
            centY = locations.locationY(locIdx);
        end
        
        % Plot marker at centroid, sized by number of agents
        markerSize = max(8, min(40, 5 + agentsHere/2)); % Scale 8-40 based on agent count
        
        if(~isempty(mapParameters.r1))
            [centX_geo, centY_geo] = setltln(currentMap, mapParameters.r1, centX, centY);
            if ~isempty(centX_geo)
                plot3(centY_geo, centX_geo, (maxColor+1),...
                    'o', 'MarkerSize', markerSize,...
                    'MarkerFaceColor', 'r',...
                    'MarkerEdgeColor', 'k',...
                    'LineWidth', 1);
                
                % Add text label with agent count if > 5
                if agentsHere > 5
                    text(centY_geo, centX_geo, (maxColor+2), num2str(agentsHere),...
                        'HorizontalAlignment', 'center',...
                        'FontSize', 8,...
                        'Color', 'white',...
                        'FontWeight', 'bold');
                end
            end
        else
            plot3(centY, centX, (maxColor+1),...
                'o', 'MarkerSize', markerSize,...
                'MarkerFaceColor', 'r',...
                'MarkerEdgeColor', 'k',...
                'LineWidth', 1);
            
            if agentsHere > 5
                text(centY, centX, (maxColor+2), num2str(agentsHere),...
                    'HorizontalAlignment', 'center',...
                    'FontSize', 8,...
                    'Color', 'white',...
                    'FontWeight', 'bold');
            end
        end
    end
end

% Plot borders
borders = mapVariables.borders * (max(max(currentMap))+10);
for indexI = 1:size(borders,3)
    if(isempty(mapParameters.r1))
        hBorder = imagesc(borders(:,:,indexI));
        set(hBorder,'AlphaData',borders(:,:,indexI) > 0);
    end
end

if(isempty(mapParameters.r1))
    map = colormap;
    map(end,:) = [1 1 1];
    colormap(map)
end

% Add title and timestep information
if(~isempty(mapParameters.r1))
    textY = mapParameters.r1(3)+mapParameters.sizeY/mapParameters.density*.1;
    textX = mapParameters.r1(2)-mapParameters.sizeX/mapParameters.density*.9;
else
    textY = mapParameters.sizeY * 0.1;
    textX = mapParameters.sizeX * 0.9;
end

titleText = sprintf('Madagascar MIDAS: n=%d agents | Year %d | Timestep %d', ...
    length(agentList), ...
    floor(mapVariables.indexT / mapVariables.cycleLength), ...
    mapVariables.indexT);
text(textY, textX, titleText, 'FontSize', 10, 'FontWeight', 'bold');

hold off;

end

