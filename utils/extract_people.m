function extract_people(params, vids)
    tmpdir = fullfile(params.root, 'tmp', vids(1).parent);        
    imgdir  = fullfile(tmpdir, 'img');
    posedir = fullfile(tmpdir, 'pose');    
    file = fullfile(posedir, sprintf('%s_done', params.detector_prefix));
    if exist(file, 'file') ~= 2        
        myprint('Extracting people... (model = %s)\n', params.detector_prefix);      
        
        [~, ~] = mkdir(posedir);
        
        selectedImg = sum(cat(1, vids(:).frames), 1) > 0;
        
        models = cell(1, length(params.detector_model));
        for i = 1 : length(params.detector_model)
            load(params.detector_model{i});
            models{i} = model;
        end

        img = dir(fullfile(imgdir, 'frame*.jpg'));        
        img = img(selectedImg);
        for j = 1 : length(img)
            img(j).path = fullfile(imgdir, img(j).name);
        end

        if 0
            for i = 1 : length(img)
                myprint('Frame %d/%d\n', i, length(img));
                ssem_run_posedetector(params, posedir, models, img(i));
            end
        else
            APT_run('ssem_run_posedetector', {params}, {posedir}, {models}, img, 'GroupBy', 10);
        end
        
        fclose(fopen(file, 'wt'));
    end
end