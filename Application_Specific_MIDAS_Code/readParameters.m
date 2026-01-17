function [agentParameters, modelParameters, networkParameters, mapParameters] = readParameters(inputs)

%All model parameters go here
modelParameters.spinupTime = 10;
modelParameters.numAgents = 200;
mapParameters.sizeX = 600;
mapParameters.sizeY = 600;
mapParameters.levelID = '_PCODE';
mapParameters.levelName = '_EN';
modelParameters.cycleLength = 4;
modelParameters.numCycles = 7;
modelParameters.incomeInterval = 1;
modelParameters.visualizeYN = 1;
modelParameters.listTimeStepYN = 1;
modelParameters.visualizeInterval = 2;  % Every 2 timesteps for clarity
modelParameters.showMovesOrNetwork = 1; %1 for recent moves, 0 for network
modelParameters.movesFadeSteps = 8;     % Don't keep too many lines visible
modelParameters.edgeAlpha = 0.5;        % Moderate visibility for movement lines 
modelParameters.ageDecision = 15;
modelParameters.ageLearn = 10;
modelParameters.utility_k = 4; 
modelParameters.utility_m = 1; 
modelParameters.utility_noise = 0.05;
modelParameters.utility_iReturn = 0.05;
modelParameters.utility_iDiscount = 0.05;
modelParameters.utility_iYears = floor(0.5 * modelParameters.numCycles); %Check that this should be 1/2 of number of cycles
modelParameters.ruralUrbanTime = 0.15;  % 15% time penalty

%Utility-Related Parameters
modelParameters.educationCost = 0;
modelParameters.largeFarmCost = 20;
modelParameters.smallFarmCost = 10;
modelParameters.schoolLength = 16;
modelParameters.educationLayer = 6; %Need to denote which layer is education, as this is used in trainingTracker as a flag for when someone completes education


%Aspirations Flag
modelParameters.aspirationsFlag = 1; %0 for no aspirations, 1 to enable aspirations

%Place attachment Flag 
modelParameters.placeAttachmentFlag = 0; %0 for no PA; 1 for PA

%Shock experiment Flag
modelParameters.shockExperiment = 0; %0 for no shock; 1 for shock
modelParameters.shockLocation = 0; %0 for whole country; 1 for both urban and rural in south; 2 for rural only in south
modelParameters.shockStart = 12; % Timestep when shock begins (default: 12)
modelParameters.shockEnd = 20; % Timestep when shock ends (default: 20)
modelParameters.shockSeverity = 0.20; % Shock severity multiplier (0.20 = 80% reduction, default: 0.20)

modelParameters.remitRate = 0;
modelParameters.creditMultiplier = 0.3;
modelParameters.normalFloodMultiplier = 1;
modelParameters.ruralUrbanTime = 0.15; %Proportion of time needed for transit between rural and urban layers of portfolio (was 0 in Round 1)
modelParameters.randDeath = 250;  %1 / randDeath is probability of death by age bracket
modelParameters.randBirth = 8;
mapParameters.movingCostPerMile = 5; %Low cost to encourage migration visualization
mapParameters.minDistForCost = 10;
mapParameters.maxDistForCost = 500;
mapParameters.movingAdminCosts = [10]; %Small cost for moving between locations
mapParameters.remitAdminCosts = [100 0]; %m x 2 array for remittance costs (1 row: base cost for all remittances)
networkParameters.networkDistanceSD = 7;
networkParameters.connectionsMean = 2; 
networkParameters.connectionsSD = 2;
networkParameters.agentPreAllocation = modelParameters.numAgents * 3;
networkParameters.nonZeroPreAllocation = networkParameters.agentPreAllocation * 10;
networkParameters.weightLocation = 3;
networkParameters.weightNetworkLink = 5;
networkParameters.weightSameLayer = 3;
networkParameters.distancePolynomial = 0.0002;
networkParameters.decayPerStep = 0.002;
networkParameters.interactBump = 0.01;
networkParameters.shareBump = 0.001;
mapParameters.degToRad = 0.0174533;
mapParameters.milesPerDeg = 69; %use for estimating actual distances in distance Matrix
mapParameters.density = 60; %pixels per degree Lat/Long, if using .shp input
mapParameters.colorSpacing = 5;  % Closer spacing = more color variation between locations
mapParameters.numDivisionMean = [2 3 3];
mapParameters.numDivisionSD = [0 1 1];
mapParameters.position = [100 100 1200 800];  % Larger window for better visibility
modelParameters.samplePortfolios = 100; %Number of example portfolios to create average utility for each aspirational layer
mapParameters.r1 = []; %Initialize empty - will be populated from cache by createMapFromSHP
mapParameters.saveDirectory = './Outputs/';

mapParameters.filePath = './Data/Madagascar_44_UrbanRural.shp';
modelParameters.popFile = './Data/madagascar_population_simple.csv';
modelParameters.survivalFile = [];
modelParameters.fertilityFile = [];
modelParameters.agePreferencesFile = './Data/age_specific_params.xls';
modelParameters.utilityDataPath = './Data';
modelParameters.saveImg = false;  % Turn off saving for faster runtime
modelParameters.shortName = 'Random_map_test';
modelParameters.runID = 'Random_test';
agentParameters.currentID = 1;
agentParameters.incomeShareFractionMean = 0.303;
agentParameters.incomeShareFractionSD = 0;
agentParameters.shareCostThresholdMean = 0.3;
agentParameters.shareCostThresholdSD = 0;
agentParameters.wealthMean = 0;
agentParameters.wealthSD = 0;
agentParameters.interactMean = 0.8;
agentParameters.interactSD = 0;
agentParameters.meetNewMean = 0.1;
agentParameters.meetNewSD = 0;
agentParameters.probAddFitElementMean = 1.0;
agentParameters.probAddFitElementSD = 0;
agentParameters.randomLearnMean = 1;
agentParameters.randomLearnSD = 0;
agentParameters.randomLearnCountMean = 5;
agentParameters.randomLearnCountSD = 0;
agentParameters.chooseMean = 1.0;
agentParameters.chooseSD = 0;
agentParameters.knowledgeShareFracMean = 0.3;
agentParameters.knowledgeShareFracSD = 0;
agentParameters.bestLocationMean = 2;
agentParameters.bestLocationSD = 0;
agentParameters.bestPortfolioMean = 2;
agentParameters.bestPortfolioSD = 0;
agentParameters.randomLocationMean = 3;
agentParameters.randomLocationSD = 0;
agentParameters.randomPortfolioMean = 3;
agentParameters.randomPortfolioSD = 0;
agentParameters.bestPortfolioAspirationsMean = 2;
agentParameters.bestPortfolioAspirationsSD = 0;
agentParameters.numPeriodsEvaluateMean = 20;
agentParameters.numPeriodsEvaluateSD = 0;
agentParameters.numPeriodsMemoryMean = 4;
agentParameters.numPeriodsMemorySD = 0;
agentParameters.discountRateMean = 0.24;
agentParameters.discountRateSD = 0;
agentParameters.rValueMean = 0.85;
agentParameters.rValueSD = 0.2;
agentParameters.bListMean = 0.5;
agentParameters.bListSD = 0.2;
agentParameters.prospectLossMean = 2.418;
agentParameters.prospectLossSD = 0;
agentParameters.informedExpectedProbJoinLayerMean = 1;
agentParameters.informedExpectedProbJoinLayerSD = 0;
agentParameters.uninformedMaxExpectedProbJoinLayerMean = 0.4;
agentParameters.uninformedMaxExpectedProbJoinLayerSD = 0;
agentParameters.expectationDecayMean = 0.1;
agentParameters.expectationDecaySD = 0;

%agent parameters for place attachment
agentParameters.placeAttachmentMean = 0.7;
agentParameters.placeAttachmentSD = 0.2;
agentParameters.placeAttachmentGrowMean = 0.01;
agentParameters.placeAttachmentGrowSD = 0;
agentParameters.placeAttachmentDecayMean = 0.001;
agentParameters.placeAttachmentDecaySD = 0;
agentParameters.initialPlaceAttachmentMean = 0.5;
agentParameters.initialPlaceAttachmentSD = 0;


%override any input variables. 'inputs' should be a dataset with two columns,
%one with the parameter name and one with the value
if(~isempty(inputs))
    for indexI = 1:size(inputs,1)
        currentValue = inputs.parameterValues{indexI};
        eval([inputs.parameterNames{indexI} ' = currentValue;']);
    end
end

modelParameters.timeSteps = modelParameters.spinupTime + modelParameters.numCycles * modelParameters.cycleLength;  %in this particular experiment only, there are 204 time steps with data

% Check available utility data timesteps and cap if necessary
% This prevents errors when simulation length exceeds available utility data
try
    cfg = load('madagascar_config.mat');
    if isfield(cfg, 'utilityBaseLayers')
        [~, ~, availableTimesteps] = size(cfg.utilityBaseLayers);
        if modelParameters.timeSteps > availableTimesteps
            fprintf('⚠ WARNING: Requested %d timesteps but utility data only has %d timesteps.\n', ...
                modelParameters.timeSteps, availableTimesteps);
            fprintf('   Capping simulation to %d timesteps.\n', availableTimesteps);
            modelParameters.timeSteps = availableTimesteps;
            % Recalculate numCycles to match
            maxCycles = floor((availableTimesteps - modelParameters.spinupTime) / modelParameters.cycleLength);
            if maxCycles < modelParameters.numCycles
                fprintf('   Adjusted numCycles from %d to %d.\n', modelParameters.numCycles, maxCycles);
                modelParameters.numCycles = maxCycles;
            end
        end
    end
catch
    % If config file can't be loaded, continue with requested timesteps
    % (will fail later if there's actually a problem)
end


end

