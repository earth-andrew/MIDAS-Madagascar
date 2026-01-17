% test_readParameters.m
% Quick test to verify readParameters works correctly

fprintf('Testing readParameters...\n\n');

% Call readParameters
[agentParameters, modelParameters, networkParameters, mapParameters] = readParameters([]);

fprintf('✓ readParameters executed\n\n');

% Check for required fields
fprintf('Checking mapParameters fields:\n');

requiredFields = {'filePath', 'movingCostPerMile', 'minDistForCost', 'maxDistForCost', ...
                  'movingAdminCosts', 'remitAdminCosts'};

for i = 1:length(requiredFields)
    field = requiredFields{i};
    if isfield(mapParameters, field)
        fprintf('  ✓ %s present\n', field);
        if strcmp(field, 'remitAdminCosts')
            fprintf('    Value: %s\n', mat2str(mapParameters.remitAdminCosts));
        end
    else
        fprintf('  ✗ %s MISSING!\n', field);
    end
end

fprintf('\nAll mapParameters fields:\n');
disp(fieldnames(mapParameters));

fprintf('\nTest complete!\n');

