function [bestBof assign bestObj] = bestKMeans(feat, K, nIter, local, verbose)   % one feat per column
    global APT_PARAMS;
    
    if ~exist('verbose', 'var')
        verbose = 0;
    end
    
    feat = single(feat);
    try        
        if verbose
            fprintf('Trying to launch kmeans in parallel...\n');
        end
        if nargin >= 4 && local
            error('local only');
        end
        [bestBof, ~, obj] = APT_run('kmeansmex', {feat}, K * ones(5, 1), {1000}, {verbose}, 'Verbose', verbose);
        obj = cat(1, obj{:});
        [bestObj, i] = min(obj);
        bestBof = double(bestBof{i});
    catch 
        fprintf('Failed: launching on local...\n');
        bestBof = [];
        bestObj = Inf;        
        for i = 1 : nIter
            fprintf('Iter %d\n', i);
            [thisBof, thisNIter, thisObj] = kmeansmex(feat, K, 1000, verbose);
            fprintf('Iter %d: obj = %g\n', i, thisObj);
            if thisObj < bestObj
                bestBof = double(thisBof);
                bestObj = thisObj;
            end
        end
    end

    if nargout >= 2
        [~, assign] = min(dist2(feat', bestBof'), [], 2); 
    end
end
