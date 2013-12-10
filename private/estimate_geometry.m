function [alpha k N] = estimate_geometry(params, cleanbb, detectorID, yh)  %% hack
    [cleanbb, personbb] = perframe_nms(params, cleanbb);       
    cleanbb = cat(1, cleanbb{:});
    personbb = cat(1, personbb{:});
           
    ID = cleanbb(:, end - 1);
    personbb = personbb(ID == detectorID, :);
    
    N = size(personbb, 1);
    if N < 5
        alpha = NaN;
        k = NaN;
        return;
    end
  
    Y = personbb(:, 4);
    H = personbb(:, 4) - personbb(:, 2) + 1;
    
    if nargin >= 4
        X = [H Y (yh * ones(size(H, 1), 1))]';
    else
        X = [H Y]';
    end
    
    results = RANSAC(X, struct(...
        'sigma', 1.5, ...
        'T_noise_squared', params.epsilon .^ 2 / 16, ...
        'validateMSS_fun', @RANSAC_validateMSS_fun, ...
        'validateTheta_fun', @RANSAC_validateTheta_fun, ...
        'est_fun', @RANSAC_estimate_fun, ...
        'man_fun', @RANSAC_man_fun, ...
        'min_iters', 2000, ...
        'max_iters', 20000, ...
        'mode', 'RANSAC', ...
        'reestimate', 1, ...
        'verbose', 1));
      
    alpha = results.Theta(1);
    k = results.Theta(2);
end
