function ssem_run_posedetector(params, posedir, models, img)
    file = fullfile(posedir, sprintf('%s_%s.mat', params.detector_prefix, img.name));
    if exist(file, 'file') == 2
        return;
    end    
    
    im = double(imread(img.path));
    
    s = max(size(im, 1), size(im, 2));
    
    if s > params.resize_to
        scale = params.resize_to / s;
        im = imresize(im, scale);
    end
        
    boxes = cell(1, length(models));
    for i = 1 : length(models)    
        myprint('Model %d/%d\n', i, length(models));
        det_th = min(params.det_th, models{i}.thresh);
        bb = detect_MM(im, models{i}, det_th, 1 : 26);

        if s > params.resize_to
            bb(:, 1:(end-2)) = bb(:, 1:(end-2)) / scale;
        end
        
        if ~isempty(bb)
            pick = nms_pose(bb, params.nms_pose);        
            bb = bb(pick, :);
            bb(:, end-1) = i;
        end
        
        boxes{i} = bb;
    end
    
    bb = cat(1, boxes{:});
    save(file, 'bb');
end