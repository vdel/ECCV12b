function model = bagOfFeatures(params, tmpdir, vids)   
    if params.featHardAssign
        model = hardEncoding(params, tmpdir, vids);
    else
        model = softEncoding(params, tmpdir, vids);
    end
end

function gmm = softEncoding(params, tmpdir, vids)
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
    
    file = fullfile(tmpdir, sprintf('gmmof_%d_%s_%d_%d%s%s%s.mat', params.KA, sprintf('%d%s', params.s(1), sprintf('_%d', params.s(2:end))), length(vids), nEx, kmext, diagext, shareext));
    
    if exist(file, 'file') == 2
        fprintf('Loading GMM from %s\n', file);
        load(file, 'gmm');
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
    
    feat = extract_features(params, vids, min(nEx, params.KA * 50));
        
    gmm = gmmTrain(feat, params.KA, start);
    
    save(file, 'gmm');
end

function bof = hardEncoding(params, tmpdir, vids)
    global APT_PARAMS;
    
    file = fullfile(tmpdir, sprintf('bof_%d_%s_%d.mat', params.KA, sprintf('%d%s', params.s(1), sprintf('_%d', params.s(2:end))), length(vids)));

    if exist(file, 'file') == 2
        fprintf('Loading bag-of-features from %s\n', file);
        load(file, 'bof');
        return;
    end
    
    feat = extract_features(params, vids, 100000)';
    
    bof = bestKMeans(feat, params.KA, 10, 0)';
%     
%     try        
%         fprintf('Trying to launch kmeans in parallel...\n');
%         if APT_PARAMS.force_local
%             error('local only');
%         end
%         [bof, ~, obj] = APT_run('kmeansmex', {feat}, params.KA * ones(5, 1), {1000}, 'KeepTmp', 1);
%         obj = cat(1, obj{:});
%         [~, i] = min(obj);
%         bof = double(bof{i}');
%     catch
%         fprintf('Failed: launching on local...\n');
%         obj = Inf;
%         for i = 1 : 5
%             fprintf('Iter %d\n', i);
%             [thisbof, ~, thisobj] = kmeansmex(feat, params.KA, 1000);
%             fprintf('Iter %d: obj = %g\n', i, thisobj);
%             if thisobj < obj
%                 obj = thisobj;
%                 bof = double(thisbof');
%             end
%         end
%     end
    
    save(file, 'bof');
end

function feat = extract_features(params, vids, maxi)
    fprintf('Extracting features from %d videos...\n', length(vids));
    feat = cell(1, length(vids));
    for i = 1 : length(vids)
        backfile = fullfile(params.root, 'annots', 'back', [vids{i} '.jpg']);
        img = double(imread(backfile));
        if size(img, 2) > params.resize_to
            img = imresize(img, params.resize_to / size(img, 2));
        end
        feat{i} = cell(1, length(params.s));
        for j = 1 : length(params.s)
            f = features(img, params.s(j));           
            feat{i}{j} = reshape(f, size(f, 1) * size(f, 2), size(f, 3));
        end
        feat{i} = cat(1, feat{i}{:});
    end
    feat = single(cat(1, feat{:}));    
        
    if size(feat, 1) > maxi
        p = randperm(size(feat, 1));
        feat = feat(p(1 : maxi), :);
    end
end
