function compute_confident_poses(params, vid)
    extract_people(params, vid);

    tmpdir = fullfile(params.root, 'tmp', vid.parent);
    directory = fullfile(params.root, 'tmp', vid.id);

    % Computing horizon height        
    file = fullfile(directory, 'horizon.mat');
    if exist(file, 'file')
        load(file, 'horizonY', 'h');
    else            
        fprintf('Computing horizon height...\n');
        try
            [horizonY h] = get_horizon(params, vid.id);
        catch
            horizonY = NaN;
            h = 0;
            save(file, 'horizonY', 'h');
        end
    end  

    % Loading detections
    file = fullfile(directory, sprintf('%s_allposes.mat', params.detector_prefix));
    if exist(file, 'file')
        load(file, 'cleanbb');
    else
        J = find(vid.frames);
        cleanbb = cell(1, length(J));
        for j = 1 : length(cleanbb)                
            if mod(j, 100) == 0 || j == length(cleanbb)
                fprintf('Loading frame %d/%d\n', j, length(cleanbb));
            end
            load(fullfile(tmpdir, 'pose', sprintf('%s_frame%06d.jpg.mat', params.detector_prefix, J(j))), 'bb');
            cleanbb{j} = posedet_nms(bb, params.nms_pose);                
        end
        save(file, 'cleanbb');
    end

    % Computing depth/height relation
    file = fullfile(directory, sprintf('%s_calibrate.mat', params.detector_prefix));
    if exist(file, 'file')
        load(file, 'alphas', 'ks');
    else
        fprintf('Computing depth/height relation...\n');
        alphas = zeros(1, length(params.detector_model));
        ks = zeros(1, length(params.detector_model));
        N = zeros(1, length(params.detector_model));
        for j = 1 : length(params.detector_model)
            try
                if isnan(horizonY)
                    [alphas(j) ks(j) N(j)] = estimate_geometry(params, cleanbb, j);
                else
                    [alphas(j) ks(j) N(j)] = estimate_geometry(params, cleanbb, j, horizonY);
                end
                if alphas(j) < 0
                    alphas(j) = NaN;
                    ks(j) = NaN;
                end
            catch
                fprintf('WARNING: (automatic) Not enough poses selected, skipping.\n');
                alphas(j) = NaN;
                ks(j) = NaN;
            end
        end

        refdet = 1;
        while refdet <= length(params.detector_model) && isnan(alphas(refdet))
            refdet = refdet + 1;
        end

        if refdet < length(params.detector_model)                    
            for j = (refdet + 1) : length(params.detector_model)
                % Check that value estimated for different detector are consistent.
                if ~isnan(alphas(j)) && abs(alphas(j) / alphas(refdet) - ks(j) / ks(refdet)) > 0.1
                    alphas(j) = NaN;
                    ks(j) = NaN;
                end

                % Check for wrong estimations                    
                if ~isnan(alphas(j)) && (alphas(j) < 0.5 * alphas(refdet) || alphas(j) > 1.5 * alphas(refdet))
                    alphas(j) = NaN;
                end
            end
        end

        save(file, 'alphas', 'ks');
    end

    % Removing false positives
    file = fullfile(directory, sprintf('%s_cleanbb.mat', params.detector_prefix));
    if ~exist(file, 'file')
        fprintf('Removing false positives...\n');
        I = find(~isnan(alphas));
        if ~isempty(I)        
            alphas(~I) = mean(alphas(I));
            horizon = mean(-ks(I) ./ alphas(I));
            ks(~I) = -alphas(~I) * horizon;

            % Clean dets using geometry
            negbb = cell(1, length(cleanbb));
            for j = 1 : length(cleanbb)  
                if isempty(cleanbb{j})
                    continue;
                end

                bbs = cell(1, length(params.detector_model));
                neg = cell(1, length(params.detector_model));        
                bbID = cleanbb{j}(:, end-1);
                for k = 1 : length(params.detector_model)            
                    [bbs{k} neg{k}] = clean_dets_geom(params, cleanbb{j}(bbID == k, :), alphas(k), ks(k));            
                end
                cleanbb{j} = cat(1, bbs{:});
                negbb{j} = cat(1, neg{:});                  
            end
        else
            negbb = cell(1, length(cleanbb));
        end
        detIDScores = cell(1, length(cleanbb));
        for j = 1 : length(cleanbb)  
            if isempty(cleanbb{j})
                detIDScores{j} = [];
            else
                detIDScores{j} = cleanbb{j}(:, (end-1):end);
            end
        end

        save(file, 'cleanbb', 'negbb', 'detIDScores');
    end  
end