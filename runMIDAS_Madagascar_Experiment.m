function runMIDAS_Madagascar_Experiment()
% Madagascar Enhanced Factorial Experiment: Place Attachment × Drought Shocks
% 6-condition factorial design with configurable replications
%
% Conditions:
%   1. Baseline: No shock, PA off
%   2. Baseline + PA: No shock, PA on
%   3. Shock Urban+Rural: Shock (both urban and rural in south), PA off
%   4. Shock Urban+Rural + PA: Shock (both urban and rural in south), PA on
%   5. Shock Rural Only: Shock (only rural areas in south), PA off
%   6. Shock Rural Only + PA: Shock (only rural areas in south), PA on

clear functions
clear classes

% Ensure proper path order and refresh cache
addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');
addpath('./Data');
rehash path;

rng('shuffle');

% ===== EXPERIMENT CONFIGURATION =====
NUM_AGENTS = 300;           % Number of agents
SPINUP_TIME = 5;            % Spinup timesteps (reduced to maximize cycles)
NUM_CYCLES = 8;             % Simulation length (cycles) - MAX with spinup=2: 9 cycles
NUM_REPLICATIONS = 1;        % Replications per condition
SHOCK_START = 12;            % Shock start timestep
SHOCK_DURATION = 12;          % Shock duration (timesteps)
SHOCK_SEVERITY = 0.15;       % Shock severity (0.15 = 85% reduction)
% ====================================
% NOTE: Available utility data has 40 timesteps
% Maximum cycles calculation: floor((40 - SPINUP_TIME) / 4)
% - With spinup=0: 10 cycles max (40 timesteps total)
% - With spinup=2: 9 cycles max (2 + 36 = 38 timesteps)
% - With spinup=5: 8 cycles max (5 + 32 = 37 timesteps)
% - With spinup=10: 7 cycles max (10 + 28 = 38 timesteps)
% ====================================

series = 'Madagascar_test_sweep_';
saveDirectory = './Outputs/';

% Create output directory if it doesn't exist
if ~exist(saveDirectory, 'dir')
    mkdir(saveDirectory);
end

fprintf('\n=== MADAGASCAR ENHANCED FACTORIAL EXPERIMENT ===\n');
fprintf('Design: 6 conditions (Baseline, Baseline+PA, Shock UR, Shock UR+PA, Shock R, Shock R+PA)\n');
fprintf('Configuration:\n');
fprintf('  Agents: %d\n', NUM_AGENTS);
fprintf('  Spinup: %d timesteps\n', SPINUP_TIME);
fprintf('  Cycles: %d (timesteps: %d)\n', NUM_CYCLES, NUM_CYCLES * 4);
fprintf('  Total timesteps: %d (spinup + cycles)\n', SPINUP_TIME + NUM_CYCLES * 4);
fprintf('  Replications: %d per condition\n', NUM_REPLICATIONS);
fprintf('  Shock: Start=%d, Duration=%d, Severity=%.0f%% reduction\n', ...
    SHOCK_START, SHOCK_DURATION, (1-SHOCK_SEVERITY)*100);
fprintf('Total runs: %d\n\n', 6 * NUM_REPLICATIONS);

experimentList = {};
% Create empty table with explicit cell array columns
experiment_table = table(cell(0,1), cell(0,1), 'VariableNames', {'parameterNames','parameterValues'});

%% Condition 1: Baseline (PA off, Shock off)
fprintf('Building experiments for Condition 1: Baseline (PA off, Shock off)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Baseline'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Baseline_Rep%d', indexI)}];
    
    % PA and Shock both OFF
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 0}];
    experiment = [experiment;{'modelParameters.shockExperiment', 0}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Condition 2: Baseline + PA (PA on, Shock off)
fprintf('Building experiments for Condition 2: Baseline + PA (PA on, Shock off)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Baseline_PA'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Baseline_PA_Rep%d', indexI)}];
    
    % PA ON, Shock OFF
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 1}];
    experiment = [experiment;{'modelParameters.shockExperiment', 0}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Condition 3: Shock Urban+Rural (PA off, Shock on - both urban and rural)
fprintf('Building experiments for Condition 3: Shock Urban+Rural (PA off, Shock on - both urban and rural)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Shock_UR'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Shock_UR_Rep%d', indexI)}];
    
    % PA OFF, Shock ON (both urban and rural in south)
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 0}];
    experiment = [experiment;{'modelParameters.shockExperiment', 1}];
    experiment = [experiment;{'modelParameters.shockLocation', 1}];  % 1 = both urban and rural
    
    % Shock timing and severity
    experiment = [experiment;{'modelParameters.shockStart', SHOCK_START}];
    experiment = [experiment;{'modelParameters.shockEnd', SHOCK_START + SHOCK_DURATION - 1}];
    experiment = [experiment;{'modelParameters.shockSeverity', SHOCK_SEVERITY}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Condition 4: Shock Urban+Rural + PA (PA on, Shock on - both urban and rural)
fprintf('Building experiments for Condition 4: Shock Urban+Rural + PA (PA on, Shock on - both urban and rural)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Shock_UR_PA'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Shock_UR_PA_Rep%d', indexI)}];
    
    % PA ON, Shock ON (both urban and rural in south)
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 1}];
    experiment = [experiment;{'modelParameters.shockExperiment', 1}];
    experiment = [experiment;{'modelParameters.shockLocation', 1}];  % 1 = both urban and rural
    
    % Shock timing and severity
    experiment = [experiment;{'modelParameters.shockStart', SHOCK_START}];
    experiment = [experiment;{'modelParameters.shockEnd', SHOCK_START + SHOCK_DURATION - 1}];
    experiment = [experiment;{'modelParameters.shockSeverity', SHOCK_SEVERITY}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Condition 5: Shock Rural Only (PA off, Shock on - only rural areas)
fprintf('Building experiments for Condition 5: Shock Rural Only (PA off, Shock on - only rural areas)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Shock_R'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Shock_R_Rep%d', indexI)}];
    
    % PA OFF, Shock ON (only rural areas in south)
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 0}];
    experiment = [experiment;{'modelParameters.shockExperiment', 1}];
    experiment = [experiment;{'modelParameters.shockLocation', 2}];  % 2 = rural only
    
    % Shock timing and severity
    experiment = [experiment;{'modelParameters.shockStart', SHOCK_START}];
    experiment = [experiment;{'modelParameters.shockEnd', SHOCK_START + SHOCK_DURATION - 1}];
    experiment = [experiment;{'modelParameters.shockSeverity', SHOCK_SEVERITY}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Condition 6: Shock Rural Only + PA (PA on, Shock on - only rural areas)
fprintf('Building experiments for Condition 6: Shock Rural Only + PA (PA on, Shock on - only rural areas)...\n');
for indexI = 1:NUM_REPLICATIONS
    experiment = experiment_table;
    
    experiment = [experiment;{'modelParameters.shortName',  'Shock_R_PA'}];
    experiment = [experiment;{'modelParameters.runID',  sprintf('Shock_R_PA_Rep%d', indexI)}];
    
    % PA ON, Shock ON (only rural areas in south)
    experiment = [experiment;{'modelParameters.placeAttachmentFlag', 1}];
    experiment = [experiment;{'modelParameters.shockExperiment', 1}];
    experiment = [experiment;{'modelParameters.shockLocation', 2}];  % 2 = rural only
    
    % Shock timing and severity
    experiment = [experiment;{'modelParameters.shockStart', SHOCK_START}];
    experiment = [experiment;{'modelParameters.shockEnd', SHOCK_START + SHOCK_DURATION - 1}];
    experiment = [experiment;{'modelParameters.shockSeverity', SHOCK_SEVERITY}];
    
    % Configurable parameters
    experiment = [experiment;{'modelParameters.numAgents', NUM_AGENTS}];
    experiment = [experiment;{'modelParameters.spinupTime', SPINUP_TIME}];
    experiment = [experiment;{'modelParameters.numCycles', NUM_CYCLES}];
    
    % Visualization OFF
    experiment = [experiment;{'modelParameters.visualizeYN', 0}];
    
    experimentList{end+1} = experiment;
end

%% Save experiment design
fprintf('\nSaving experiment design to file...\n');
experimentDesignFile = [saveDirectory 'Madagascar_Experiment_' datestr(now, 'yyyy-mm-dd_HH-MM-SS') '_design.mat'];
save(experimentDesignFile, 'experimentList');
fprintf('Experiment design saved to: %s\n', experimentDesignFile);

%% Run all experiments
fprintf('\n=== STARTING EXPERIMENTAL RUNS ===\n');
fprintf('Total experiments to run: %d\n\n', length(experimentList));

runList = zeros(length(experimentList), 1);
startTime = now;

for indexI = 1:length(experimentList)
    if runList(indexI) == 0
        fprintf('--- Run %d of %d ---\n', indexI, length(experimentList));
        
        input = experimentList{indexI};
        
        % Display current condition
        conditionName = input.parameterValues{strcmp(input.parameterNames, 'modelParameters.shortName')};
        runID = input.parameterValues{strcmp(input.parameterNames, 'modelParameters.runID')};
        fprintf('Condition: %s (ID: %s)\n', conditionName, runID);
        
        % Run MIDAS with current parameters
        runStartTime = now;
        try
            output = midasMainLoop(input, sprintf('Madagascar Experiment %d: %s', indexI, runID));
            
            % Store metadata
            functionVersions = inmem('-completenames');
            functionVersions = functionVersions(strmatch(pwd, functionVersions));
            output.codeUsed = functionVersions;
            output.runTimestamp = datestr(now);
            output.runDuration_minutes = (now - runStartTime) * 24 * 60;
            
            % Store modelParameters in output for scenario detection
            [~, modelParameters, ~, ~] = readParameters(input);
            output.modelParameters = modelParameters;
            
            % Save output
            currentFile = sprintf('%s%sRun%03d_%s.mat', saveDirectory, series, indexI, datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
            currentFile = strrep(currentFile, ':', '-');
            currentFile = strrep(currentFile, ' ', '_');
            
            saveToFile(input, output, currentFile);
            
            fprintf('✓ Completed successfully in %.1f minutes\n', output.runDuration_minutes);
            fprintf('  Saved to: %s\n\n', currentFile);
            
            runList(indexI) = 1;
        catch ME
            fprintf('✗ ERROR in run %d: %s\n', indexI, ME.message);
            fprintf('  Stack trace:\n');
            for j = 1:min(3, length(ME.stack))
                fprintf('    %s (line %d)\n', ME.stack(j).name, ME.stack(j).line);
            end
            fprintf('\n');
            
            % Save error information
            errorFile = sprintf('%sERROR_Run%03d_%s.mat', saveDirectory, indexI, datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
            errorFile = strrep(errorFile, ':', '-');
            errorFile = strrep(errorFile, ' ', '_');
            save(errorFile, 'input', 'ME');
        end
    end
end

%% Summary
elapsedTime = (now - startTime) * 24 * 60;
successfulRuns = sum(runList);

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total time: %.1f minutes (%.1f hours)\n', elapsedTime, elapsedTime/60);
fprintf('Successful runs: %d / %d\n', successfulRuns, length(experimentList));
fprintf('Results saved to: %s\n', saveDirectory);

if successfulRuns == length(experimentList)
    fprintf('\n✓ ALL RUNS COMPLETED SUCCESSFULLY!\n');
else
    fprintf('\n⚠ Warning: %d runs failed. Check error files in output directory.\n', ...
        length(experimentList) - successfulRuns);
end

end

%% Helper function to save files
function saveToFile(input, output, filename)
    save(filename, 'input', 'output', '-v7.3');
end

