function [cleanbb personbb] = perframe_nms(params, cleanbb)
    personbb = cell(1, length(cleanbb));
    for i = 1 : length(cleanbb)
        if isempty(cleanbb{i})
            continue;
        end
        personbb{i} = get_personbb(cleanbb{i});
        select = nms(personbb{i}, params.nms_bb);
                
        cleanbb{i} = cleanbb{i}(select, :);
        personbb{i} = personbb{i}(select, :);
    end
end
