% test_admin_levels.m
% Check how many admin levels are in the Madagascar locations

fprintf('\nChecking administrative levels in Madagascar data...\n\n');

% Load cache
cacheData = load('Madagascar_44_UrbanRural_MIDAS.mat');
locations = cacheData.locations;

% Convert to table if needed
if isstruct(locations)
    locations = struct2table(locations);
end

fprintf('Locations table has %d rows (locations)\n', height(locations));
fprintf('Locations table has %d columns (variables)\n\n', width(locations));

% Find AdminUnit columns
colNames = locations.Properties.VariableNames;
adminCols = contains(colNames, 'AdminUnit');
adminColNames = colNames(adminCols);

fprintf('AdminUnit columns found:\n');
for i = 1:length(adminColNames)
    fprintf('  %d. %s\n', i, adminColNames{i});
end

numAdminLevels = length(adminColNames);
fprintf('\nTotal AdminUnit levels: %d\n', numAdminLevels);

% According to createRemittanceCosts, we need:
% numScalesSpecified = size(remitAdminCosts, 1)
% numScalesReceived = sum(AdminUnit columns) + 1
% These must match!

numScalesReceived = numAdminLevels + 1;
fprintf('Number of scales expected by createRemittanceCosts: %d\n', numScalesReceived);

fprintf('\n');
fprintf('========================================\n');
fprintf('REQUIRED FIX:\n');
fprintf('========================================\n');
fprintf('In readParameters.m, remitAdminCosts must have %d rows (one for each scale level)\n', numScalesReceived);
fprintf('Current definition (line 56) has 4 rows\n');
fprintf('Change to %d rows to match Madagascar data structure\n', numScalesReceived);
fprintf('\nSuggested fix:\n');
fprintf('mapParameters.remitAdminCosts = [');
for i = 1:numScalesReceived
    if i < numScalesReceived
        fprintf('100 0; ');
    else
        fprintf('100 0');
    end
end
fprintf('];\n');
fprintf('========================================\n');

