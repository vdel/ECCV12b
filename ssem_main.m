function avgperf = ssem_main(root, prefix)    
    if nargin < 2
        prefix = 'final';
    end
    
    % Set up path & compile
    ssem_setup();

    % Set parameters
    addpath(fullfile(root, 'utils'));
    params = ssem_set_params(root);   
    
    % Check for DB
    try
        splits = ssem_load_splits(params);
    catch E
        error('Please download the database using the code provided in http://www.di.ens.fr/willow/research/scenesemantics/database.zip.');
    end
        
    % Propose to copy pre-computed poses
    if strcmp(params.detector_prefix, 'separate') 
        % Check if all poses were extracted
        vids = ssem_split_videos(params, ssem_load_videos(params));
        ok = 1;
        for i = 1 : length(vids)
            if ~exist(fullfile(params.root, 'tmp', vids{i}, 'separate_cleanbb.mat'), 'file')
                ok = 0;
                break;
            end
        end
        if ~ok % Propose to copy        
            while (1)
                a = input('Pose extraction can take several weeks on a single machine.\nYou may accelerate pose detection by using one single model on smaller images.\nTo do this set ''detector_type = 3;'' in "ssem_set_params.m".\nYou can also use the pre-computed confident poses for ''detector_type = 1;''.\nDo you want to copy the pre-computed poses in the database? [y]/n\n', 's');
                if strcmpi(a, 'y')
                    d = fileparts(mfilename('fullpath'));
                    copyfile(fullfile(d, 'DB'), root);
                    break;
                elseif strcmpi(a, 'n')
                    break;
                else
                    fprintf('Unknown choice. Please type ''y'' for yes or ''n'' for no.\n');
                end
            end
        end
    end
       
    % Compute SIFTs, super-pixels, clean poses for each video
    vids = ssem_load_videos(params);     
    for i = 1 : length(vids)
        ssem_process_vid(params, vids{i});
    end      
            
    % Memory warning
    if (~params.featHardAssign && params.ALP(1)) || (~params.poseHardAssign && params.ALP(3))
        warning('Soft assignement is enabled and can take up to 25Gb of RAM. Consider using hard assignement if you want to use less memory (see ssem_set_params.m).'); 
    end
    
    % Create temporary directory
    tmpdir = fullfile(params.root, 'results', prefix);
    [s,m] = mkdir(tmpdir);        
    fid = fopen(fullfile(tmpdir, 'perf.txt'), 'wt');
    
    % Train and test for each split
    [splits freqLabels] = ssem_load_splits(params);
    
    nsplits = length(splits);
    ngroups = length(params.annots.visuGroups);
    perf = cell(nsplits, ngroups);
    for i = 1 : length(splits)                
        fprintf('Testing on split %d:\n', i);
        
        % Create temporary directory for split i
        splitdir = fullfile(tmpdir, sprintf('split%i', i));
        [s,m] = mkdir(splitdir);

        % Leave one out setting: test on i^th split, train on the rest
        I = 1 : nsplits;
        I(i) = [];
               
        % Train a model on features extracted from videos of the split                 
        [model bof bop] = ssem_train_model(params, splitdir, splits(I), freqLabels(I, :));
        
        % Compute pixel-wise score for each labels
        nvids = length(splits{i});
        scores = cell(1, nvids);
        for j = 1 : nvids
            fprintf('Testing on video %d/%d...\n', j, nvids);
            scores{j} = ssem_test_model(params, splitdir, splits{i}{j}, model, bof, bop);    
        end
        
        % Compute performance
        perf(i, :) = ssem_get_perf_split(params, splits{i}, scores);                
        printMsg(fid, sprintf(' Performance for split %d ', i));        
        [~, perfstr] = ssem_display_perf(params, perf(i, :));        
        fprintf(fid, perfstr);
    end
    
    % Display performances
    printMsg(fid, 'Final overall performance');
    [avgperf, perfstr] = ssem_display_perf(params, perf);
    fprintf(fid, perfstr);
    fclose(fid);
end

function printMsg(fid, msg)
    str = '\n';
    str = [str sprintf('*******************************\n')];
    str = [str sprintf('**                           **\n')];
    str = [str sprintf('** %s **\n', msg)];
    str = [str sprintf('**                           **\n')];
    str = [str sprintf('*******************************\n\n')];
    fprintf(str);
    fprintf(fid, str);
end
