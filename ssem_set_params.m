function params = ssem_set_params(root)
    params = ssem_set_params_sub(root);
           
    % Appearance features
    params.featimwidth = 600;                                              % Background resized to this value for computing features
    params.KA = 1024;                                                      % Number of visual words
    params.s  = [4 8 16 32];                                               % patch size for visual word extraction
    params.featHardAssign = 1;                                             % Hard assignement (K-means) or soft assignment (GMM)
    
    % Pose features
    detector_type = 1;                                                     % detector type:
                                                                           % 1 (very slow) : 3 separately train models for standing, reaching, sitting
                                                                           % 2 (slow)      : one single model for standing, reaching, sitting 
                                                                           % 3 (faster)    : same as 2 without background substraction and high precision 
    detector_prefix = {'separate' 'combined' 'fastest'};
    detector_model = {{'STANDING_final' 'SITTING_final' 'REACHING_final'} {'COMBINED_final'} {'COMBINED_final'}};
    detector_det_th    = [Inf Inf Inf];
    detector_resize_to = [600 600 300];
    params.detector_prefix = detector_prefix{detector_type};               % pose estimation output prefix
    params.detector_model = detector_model{detector_type};                 % pose estimation models to load    
    params.det_th = detector_det_th(detector_type);                        % minimum allowed score for pose detection     
    params.resize_to = detector_resize_to(detector_type);                  % maximum image size, resize if larger    
    params.nms_pose = 0.5;                                                 % nms threshold for the pose detector
    params.nms_bb   = 0.3;                                                 % nms threshold for person bounding boxes
    params.KP = 32;
    params.poseHardAssign = 1;                                             % Hard assignement (K-means) or soft assignment (GMM)
    params.bbResizeFactor = 2;                                             % resize part boxes returned by pose detector
    
    % Localization features
    params.KL = [10 10];                                                   % Number of location bins: nX nY
    
    % Superpixel parameters
    params.segimwidth = 400;                                               % Background resized to this value for computing super pixels
    params.sigma_k_min = [0.3 0.2; ...                                     % different sigma, k and min parameters
                           80  80; ...
                          600 600];  
                      
    % Miscellaneous  
    params.jointnames = {'TopHead', 'Neck' 'RShoulder' 'RArm1' 'RArm2' 'RArm3' 'RArm4' 'RTorsoUp' 'RTorsoMiddle' 'RTorsoDown' 'RLeg1' 'RLeg2' 'RLeg3' 'RLeg4' 'LShoulder' 'LArm1' 'LArm2' 'LArm3' 'LArm4' 'LTorsoUp' 'LTorsoMiddle' 'LTorsoDown' 'LLeg1' 'LLeg2' 'LLeg3' 'LLeg4'}; % name of the body parts
    params.joints_to_annot = [14 12 10 22 24 26 7 5 3 15 17 19 2 1];       % ID of the joints corresponding to person annotation
    params.epsilon = 0.3;                                                  % the height of the person has to be within (1+/-epsilon) of the estimated height
    params.ALP = logical([1 0 1]);                                         % Feature activated: A (appearance), L (localization), P (person)
    params.Pfeat = logical([0 0 1 0]);                                     % Person feature on: jointpos, jointreg, jointgrid, persongrid
    params.person_grid = [10 10];                                          % number of bins for persongrid (see Pfeat): nX nY
    params.bias = true;                                                    % Biased SVM or not
    params.rescore = true;                                                 % Rescore SVMs output    
end
