function ssem_compile()
    currdir = cd();    
    root = fileparts(fileparts(mfilename('fullpath')));
    
    cd(fullfile(root, '3rdparty', 'segment'));
    segment_compile();
    
    cd(fullfile(root, '3rdparty', 'pose_detector'));
    posedet_compile();
    
    cd(fullfile(root, '3rdparty', 'nbest_release'));
    compile();

    if ~exist('train', 'file')    
	    cd(fullfile(root, '3rdparty', 'liblinear-1.91', 'matlab'));
	    make();
    end

    if ~exist('kmeansmex', 'file')
        cd(fullfile(root, '3rdparty', 'kmeans'));    
        mex -o kmeansmex -DMEXFILE=1 -largeArrayDims kmeans.cpp
    end
    
    if ~exist('fast_load_labels', 'file')
        cd(fullfile(root, 'private'));        
        mex -largeArrayDims box2seg.c 
        mex -largeArrayDims fast_load_labels.c
    end
    
    cd(currdir);	
end
