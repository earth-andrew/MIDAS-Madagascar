function [locationLikelihood, genderLikelihood, ageLikelihood, survivalRate, fertilityRate, ageDiscountRateFactor, agePointsPopulation, agePointsSurvival, agePointsFertility, agePointsPref] = buildDemography(modelParameters, locations)
%buildDemography - Madagascar-specific version using 2018 census data
%
% This override version loads population data from the simplified CSV format
% and handles the shapefile-to-census region code mapping

% Mapping between shapefile region codes and census region codes
% Shapefile uses province-district (e.g., 34 = province 3, district 4)
% Census uses administrative regions (e.g., 24 = Ihorombe)
regionCodeMapping = containers.Map(...
    {'34_R', '34_U', '35_R', '35_U', '63_R', '63_U', '64_R', '64_U'}, ...
    {'24_R', '24_U', '23_R', '23_U', '51_R', '51_U', '54_R', '54_U'});

if(~isempty(modelParameters.popFile))
    % Load population CSV - only the columns we need
    popTable = readtable(modelParameters.popFile, 'ReadVariableNames', true);
    
    % Extract just the columns we need to avoid type conflicts
    popLocationCodes = popTable.location_code;
    popPopulation = popTable.population;
    
    % Create location codes for shapefile locations
    % Extract region codes from ADM2_PCODE (e.g., MDG0101-R -> 11_R)
    if isstruct(locations)
        locStruct = locations;
        numLocs = length(locations);
    else
        locStruct = [];
        numLocs = height(locations);
    end
    
    locationCodes = cell(numLocs, 1);
    for i = 1:numLocs
        % Get ADM2_PCODE - handle both struct and table formats
        if ~isempty(locStruct)
            % Struct format
            fullcode = locStruct(i).ADM2_PCODE;
        else
            % Table format
            if iscell(locations.ADM2_PCODE)
                fullcode = locations.ADM2_PCODE{i};
            else
                fullcode = locations.ADM2_PCODE(i);
                if isnumeric(fullcode)
                    fullcode = num2str(fullcode);
                end
            end
        end
        
        % Extract region code from "MDG0101-R" format
        if length(fullcode) >= 7 && startsWith(fullcode, 'MDG')
            province = fullcode(4:5);
            region = fullcode(6:7);
            region_number = str2double(province) * 10 + str2double(region);
            
            % Get urban/rural letter
            if contains(fullcode, '-R')
                ur_letter = 'R';
            else
                ur_letter = 'U';
            end
            
            code = sprintf('%d_%s', region_number, ur_letter);
            
            % Apply mapping if needed
            if regionCodeMapping.isKey(code)
                locationCodes{i} = regionCodeMapping(code);
            else
                locationCodes{i} = code;
            end
        else
            locationCodes{i} = fullcode;
        end
    end
    
    % Match locations with population data
    populationData = zeros(numLocs, 1);
    for i = 1:numLocs
        % Find matching row in population data
        matchIdx = find(strcmp(popLocationCodes, locationCodes{i}));
        if ~isempty(matchIdx)
            populationData(i) = popPopulation(matchIdx(1));
        end
    end
    
    numMatched = sum(populationData > 0);
    
    % Calculate location likelihood (cumulative distribution)
    locationLikelihood = populationData / sum(populationData);
    locationLikelihood = cumsum(locationLikelihood);
    
    % Simple gender likelihood (50/50 male/female)
    genderLikelihood = 0.5 * ones(numLocs, 1);
    
    fprintf('   ✓ Population data loaded: %d / %d locations matched\n', numMatched, numLocs);
    if numMatched < numLocs
        fprintf('   ⚠ WARNING: %d locations missing population (will get proportional share)\n', ...
            numLocs - numMatched);
    end
else
    % No population file - use uniform distribution
    if isstruct(locations)
        numLocs = length(locations);
    else
        numLocs = height(locations);
    end
    locationLikelihood = ones(numLocs,1) / numLocs;
    locationLikelihood = cumsum(locationLikelihood);
    genderLikelihood = 0.5 * ones(numLocs, 1);
end

% Age distribution (simplified - no detailed age data in CSV)
agePointsPopulation = [0 15 30 50 100];
ageLikelihood = ones(numLocs,1) * [0 0.3 0.6 0.85 1.0];
ageLikelihood(:,:,2) = ageLikelihood;  % Same for both genders

% Survival rates (use model defaults)
agePointsSurvival = agePointsPopulation;
survivalRate = 1 - rand(numLocs,size(agePointsSurvival,2),2) / modelParameters.randDeath;

% Fertility rates (use model defaults)
agePointsFertility = agePointsPopulation;
fertilityRate = zeros(numLocs, length(agePointsFertility));
fertilityRate(:, 2:4) = rand(numLocs, 3) / modelParameters.randBirth;

% Age-based discount factor (no age preferences in CSV)
if ~isempty(modelParameters.agePreferencesFile) && exist(modelParameters.agePreferencesFile, 'file')
    try
        agePrefs = readtable(modelParameters.agePreferencesFile);
        agePointsPref = agePrefs.Age';
        ageDiscountRateFactor = agePrefs.DiscountFactor';
    catch
        % Fallback if file doesn't exist or wrong format
        agePointsPref = agePointsPopulation;
        ageDiscountRateFactor = ones(1, length(agePointsPref));
    end
else
    agePointsPref = agePointsPopulation;
    ageDiscountRateFactor = ones(1, length(agePointsPref));
end

end

