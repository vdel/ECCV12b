function ssem_process_vid(params, vid)     
    fprintf('Processing %s...\n', vid);
                 
    % Loading splits
    load(fullfile(params.root, 'annots', 'splits', [vid '.mat']), 'vids');
    
    for i = 1 : length(vids)
        if length(vids) > 1
            fprintf('Processing split %s...\n', vids(i).name);
        end
    
        directory = fullfile(params.root, 'tmp', vids(i).name);        
        if ~isdir(directory)
            [~, ~] = mkdir(directory);
        end
        
        % Compute visual features
        file = sprintf('featSIFT_%s.mat', sprintf('%d%s', params.s(1), sprintf('_%d', params.s(2:end)))); 
        if ~exist(fullfile(directory, file), 'file')
            fprintf('Computing visual features...\n');
            compute_features(params, vids(i).name);
        end
    
        % Extract superpixels
        if ~exist(fullfile(directory, 'segments.mat'), 'file')
            fprintf('Computing super-pixels...\n');
            segment_back(params, vids(i).name);
        end      

        % Extract confident poses
        if ~exist(fullfile(directory, sprintf('%s_cleanbb.mat', params.detector_prefix)), 'file')
            compute_confident_poses(params, vids(i));
        end       
    end
end