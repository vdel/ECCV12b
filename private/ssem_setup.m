function ssem_setup()     
    root = fileparts(fileparts(mfilename('fullpath')));     
    
    addpath(fullfile(root, '3rdparty', 'APT')); 
    addpath(fullfile(root, '3rdparty', 'dense_sift')); 
    addpath(fullfile(root, '3rdparty', 'kmeans'));
    addpath(fullfile(root, '3rdparty', 'liblinear-1.91', 'matlab'));
    addpath(fullfile(root, '3rdparty', 'pose_detector')); 
    addpath(fullfile(root, '3rdparty', 'nbest_release')); 
    addpath(fullfile(root, '3rdparty', 'RANSAC')); 
    addpath(fullfile(root, '3rdparty', 'segment')); 
    addpath(fullfile(root, 'detectors')); 
    RANSAC_SetPathLocal(fullfile(root, '3rdparty', 'RANSAC'));
    
    APT_params();
    
    ssem_compile();
end
