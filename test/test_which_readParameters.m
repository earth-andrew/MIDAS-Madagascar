% test_which_readParameters.m
% Find which readParameters MATLAB will use

fprintf('\nChecking which readParameters will be called...\n\n');

% Set up paths like test_full_integration does
addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');
addpath('./Data');

% Check which readParameters
whichRead = which('readParameters');
fprintf('which(''readParameters''):\n');
fprintf('  %s\n\n', whichRead);

% Try calling it
fprintf('Attempting to call readParameters...\n');
try
    [agentParameters, modelParameters, networkParameters, mapParameters] = readParameters([]);
    fprintf('✓ readParameters executed successfully\n\n');
    
    % Check if remitAdminCosts exists
    fprintf('Checking for remitAdminCosts field:\n');
    if isfield(mapParameters, 'remitAdminCosts')
        fprintf('  ✓ remitAdminCosts EXISTS\n');
        fprintf('    Value: %s\n', mat2str(mapParameters.remitAdminCosts));
    else
        fprintf('  ✗ remitAdminCosts MISSING!\n');
        fprintf('    Available fields in mapParameters:\n');
        fields = fieldnames(mapParameters);
        for i = 1:length(fields)
            fprintf('      - %s\n', fields{i});
        end
    end
    
catch ME
    fprintf('✗ ERROR calling readParameters:\n');
    fprintf('  %s\n', ME.message);
end

fprintf('\nTest complete!\n');

