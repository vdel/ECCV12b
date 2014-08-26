function [models bof bop] = ssem_train_model(params, tmpdir, splits, freqLabels)      
    file = fullfile(tmpdir, sprintf('model_%s.mat', params.annots.name));     
    if exist(file, 'file') == 2
        fprintf('Model loaded from %s\n', file);
        load(file);         
    else
        model = cell(length(splits), 1);      
    end       
        
    if ~exist('models', 'var') 
        nlabels = length(params.annots.labels);         
    
        vidsIDs = cell(length(splits), 1);
        k = 0;
        for i = 1 : length(splits)
            vidsIDs{i} = k + (1 : length(splits{i}));
            k = k + length(splits{i});
        end       

        vid_list = cat(2, splits{:});
        vids = ssem_load_subvideos(params, vid_list, 1);
        fprintf('Training on %d videos\n', length(vids));         
    
        % Bag of words
        if params.ALP(1)
            bof = bagOfFeatures(params, tmpdir, vids);
        else
            bof = [];
        end        
    
        % Bag of poses
        if params.ALP(3) % do pose
            % Compute normalisation between detectors
            filemean = fullfile(tmpdir, sprintf('meanstd_%s.mat', params.annots.name));  
            if exist(filemean, 'file') == 2
                load(filemean, 'meanstd');         
            else
                scores = cell(length(vids), 1);
                for i = 1 : length(vids)
                    [~, detIDScores] = load_poses(params, vids(i).id);            
                    scores{i} = cat(1, detIDScores{:});
                end    
                scores = cat(1, scores{:});
                meanstd = zeros(2, length(params.detector_model));
                for i = 1 : length(params.detector_model)
                    meanstd(1, i) = mean(scores(scores(:, 1) == i, 2));
                    meanstd(2, i) = std (scores(scores(:, 1) == i, 2));
                end   
                save(filemean, 'meanstd');
            end  
        
            bop = bagOfPoses(params, tmpdir, vids);
        else
            meanstd = [];
            bop = [];            
        end          
    
        % Computes histogram for each superpixel   
        annots = ssem_load_annots(params, vid_list);
        dataSP = cell(length(vids), 1);
        labels = cell(length(vids), 1);
        for n = 1 : length(vids)
            [dataSP{n}, labels{n}, blocks] = compute_hist(params, tmpdir, vids(n), meanstd, bof, bop, annots{n});    
        end 
        dataSP = cat(1, dataSP{:});
        labels = cat(1, labels{:});
        
        % Normalize & Hellinger        
        for n = 1 : length(vids)
            dataSP(n).h = sqrt(bsxfun(@rdivide, dataSP(n).h, eps + sum(dataSP(n).h, 2)));
        end
        
        % Remember video IDs before concatenation
        featVidIDs = cell(1, length(vids));     
        for i = 1 : length(vids)
            featVidIDs{i} = i * ones(size(dataSP(i).h, 1), 1);
        end
        
        featVidIDs = cat(1, featVidIDs{:});
        neighbours = {dataSP(:).neighbours};
        segblocks = {dataSP(:).segblocks};
        dataSP = cat(1, dataSP(:).h);
        labelsSplits = cat(1, labels(:).labels);       

        for s = 1 : length(splits)     
            I = 1 : length(splits);
            I(s) = [];      
            trainFeat = false(size(dataSP, 1), 1);
            trainVids = cell(1, length(splits));
            for i = I
                trainVids{i} = false(size(dataSP, 1), 1);
                for j = vidsIDs{i}
                    trainVids{i}(featVidIDs == j) = 1;                    
                end
                trainFeat = trainFeat | trainVids{i};
            end       
            trainVids(s) = [];
            fprintf('Split %d: %d videos\n', s, length([vidsIDs{I}]));                       
            
            % Cat all labels
            thisLabelsSplit = cat(1, labelsSplits(trainFeat, :));                          
            
            if isempty(model{s})                           
                svm = cell(nlabels, 1);                
                scores = zeros(size(thisLabelsSplit, 1), nlabels);
                C = zeros(1, nlabels);
                J = zeros(1, nlabels);
                G = zeros(1, nlabels);
                for i = 1 : nlabels
                    fprintf('--- Training label %d of %d.\n', i, nlabels);  
                    [C(i) J(i) G(i) svm{i} scores(:, i)] = train_svm(params, dataSP, labelsSplits(:, i) > 0.34, trainVids);
                end                 
                model{s} = struct('svm', {svm}, 'C', C, 'J', J, 'G', G, 'weightsN', [], 'CStruct', [], 'meanstd', meanstd, 'blocks', {blocks}, 'valScores', scores, 'valLabels', thisLabelsSplit > 0.34);                                
                save(file, 'params', 'bof', 'bop', 'model');
            end

            if params.rescore && isempty(model{s}.weightsN)
                % Training examples for rescoring
                nvids = length(splits{s});
                unaryTerm = cell(nvids, 1);
                l = cell(nvids, 1); 
                for v = 1 : nvids
                    unaryTerm{v} = test_svm(params, model{s}, dataSP(featVidIDs == vidsIDs{s}(v), :));  
                    unaryTerm{v}.segblocks = segblocks{vidsIDs{s}(v)};
                    unaryTerm{v}.neighbours = neighbours{vidsIDs{s}(v)};
                    l{v} = labels(vidsIDs{s}(v));
                    [~, I] = max(l{v}.labels, [], 2);
                    l{v}.labels = zeros(size(l{v}.labels));
                    nseg = size(l{v}.labels, 1);
                    l{v}.labels((I - 1) * nseg + (1 : nseg)') = 1;                       
                end
                % Validation examples for rescoring
                valScores = model{s}.valScores;
                valLabels = model{s}.valLabels;       
                
                [AP Acc] = evaluate(valScores, valLabels);
                fprintf('Raw model: AP = %.2f%%, Acc = %.2f%%\n', AP * 100, Acc * 100);                

                if params.rescore && isempty(model{s}.weightsN)  
                    fprintf('Computing rescoring matrix...\n');
                    scores = cat(1, unaryTerm{:});
                    scores = cat(1, scores(:).scores);
                    lcat = cat(1, l{:});
                    lcat = cat(1, lcat(:).labels);
                    
                    % training data on 4th split and validation scores of
                    % splits 1 to 3 (more robust)
                    scores = cat(1, scores, valScores);
                    lcat = cat(1, lcat, valLabels);
                       
                    model{s}.weightsN = zeros(nlabels + 1, nlabels);                  
                    for g = 1 : length(params.annots.normGroups)
                        I = params.annots.normGroups{g};
                        
                        if 0 % normalize by frequency
                            coeff = 1 ./ reshape(freqLabels, 1, length(freqLabels));
                            lg = lcat .* repmat(coeff / min(coeff), size(lcat, 1), 1);
                        else
                            lg = lcat;
                        end
                        lg = lg(:, I);                       
    
                        l_none = zeros(size(lg, 1), 1);
                        l_none(sum(lg, 2) == 0) = 1;
                     
                        lg = cat(2, lg, l_none);
                        lg = bsxfun(@rdivide, lg, sum(lg, 2));
                 
                        B = mnrfit(scores, lg);
                        model{s}.weightsN(:, I) = B; 
                    end
                     
                    % Rescore training examples 
                    for v = 1 : nvids
                        scores = [ones(size(unaryTerm{v}.scores, 1), 1), ...
                                   unaryTerm{v}.scores];
                        scores = exp(scores * model{s}.weightsN);
                        for g = 1 : length(params.annots.normGroups)
                            I = params.annots.normGroups{g};
                            unaryTerm{v}.scores(:, I) = scores(:, I) ./ ...
                                repmat(1 + sum(scores(:, I), 2), 1, length(I));
                         end
                    end      
                    
                    % Rescore validation examples
                    valScores = exp([ones(size(model{s}.valScores, 1), 1), model{s}.valScores] * model{s}.weightsN);
                    for g = 1 : length(params.annots.normGroups)
                        I = params.annots.normGroups{g};
                        valScores(:, I) = valScores(:, I) ./ repmat(1 + sum(valScores(:, I), 2), 1, length(I));
                    end     
                    
                    [AP Acc] = evaluate(valScores, valLabels);
                    fprintf('Rescored model: AP = %.2f%%, Acc = %.2f%%\n', AP * 100, Acc * 100);               
                end 
                                 
                save(file, 'params', 'bof', 'bop', 'model'); 
            end
        end    
        
        models = cat(1, model{:});     
                
        save(file, 'params', 'bof', 'bop', 'models');  
    end
end

function [C J G svm scores] = train_svm(params, dataSP, labels, splits)   
    trainOn_GCJ = logical([0 1 1]);    
    maxExCV = Inf;
    maxExTrain = max(Inf, maxExCV);        

    Ccoeff = 2;
    Jcoeff = 1.5;
    Gcoeff = 1.5;
    factor = 0.8;
    
    scores = cell(1, 3);
    APs = zeros(1, 3);     
        
    subsetTrain = cell(1, length(splits));
    maxExTrainPerSplit = maxExTrain / (length(splits) - 1);
    nposTrain = 0;
    nnegTrain = 0;
    for i = 1 : length(splits)        
        if length(find(splits{i})) > maxExTrainPerSplit
            pos = find(labels & splits{i});
            neg = find(~labels & splits{i});
            if length(pos) > maxExTrainPerSplit / 2                
                perm = randperm(length(pos));
                pos = pos(perm(1 : ceil(maxExTrainPerSplit / 2)));                
                perm = randperm(length(neg));
                neg = neg(perm(1 : ceil(maxExTrainPerSplit / 2))); 
            else                
                perm = randperm(length(neg));
                neg = neg(perm(1 : (maxExTrainPerSplit - length(pos))));                
            end
            subsetTrain{i} = [pos; neg];
        else
            subsetTrain{i} = find(splits{i});
        end
        nposTrain = nposTrain + length(find(labels(subsetTrain{i})));
        nnegTrain = nnegTrain + length(find(~labels(subsetTrain{i})));
    end
    
    subsetCV = cell(1, length(splits));        
    maxExCVPerSplit = maxExCV / (length(splits) - 1);
    nposCV = 0;
    nnegCV = 0;
    for i = 1 : length(splits)
        if length(subsetTrain{i}) > maxExCVPerSplit
            index = false(size(labels));
            index(subsetTrain{i}) = 1;
            pos = find(labels & index);
            neg = find(~labels & index);
            if length(pos) > maxExCVPerSplit / 2                
                perm = randperm(length(pos));
                pos = pos(perm(1 : ceil(maxExCVPerSplit / 2)));                
                perm = randperm(length(neg));
                neg = neg(perm(1 : ceil(maxExCVPerSplit / 2)));                
            else                
                perm = randperm(length(neg));
                neg = neg(perm(1 : (maxExCVPerSplit - length(pos))));                
            end
            subsetCV{i} = [pos; neg];
        else
            subsetCV{i} = subsetTrain{i};
        end
        nposCV = nposCV + length(find(labels(subsetCV{i})));
        nnegCV = nnegCV + length(find(~labels(subsetCV{i})));              
    end
        
    fprintf('CV: %d positives, %d negatives\n', nposCV, nnegCV); 
    fprintf('Train: %d positives, %d negatives\n', nposTrain, nnegTrain);    
    
    C = 0.01;
    J = length(find(~labels)) / length(find(labels));
    perm = randperm(min(1000, size(dataSP, 1)));
    nX = sum(dataSP(perm, :) .^ 2, 2);
    G = 1 / mean(mean(repmat(nX, 1, length(perm)) + repmat(nX', length(perm), 1) - 2 * dataSP(perm, :) * (dataSP(perm, :)')));
               
    trainGCJ = find(trainOn_GCJ, 1);
    lastChange = find(trainOn_GCJ, 1, 'last');  
    while 1        
        Niter = 0;
        fillID = -1;
        if trainGCJ == 1
            Ccoeffs = ones(1, 3);
            Jcoeffs = ones(1, 3);
            Gcoeffs = Gcoeff .^ (-1 : 1);   
        elseif trainGCJ == 2
            Ccoeffs = Ccoeff .^ (-1 : 1);
            Jcoeffs = ones(1, 3);
            Gcoeffs = ones(1, 3);
        else
            Ccoeffs = ones(1, 3);
            Jcoeffs = Jcoeff .^ (-1 : 1);
            Gcoeffs = ones(1, 3);                    
        end
        while 1
            if fillID == -1       
                scores{1} = [];
                scores{3} = [];
                % At first iteration we also have scores{2} == [];
                for k = 1 : 3 
                    if isempty(scores{k})
                        [APs(k) scores{k}] = cross_validate(params, dataSP, labels, subsetCV, splits, C * Ccoeffs(k), J * Jcoeffs(k), G * Gcoeffs(k));    
                    end
                end
            else
                [APs(fillID) scores{fillID}] = cross_validate(params, dataSP, labels, subsetCV, splits, C * Ccoeffs(fillID), J * Jcoeffs(fillID), G * Gcoeffs(fillID));                
            end     
            [~, fillID] = max(APs);    
            if isempty(find(APs ~= APs(fillID), 1))
                Niter = 1;
                break;
            elseif fillID == 2
                break;
            else
                if fillID == 1
                    Isrc = [1 2];
                    Idst = [2 3];                    
                else
                    Isrc = [2 3];
                    Idst = [1 2]; 
                end
                C = C * Ccoeffs(fillID);
                J = J * Jcoeffs(fillID);
                G = G * Gcoeffs(fillID);
                APs(Idst) = APs(Isrc);
                scores(Idst) = scores(Isrc);    
                Niter = Niter + 1;
            end
        end
        if Niter == 0 && lastChange == trainGCJ
            break;
        end
        if Niter > 0
            lastChange = trainGCJ;
        end
        k = find(trainOn_GCJ((trainGCJ + 1) : end), 1);
        if isempty(k)
            trainGCJ = find(trainOn_GCJ, 1);                
            Gcoeff = Gcoeff * factor;
            Ccoeff = Ccoeff * factor;
            Jcoeff = Jcoeff * factor;
            if min([Gcoeff Ccoeff Jcoeff]) < 1
                break;
            end
        else
            trainGCJ = trainGCJ + k;
        end        
    end
    scores = scores{2};
       
    fprintf('Final C = %.4g, J = %.4g, G = %.4g\n', C, J, G); 
    fprintf('Train: %d positives, %d negatives\n', nposTrain, nnegTrain);
    
    subsetTrain = cat(1, subsetTrain{:});    
    svm = train_binary_svm_helper(dataSP(subsetTrain, :), labels(subsetTrain), C, J, G, params.bias);
end

function [AP scores] = cross_validate(params, dataSP, labels, subsetCV, subsetTest, C, J, G)
    nSplits = length(subsetCV);
    AP = zeros(nSplits, 1);   
    scores = cell(nSplits, 1);
    fprintf('C = %.4g, J = %.4g, G = %.4g:\n', C, J, G);    
        
    for i = 1 : nSplits
        fprintf('--> Fold %d: ', i);
        
        I = 1 : nSplits;
        I(i) = [];
        
        subsetTrain = cat(1, subsetCV{I});    
     
        svm = train_binary_svm_helper(dataSP(subsetTrain, :), labels(subsetTrain), C, J, G, params.bias);
        
        scores{i} = test_binary_svm_helper(svm, dataSP(subsetTest{i}, :));               
        [~, ~, AP(i)] = precisionrecall(scores{i}, labels(subsetTest{i}));    
        fprintf('AP = %.4g\n', AP(i) * 100);
    end    
    AP = mean(AP);
    scores = cat(1, scores{:});
    fprintf('--> Mean AP = %.4g\n\n', AP * 100);    
end
 
function [AP Acc] = evaluate(unaryPot, labels, wB, neighbours)
    nlabels = size(unaryPot, 2);
    
    if nargin < 3
        scores = unaryPot;
    else    
        n = 0;
        scores = zeros(size(unaryPot));
        for v = 1 : length(neighbours)
            connect = full(blkdiag(neighbours{v}{:})); 
            nseg = size(connect, 1);
            I = n + (1 : nseg);  
            uweights = unaryPot(I, :);

            y = segmentation(reshape(-double(uweights), [nseg 1 nlabels]), wB, connect, 0);
            
            for i = 1 : nseg
                nb = find(connect(:, i)');
                for j = 1 : nlabels
                    sc = uweights(i, j);
                    for k = nb
                        if y(k) ~= j
                            sc = sc - wB(y(k), j) * connect(k, i);
                        end
                    end
                    scores(n + i, j) = sc;
                end
            end
            n = n + nseg;
        end
    end 
    
    AP = zeros(1, nlabels);
    for i = 1 : nlabels
        [~, ~, AP(i)] = precisionrecall(scores(:, i), labels(:, i) > 0.34);        
    end
    AP = mean(AP);
    
    [~, gt] = max(labels, [], 2);
    [~, opt] = max(scores, [], 2);
    Acc = sum(gt == opt) / size(labels, 1);
end

function scores = test_svm(params, model, dataSP)
    nlabels = length(params.annots.labels);    
    scores = zeros(size(dataSP, 1), nlabels);
    for i = 1 : nlabels
        scores(:, i) = test_binary_svm_helper(model.svm{i}, dataSP);
    end
    
    scores = struct('scores', scores);    
end
