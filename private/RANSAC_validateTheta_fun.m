function flag = RANSAC_validateTheta_fun(X, Theta, s)
    % alpha should be positive
    flag = (Theta(1) > 0);  
end
