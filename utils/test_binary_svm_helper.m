function scores = test_binary_svm_helper(svm, x)
    if svm.type == 1
        [~, scores] = svmclassify(double(x), zeros(size(x, 1), 1), svm);
    elseif svm.type == 2
        [~, ~, scores] = svmpredict(zeros(size(x, 1), 1), sparse(x), svm);
    elseif svm.type == 3
        [~, ~, scores] = predict(zeros(size(x, 1), 1), sparse(x), svm);
    else
        error('Unknown type !');
    end        
end
