function [cleanbb detIDScores negbb] = load_poses(params, vid)
    load(fullfile(params.root, 'tmp', vid.id, sprintf('%s_cleanbb.mat', params.detector_prefix)), 'cleanbb', 'negbb', 'detIDScores');      
end
