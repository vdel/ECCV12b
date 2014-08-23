function [Theta minsubset] = RANSAC_estimate_fun(X, s)
    minsubset = 2;
    if isempty(X)
        Theta = [];
    else
        if nargin < 2
           s = 1 : size(X, 2);
        end 
        
        if size(X, 1) == 3
            [alpha k] = fit_params2(X(1, s)', X(2, s)', X(3, 1)');    
        else        
            [alpha k] = fit_params(X(1, s)', X(2, s)');
        end
        Theta = [alpha k];    
    end
end

function [alpha k] = fit_params(H, Y)  % fit parameters by linear least square    % H = alpha * Y + k;        
    X = [Y ones(length(Y), 1)];        
    B = ((X' * X) ^ -1) * X' * H;
    alpha = B(1);
    k = B(2);  
end

function [alpha k] = fit_params2(H, Y, yh)  % fit parameters by linear least square    % H = alpha * Y + k;      with k = - alpha * yh
    Y = 1 - Y / yh;
    B = ((Y' * Y) ^ -1) * Y' * H;    
    k = B(1);  
    alpha = - k / yh;
end
