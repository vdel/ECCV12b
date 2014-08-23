function flag = RANSAC_validateMSS_fun(X, s)
    flag = X(2,s(1)) ~= X(2,s(2));
    
    if flag
        if size(X, 1) == 3
            Y = 1 - X(2, s)' / X(3, 1);
            flag = abs(det(Y' * Y)) > 16 * eps;
        else
            Y = X(2, s(1))';
            X = [Y ones(length(Y), 1)];

            flag = abs(det(X' * X)) > 16 * eps;
        end
    end
end
