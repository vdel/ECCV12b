function svm = train_binary_svm_helper(X, Y, C, J, G, bias, L)   %one example per line
    if ~exist('L', 'var')
        L = 2;
    end
    if 0
        if 0
            %%% LibSVM
            if ~bias
                myprintf('(WARNING: Biased SVM only.)\n');
            end
            if L == 1
                myprintf('(WARNING: L2 SVM only.)\n');
            end
            % X can be double or sparse
            if exist('G', 'var') && ~isempty(G) % RBF
                svm = svmtrain(double(Y), sparse(X), sprintf('-c %g -w1 %g -t 2 -g %g -q', C, J, G)); 
            else % Linear
                svm = svmtrain(double(Y), sparse(X), sprintf('-c %g -w1 %g -t 0 -q', C, J)); 
            end            
            if svm.Label(1) ~= 1
                svm.sv_coef = -svm.sv_coef;
                svm.rho = -svm.rho;
            end                    
            svm.type = 2;   
            if ~exist('G', 'var') || isempty(G)
                svm.myw = (svm.sv_coef' * svm.SVs)';
                if bias                
                    svm.mybias = -svm.rho;
                else
                    svm.mybias = 0;
                end
            end
        else
            %%% SVM-Light  
            if L == 1
                myprintf('(WARNING: L2 SVM only.)\n');
            end
            if exist('G', 'var') && ~isempty(G)  % RBF
                svm = svmlearn(double(full(X)), double(Y) * 2 - 1, sprintf('-c %g -j %g -t 2 -g %g -b %d -v 0', C, J, G, bias));            
            else % Linear
                svm = svmlearn(double(full(X)), double(Y) * 2 - 1, sprintf('-c %g -j %g -t 0 -b %d -v 0', C, J, bias));                
            end
            svm.type = 1;    
            if ~exist('G', 'var') || isempty(G)
                svm.myw = (svm.a' * X)';
                if bias                
                    svm.mybias = svm.b;
                else
                    svm.mybias = 0;
                end
            end
        end
    else
        %%% Liblinear        
        if L == 1
            type = 5;
        elseif L == 2
            type = 3;
        else            
            myprintf('(WARNING: L1 or L2 SVM only.)\n');
        end
        if exist('G', 'var') && ~isempty(G) % RBF
            fprintf('(WARNING: Linear SVM only.)\n');
        end
        if bias
            strbias = '-B 100';
        else
            strbias = '';
        end        
        svm = train(double(Y), sparse(X), sprintf('-s %d -c %g -w1 %g %s -q', type, C, J, strbias));  
        if svm.Label(1) ~= 1
            svm.w = -svm.w;
        end    
        svm.type = 3;        
        if bias
            svm.myw = svm.w(1 : (end - 1))';
            svm.mybias = svm.w(end) * svm.bias;
        else
            svm.myw = svm.w';
            svm.mybias = 0;
        end
    end
end

