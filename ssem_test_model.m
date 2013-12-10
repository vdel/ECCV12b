function score = ssem_test_model(params, tmpdir, vid, model, bof, bop)        
    file = fullfile(tmpdir, sprintf('score_%s_%s.mat', vid, params.annots.name));
    if exist(file, 'file')
        fprintf('Loading test scores from %s\n', file);
        load(file, 'score');
        return;
    end                                              

    dataSP = compute_hist(params, tmpdir, vid, model(1).meanstd, bof, bop);    
    segments = dataSP.segments;
    segblocks = dataSP.segblocks;

    % Normalize & Hellinger
    dataSP.h = sqrt(bsxfun(@rdivide, dataSP.h, eps + sum(dataSP.h, 2)));

    % Classify pixels
    nseg = size(dataSP.h, 1);
    nlabels = length(params.annots.labels);  
    scores = cell(1, length(model));
    for m = 1 : length(model)
        tmpscores = zeros(nseg, nlabels);
        for i = 1 : nlabels
            tmpscores(:, i) = test_binary_svm_helper(model(m).svm{i}, dataSP.h);
        end

        if ~isempty(model(m).weightsN)
            tmpscores = exp([ones(size(tmpscores, 1), 1), tmpscores] * model(m).weightsN);
            for i = 1 : length(params.annots.normGroups) 
                I = params.annots.normGroups{i};
                tmpscores(:, I) = tmpscores(:, I) ./ repmat(1 + sum(tmpscores(:, I), 2), 1, length(I));            
            end        
        end
        scores{m} = tmpscores;        
    end    
    scores = mean(cat(3, scores{m}), 3);    

    % Produce confidence map        
    back = ssem_load_back(params, vid);
    if size(back, 2) > params.segimwidth
        scale = params.segimwidth / size(back, 2);
        back = imresize(back, [round(size(back, 1) * scale) params.segimwidth]);
    end    
    [h, w, d] = size(back);
    nlabels = length(params.annots.labels);
    score = zeros([h, w, nlabels, length(segments)]);
    for k = 1 : length(segments)
        for j = 1 : nlabels
            scoremap = zeros(h, w);
            for i = 1 : length(segblocks{k})
                s = imresize(segments{k}, [h, w], 'nearest');
                scoremap(s == i) = scores(segblocks{k}(i), j);                    
            end                
            score(:, :, j, k) = scoremap;
        end
    end
    
    % Take pixel-wise mean between the different segmentations
    score = mean(score, 4);

    % Show results
    annot = ssem_load_annots(params, {vid});
    annot = ssem_unpack_annot(annot{1});
    inferred_labels = cell(1, length(params.annots.visuGroups));    
    for k = 1 : length(params.annots.visuGroups)           
        % Show results
        figure(k);
        
        subplot(2, 2, 1);
        back(back < 0) = 0;
        back(back > 1) = 1;
        imagesc(back);
        axis equal off;
        title('Background image');

        subplot(2, 2, 2);    
        imagesc(ssem_scores2img(params, annot, k));
        axis equal off;
        title('Ground truth');
        
        subplot(2, 2, 3);
        [img proba] = ssem_scores2img(params, score, k);
        imwrite(img, fullfile(tmpdir, sprintf('softseg_%s_%s_%s.jpg', vid, params.annots.name, params.annots.visuGroups(k).name)));
        imagesc(img);        
        axis equal off;   
        title('Soft segmentation');                

        subplot(2, 2, 4);              
        img = ssem_scores2img(params, score, k, true);
        imwrite(img, fullfile(tmpdir, sprintf('hardseg_%s_%s_%s.jpg', vid, params.annots.name, params.annots.visuGroups(k).name)));
        imagesc(img);
        axis equal off;
        title('Hard segmentation');
    end
    
    pause(0.1);

    % Save results
    save(file, 'params', 'score', 'inferred_labels'); 
end
