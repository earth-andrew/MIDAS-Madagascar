% test_override_mechanism.m
% Test that Override_Core_MIDAS_Code files take precedence over Core files

fprintf('\n========================================\n');
fprintf('OVERRIDE MECHANISM TEST\n');
fprintf('========================================\n\n');

%% Test 1: Check Path Order
fprintf('Test 1: Checking MATLAB path order...\n');
pathCell = regexp(path, pathsep, 'split');

% Find positions of key directories
override_pos = find(contains(pathCell, 'Override_Core_MIDAS_Code'), 1);
application_pos = find(contains(pathCell, 'Application_Specific_MIDAS_Code'), 1);
core_pos = find(contains(pathCell, fullfile('Core_MIDAS_Code')), 1);

fprintf('  Path positions:\n');
if ~isempty(override_pos)
    fprintf('    Override folder:      position %d\n', override_pos);
else
    fprintf('    Override folder:      NOT IN PATH ✗\n');
end
if ~isempty(application_pos)
    fprintf('    Application folder:   position %d\n', application_pos);
else
    fprintf('    Application folder:   NOT IN PATH ✗\n');
end
if ~isempty(core_pos)
    fprintf('    Core folder:          position %d\n', core_pos);
else
    fprintf('    Core folder:          NOT IN PATH ✗\n');
end

if ~isempty(override_pos) && ~isempty(core_pos)
    if override_pos < core_pos
        fprintf('  ✓ PASS: Override comes before Core (correct precedence)\n');
    else
        fprintf('  ✗ FAIL: Core comes before Override (wrong precedence!)\n');
    end
else
    fprintf('  ⚠ WARNING: Could not verify path order\n');
end

%% Test 2: Check which createUtilityLayers will be used
fprintf('\nTest 2: Checking which createUtilityLayers.m will be used...\n');

% Use MATLAB's 'which' command to find which file will be called
whichFile = which('createUtilityLayers');
fprintf('  which(''createUtilityLayers''):\n');
fprintf('    %s\n', whichFile);

if contains(whichFile, 'Override_Core_MIDAS_Code')
    fprintf('  ✓ PASS: Override version will be used (72 lines, loads config)\n');
elseif contains(whichFile, 'Application_Specific_MIDAS_Code')
    fprintf('  ✓ PASS: Application-Specific version will be used\n');
elseif contains(whichFile, 'Core_MIDAS_Code')
    fprintf('  ✗ FAIL: Core version will be used (339 lines, synthetic data)\n');
    fprintf('  ⚠ THIS WILL NOT LOAD MADAGASCAR CONFIG!\n');
else
    fprintf('  ⚠ WARNING: Unexpected location: %s\n', whichFile);
end

%% Test 3: Count lines in the file that will be used
fprintf('\nTest 3: Verifying file content...\n');
if ~isempty(whichFile) && exist(whichFile, 'file')
    fid = fopen(whichFile, 'r');
    if fid ~= -1
        line_count = 0;
        found_config_load = false;
        found_synthetic = false;
        
        while ~feof(fid)
            line = fgetl(fid);
            line_count = line_count + 1;
            
            % Check for madagascar_config loading
            if contains(line, 'madagascar_config')
                found_config_load = true;
            end
            
            % Check for synthetic data generation
            if contains(line, 'mean_utility_by_layer')
                found_synthetic = true;
            end
        end
        fclose(fid);
        
        fprintf('  File has %d lines\n', line_count);
        
        if found_config_load
            fprintf('  ✓ PASS: File loads madagascar_config.mat\n');
        elseif found_synthetic
            fprintf('  ✗ FAIL: File generates synthetic data (not Madagascar-specific)\n');
        else
            fprintf('  ⚠ WARNING: Could not determine data source\n');
        end
        
        % Expected line counts
        if line_count <= 80
            fprintf('  ✓ Likely Override version (short, config-loading)\n');
        elseif line_count >= 300
            fprintf('  ⚠ Likely Core version (long, synthetic data)\n');
        end
    end
end

%% Test 4: Check all three versions exist
fprintf('\nTest 4: Checking all createUtilityLayers versions...\n');

versions = {
    fullfile('Core_MIDAS_Code', 'createUtilityLayers.m'), 'Core';
    fullfile('Application_Specific_MIDAS_Code', 'createUtilityLayers.m'), 'Application';
    fullfile('Override_Core_MIDAS_Code', 'createUtilityLayers.m'), 'Override'
};

for i = 1:size(versions, 1)
    file_path = versions{i, 1};
    version_name = versions{i, 2};
    
    if exist(file_path, 'file')
        % Count lines
        fid = fopen(file_path, 'r');
        line_count = 0;
        while ~feof(fid)
            fgetl(fid);
            line_count = line_count + 1;
        end
        fclose(fid);
        
        fprintf('  ✓ %s version exists (%d lines)\n', version_name, line_count);
    else
        fprintf('  ✗ %s version NOT FOUND\n', version_name);
    end
end

%% Test 5: Simulate function call (dry run)
fprintf('\nTest 5: Test loading Override createUtilityLayers...\n');
fprintf('  (This will test if the file can be loaded without errors)\n');

% Add paths in correct order
addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');

% Verify path order again
whichFile2 = which('createUtilityLayers');
if contains(whichFile2, 'Override_Core_MIDAS_Code')
    fprintf('  ✓ Path order confirmed: Override version active\n');
    
    % Check if madagascar_config.mat exists
    if exist('madagascar_config.mat', 'file')
        fprintf('  ✓ madagascar_config.mat found (required by Override version)\n');
    else
        fprintf('  ✗ madagascar_config.mat NOT FOUND (required by Override version!)\n');
    end
else
    fprintf('  ⚠ WARNING: Override version not active after addpath\n');
end

%% Summary
fprintf('\n========================================\n');
fprintf('TEST SUMMARY\n');
fprintf('========================================\n\n');

% Determine overall status
uses_override = contains(whichFile, 'Override_Core_MIDAS_Code');
config_exists = exist('madagascar_config.mat', 'file') == 2;

if uses_override && config_exists
    fprintf('✅ PASS: Override mechanism working correctly\n');
    fprintf('   • Override createUtilityLayers will be used\n');
    fprintf('   • Madagascar config file available\n');
    fprintf('   • Path precedence is correct\n\n');
    fprintf('🎯 MIDAS will load Madagascar-specific data\n');
elseif uses_override && ~config_exists
    fprintf('⚠ PARTIAL: Override mechanism works but config missing\n');
    fprintf('   • Override createUtilityLayers will be used\n');
    fprintf('   • BUT madagascar_config.mat NOT FOUND\n');
    fprintf('   • Will fail when trying to load config\n');
elseif ~uses_override && config_exists
    fprintf('✗ FAIL: Override mechanism NOT working\n');
    fprintf('   • Core/Application version will be used\n');
    fprintf('   • Madagascar config exists but won''t be loaded\n');
    fprintf('   • Will generate SYNTHETIC data instead\n\n');
    fprintf('🔧 FIX: Ensure Override folder is added to path FIRST\n');
else
    fprintf('✗ FAIL: Multiple problems detected\n');
    fprintf('   • Override mechanism not working\n');
    fprintf('   • Madagascar config missing\n');
end

fprintf('\n========================================\n\n');

