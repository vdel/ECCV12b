function [avgperf perfstr] = ssem_display_perf(params, perf)
%   avgperf = ssem_display_perf(params, perf): Displays a summary of the 
%   performance obtained via ssem_get_perf_split.

    perfstr = [];
    ngroups = length(params.annots.visuGroups);
    avgperf = zeros(1, ngroups);
    for k = 1 : ngroups
        str = sprintf('\n--== %s ==--\n', params.annots.visuGroups(k).name);
        perfstr = [perfstr str];
        nlabels = length(params.annots.visuGroups(k).foregnd);
        
        p = cat(1, perf{:, k});
        meanperf = mean(p, 1);
        stdperf  = std (p, 1, 1);
        l = cell(1, nlabels);
        maxlen = 0;
        for j = 1 : nlabels
            I = params.annots.visuGroups(k).foregnd{j};
            if length(I) == 1
                l{j} = params.annots.labels{I};
            else
                l{j} = params.annots.labels{I(1)};
                for n = 2 : length(I)
                    l{j} = [l{j} '/' params.annots.labels{I(n)}];
                end
            end
            maxlen = max(maxlen, length(l{j}));
        end        
        for j = 1 : nlabels           
            str = sprintf('%s:%s %4.1f%%%% +/- %4.1f%%%%\n', l{j}, repmat(' ', 1, maxlen - length(l{j})), meanperf(j), stdperf(j));
            perfstr = [perfstr str];            
        end        
        avgperf(k) = mean(mean(p, 2));
        str = sprintf('---------\nMean:%s %4.1f%%%% +/- %4.1f%%%%\n', repmat(' ', 1, maxlen - 4), avgperf(k), std(mean(p, 2))); 
        perfstr = [perfstr str];            
    end
    fprintf(perfstr);
end