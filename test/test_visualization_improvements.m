% Test improved visualization with colors and movement lines
clear; close all;

fprintf('Testing improved visualization...\n\n');

% Load spatial data (try cache first, then build from shapefile)
fprintf('1. Loading spatial data...\n');
if exist('./Data/Madagascar_44_UrbanRural_MIDAS.mat', 'file')
    load('./Data/Madagascar_44_UrbanRural_MIDAS.mat', 'locations');
    fprintf('   ✓ Loaded from cache\n');
else
    % Build from shapefile
    fprintf('   Cache not found, loading from shapefile...\n');
    shapeData = shaperead('./Data/Madagascar_44_UrbanRural.shp');
    
    % Extract coordinates as locations table
    nLocs = length(shapeData);
    Longitude = zeros(nLocs, 1);
    Latitude = zeros(nLocs, 1);
    for i = 1:nLocs
        % Get centroid as location coordinate
        x = shapeData(i).X(~isnan(shapeData(i).X));
        y = shapeData(i).Y(~isnan(shapeData(i).Y));
        Longitude(i) = mean(x);
        Latitude(i) = mean(y);
    end
    locations = table(Longitude, Latitude);
    fprintf('   ✓ Created %d locations from shapefile\n', nLocs);
end

% Create dummy agents with realistic movement history
fprintf('2. Creating test agents with movement history...\n');
nAgents = 50;
agentList = repmat(struct('matrixLocation', 1, 'moveHistory', []), 1, nAgents);

% Distribute agents across locations with some movement
rng(42);
for i = 1:nAgents
    % Random starting location
    startLoc = randi(height(locations));
    agentList(i).matrixLocation = startLoc;
    
    % Create movement history (timestep, location, visX, visY)
    % Simulate some agents moving over 20 timesteps
    currentLoc = startLoc;
    moveHistory = [0, currentLoc, 0, 0];
    
    for t = 1:20
        % 20% chance to move each timestep
        if rand < 0.2
            % Move to nearby location
            newLoc = randi(height(locations));
            moveHistory = [moveHistory; t, newLoc, 0, 0];
            currentLoc = newLoc;
        end
    end
    
    agentList(i).moveHistory = moveHistory;
    agentList(i).matrixLocation = currentLoc;
end

% Test the visualization
fprintf('3. Testing shapefile visualization with colors and movements...\n');
try
    visualize_madagascar_shapefile(agentList, locations, 20);
    fprintf('   ✓ Visualization displayed!\n\n');
    
    fprintf('Expected to see:\n');
    fprintf('  • 44 regions in DIFFERENT colors (reds, greens, blues, yellows, etc.)\n');
    fprintf('  • White boundaries between regions\n');
    fprintf('  • Red dots for agents\n');
    fprintf('  • Black lines showing recent movements between regions\n');
    fprintf('  • Arrows showing movement direction\n\n');
    
    fprintf('✅ TEST PASSED! Check the figure window.\n');
catch ME
    fprintf('   ✗ ERROR: %s\n', ME.message);
    fprintf('   Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('     %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

