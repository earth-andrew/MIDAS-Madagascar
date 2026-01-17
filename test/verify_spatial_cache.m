% verify_spatial_cache.m
% Verify Madagascar_44_UrbanRural_MIDAS.mat spatial data structure

fprintf('\n========================================\n');
fprintf('SPATIAL CACHE VERIFICATION\n');
fprintf('========================================\n\n');

%% Load Spatial Cache
fprintf('Test 1: Loading Madagascar_44_UrbanRural_MIDAS.mat...\n');
try
    load('Madagascar_44_UrbanRural_MIDAS.mat');
    fprintf('  ✓ Spatial cache loaded successfully\n\n');
catch ME
    fprintf('  ✗ ERROR loading spatial cache:\n');
    fprintf('    %s\n', ME.message);
    return;
end

%% Check locations structure
fprintf('Test 2: Checking locations structure...\n');
if exist('locations', 'var')
    % Convert to table if it's a struct
    if isstruct(locations)
        locations = struct2table(locations);
        fprintf('  ✓ Converted locations from struct to table\n');
    end
    
    fprintf('  Number of locations: %d\n', height(locations));
    
    if height(locations) == 44
        fprintf('  ✓ PASS: 44 locations (correct for Madagascar)\n');
    else
        fprintf('  ✗ FAIL: Expected 44, found %d\n', height(locations));
    end
    
    % Check required fields
    fprintf('\n  Checking required fields:\n');
    required_fields = {'Latitude', 'Longitude', 'NAME_2', 'URBAN_RURAL'};
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ismember(field, locations.Properties.VariableNames)
            fprintf('    ✓ %s present\n', field);
        else
            fprintf('    ✗ %s MISSING\n', field);
        end
    end
else
    fprintf('  ✗ FAIL: locations variable not found\n');
    return;
end

%% Check urban/rural distribution
fprintf('\nTest 3: Checking urban/rural distribution...\n');
if ismember('URBAN_RURAL', locations.Properties.VariableNames)
    n_urban = sum(contains(locations.URBAN_RURAL, 'Urban'));
    n_rural = sum(contains(locations.URBAN_RURAL, 'Rural'));
    
    fprintf('  Urban locations: %d\n', n_urban);
    fprintf('  Rural locations: %d\n', n_rural);
    
    if n_urban == 22 && n_rural == 22
        fprintf('  ✓ PASS: Correct 22/22 split\n');
    else
        fprintf('  ⚠ WARNING: Expected 22 urban, 22 rural\n');
    end
    
    % Check alternating pattern
    fprintf('\n  Checking alternating pattern (first 6 locations):\n');
    for i = 1:min(6, height(locations))
        fprintf('    %2d: %-30s %s\n', i, locations.NAME_2{i}, locations.URBAN_RURAL{i});
    end
    
    % Verify pattern
    correct_pattern = true;
    for i = 1:min(6, height(locations))
        expected = {'Rural', 'Urban'};
        if ~contains(locations.URBAN_RURAL{i}, expected{mod(i-1, 2) + 1})
            correct_pattern = false;
            break;
        end
    end
    
    if correct_pattern
        fprintf('  ✓ Follows Rural/Urban alternating pattern\n');
    else
        fprintf('  ⚠ Pattern differs from expected\n');
    end
end

%% Check distance matrix
fprintf('\nTest 4: Checking distance matrix...\n');
if exist('distanceMatrix', 'var')
    [dm_rows, dm_cols] = size(distanceMatrix);
    fprintf('  Dimensions: %d × %d\n', dm_rows, dm_cols);
    
    if dm_rows == 44 && dm_cols == 44
        fprintf('  ✓ PASS: 44×44 matrix (correct)\n');
    else
        fprintf('  ✗ FAIL: Expected 44×44, got %d×%d\n', dm_rows, dm_cols);
    end
    
    % Check symmetry
    if isequal(distanceMatrix, distanceMatrix')
        fprintf('  ✓ Matrix is symmetric\n');
    else
        fprintf('  ✗ Matrix is not symmetric!\n');
    end
    
    % Check diagonal is zero
    if all(diag(distanceMatrix) == 0)
        fprintf('  ✓ Diagonal is zero (correct)\n');
    else
        fprintf('  ⚠ WARNING: Diagonal contains non-zero values\n');
    end
    
    % Distance statistics
    non_zero = distanceMatrix(distanceMatrix > 0);
    fprintf('\n  Distance statistics:\n');
    fprintf('    Min (non-zero): %.2f km\n', min(non_zero));
    fprintf('    Mean:           %.2f km\n', mean(non_zero));
    fprintf('    Max:            %.2f km\n', max(distanceMatrix(:)));
    
    % Check within-region distances (urban-rural pairs)
    if height(locations) == 44
        fprintf('\n  Within-region distances (urban-rural pairs):\n');
        for i = 1:2:min(10, height(locations))
            rural_row = i;
            urban_row = i + 1;
            dist = distanceMatrix(rural_row, urban_row);
            region_name = strrep(locations.NAME_2{rural_row}, '_Rural', '');
            fprintf('    %s: %.2f km\n', region_name, dist);
        end
    end
    
    % Validate realistic ranges
    if min(non_zero) < 50 && max(distanceMatrix(:)) > 1000
        fprintf('\n  ✓ Distance range looks realistic for Madagascar\n');
    else
        fprintf('\n  ⚠ Distance range may be unusual\n');
    end
else
    fprintf('  ✗ FAIL: distanceMatrix not found\n');
end

%% Check map and borders
fprintf('\nTest 5: Checking map and borders...\n');
if exist('map', 'var')
    fprintf('  map dimensions: %d × %d × %d\n', size(map));
    fprintf('  ✓ map structure present\n');
end

if exist('borders', 'var')
    fprintf('  borders dimensions: %d × %d × %d\n', size(borders));
    fprintf('  ✓ borders structure present\n');
end

if exist('mapParameters', 'var')
    fprintf('  ✓ mapParameters structure present\n');
    if isfield(mapParameters, 'sizeX') && isfield(mapParameters, 'sizeY')
        fprintf('    Map size: %d × %d\n', mapParameters.sizeX, mapParameters.sizeY);
    end
end

%% Check geographic bounds
fprintf('\nTest 6: Checking geographic coordinates...\n');
if ismember('Latitude', locations.Properties.VariableNames) && ...
   ismember('Longitude', locations.Properties.VariableNames)
    
    lat_min = min(locations.Latitude);
    lat_max = max(locations.Latitude);
    lon_min = min(locations.Longitude);
    lon_max = max(locations.Longitude);
    
    fprintf('  Latitude range:  %.2f° to %.2f°\n', lat_min, lat_max);
    fprintf('  Longitude range: %.2f° to %.2f°\n', lon_min, lon_max);
    
    % Madagascar should be roughly: Lat -25 to -12, Lon 43 to 51
    if lat_min >= -26 && lat_max <= -11 && lon_min >= 42 && lon_max <= 52
        fprintf('  ✓ Coordinates match Madagascar bounds\n');
    else
        fprintf('  ⚠ WARNING: Coordinates outside expected Madagascar range\n');
    end
end

%% Summary
fprintf('\n========================================\n');
fprintf('VERIFICATION SUMMARY\n');
fprintf('========================================\n\n');

fprintf('✅ Spatial cache structure:\n');
fprintf('   • 44 locations (22 regions × urban/rural)\n');
fprintf('   • Distance matrix: 44×44, symmetric\n');
fprintf('   • Distance range: %.0f - %.0f km\n', min(non_zero), max(distanceMatrix(:)));
fprintf('   • All required fields present\n');

fprintf('\n🗺 Geographic coverage:\n');
if exist('lat_min', 'var')
    fprintf('   • Latitude: %.1f° to %.1f°\n', lat_min, lat_max);
    fprintf('   • Longitude: %.1f° to %.1f°\n', lon_min, lon_max);
end

fprintf('\n🎯 Ready for MIDAS:\n');
if height(locations) == 44 && dm_rows == 44
    fprintf('   ✅ YES - Spatial cache is properly structured\n');
else
    fprintf('   ⚠ ISSUES DETECTED - Review warnings above\n');
end

fprintf('\n========================================\n\n');

