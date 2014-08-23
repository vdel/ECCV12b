function svm = train_binary_svm_helper(params, X, Y, C, J, G)
    if 0
        if 0
            %%% LibSVM
            if ~params.bias
                fprintf('(WARNING: Biased SVM only.) ');
            end
            % X can be double or sparse
            if exist('G', 'var') % RBF
                svm = svmtrain(double(Y), sparse(X), sprintf('-c %g -w1 %g -t 2 -g %g -q', C, J, G)); 
            else % Linear
                svm = svmtrain(double(Y), sparse(X), sprintf('-c %g -w1 %g -t 0 -q', C, J)); 
            end            
            if svm.Label(1) ~= 1
                svm.sv_coef = -svm.sv_coef;
                svm.rho = -svm.rho;
            end                    
            svm.type = 2;     
        else
            %%% SVM-Light            
            if exist('G', 'var')  % RBF
                svm = svmlearn(double(full(X)), double(Y) * 2 - 1, sprintf('-c %g -j %g -t 2 -g %g -b %d -v 0', C, J, G, params.bias));            
            else % Linear
                svm = svmlearn(double(full(X)), double(Y) * 2 - 1, sprintf('-c %g -j %g -t 0 -b %d -v 0', C, J, params.bias));                
            end
            svm.type = 1;      
        end
    else
        %%% Liblinear
        if exist('G', 'var') % RBF
            fprintf('(WARNING: Linear SVM only.) ');
        end
        if params.bias
            strbias = '-B 1';
        else
            strbias = '';
        end        
        svm = train(double(Y), sparse(X), sprintf('-s 1 -c %g -w1 %g %s -q', C, J, strbias));  
        if svm.Label(1) ~= 1
            svm.w = -svm.w;
        end    
        svm.type = 3;
    end
end

