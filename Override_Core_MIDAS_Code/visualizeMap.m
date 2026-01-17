function [mapHandle] = visualizeMap( agentList, mapVariables, mapParameters, modelParameters )
%visualizeMap - Madagascar enhanced version WITH Mapping Toolbox
%
% Uses shapefile for high-quality visualization

% Try high-quality shapefile visualization first
try
    visualize_madagascar_shapefile(agentList, mapVariables.locations, mapVariables.indexT);
    mapHandle = gcf;
    return;
catch ME
    % If shapefile fails, try simple raster version
    fprintf('Warning: Shapefile visualization failed: %s\n', ME.message);
    fprintf('Trying raster visualization...\n');
    try
        visualize_madagascar_simple(agentList, mapVariables.locations, mapVariables.map, mapVariables.indexT);
        mapHandle = gcf;
        return;
    catch ME2
        fprintf('Warning: Raster visualization also failed: %s\n', ME2.message);
        fprintf('Falling back to standard visualization...\n');
    end
end

% FALLBACK: Standard visualization
if(isfield(mapVariables,'mapHandle'))
    mapHandle = mapVariables.mapHandle;
else
    mapHandle = figure;
end

hold off;

% Get the map (last layer has the final administrative regions)
currentMap = mapVariables.map(:,:,end);

% Get maximum region ID to determine number of regions
maxRegionID = max(currentMap(:));
numRegions = maxRegionID;

% Check if we have spatial reference
if(~isempty(mapParameters.r1))
    % Shapefile mode with spatial reference
    currentMap(currentMap == 0) = -Inf; % Ocean = white
    hMap = mapshow(currentMap, mapParameters.r1,'CData',currentMap,'displaytype','surface');
else
    % No spatial reference - use imagesc with improved colormap
    imagesc(currentMap);
    axis equal tight;
end

% Create distinct colormap for Madagascar regions
% Generate 22+ distinct colors using HSV color space
nColors = max(numRegions, 30); % Extra colors for safety
cmap = hsv(nColors);

% Shuffle to ensure adjacent regions get different colors
rng(42); % Fixed seed for consistency
shuffleIdx = randperm(nColors);
cmap = cmap(shuffleIdx, :);

% Set ocean/background to white
cmap(1,:) = [1 1 1]; % White for region ID = 0 or background

% Apply colormap
colormap(cmap);

hold on;

% Draw white borders between administrative regions
borders = mapVariables.borders;
for indexI = 1:size(borders,3)
    if(isempty(mapParameters.r1))
        % For imagesc mode: overlay borders
        hBorder = imagesc(borders(:,:,indexI));
        set(hBorder,'AlphaData',borders(:,:,indexI) > 0);
        % Make borders white
        borderCmap = colormap;
        borderCmap(end,:) = [1 1 1];
        colormap(borderCmap);
    end
end

% Get max color for layering (keep agents on top)
maxColor = max(max(currentMap));
if maxColor == -Inf
    maxColor = numRegions;
end

% DRAW MOVEMENT LINES
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
                if(~isempty(mapParameters.r1))
                    % With spatial reference
                    [startPointsX,startPointsY] = setltln(currentMap,mapParameters.r1,startPointsX, startPointsY);
                    [endPointsX,endPointsY] = setltln(currentMap,mapParameters.r1,endPointsX, endPointsY);
                    if(~isempty(startPointsX))
                        plot3([startPointsY endPointsY],[startPointsX endPointsX],...
                            (maxColor+1) * ones(size(startPointsY,1),2),...
                            'Color',[0 0 0 fade],'LineWidth',2);
                    end
                else
                    % Without spatial reference - use direct coordinates
                    plot3([startPointsY endPointsY],[startPointsX endPointsX],...
                        (maxColor+1) * ones(size(startPointsY,1),2),...
                        'Color',[0 0 0 fade],'LineWidth',2);
                end
            end
        end
    end
end

% DRAW AGENTS (red dots on top of everything)
if(~isempty(mapParameters.r1))
    [x,y] = setltln(currentMap, mapParameters.r1, [agentList.visX],[agentList.visY]);
    plot3(y,x,(maxColor+2) * ones(size(x,2),1),...
        'o','MarkerSize',4,...
        'MarkerFaceColor','r',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.5);
else
    y = [agentList.visY];
    x = [agentList.visX];
    plot3(y,x,(maxColor+2) * ones(size(x,2),1),...
        'o','MarkerSize',4,...
        'MarkerFaceColor','r',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.5);
end

% Add title with simulation info
if(~isempty(mapParameters.r1))
    textY = mapParameters.r1(3)+mapParameters.sizeY/mapParameters.density*.1;
    textX = mapParameters.r1(2)-mapParameters.sizeX/mapParameters.density*.9;
else
    textY = mapParameters.sizeY * 0.1;
    textX = mapParameters.sizeX * 0.9;
end

titleText = sprintf('Madagascar: %d agents | Year %d | Timestep %d', ...
    length(agentList), ...
    floor(mapVariables.indexT / mapVariables.cycleLength), ...
    mapVariables.indexT);
text(textY, textX, titleText,...
    'FontSize', 12,...
    'FontWeight', 'bold',...
    'BackgroundColor', [1 1 1 0.7],...
    'EdgeColor', 'k');

hold off;

end

