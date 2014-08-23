function [E T_noise_squared d] = RANSAC_man_fun(Theta, X, sigma, P_inlier)

    % compute the squared error
    E = [];
    if ~isempty(Theta) && ~isempty(X)
        
        D = (X(1, :) - (Theta(1) * X(2, :) + Theta(2))) ./ X(1, :);
        
        E = D .^2;

    end;
    
    % compute the error threshold
    if (nargout > 1)
        d = 2;
        if (isempty(P_inlier) || P_inlier == 0)
            T_noise_squared = sigma;
        else
            % Assumes the errors are normally distributed. Hence the sum of
            % their squares is Chi distributed (with 2 DOF since we are 
            % computing the distance of a 2D point to a line)
            d = 2;

            % compute the inverse probability
            T_noise_squared = sigma^2 * chi2inv_LUT(P_inlier, d);

        end;    
    end;
end
