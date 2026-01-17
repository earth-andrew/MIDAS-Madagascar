% TEST_JSON_EXPORT Test JSON export functionality
%
% This script tests the export_for_python.m function by:
% 1. Finding a MIDAS output file
% 2. Exporting it to JSON
% 3. Verifying the JSON structure
% 4. Displaying summary statistics

fprintf('\n=== Testing JSON Export ===\n\n');

%% Find a test file
test_files = dir('Outputs/*Run001*.mat');

% Filter out design files
test_files = test_files(~contains({test_files.name}, 'design'));
test_files = test_files(~contains({test_files.name}, 'python'));
test_files = test_files(~contains({test_files.name}, '.json'));

if isempty(test_files)
    error('No test files found in Outputs/ directory');
end

% Use first file
test_file = fullfile(test_files(1).folder, test_files(1).name);
[~, name, ~] = fileparts(test_file);
json_file = fullfile(test_files(1).folder, [name '.json']);

fprintf('Test file: %s\n\n', test_files(1).name);

%% Export to JSON
fprintf('Step 1: Exporting to JSON...\n');
fprintf('────────────────────────────────────────\n');
export_for_python(test_file, json_file);

%% Verify JSON structure
fprintf('\n\nStep 2: Verifying JSON structure...\n');
fprintf('────────────────────────────────────────\n');

try
    % Read JSON file
    json_text = fileread(json_file);
    data = jsondecode(json_text);
    
    % Check required fields
    fprintf('✓ JSON file readable\n');
    
    if isfield(data, 'agents')
        fprintf('✓ agents field present (%d agents)\n', length(data.agents));
    else
        error('Missing agents field');
    end
    
    if isfield(data, 'locations')
        fprintf('✓ locations field present (%d locations)\n', length(data.locations));
    else
        error('Missing locations field');
    end
    
    if isfield(data, 'meta')
        fprintf('✓ meta field present\n');
        fprintf('  - num_agents: %d\n', data.meta.num_agents);
        fprintf('  - num_timesteps: %d\n', data.meta.num_timesteps);
        fprintf('  - num_locations: %d\n', data.meta.num_locations);
        fprintf('  - scenario: %s\n', data.meta.scenario);
    else
        error('Missing meta field');
    end
    
    % Check agent structure
    fprintf('\n✓ Agent structure:\n');
    agent1 = data.agents{1};
    fprintf('  - Agent ID: %d\n', agent1.id);
    fprintf('  - Move history length: %d\n', length(agent1.moveHistory));
    
    if ~isempty(agent1.moveHistory)
        first_move = agent1.moveHistory{1};
        fprintf('  - First move: [t=%d, loc=%d, lon=%.2f, lat=%.2f]\n', ...
            first_move(1), first_move(2), first_move(3), first_move(4));
    end
    
    % Check location structure
    fprintf('\n✓ Location structure:\n');
    loc1 = data.locations{1};
    fprintf('  - Location ID: %d\n', loc1.location_id);
    fprintf('  - Longitude: %.4f\n', loc1.Longitude);
    fprintf('  - Latitude: %.4f\n', loc1.Latitude);
    fprintf('  - ADM2_PCODE: %s\n', loc1.ADM2_PCODE);
    
    % File size
    file_info = dir(json_file);
    fprintf('\n✓ JSON file size: %.2f MB\n', file_info.bytes / (1024 * 1024));
    
    fprintf('\n════════════════════════════════════════\n');
    fprintf('✓ All tests passed!\n');
    fprintf('════════════════════════════════════════\n\n');
    
    fprintf('JSON file ready for Python:\n');
    fprintf('  %s\n\n', json_file);
    
    fprintf('Test in Python with:\n');
    fprintf('  cd python_viz\n');
    fprintf('  python run_visualization.py test --output ../%s\n\n', json_file);
    
catch ME
    fprintf('\n✗ ERROR verifying JSON:\n');
    fprintf('  %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

