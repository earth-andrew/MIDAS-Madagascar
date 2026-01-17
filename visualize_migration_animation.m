function visualize_migration_animation(outputFile, frameDir, framePrefix)
% VISUALIZE_MIGRATION_ANIMATION Generate high-quality animation frames
%
% Inputs:
%   outputFile  - Path to MIDAS output .mat file
%   frameDir    - Directory to save frames (will be created if needed)
%   framePrefix - Prefix for frame filenames (e.g., 'migration')
%
% Outputs:
%   Saves PNG frames: frameDir/framePrefix_001.png, _002.png, etc.
%
% Example:
%   visualize_migration_animation('Outputs/Madagascar_Baseline_Run001.mat', ...
%                                  'Frames/', 'migration')

    fprintf('\n=== MIDAS MIGRATION ANIMATION GENERATOR ===\n\n');
    
    % Create output directory if needed
    if ~exist(frameDir, 'dir')
        mkdir(frameDir);
        fprintf('Created frame directory: %s\n', frameDir);
    end
    
    % Load MIDAS output
    fprintf('Loading output file: %s\n', outputFile);
    data = load(outputFile);
    
    % Extract key data structures
    if isfield(data, 'output')
        output = data.output;
    else
        error('Output file does not contain "output" structure');
    end
    
    % Get locations from mapVariables
    if isfield(output, 'mapVariables') && isfield(output.mapVariables, 'locations')
        locations = output.mapVariables.locations;
    else
        error('Cannot find locations in output.mapVariables');
    end
    
    % Get agent data (handle both singular and plural naming)
    if isfield(output, 'agentSummary')
        agentTable = output.agentSummary;
    elseif isfield(output, 'agentSummaries')
        agentTable = output.agentSummaries;
    else
        error('Cannot find agentSummary or agentSummaries in output');
    end
    
    % Determine total timesteps from agent move histories
    numTimesteps = 0;
    for i = 1:height(agentTable)
        if ~isempty(agentTable.moveHistory{i})
            numTimesteps = max(numTimesteps, max(agentTable.moveHistory{i}(:,1)));
        end
    end
    fprintf('Total timesteps to render: %d\n', numTimesteps);
    fprintf('Total agents: %d\n', height(agentTable));
    
    % Load shapefile (once for efficiency)
    fprintf('Loading Madagascar shapefile...\n');
    shapeFile = './Data/Madagascar_44_UrbanRural.shp';
    if ~exist(shapeFile, 'file')
        error('Shapefile not found: %s', shapeFile);
    end
    shapeData = shaperead(shapeFile);
    fprintf('  Loaded %d regions\n', length(shapeData));
    
    % Generate consistent colors for all regions (urban/rural paired)
    regionColors = generate_region_colors_paired(locations);
    
    % Set up figure properties
    figWidth = 1920;
    figHeight = 1080;
    dpi = 150;
    
    % Generate frames for each timestep
    fprintf('\nGenerating frames:\n');
    for t = 1:numTimesteps
        fprintf('  Frame %d/%d (timestep %d)... ', t, numTimesteps, t);
        tic;
        
        % Create high-resolution figure
        fig = figure('Visible', 'off', ...
                     'Position', [0 0 figWidth figHeight], ...
                     'Color', 'w', ...
                     'PaperPositionMode', 'auto');
        
        % Create axes
        ax = axes('Parent', fig, ...
                  'Position', [0.05 0.08 0.9 0.82]);
        hold(ax, 'on');
        
        % Draw map with clean style (like live simulation)
        draw_map_regions_simple(ax, shapeData, regionColors);
        
        % Extract agent locations at this timestep
        agentLocations = get_agent_locations_at_timestep(agentTable, t);
        
        % Count agents per location
        agentCounts = count_agents_per_location_from_table(agentLocations, locations);
        
        % Plot agent markers
        plot_agent_markers(ax, locations, agentCounts);
        
        % Draw movement arrows (for moves in last 3 timesteps)
        if t > 1
            draw_migration_arrows_from_table(ax, agentTable, locations, t, 3);
        end
        
        % Count active agents
        numActiveAgents = sum(agentLocations > 0);
        
        % Add title and labels
        add_title_and_info(ax, t, numTimesteps, numActiveAgents);
        
        % Set axis properties
        axis(ax, 'equal');
        axis(ax, 'tight');
        set(ax, 'XTick', [], 'YTick', []);
        box(ax, 'on');
        
        % Save frame
        frameName = sprintf('%s%s_%03d.png', frameDir, framePrefix, t);
        print(fig, frameName, '-dpng', sprintf('-r%d', dpi));
        
        close(fig);
        
        elapsedTime = toc;
        fprintf('done (%.2f sec)\n', elapsedTime);
    end
    
    fprintf('\n✓ All frames generated successfully!\n');
    fprintf('  Output directory: %s\n', frameDir);
    fprintf('  Total frames: %d\n', numTimesteps);
    fprintf('  File pattern: %s_###.png\n\n', framePrefix);
end

%% Helper Functions

function regionColors = generate_region_colors_paired(locations)
    % Generate colors where urban areas match their rural province
    % Rural gets base color, Urban gets lighter shade
    
    rng(42); % Fixed seed for reproducibility
    numLocs = height(locations);
    regionColors = zeros(numLocs, 3);
    
    % Get base region codes (remove -R/-U suffix)
    baseRegions = cell(numLocs, 1);
    isUrban = false(numLocs, 1);
    
    for i = 1:numLocs
        if istable(locations)
            code = locations.ADM2_PCODE{i};
        else
            code = locations(i).ADM2_PCODE;
        end
        
        % Check if urban or rural
        if endsWith(code, '-U')
            isUrban(i) = true;
            baseRegions{i} = code(1:end-2);  % Remove -U
        elseif endsWith(code, '-R')
            baseRegions{i} = code(1:end-2);  % Remove -R
        else
            baseRegions{i} = code;  % No suffix
        end
    end
    
    % Get unique base regions
    uniqueRegions = unique(baseRegions);
    numBaseRegions = length(uniqueRegions);
    
    % Generate distinct base colors for each province (22 colors)
    baseColors = distinguishable_colors(numBaseRegions);
    
    % Assign colors: rural=base, urban=lighter shade
    for i = 1:numLocs
        % Find which base region this location belongs to
        regionIdx = find(strcmp(uniqueRegions, baseRegions{i}), 1);
        baseColor = baseColors(regionIdx, :);
        
        if isUrban(i)
            % Urban: lighter shade (blend with white)
            regionColors(i, :) = baseColor * 0.6 + [1 1 1] * 0.4;
        else
            % Rural: base color
            regionColors(i, :) = baseColor;
        end
    end
end

function colors = distinguishable_colors(n)
    % Generate maximally distinguishable colors
    % Uses optimized color set for maximum perceptual difference
    
    if n <= 20
        % Use predefined highly distinct colors for small sets
        baseColors = [
            0.00 0.45 0.74;  % Blue
            0.85 0.33 0.10;  % Red-orange
            0.93 0.69 0.13;  % Yellow
            0.49 0.18 0.56;  % Purple
            0.47 0.67 0.19;  % Green
            0.30 0.75 0.93;  % Cyan
            0.64 0.08 0.18;  % Dark red
            0.74 0.74 0.13;  % Yellow-green
            1.00 0.41 0.16;  % Orange
            0.20 0.63 0.17;  % Forest green
            0.89 0.10 0.11;  % Bright red
            0.10 0.67 0.79;  % Teal
            0.94 0.50 0.50;  % Pink
            0.60 0.40 0.80;  % Lavender
            0.40 0.40 0.00;  % Olive
            0.00 0.60 0.50;  % Sea green
            0.80 0.60 0.70;  % Mauve
            0.60 0.30 0.00;  % Brown
            0.50 0.00 0.50;  % Dark purple
            0.00 0.50 0.80;  % Sky blue
        ];
        colors = baseColors(1:min(n, 20), :);
    else
        % For larger sets, use HSV with adjustments
        hueValues = linspace(0, 1, n+1);
        hueValues = hueValues(1:end-1);
        
        % Shuffle to avoid similar hues being adjacent
        rng(42);
        hueValues = hueValues(randperm(n));
        
        % Create colors with varied saturation and value
        colors = zeros(n, 3);
        for i = 1:n
            sat = 0.7 + 0.3 * mod(i, 3) / 2;  % Vary saturation
            val = 0.8 + 0.2 * mod(i, 2);      % Vary brightness
            colors(i, :) = hsv2rgb([hueValues(i), sat, val]);
        end
    end
end

function draw_map_regions_simple(ax, shapeData, regionColors)
    % Draw map in clean style like live simulation
    % No gaps, subtle colors, clear boundaries
    
    % Set light background color
    set(ax, 'Color', [0.96 0.96 0.98]);  % Very light blue-gray
    
    % First pass: Draw regions with matching edges to eliminate gaps
    for i = 1:length(shapeData)
        % Get polygon coordinates
        x = shapeData(i).X;
        y = shapeData(i).Y;
        
        % Remove NaN values (multipart polygons)
        validIdx = ~isnan(x) & ~isnan(y);
        x = x(validIdx);
        y = y(validIdx);
        
        if isempty(x)
            continue;
        end
        
        % Draw with subtle fill AND matching edge color (no gaps)
        patch(ax, x, y, regionColors(i, :), ...
              'EdgeColor', regionColors(i, :), ...  % Same as face
              'LineWidth', 0.5, ...
              'FaceAlpha', 0.30);  % More visible (was 0.15)
    end
    
    % Second pass: Draw boundaries for clarity
    for i = 1:length(shapeData)
        x = shapeData(i).X;
        y = shapeData(i).Y;
        validIdx = ~isnan(x) & ~isnan(y);
        x = x(validIdx);
        y = y(validIdx);
        
        if ~isempty(x)
            % Thin gray lines for boundaries
            plot(ax, x, y, '-', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.4);
        end
    end
    
    % Set proper aspect ratio and axis settings for geographic data
    axis(ax, 'equal');
    set(ax, 'DataAspectRatio', [1 1 1]);
    grid(ax, 'off');  % No grid
end

function agentLocations = get_agent_locations_at_timestep(agentTable, timestep)
    % Extract each agent's location at the specified timestep
    numAgents = height(agentTable);
    agentLocations = zeros(numAgents, 1);
    
    for i = 1:numAgents
        moveHist = agentTable.moveHistory{i};
        
        if isempty(moveHist)
            agentLocations(i) = 0;  % Agent not active
            continue;
        end
        
        % Find the most recent move up to this timestep
        validMoves = moveHist(moveHist(:,1) <= timestep, :);
        
        if isempty(validMoves)
            agentLocations(i) = 0;  % Agent not yet active
        else
            % Get location from most recent move (column 2)
            agentLocations(i) = validMoves(end, 2);
        end
    end
end

function agentCounts = count_agents_per_location_from_table(agentLocations, locations)
    numLocations = height(locations);
    agentCounts = zeros(numLocations, 1);
    
    for i = 1:length(agentLocations)
        loc = agentLocations(i);
        if loc > 0 && loc <= numLocations
            agentCounts(loc) = agentCounts(loc) + 1;
        end
    end
end

function plot_agent_markers(ax, locations, agentCounts)
    % Plot agent markers at region centroids
    
    for i = 1:height(locations)
        if agentCounts(i) > 0
            % Get location coordinates
            lon = locations.Longitude(i);
            lat = locations.Latitude(i);
            
            % Scale marker size by agent count
            markerSize = 50 + sqrt(agentCounts(i)) * 10;
            
            % Draw marker
            plot(ax, lon, lat, 'o', ...
                 'MarkerFaceColor', [0.8 0.2 0.2], ...
                 'MarkerEdgeColor', 'k', ...
                 'MarkerSize', markerSize/10, ...
                 'LineWidth', 1.5);
            % Numbers removed - cleaner visualization
        end
    end
end

function draw_migration_arrows_from_table(ax, agentTable, locations, currentT, fadeSteps)
    % Extract migrations from moveHistory for recent timesteps
    migrationCounts = struct();
    
    % Process each agent's move history
    for i = 1:height(agentTable)
        moveHist = agentTable.moveHistory{i};
        
        if isempty(moveHist)
            continue;
        end
        
        % Find moves in the recent window
        recentMoves = moveHist(moveHist(:,1) > (currentT - fadeSteps) & ...
                               moveHist(:,1) <= currentT, :);
        
        % Process each move in the recent window
        for j = 2:size(recentMoves, 1)
            % Get from/to locations
            tMove = recentMoves(j, 1);
            locFrom = recentMoves(j-1, 2);
            locTo = recentMoves(j, 2);
            
            % Skip if not a real move or invalid locations
            if locFrom == locTo || locFrom <= 0 || locTo <= 0 || ...
               locFrom > height(locations) || locTo > height(locations)
                continue;
            end
            
            % Create key for this migration pair (prefix with 'm' for valid field name)
            key = sprintf('m%d_%d', locFrom, locTo);
            
            % Calculate how recent this move was
            tOffset = currentT - tMove + 1;
            
            % Update counts
            if isfield(migrationCounts, key)
                migrationCounts.(key).count = migrationCounts.(key).count + 1;
                migrationCounts.(key).mostRecent = min(migrationCounts.(key).mostRecent, tOffset);
            else
                migrationCounts.(key).count = 1;
                migrationCounts.(key).mostRecent = tOffset;
                migrationCounts.(key).from = locFrom;
                migrationCounts.(key).to = locTo;
            end
        end
    end
    
    % Draw arrows for each migration flow
    fields = fieldnames(migrationCounts);
    for i = 1:length(fields)
        migration = migrationCounts.(fields{i});
        fromLon = locations.Longitude(migration.from);
        fromLat = locations.Latitude(migration.from);
        toLon = locations.Longitude(migration.to);
        toLat = locations.Latitude(migration.to);
        thickness = 0.5 + log(1 + migration.count);
        fade = 1 - (migration.mostRecent / (fadeSteps + 1));
        fade = max(0.3, fade);
        draw_curved_arrow(ax, fromLon, fromLat, toLon, toLat, thickness, fade);
    end
end

function draw_curved_arrow(ax, x1, y1, x2, y2, thickness, alpha)
    % Draw curved arrow from (x1,y1) to (x2,y2)
    
    % Calculate control point for bezier curve (20% arc)
    midX = (x1 + x2) / 2;
    midY = (y1 + y2) / 2;
    
    % Perpendicular offset for curve
    dx = x2 - x1;
    dy = y2 - y1;
    dist = sqrt(dx^2 + dy^2);
    
    if dist < 0.01
        return; % Skip very short arrows
    end
    
    % Control point offset (perpendicular to line)
    offset = dist * 0.2;
    perpX = -dy / dist * offset;
    perpY = dx / dist * offset;
    
    ctrlX = midX + perpX;
    ctrlY = midY + perpY;
    
    % Generate bezier curve points
    t = linspace(0, 1, 50);
    curveX = (1-t).^2 * x1 + 2*(1-t).*t * ctrlX + t.^2 * x2;
    curveY = (1-t).^2 * y1 + 2*(1-t).*t * ctrlY + t.^2 * y2;
    
    % Draw curve
    plot(ax, curveX, curveY, ...
         'Color', [0 0 0 alpha], ...
         'LineWidth', thickness);
    
    % Add arrowhead
    arrowT = 0.85;
    arrowX = (1-arrowT)^2 * x1 + 2*(1-arrowT)*arrowT * ctrlX + arrowT^2 * x2;
    arrowY = (1-arrowT)^2 * y1 + 2*(1-arrowT)*arrowT * ctrlY + arrowT^2 * y2;
    
    % Arrow direction
    dArrowX = x2 - arrowX;
    dArrowY = y2 - arrowY;
    arrowDist = sqrt(dArrowX^2 + dArrowY^2);
    
    if arrowDist > 0.01
        quiver(ax, arrowX, arrowY, dArrowX*0.3, dArrowY*0.3, 0, ...
               'Color', [0 0 0 alpha], ...
               'LineWidth', thickness, ...
               'MaxHeadSize', 1.5);
    end
end

function add_title_and_info(ax, timestep, totalSteps, numActive)
    % Add title with timestep and agent count information
    
    % Convert timestep to years and quarters
    year = floor((timestep - 1) / 4) + 1;
    quarter = mod(timestep - 1, 4) + 1;
    
    % Create title
    titleStr = sprintf('Madagascar Migration Dynamics - Timestep %d/%d', ...
                      timestep, totalSteps);
    title(ax, titleStr, 'FontSize', 16, 'FontWeight', 'bold');
    
    % Add info text
    infoStr = sprintf('Year %d, Quarter %d | %d Active Agents', ...
                     year, quarter, numActive);
    xlabel(ax, infoStr, 'FontSize', 12);
end

