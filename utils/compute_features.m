function [feat, bbs, scores] = compute_features(params, vid)
    file = fullfile(params.root, 'tmp', vid, sprintf('featSIFT_%s.mat', sprintf('%d%s', params.s(1), sprintf('_%d', params.s(2:end))))); 
    if exist(file, 'file') == 2
        if nargout > 0
            load(file, 'feat', 'bbs', 'scores');
            fprintf('Features loaded from %s\n', file);
        end
    else
        img = ssem_load_back(params, vid);        
        if size(img, 2) ~= params.featimwidth
            scale = params.featimwidth / size(img, 2);
            img = min(max(imresize(img, [(scale * size(img, 1)) params.featimwidth]), 0), 1);   
        else
            scale = 1;
        end

        feat = cell(1, length(params.s));
        bbs = cell(1, length(params.s));
        for j = 1 : length(params.s)
            [feat{j} featpos] = features(img, params.s(j));
            bbs{j} = [featpos-params.s(j) featpos+params.s(j) repmat((2 * params.s(j))^2, size(featpos, 1), 1)];
        end
        feat = cat(1, feat{:});
        bbs = round(cat(1, bbs{:}) / scale); 
        scores = bbs(:, end);
        bbs = int32(bbs(:, 1 : (end-1)))';
        save(file, 'feat', 'bbs', 'scores');        
    end
end
