function [dataSP labels blocks] = compute_hist(params, tmpdir, vid, meanstd, bof, bop, annots)
    file = fullfile(tmpdir, sprintf('hist_%s_%s.mat', params.annots.name, vid));     
    if exist(file, 'file') == 2
        load(file);
        fprintf('Histogam loaded from %s.\n', file);        
        return;
    end
    
    fprintf('Computing histogam for %s:\n', vid);

    if exist('annots', 'var') && ~isempty(annots)
        annots = ssem_unpack_annot(annots);
    end
        
    [segments, neighbours] = segment_back(params, vid);
    img = ssem_load_back(params, vid); 
    if size(img, 2) > params.segimwidth
        scale = params.segimwidth / size(img, 2);
        img = imresize(img, [round(size(img, 1) * scale) params.segimwidth]);
    else
        scale = 1;
    end
    [height, width, ~] = size(img);
    if exist('annots', 'var') && ~isempty(annots) 
        annots = imresize(annots, [height, width], 'nearest');
    end
    for k = 1 : length(segments)
    	segments{k} = imresize(segments{k}, [height, width], 'nearest');
    end
      
    nsegments = 0;
    for k = 1 : length(segments)
        nsegments = nsegments + size(neighbours{k}, 1);
    end
    
    tic();
    segID = 0;
    areas = cell(1, length(segments));    
    segblocks = cell(1, length(segments));    
    if exist('annots', 'var') && ~isempty(annots)  
        labels = cell(1, length(segments));        
    end            
    for k = 1 : length(segments)   
        nseg = size(neighbours{k}, 1);
        if exist('annots', 'var') && ~isempty(annots)
            [areas{k} labels{k}] = fast_load_labels(segments{k}, nseg, annots);
        else
            areas{k} = fast_load_labels(segments{k}, nseg);     
        end
        segblocks{k} = segID + (1 : nseg);
        segID = segID + nseg;
    end    
    areas = cat(2, areas{:});
    if exist('annots', 'var') && ~isempty(annots)
        labels = cat(1, labels{:});
    end
    fprintf('--> Loading labels: %.2fs\n', toc());

    h = zeros(nsegments, 0);
    blocks = {};  
    
    % Appearence term
    if params.ALP(1)
        tic();
        [feat, bbs, scores] = compute_features(params, vid);
        
        if params.featHardAssign
            [~, assign] = min(dist2(feat, bof), [], 2);    
            assign = assign2FeatMat(assign, params.KA, scores);                                    
        else
            assign = gmmAssign(bof, feat);
            assign(assign < 1e-5) = 0;
            assign = sparse(assign); 
            assign = bsxfun(@rdivide, assign, eps + sum(abs(assign), 2));                
            assign = bsxfun(@times, assign, scores);
        end   
        
        h2 = process_bb2hist(segments, neighbours, round(bbs * scale), assign);
        
        [h blocks] = add_block(h, blocks, h2, 'bofSIFT');                
        fprintf('--> Appearence feature: %.2fs\n', toc());
    end    

    % Localization term
    if params.ALP(2)
        tic();       
        KLx = params.KL(1);
        KLy = params.KL(2);
        Xb = round(    (1 : KLx) * (size(img, 2) / KLx));
        Xe = round(1 + (1 : KLx) * (size(img, 2) / KLx));
        Yb = round(    (1 : KLy) * (size(img, 1) / KLy));
        Ye = round(1 + (1 : KLy) * (size(img, 1) / KLy));        
        Xb = kron(Xb, ones(1, KLy));
        Xe = kron(Xe, ones(1, KLy));
        Yb = repmat(Yb, 1, KLx);
        Ye = repmat(Ye, 1, KLx);        
        bbs = int32([Xb; Yb; Xe; Ye]);
        
        KL = prod(params.KL);
        h2 = process_bb2hist(segments, neighbours, bbs, sparse(eye(KL)));
        
        [h blocks] = add_block(h, blocks, h2, 'positionFeat');
        fprintf('--> Localization feature: %.2fs\n', toc());
    end    

    % Interaction term
	if params.ALP(3)    
        tic();
        poses = load_poses(params, vid);
        [cleanbb personbb] = perframe_nms(params, poses);
        cleanbb = cat(1, cleanbb{:}) * scale;
        personbb = cat(1, personbb{:}) * scale;        
        
        if isempty(cleanbb)
            njoints = length(params.jointnames);
            if params.Pfeat(1)
                h2 = sparse(nsegments, njoints * params.KP);
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointpos'); 
            end
            if params.Pfeat(2)
                h2 = sparse(nsegments, njoints * params.KP);
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointreg'); 
            end
            if params.Pfeat(3)
                h2 = sparse(nsegments, njoints * params.KP * 9);
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointgrid'); 
            end
            if params.Pfeat(4)
                h2 = sparse(nsegments, prod(params.person_grid) * params.KP);
                [h blocks] = add_block(h, blocks, h2, 'personFeat_persongrid'); 
            end
        else        
            cleanbb(:, 1 : (end - 2)) = cleanbb(:, 1 : (end - 2));
            personbb(:, 1 : 4) = personbb(:, 1 : 4);

            joints = get_joints(cleanbb);

            scores = cleanbb(:, end);
            for i = 1 : length(params.detector_model)
                scores(cleanbb(:, end - 1) == i) = (scores(cleanbb(:, end - 1) == i) - meanstd(1, i)) / meanstd(2, i);
            end
            scores = 1 ./ (1 + exp(- 3 * scores));

            cleanbb = reshape(cleanbb(:, 1:(end-2))', [4, (size(cleanbb, 2)-2)/4, size(cleanbb, 1)]);   
            
            % 14 bb instead of 26            
            cleanbb = cleanbb(:, params.joints_to_annot, :);              

            % multiply size of part boxes by params.bbResizeFactor
            if params.Pfeat(2) || params.Pfeat(3)
                centers = repmat((cleanbb(3:4, :, :) + cleanbb(1:2, :, :)) / 2, 2, 1);
                bbs = cell(1, length(params.bbResizeFactor));
                for i = 1 : length(params.bbResizeFactor)
                    bbs{i} = centers + (cleanbb - centers) * params.bbResizeFactor(i);                 
                end
                cleanbb = cat(3, bbs{:});
                scores = repmat(scores, length(params.bbResizeFactor), 1);
                joints = repmat(joints, [1, 1, length(params.bbResizeFactor)]);
            end                       

            jnorm = normalize_poses(joints);                               

            if params.poseHardAssign
                [~, assign] = min(dist2(jnorm, bop), [], 2);                        
                assign = assign2FeatMat(assign, params.KP, scores);
            else
                assign = gmmAssign(bop, jnorm);
                assign(assign < 1e-5) = 0;                    
                assign = sparse(assign);                    
                assign = bsxfun(@rdivide, assign, eps + sum(abs(assign), 2));                
                assign = bsxfun(@times, assign, scores);
            end

            if params.Pfeat(1)
                h2 = extract_pose_cluster_joints(assign, [joints; joints], 0, segments, neighbours);           
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointpos'); 
            end
            if params.Pfeat(2)
                h2 = extract_pose_cluster_joints(assign, cleanbb, 0, segments, neighbours);
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointreg'); 
            end
            if params.Pfeat(3)
                h2 = extract_pose_cluster_joints(assign, cleanbb, 1, segments, neighbours); 
                [h blocks] = add_block(h, blocks, h2, 'personFeat_jointgrid'); 
            end
            if params.Pfeat(4)
                h2 = extract_pose_cluster_personbb_grid(params, assign, personbb, segments, neighbours); 
                [h blocks] = add_block(h, blocks, h2, 'personFeat_persongrid'); 
            end
        end
        fprintf('--> Person feature: %.2fs\n', toc());
	end
              
    dataSP = struct('nsegments', nsegments, 'areas', areas, 'segments', {segments}, 'segblocks', {segblocks}, 'neighbours', {neighbours}, 'h', h);    
    if exist('annots', 'var') && ~isempty(annots)
        labels = struct('labels', labels, 'areas', areas);
        save(file, 'dataSP', 'labels', 'blocks');
    else
        save(file, 'dataSP', 'blocks');
    end         
end

function [h blocks] = add_block(h, blocks, h2, name)  
    h2 = bsxfun(@rdivide, h2, eps + sum(abs(h2), 2));
    
    blocks{end+1, 1} = size(h, 2) + (1:size(h2, 2)); 
    blocks{end, 2} = name;
    
    h = cat(2, h, h2);
end

function h = extract_pose_cluster_joints(assign, cleanbb, do_grid, segments, neighbours)
    % Cast a vote for each joint and cluster at the region covered by the joint
    njoints = size(cleanbb, 2);
    nposes = size(cleanbb, 3);    
        
    cleanbb = int32(round(cleanbb));
    % We need to put it in the form 4 x nposes x njoints
    bb = cell(1, njoints);
    for i = 1 : njoints
        bb{i} = reshape(cleanbb(:, i, :), 4, nposes);
    end
    cleanbb = cat(3, bb{:});
        
    if do_grid
        W = cleanbb(3, :, :) - cleanbb(1, :, :) + 1;
        H = cleanbb(4, :, :) - cleanbb(2, :, :) + 1;
        bb = cell(9, 1);
        for u = -1 : 1
            for v = -1 : 1
                bb{(u + 1) * 3 + v + 2} = cleanbb + repmat([u * W; v * H], 2, 1);
            end
        end
        cleanbb = cat(3, bb{:});   
    end
        
    h = process_bb2hist(segments, neighbours, cleanbb, assign);             
end

function h = extract_pose_cluster_personbb_grid(params, assign, personbb, segments, neighbours)
    % Cast a vote by cluster and grid cell for each segment under the grid 
    nposes = size(personbb, 1);   

    personbb = personbb(:, 1:4);
    centers = (personbb(:, 1:2) + personbb(:, 3:4)) / 2;    
    personbb = round((personbb - [centers centers]) * params.bbox_rescale + [centers centers]);
    bbsize = personbb(:, 3:4) - personbb(:, 1:2) + 1;

    bbs = cell(1, nposes);
    for i = 1 : nposes
        Xb = int32(round(personbb(i, 1) + (0:(params.person_grid(1)-1)) * (bbsize(i, 1) / params.person_grid(1))));
        Xe = int32(round(personbb(i, 1) + (1: params.person_grid(1)   ) * (bbsize(i, 1) / params.person_grid(1))));
        Yb = int32(round(personbb(i, 2) + (0:(params.person_grid(2)-1)) * (bbsize(i, 2) / params.person_grid(2))));
        Ye = int32(round(personbb(i, 2) + (1: params.person_grid(2)   ) * (bbsize(i, 2) / params.person_grid(2))));
        Xb = kron(Xb, int32(ones(1, params.person_grid(2))));
        Xe = kron(Xe, int32(ones(1, params.person_grid(2))));
        Yb = repmat(Yb, 1, params.person_grid(1));
        Ye = repmat(Ye, 1, params.person_grid(1));        
        bbs{i} = reshape([Xb; Yb; Xe; Ye], [4, 1, prod(params.person_grid)]);
    end    
    bbs = cat(2, bbs{:});
    
    h = process_bb2hist(segments, neighbours, bbs, assign);
end

function h = process_bb2hist(segments, neighbours, bbs, assign)   
    h = cell(1, length(segments));
    for k = 1 : length(segments)
        nseg = size(neighbours{k}, 1);
        seg = box2seg(segments{k}, nseg, bbs);            

        h2 = cell(1, length(seg));
        for i = 1 : length(seg)
            h2{i} = seg{i} * assign;  
        end
        h{k} = cat(2, h2{:});
    end
    h = cat(1, h{:});
end

function mat = assign2FeatMat(assign, nClusters, scores)
    nFeat = length(assign);
    if nargin < 3
        scores = ones(nFeat, 1);
    end
	mat = sparse(1 : nFeat, assign, scores, nFeat, nClusters);
end
