function gmm = gmmTrain(feat, K, start) % one per row
    gmm = [];
        
    if exist('start', 'var') && ~isempty(start)
        shared = (size(start.Sigma, 3) == 1);
        if size(start.Sigma, 1) == 1
            covtype = 'diagonal';
        else
            covtype = 'full';
        end
    else
        start = 'randSample';
        covtype = 'diagonal';
        shared = true;
    end
    opt = statset('Display', 'iter');
    if exist('start', 'var') && ~isempty(start)
        gmmfit = gmdistribution.fit(feat, K, 'Regularize', 1e-6, 'Start', start, 'CovType', covtype, 'SharedCov', shared, 'Options', opt);    
        if isempty(gmm) || gmmfit.NlogL < gmm.NlogL
            gmm = gmmfit;
        end
    else
        for i = 1 : 5 
            gmmfit = gmdistribution.fit(feat, K, 'Regularize', 1e-6, 'Start', start, 'CovType', covtype, 'SharedCov', shared, 'Options', opt);    
            if isempty(gmm) || gmmfit.NlogL < gmm.NlogL
                gmm = gmmfit;
            end
        end
    end
end
