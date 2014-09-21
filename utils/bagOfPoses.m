function [clusters stats] = bagOfPoses(params, tmpdir, vids)
    if params.poseHardAssign
        [clusters stats] = hardEncoding(params, tmpdir, vids);
    else
        [clusters stats] = softEncoding(params, tmpdir, vids);
    end
end

function [clusters stats] = softEncoding(params, tmpdir, vids)
    kmeansinit = 1;
    diagonal = 1;
    share = 0;
    nEx = 1e5;

    kmext = '';
    diagext = '';
    shareext = '';
    if kmeansinit
        kmext = '_kmeansinit';
    end
    if diagonal
        diagext = '_diagonal';
    end
    if share
        shareext = '_shared';
    end
    file = fullfile(tmpdir, sprintf('gmmop_%d_%d_%d%s%s%s.mat', params.KP, length(vids), nEx, kmext, diagext, shareext));

    if exist(file, 'file')
        fprintf('Pose clustering loaded from %s\n', file);
        load(file, 'clusters', 'stats'); 
        return;
    end
    
    if kmeansinit
        clusters = hardEncoding(params, tmpdir, vids);
        start.mu = clusters;
        start.PComponents = ones(1, size(clusters, 1));
        if diagonal
            start.Sigma = ones(1, size(clusters, 2));
        else
            start.Sigma = eye(size(clusters, 2));
        end
        if ~share
            start.Sigma = repmat(start.Sigma, [1 1 size(clusters, 1)]);
        end
    else
        start = [];    
    end
    
    [joints detID] = extract_features(params, vids, nEx);  
    nposes = size(joints, 1);
    
    % Train GMM
    clusters = gmmTrain(joints, params.KP, start);    
    
    % Assign examples
    pb = clusters.posterior(joints);
    
    stats = struct('freq_assign', cell(params.KP, 1), 'type_dets', []);
    for i = 1 : params.KP     
        nmatch = sum(pb(:, i));
        stats(i).freq_assign = nmatch / nposes;
        stats(i).type_dets = zeros(1, 3);
        for j = 1 : 3            
            stats(i).type_dets(j) = sum(pb(detID == j, i)) / (nmatch + eps);
        end
    end   

    save(file, 'clusters', 'stats');
end

function [clusters stats] = hardEncoding(params, tmpdir, vids)
    file = fullfile(tmpdir, sprintf('bop_%d_%d.mat', params.KP, length(vids)));
    if exist(file, 'file')
        fprintf('Pose clustering loaded from %s\n', file);
        stats = []; % compatibility with older version
        load(file, 'clusters', 'stats'); 
        return;
    end
    
    fprintf('Clustering...\n');
    
    [joints detID] = extract_features(params, vids, 100000);    
    nposes = size(joints, 1);
    joints = joints';
    
    % Compute Kmeans
    obj = Inf;
    for i = 1 : 5 
        [thisclusters, ~, thisobj] = kmeansmex(joints, params.KP, 10);
        fprintf('Iter %d: obj = %g\n', i, thisobj);
        if thisobj < obj
            obj = thisobj;
            clusters = thisclusters;
        end
    end
    
    clusters = double(clusters');
    joints = joints';

    % Assign examples
    [~, assign] = min(dist2(joints, clusters), [], 2); 

    stats = struct('freq_assign', cell(params.KP, 1), 'type_dets', []);
    for i = 1 : params.KP
        I = detID(assign == i);
        nmatch = length(I);
        stats(i).freq_assign = nmatch / nposes;
        stats(i).type_dets = zeros(1, 3);
        for j = 1 : 3
            stats(i).type_dets(j) = length(find(I == j)) / nmatch;
        end
    end        

    save(file, 'clusters', 'stats');
end

function [joints detID] = extract_features(params, vids, maxi)
    cleanbb = cell(1, length(vids));
    for i = 1 : length(vids)
        cleanbb{i} = perframe_nms(params, load_poses(params, vids{i}));
        cleanbb{i} = cat(1, cleanbb{i}{:});
    end
    cleanbb = cat(1, cleanbb{:});        
    joints = get_joints(cleanbb);
    detID = cleanbb(:, end - 1);
    
    if size(joints, 3) > maxi
        p = randperm(size(joints, 3));
        joints = joints(:, :, p(1 : maxi));
        detID = detID(p(1 : maxi));
    end

    joints = single(normalize_poses(joints));  
end
