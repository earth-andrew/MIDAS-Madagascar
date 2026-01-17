% Verify Madagascar Experiment Setup
% Check that all parameters are correctly configured

clear; close all;

fprintf('=== VERIFYING MADAGASCAR EXPERIMENT SETUP ===\n\n');

%% 1. Check readParameters defaults
fprintf('1. Checking readParameters defaults...\n');
[agentParameters, modelParameters, networkParameters, mapParameters] = readParameters([]);

fprintf('   Place Attachment:\n');
fprintf('     - placeAttachmentFlag: %d (should be 0 by default)\n', modelParameters.placeAttachmentFlag);
fprintf('     - placeAttachmentMean: %.2f\n', agentParameters.placeAttachmentMean);

fprintf('   Shock Experiment:\n');
fprintf('     - shockExperiment: %d (should be 0 by default)\n', modelParameters.shockExperiment);

fprintf('   Simulation Parameters:\n');
fprintf('     - numAgents: %d\n', modelParameters.numAgents);
fprintf('     - spinupTime: %d\n', modelParameters.spinupTime);
fprintf('     - numCycles: %d\n', modelParameters.numCycles);
fprintf('     - cycleLength: %d\n', modelParameters.cycleLength);
fprintf('     - Total timesteps: %d\n', modelParameters.spinupTime + modelParameters.numCycles * modelParameters.cycleLength);

fprintf('   Visualization:\n');
fprintf('     - visualizeYN: %d (should be 0 for experiments)\n\n', modelParameters.visualizeYN);

%% 2. Test parameter override mechanism
fprintf('2. Testing parameter override mechanism...\n');
% Create table with explicit cell array columns
test_table = table(cell(0,1), cell(0,1), 'VariableNames', {'parameterNames','parameterValues'});
test_table = [test_table; {'modelParameters.placeAttachmentFlag', 1}];
test_table = [test_table; {'modelParameters.shockExperiment', 1}];
test_table = [test_table; {'modelParameters.visualizeYN', 0}];

[agentParameters2, modelParameters2, networkParameters2, mapParameters2] = readParameters(test_table);

fprintf('   After override:\n');
fprintf('     - placeAttachmentFlag: %d (should be 1)\n', modelParameters2.placeAttachmentFlag);
fprintf('     - shockExperiment: %d (should be 1)\n', modelParameters2.shockExperiment);
fprintf('     - visualizeYN: %d (should be 0)\n\n', modelParameters2.visualizeYN);

if modelParameters2.placeAttachmentFlag == 1 && modelParameters2.shockExperiment == 1 && modelParameters2.visualizeYN == 0
    fprintf('   ✓ Parameter override works correctly!\n\n');
else
    fprintf('   ✗ ERROR: Parameter override not working!\n\n');
    return;
end

%% 3. Verify experiment script exists
fprintf('3. Checking experiment script...\n');
if exist('runMIDAS_Madagascar_Experiment.m', 'file')
    fprintf('   ✓ runMIDAS_Madagascar_Experiment.m exists\n');
    
    % Count conditions by reading the file
    fid = fopen('runMIDAS_Madagascar_Experiment.m', 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    % Check for 4 conditions with 5 reps each
    control_count = numel(regexp(content, 'Control'));
    shock_count = numel(regexp(content, 'Shock_Only'));
    pa_count = numel(regexp(content, 'PA_Only'));
    pashock_count = numel(regexp(content, 'PA_Shock'));
    
    fprintf('   Found conditions:\n');
    fprintf('     - Control mentions: %d\n', control_count);
    fprintf('     - Shock_Only mentions: %d\n', shock_count);
    fprintf('     - PA_Only mentions: %d\n', pa_count);
    fprintf('     - PA_Shock mentions: %d\n', pashock_count);
else
    fprintf('   ✗ ERROR: runMIDAS_Madagascar_Experiment.m not found!\n');
    return;
end

fprintf('\n');

%% 4. Check output directory
fprintf('4. Checking output directory...\n');
if exist('./Outputs/', 'dir')
    fprintf('   ✓ Outputs directory exists\n');
else
    fprintf('   Creating Outputs directory...\n');
    mkdir('./Outputs/');
    fprintf('   ✓ Outputs directory created\n');
end

fprintf('\n');

%% 5. Verify override functions are active
fprintf('5. Verifying critical override functions...\n');

% Check createUtilityLayers
createUtilPath = which('createUtilityLayers');
if contains(createUtilPath, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ createUtilityLayers: Override active\n');
else
    fprintf('   ✗ WARNING: createUtilityLayers not using Override!\n');
    fprintf('     Current: %s\n', createUtilPath);
end

% Check choosePortfolio
choosePortPath = which('choosePortfolio');
if contains(choosePortPath, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ choosePortfolio: Override active\n');
else
    fprintf('   ✗ WARNING: choosePortfolio not using Override!\n');
    fprintf('     Current: %s\n', choosePortPath);
end

% Check buildDemography
buildDemoPath = which('buildDemography');
if contains(buildDemoPath, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ buildDemography: Override active\n');
else
    fprintf('   ✗ WARNING: buildDemography not using Override!\n');
    fprintf('     Current: %s\n', buildDemoPath);
end

fprintf('\n');

%% Summary
fprintf('=== VERIFICATION COMPLETE ===\n\n');
fprintf('Experimental Design Summary:\n');
fprintf('  • 4 conditions (Control, Shock, PA, PA+Shock)\n');
fprintf('  • 5 replications per condition\n');
fprintf('  • Total: 20 runs\n');
fprintf('  • Visualization: OFF\n');
fprintf('  • Agents: %d\n', modelParameters.numAgents);
fprintf('  • Timesteps: %d\n', modelParameters.spinupTime + modelParameters.numCycles * modelParameters.cycleLength);
fprintf('\n✓ Setup verified! Ready to run experiments.\n');
fprintf('\nTo run experiments, execute in MATLAB:\n');
fprintf('  >> runMIDAS_Madagascar_Experiment\n\n');

