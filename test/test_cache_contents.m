% test_cache_contents.m
% Check what's actually in the Madagascar cache file

fprintf('\nChecking Madagascar_44_UrbanRural_MIDAS.mat contents...\n\n');

% Check if file exists
if ~exist('Madagascar_44_UrbanRural_MIDAS.mat', 'file')
    fprintf('✗ Cache file NOT FOUND!\n');
    return;
end

fprintf('✓ Cache file exists\n\n');

% Load cache
fprintf('Loading cache file...\n');
try
    cacheData = load('Madagascar_44_UrbanRural_MIDAS.mat');
    fprintf('✓ Cache loaded successfully\n\n');
catch ME
    fprintf('✗ ERROR loading cache:\n');
    fprintf('  %s\n', ME.message);
    return;
end

% Show what's in the cache
fprintf('Variables in cache file:\n');
fields = fieldnames(cacheData);
for i = 1:length(fields)
    field = fields{i};
    data = cacheData.(field);
    
    if isnumeric(data) || islogical(data)
        fprintf('  • %s: %s %s\n', field, mat2str(size(data)), class(data));
    elseif istable(data)
        fprintf('  • %s: table with %d rows, %d columns\n', field, height(data), width(data));
    elseif isstruct(data)
        fprintf('  • %s: struct array with %d elements\n', field, numel(data));
    elseif iscell(data)
        fprintf('  • %s: cell array %s\n', field, mat2str(size(data)));
    else
        fprintf('  • %s: %s\n', field, class(data));
    end
end

% Check for required fields
fprintf('\nChecking required fields:\n');
requiredFields = {'locations', 'map', 'borders', 'distanceMatrix'};

for i = 1:length(requiredFields)
    field = requiredFields{i};
    if isfield(cacheData, field)
        fprintf('  ✓ %s present\n', field);
    else
        fprintf('  ✗ %s MISSING\n', field);
    end
end

% Check mapParameters specifically
fprintf('\nChecking mapParameters:\n');
if isfield(cacheData, 'mapParameters')
    fprintf('  ✓ mapParameters present\n');
    mp = cacheData.mapParameters;
    mpFields = fieldnames(mp);
    fprintf('  Fields in mapParameters:\n');
    for i = 1:length(mpFields)
        fprintf('    - %s\n', mpFields{i});
    end
else
    fprintf('  ⚠ mapParameters NOT present (will need to use input version)\n');
end

% Try the same operation the code does
fprintf('\nTesting cache loading like createMapFromSHP does:\n');
try
    locations = cacheData.locations;
    fprintf('  ✓ Can extract locations\n');
    
    map = cacheData.map;
    fprintf('  ✓ Can extract map\n');
    
    borders = cacheData.borders;
    fprintf('  ✓ Can extract borders\n');
    
    if isfield(cacheData, 'distanceMatrix')
        distanceMatrix = cacheData.distanceMatrix;
        fprintf('  ✓ Can extract distanceMatrix\n');
    else
        fprintf('  ✗ distanceMatrix not in cache\n');
    end
    
    % Convert locations if needed
    if isstruct(locations)
        locations = struct2table(locations);
        fprintf('  ✓ Converted locations from struct to table\n');
    end
    
    fprintf('\n✅ Cache loading simulation successful!\n');
    
catch ME
    fprintf('\n✗ ERROR during cache loading simulation:\n');
    fprintf('  %s\n', ME.message);
end

fprintf('\nTest complete!\n');

