% test_population_integration.m
% Test population data integration with Madagascar locations

fprintf('\n========================================\n');
fprintf('TESTING POPULATION DATA INTEGRATION\n');
fprintf('========================================\n\n');

% Load locations from cache
fprintf('1. Loading locations from cache...\n');
cache = load('Madagascar_44_UrbanRural_MIDAS.mat');
locations = cache.locations;
if isstruct(locations)
    locations = struct2table(locations);
end
fprintf('   ✓ Loaded %d locations\n', height(locations));
fprintf('   Location fields: %s\n', strjoin(locations.Properties.VariableNames, ', '));

% Show sample location codes
fprintf('\n   Sample location identifiers:\n');
if ismember('cityName', locations.Properties.VariableNames)
    fprintf('     cityName examples: %s, %s, %s\n', locations.cityName{1}, locations.cityName{2}, locations.cityName{3});
end
if ismember('Name', locations.Properties.VariableNames)
    fprintf('     Name examples: %s, %s, %s\n', locations.Name{1}, locations.Name{2}, locations.Name{3});
end
if ismember('cityID', locations.Properties.VariableNames)
    fprintf('     cityID examples: %d, %d, %d\n', locations.cityID(1), locations.cityID(2), locations.cityID(3));
end

% Load population CSV
fprintf('\n2. Loading population CSV...\n');
popCSV = readtable('./Data/madagascar_population_census2018.csv');
fprintf('   ✓ Loaded %d population records\n', height(popCSV));
fprintf('   CSV fields: %s\n', strjoin(popCSV.Properties.VariableNames, ', '));
fprintf('   Sample location_code: %s, %s, %s\n', popCSV.location_code{1}, popCSV.location_code{2}, popCSV.location_code{3});

% Try to match locations
fprintf('\n3. Creating composite location codes from ADM2_PCODE + URBAN_RURAL...\n');

% Create composite key by extracting region code from ADM2_PCODE
% ADM2_PCODE format: "MDG0101-R" means province 01, region 01, Rural
% We need to convert to CSV format: "11_R"
locations.location_code = cell(height(locations), 1);
for i = 1:height(locations)
    % Get ADM2_PCODE as string
    if isnumeric(locations.ADM2_PCODE(i))
        fullcode = num2str(locations.ADM2_PCODE(i));
    else
        fullcode = locations.ADM2_PCODE{i};
    end
    
    % Extract province and region from "MDG0101-R" format
    % Characters 4-5 are province (01), characters 6-7 are region (01)
    if length(fullcode) >= 7 && startsWith(fullcode, 'MDG')
        province = fullcode(4:5);  % '01'
        region = fullcode(6:7);    % '01'
        region_code = strcat(province, region);  % '0101' -> but we want '11'
        
        % Remove leading zeros: '0101' -> '11'
        region_number = str2double(province) * 10 + str2double(region);
        region_code = num2str(region_number);
        
        % Get urban/rural suffix from the ADM2_PCODE itself
        if contains(fullcode, '-R')
            urban_rural_letter = 'R';
        elseif contains(fullcode, '-U')
            urban_rural_letter = 'U';
        else
            % Fallback to URBAN_RURAL field
            urban_rural_letter = upper(locations.URBAN_RURAL{i}(1));
        end
        
        locations.location_code{i} = sprintf('%s_%s', region_code, urban_rural_letter);
    else
        % Fallback for unexpected format
        fprintf('   WARNING: Unexpected ADM2_PCODE format: %s\n', fullcode);
        locations.location_code{i} = fullcode;
    end
end

fprintf('   Created location codes. Examples:\n');
% Handle display of ADM2_PCODE
if iscell(locations.ADM2_PCODE)
    pcode1 = locations.ADM2_PCODE{1};
    pcode2 = locations.ADM2_PCODE{2};
else
    pcode1 = num2str(locations.ADM2_PCODE(1));
    pcode2 = num2str(locations.ADM2_PCODE(2));
end
fprintf('     %s ← from ADM2_PCODE=%s\n', locations.location_code{1}, pcode1);
fprintf('     %s ← from ADM2_PCODE=%s\n', locations.location_code{2}, pcode2);

% Now match with CSV
matched = sum(ismember(locations.location_code, popCSV.location_code));
fprintf('\n4. Matching location codes with population CSV...\n');
fprintf('   Matched: %d / %d locations\n', matched, height(locations));

if matched == height(locations)
    fprintf('   ✓ SUCCESS: All locations matched!\n');
    
    % Join tables
    joinedTable = join(locations, popCSV, 'LeftKeys', 'location_code', 'RightKeys', 'location_code');
    fprintf('\n5. Population distribution:\n');
    fprintf('     Total population: %d\n', sum(joinedTable.population));
    fprintf('     Urban population: %d (%.1f%%)\n', ...
        sum(joinedTable.population(joinedTable.is_urban == 1)), ...
        100*sum(joinedTable.population(joinedTable.is_urban == 1))/sum(joinedTable.population));
    fprintf('     Rural population: %d (%.1f%%)\n', ...
        sum(joinedTable.population(joinedTable.is_urban == 0)), ...
        100*sum(joinedTable.population(joinedTable.is_urban == 0))/sum(joinedTable.population));
    
    % Show how agents would be distributed
    fprintf('\n6. Agent distribution (with 100 agents):\n');
    locationLikelihood = joinedTable.population / sum(joinedTable.population);
    expectedAgents = locationLikelihood * 100;
    fprintf('     Min expected agents per location: %.1f\n', min(expectedAgents));
    fprintf('     Max expected agents per location: %.1f\n', max(expectedAgents));
    fprintf('     Mean expected agents: %.1f\n', mean(expectedAgents));
    fprintf('     Locations with <1 expected agent: %d / %d\n', ...
        sum(expectedAgents < 1), height(joinedTable));
    
    % Show top 5 locations by population
    [~, sortIdx] = sort(joinedTable.population, 'descend');
    fprintf('\n7. Top 5 locations by population:\n');
    for i = 1:5
        idx = sortIdx(i);
        fprintf('     %s: %d people (%.1f agents expected)\n', ...
            joinedTable.location_code{idx}, joinedTable.population(idx), expectedAgents(idx));
    end
else
    fprintf('   ✗ FAILED: Not all locations matched\n');
    fprintf('\n   Missing locations (in shapefile but not in CSV):\n');
    missingIdx = find(~ismember(locations.location_code, popCSV.location_code));
    for i = 1:length(missingIdx)
        idx = missingIdx(i);
        if iscell(locations.ADM2_PCODE)
            adm2 = locations.ADM2_PCODE{idx};
        else
            adm2 = num2str(locations.ADM2_PCODE(idx));
        end
        fprintf('     %s (ADM2_PCODE=%s, NAME_2=%s)\n', ...
            locations.location_code{idx}, adm2, locations.NAME_2{idx});
    end
    
    % Show what regions ARE in the CSV
    fprintf('\n   Regions in CSV (for comparison):\n');
    uniqueRegions = unique(popCSV.region_code);
    fprintf('     ');
    for i = 1:length(uniqueRegions)
        fprintf('%d ', uniqueRegions(i));
    end
    fprintf('\n');
end

fprintf('\n========================================\n');
fprintf('INTEGRATION TEST COMPLETE\n');
fprintf('========================================\n');

