function [experimentData] = load_experiment_data()
% LOAD_EXPERIMENT_DATA Load and organize all experimental output files
%
% Returns:
%   experimentData - Struct array with fields:
%     .runID: Run identifier
%     .scenario: 'Control', 'Shock', 'PA', or 'PA_Shock'
%     .PA: Place attachment flag (0 or 1)
%     .Shock: Shock experiment flag (0 or 1)
%     .input: Input parameters table
%     .output: Full output structure from midasMainLoop
%     .agentSummary: Agent summary table
%     .filename: Source filename

fprintf('=== LOADING EXPERIMENT DATA ===\n\n');

% Find all output files
outputDir = '../';  % Relative to Analysis folder
files = dir(fullfile(outputDir, 'Madagascar_PA_Shock_Full_Run*.mat'));

if isempty(files)
    error('No output files found! Expected files matching: Madagascar_PA_Shock_Full_Run*.mat');
end

fprintf('Found %d output files\n', length(files));

if length(files) ~= 20
    warning('Expected 20 files, found %d', length(files));
end

% Sort files by run number
[~, sortIdx] = sort({files.name});
files = files(sortIdx);

% Initialize structure array
experimentData = struct('runID', {}, 'scenario', {}, 'PA', {}, 'Shock', {}, ...
    'input', {}, 'output', {}, 'agentSummary', {}, 'filename', {});

fprintf('\nLoading files...\n');
for i = 1:length(files)
    fprintf('  [%2d/%2d] %s...', i, length(files), files(i).name);
    
    % Load file
    fullPath = fullfile(outputDir, files(i).name);
    data = load(fullPath);
    
    % Extract PA and Shock flags from input parameters
    PA_flag = 0;
    Shock_flag = 0;
    
    if isfield(data, 'input') && istable(data.input)
        % Find PA flag
        pa_idx = find(strcmp(data.input.parameterNames, 'modelParameters.placeAttachmentFlag'));
        if ~isempty(pa_idx)
            PA_flag = data.input.parameterValues{pa_idx};
        end
        
        % Find Shock flag
        shock_idx = find(strcmp(data.input.parameterNames, 'modelParameters.shockExperiment'));
        if ~isempty(shock_idx)
            Shock_flag = data.input.parameterValues{shock_idx};
        end
        
        % Find run ID
        runid_idx = find(strcmp(data.input.parameterNames, 'modelParameters.runID'));
        if ~isempty(runid_idx)
            runID = data.input.parameterValues{runid_idx};
        else
            runID = sprintf('Run%03d', i);
        end
    else
        runID = sprintf('Run%03d', i);
    end
    
    % Determine scenario name
    if PA_flag == 0 && Shock_flag == 0
        scenario = 'Control';
    elseif PA_flag == 0 && Shock_flag == 1
        scenario = 'Shock';
    elseif PA_flag == 1 && Shock_flag == 0
        scenario = 'PA';
    elseif PA_flag == 1 && Shock_flag == 1
        scenario = 'PA_Shock';
    else
        scenario = 'Unknown';
    end
    
    % Store in structure
    experimentData(i).runID = runID;
    experimentData(i).scenario = scenario;
    experimentData(i).PA = PA_flag;
    experimentData(i).Shock = Shock_flag;
    experimentData(i).input = data.input;
    experimentData(i).output = data.output;
    
    % Extract agent summary if available
    if isfield(data.output, 'agentSummary')
        experimentData(i).agentSummary = data.output.agentSummary;
    else
        experimentData(i).agentSummary = [];
    end
    
    experimentData(i).filename = files(i).name;
    
    fprintf(' %s\n', scenario);
end

% Print summary
fprintf('\n=== DATA LOADING SUMMARY ===\n');
scenarios = {'Control', 'Shock', 'PA', 'PA_Shock'};
for s = 1:length(scenarios)
    count = sum(strcmp({experimentData.scenario}, scenarios{s}));
    fprintf('%12s: %d runs\n', scenarios{s}, count);
end

fprintf('\n✓ Data loading complete\n\n');

end

