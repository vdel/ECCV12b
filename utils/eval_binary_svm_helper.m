function [ap acc] = eval_binary_svm_helper(opt, X, Y, params)
    C = params(1);
    J = params(2);
    if length(params) > 2
        G = params(3);
        myprintf('C = %.4g, J = %.4g, G = %.4g:\n', C, J, G);  
    else
        G = [];
        myprintf('C = %.4g, J = %.4g:\n', C, J);  
    end
    
    nsplits = length(X);
    ap = zeros(nsplits, 1);
    acc = zeros(nsplits, 1);
    for i = 1 : nsplits
        myprintf('--> Fold %d: ', i);
        
        I = 1 : nsplits;
        I(i) = [];
        
        x = cat(1, X{I});
        y = cat(1, Y{I});        
        svm = train_binary_svm_helper(x, y, C, J, G, opt.bias, opt.norm);
        scores = test_binary_svm_helper(svm, X{i}); 
        
        [~, ~, ap(i)] = precisionrecall(scores, Y{i});    
        acc(i) = sum((scores > 0) == Y{i}) / length(Y{i});
        myprintf('AP = %.4g, Acc = %.4g\n', ap(i) * 100, acc(i) * 100);
    end    
    ap = mean(ap);
    acc = mean(acc);
    myprintf('--> Mean AP = %.4g, Acc = %.4g\n\n', ap * 100, acc * 100);  
end