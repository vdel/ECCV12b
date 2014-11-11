function [cleanbb detIDScores negbb] = load_poses(params, vid)
    load(fullfile(params.root, 'tmp', vid, sprintf('%s_cleanbb.mat', params.detector_prefix)), 'cleanbb', 'negbb', 'detIDScores');      
    
    th = params.det_th;
    for i = 1 : length(cleanbb)
        if ~isempty(cleanbb{i})
            scoreMin = th(cleanbb{i}(:, end - 1))';
            cleanbb{i} = cleanbb{i}(cleanbb{i}(:, end) >= scoreMin, :);
        else
            cleanbb{i} = [];  % get rid of the 0xn matrices
        end
    end
end
