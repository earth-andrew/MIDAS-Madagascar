function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityDuration, utilityAccessCodesMat, utilityPrereqs, utilityBaseLayers, utilityForms, incomeForms, nExpected, hardSlotCountYN ] = createUtilityLayers(locations, modelParameters, demographicVariables )
% === START: consume precomputed MIDAS config ===
cfg = load('madagascar_config.mat');

% Basic guards
assert(isfield(cfg,'utilityBaseLayers'),'config missing utilityBaseLayers');
assert(isfield(cfg,'utilityHistory'),'config missing utilityHistory');
[Lloc, Llayers, Lt] = size(cfg.utilityBaseLayers);
assert(Llayers > 0 && Lt > 0, 'utilityBaseLayers has invalid shape');

% Ensure locations match
assert(size(locations,1) == Lloc, ...
  'locations rows (%d) must match utilityBaseLayers locations (%d).', ...
  size(locations,1), Lloc);

% Use  existing density-dependent layer function for each layer
if ~isfield(modelParameters,'utility_k'), modelParameters.utility_k = 4; end
if ~isfield(modelParameters,'utility_m'), modelParameters.utility_m = 1; end
k = modelParameters.utility_k; 
m = modelParameters.utility_m;

utilityLayerFunctions = cell(Llayers,1);
for ii = 1:Llayers
  utilityLayerFunctions{ii,1} = @(k_in,m_in,nExp,nAct,base) ...
    base * (m_in * nExp) / (max(1, nAct - m_in * nExp) * k_in + m_in * nExp);
end
% We keep k,m external so engine can pass modelParameters.utility_k/_m.

% Directly take all precomputed arrays
utilityBaseLayers      = cfg.utilityBaseLayers;      % [loc x layer x time]
utilityHistory         = cfg.utilityHistory;         % with spinup preprended

% Conditionally load optional fields
if isfield(cfg,'utilityAccessCosts')
    utilityAccessCosts = cfg.utilityAccessCosts;
else
    utilityAccessCosts = [];
end

if isfield(cfg,'utilityTimeConstraints')
    utilityTimeConstraints = cfg.utilityTimeConstraints;
else
    utilityTimeConstraints = [];
end

if isfield(cfg,'utilityDuration')
    utilityDuration = cfg.utilityDuration;
else
    utilityDuration = [];
end

if isfield(cfg,'utilityAccessCodesMat')
    utilityAccessCodesMat = cfg.utilityAccessCodesMat;
else
    utilityAccessCodesMat = [];
end

if isfield(cfg,'utilityPrereqs')
    utilityPrereqs = cfg.utilityPrereqs;
else
    utilityPrereqs = [];
end

if isfield(cfg,'utilityForms')
    utilityForms = double(cfg.utilityForms(:));  % Ensure double type for compatibility
else
    utilityForms = [];
end

if isfield(cfg,'incomeForms')
    incomeForms = double(cfg.incomeForms(:));  % Ensure double type for compatibility
else
    incomeForms = [];
end

if isfield(cfg,'nExpected')
    nExpected = cfg.nExpected;
else
    nExpected = [];
end

if isfield(cfg,'hardSlotCountYN')
    hardSlotCountYN_in = cfg.hardSlotCountYN;
else
    hardSlotCountYN_in = [];
end

% If some fields were absent or wrong size, set safe defaults:
if isempty(utilityAccessCosts),    utilityAccessCosts = zeros(0,2); end

% utilityAccessCodesMat must be (numCosts × numLayers × numLocations)
% Force correct dimensions for Madagascar (44 locations)
if isempty(utilityAccessCodesMat)
    utilityAccessCodesMat = zeros(0, Llayers, size(locations,1));
elseif size(utilityAccessCodesMat, 3) ~= size(locations,1)
    % Config file has wrong number of locations - recreate with correct size
    utilityAccessCodesMat = zeros(0, Llayers, size(locations,1));
end

if isempty(utilityTimeConstraints), error('Missing utilityTimeConstraints in config.'); end
if isempty(utilityDuration),        error('Missing utilityDuration in config.'); end
if isempty(utilityPrereqs),         error('Missing utilityPrereqs in config.'); end
if isempty(utilityForms),           utilityForms = ones(Llayers,1); end
% Ensure utilityForms is double
utilityForms = double(utilityForms);
if isempty(incomeForms),            incomeForms  = double(utilityForms == 1); end
% Ensure incomeForms is double (critical for income calculations)
incomeForms = double(incomeForms);
if isempty(nExpected),              nExpected    = zeros(size(locations,1), Llayers); end

% Ensure utilityAccessCosts has correct default for Madagascar (no access costs)
if isempty(utilityAccessCosts) || size(utilityAccessCosts, 1) == 0
    utilityAccessCosts = zeros(0, 2);
end

% TimeConstraints: add [id] column if provided as Lx4
if size(utilityTimeConstraints,2) == 4
  utilityTimeConstraints = [(1:size(utilityTimeConstraints,1))' utilityTimeConstraints];
end

% Prereqs to sparse (convert to double first to avoid type issues)
if ~issparse(utilityPrereqs)
    utilityPrereqs = sparse(double(utilityPrereqs));
end

% hardSlotCountYN: vector → expand to matrix like original expectation
if isempty(hardSlotCountYN_in)
  hardSlotCountYN = false(size(nExpected));         % default: all false
elseif isvector(hardSlotCountYN_in)
  % Expand vector to matrix: replicate across all locations
  hardSlotCountYN = repmat(logical(hardSlotCountYN_in(:)'), size(nExpected,1), 1);
else
  hardSlotCountYN = logical(hardSlotCountYN_in);
end

% Align education layer to "last" automatically (no params file edits needed)
modelParameters.educationLayer = Llayers;

% === ECONOMIC SHOCK IMPLEMENTATION ===
% Apply economic shock if specified (affects all income-generating sectors)
if modelParameters.shockExperiment == 1
    % Read shock parameters from modelParameters (with defaults if not set)
    if isfield(modelParameters, 'shockStart')
        shockStart = modelParameters.shockStart;
    else
        shockStart = 12;  % Default: Start after spinup
    end
    
    if isfield(modelParameters, 'shockEnd')
        shockEnd = modelParameters.shockEnd;
    else
        shockEnd = 20;    % Default: End at timestep 20
    end
    
    if isfield(modelParameters, 'shockSeverity')
        shockSeverity = modelParameters.shockSeverity;
    else
        shockSeverity = 0.20;  % Default: 80% reduction
    end
    
    % Determine affected locations based on shockLocation parameter
    if modelParameters.shockLocation == 0
        % Whole country: all locations
        affectedLocs = 1:size(locations, 1);
        
    elseif modelParameters.shockLocation == 1
        % Southern drought regions only (both urban and rural)
        % Extract region codes from ADM2_PCODE (format: MDG0123-R/U)
        numLocs = size(locations, 1);
        regionCodes = zeros(numLocs, 1);
        
        for i = 1:numLocs
            if istable(locations)
                pcode = locations.ADM2_PCODE{i};
            else
                pcode = locations(i).ADM2_PCODE;
            end
            
            % Extract region from MDG0123-R format
            if length(pcode) >= 7 && startsWith(pcode, 'MDG')
                province = str2double(pcode(4:5));
                district = str2double(pcode(6:7));
                regionCodes(i) = province * 10 + district;
            end
        end
        
        % Drought-affected regions in southern Madagascar
        % Androy, Anosy, Atsimo-Andrefana, Atsimo-Atsinanana, Vatovavy, Ihorombe
        droughtRegions = [15, 19, 20, 21, 22, 24];
        affectedLocs = find(ismember(regionCodes, droughtRegions));
        
    elseif modelParameters.shockLocation == 2
        % Southern drought regions - RURAL ONLY
        % Extract region codes from ADM2_PCODE (format: MDG0123-R/U)
        numLocs = size(locations, 1);
        regionCodes = zeros(numLocs, 1);
        isRural = false(numLocs, 1);
        
        for i = 1:numLocs
            if istable(locations)
                pcode = locations.ADM2_PCODE{i};
                % Check if rural - handle both 'R' and 'Rural' values
                if ismember('URBAN_RURAL', locations.Properties.VariableNames)
                    ur_value = locations.URBAN_RURAL{i};
                    isRural(i) = strcmp(ur_value, 'R') || strcmp(ur_value, 'Rural') || ...
                        contains(ur_value, 'Rural', 'IgnoreCase', true);
                end
            else
                pcode = locations(i).ADM2_PCODE;
                % Check if rural - handle both 'R' and 'Rural' values
                if isfield(locations(i), 'URBAN_RURAL')
                    ur_value = locations(i).URBAN_RURAL;
                    if ischar(ur_value) || isstring(ur_value)
                        isRural(i) = strcmp(ur_value, 'R') || strcmp(ur_value, 'Rural') || ...
                            contains(ur_value, 'Rural', 'IgnoreCase', true);
                    end
                end
            end
            
            % Extract region from MDG0123-R format
            if length(pcode) >= 7 && startsWith(pcode, 'MDG')
                province = str2double(pcode(4:5));
                district = str2double(pcode(6:7));
                regionCodes(i) = province * 10 + district;
            end
        end
        
        % Drought-affected regions in southern Madagascar
        % Androy, Anosy, Atsimo-Andrefana, Atsimo-Atsinanana, Vatovavy, Ihorombe
        droughtRegions = [15, 19, 20, 21, 22, 24];
        inDroughtRegion = ismember(regionCodes, droughtRegions);
        affectedLocs = find(inDroughtRegion & isRural);
        
    else
        affectedLocs = [];
    end
    
    % Apply shock: reduce ALL income sectors (all layers)
    if ~isempty(affectedLocs)
        utilityBaseLayers(affectedLocs, :, shockStart:shockEnd) = ...
            utilityBaseLayers(affectedLocs, :, shockStart:shockEnd) * shockSeverity;
        
        fprintf('Economic shock applied:\n');
        fprintf('  Locations: %d of %d\n', length(affectedLocs), size(locations,1));
        fprintf('  Sectors: ALL layers\n');
        fprintf('  Timesteps: %d-%d\n', shockStart, shockEnd);
        fprintf('  Severity: %.0f%% reduction\n', (1-shockSeverity)*100);
        if modelParameters.shockLocation == 2
            fprintf('  Type: Rural areas only in southern drought regions\n');
        elseif modelParameters.shockLocation == 1
            fprintf('  Type: Both urban and rural in southern drought regions\n');
        end
    end
end

% Skip all synthetic construction below (mean_utility_by_layer, random epsilons, etc.)
% === END: consume precomputed MIDAS config ===