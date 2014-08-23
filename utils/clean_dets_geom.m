function [bb neg] = clean_dets_geom(params, bb, alpha, k)
    nbb = size(bb, 1);
    select = true(nbb, 1);
    
    for i = 1 : nbb
        [h y] = get_bb_heightNpos(bb(i, :));
        hth = alpha * y + k;
        if h < hth * (1 - params.epsilon) || h > hth * (1 + params.epsilon)
            select(i) = 0;
        end
    end    
    
    neg = bb(~select, :);
    bb = bb(select, :);
end

function [height pos] = get_bb_heightNpos(bb)
    b = reshape(bb(1:(end-2)), 4, (length(bb)-2) / 4);                    
    centers = (b(1:2, :) + b(3:4, :)) / 2;
    d = dist(centers, 1, 2);
    dleg1 = dist(centers, 2, 11) + dist(centers, 11, 12) + dist(centers, 12, 13) + dist(centers, 13, 14);
    dleg2 = dist(centers, 2, 23) + dist(centers, 23, 24) + dist(centers, 24, 25) + dist(centers, 25, 26);
    height = d + max(dleg1, dleg2);
    pos = max(b(4, :));
end

function d = dist(centers, i, j)
    d = norm(centers(:, i) - centers(:, j));
end
