% test_madagascar_visualization.m
% Quick test of the Madagascar visualization

fprintf('\n========================================\n');
fprintf('TESTING MADAGASCAR VISUALIZATION\n');
fprintf('========================================\n\n');

% Load data
fprintf('Loading Madagascar cache...\n');
cache = load('Madagascar_44_UrbanRural_MIDAS.mat');
locations = cache.locations;
map = cache.map;
if isstruct(locations)
    locations = struct2table(locations);
end
fprintf('✓ Loaded %d locations\n', height(locations));
fprintf('✓ Loaded map: %s\n', mat2str(size(map)));

% Create some test agents
fprintf('\nCreating test agents...\n');
nTestAgents = 100;
testAgents = [];

for i = 1:nTestAgents
    agent.id = i;
    agent.matrixLocation = randi(height(locations)); % Random location
    agent.moveHistory = [1 agent.matrixLocation]; % Initial position
    
    % Add some random migrations for 20% of agents
    if rand() < 0.2
        % Simulate migration
        newLoc = randi(height(locations));
        agent.moveHistory = [agent.moveHistory; 2 newLoc];
    end
    
    testAgents = [testAgents agent];
end

fprintf('✓ Created %d test agents\n', nTestAgents);

% Visualize
fprintf('\nGenerating HIGH-QUALITY shapefile visualization...\n');
try
    visualize_madagascar_shapefile(testAgents, locations, 1);
    fprintf('✓ Visualization created successfully!\n\n');
    fprintf('You should see:\n');
    fprintf('  - Madagascar map with 44 colored regions (smooth polygons)\n');
    fprintf('  - White boundaries between regions\n');
    fprintf('  - Red dots showing agents (sized by count)\n');
    fprintf('  - Black arrows showing migrations\n');
    fprintf('  - Light blue ocean background\n\n');
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('========================================\n');
fprintf('TEST COMPLETE\n');
fprintf('========================================\n');

