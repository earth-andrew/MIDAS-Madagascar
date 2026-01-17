% verify_override_active.m - Comprehensive verification of Override files

fprintf('\n========================================\n');
fprintf('VERIFYING OVERRIDE FILES ARE ACTIVE\n');
fprintf('========================================\n\n');

% Clear everything first
clear all;
close all;
clear functions;
rehash path;

% Add paths in correct order
addpath('./Override_Core_MIDAS_Code');
addpath('./Application_Specific_MIDAS_Code');
addpath('./Core_MIDAS_Code');
addpath('./Data');

fprintf('1. Checking choosePortfolio.m:\n');
choosePortfolio_path = which('choosePortfolio');
fprintf('   Located at: %s\n', choosePortfolio_path);
if contains(choosePortfolio_path, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ CORRECT: Using Override version\n');
    % Verify it has the fix
    fid = fopen(choosePortfolio_path, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    if contains(content, 'Madagascar fix: Handle empty access codes')
        fprintf('   ✓ VERIFIED: Contains Madagascar fix\n');
    else
        fprintf('   ✗ ERROR: Override file missing Madagascar fix!\n');
    end
else
    fprintf('   ✗ ERROR: Using Core version instead of Override!\n');
    fprintf('   FIX: Delete Override version or check path order\n');
end

fprintf('\n1b. Checking visualizeMap.m:\n');
visualizeMap_path = which('visualizeMap');
fprintf('   Located at: %s\n', visualizeMap_path);
if contains(visualizeMap_path, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ CORRECT: Using Override version\n');
    % Verify it has Madagascar enhancements
    fid = fopen(visualizeMap_path, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    if contains(content, 'Madagascar enhanced version')
        fprintf('   ✓ VERIFIED: Contains Madagascar visualization enhancements\n');
    else
        fprintf('   ⚠ WARNING: Override exists but missing enhancements marker\n');
    end
else
    fprintf('   ⚠ INFO: Using Core version (OK if no visualization issues)\n');
end

fprintf('\n2. Checking createUtilityLayers.m:\n');
createUtilityLayers_path = which('createUtilityLayers');
fprintf('   Located at: %s\n', createUtilityLayers_path);
if contains(createUtilityLayers_path, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ CORRECT: Using Override version\n');
else
    fprintf('   ⚠ WARNING: Not using Override (this may be OK)\n');
end

fprintf('\n3. Checking buildDemography.m:\n');
buildDemography_path = which('buildDemography');
fprintf('   Located at: %s\n', buildDemography_path);
if contains(buildDemography_path, 'Override_Core_MIDAS_Code')
    fprintf('   ✓ CORRECT: Using Override version\n');
else
    fprintf('   ⚠ WARNING: Not using Override\n');
end

fprintf('\n4. Checking readParameters.m:\n');
readParameters_path = which('readParameters');
fprintf('   Located at: %s\n', readParameters_path);
if contains(readParameters_path, 'Application_Specific_MIDAS_Code')
    fprintf('   ✓ CORRECT: Using Application_Specific version\n');
else
    fprintf('   ✗ ERROR: Not using Application_Specific version!\n');
end

fprintf('\n========================================\n');
fprintf('VERIFICATION COMPLETE\n');
fprintf('========================================\n\n');

fprintf('If all checks passed, run: runMIDAS\n');
fprintf('If any checks failed, run this script again\n\n');

