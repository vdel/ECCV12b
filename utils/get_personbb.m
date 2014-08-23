function personbb = get_personbb(bb)
    compo_score = bb(:, (end-1):end);    
    bb = reshape(bb(:, 1:(end-2))', [4, (size(bb, 2)-2) / 4, size(bb, 1)]);
    bb = cat(1, min(bb(1:2, :, :), [], 2), max(bb(3:4, :, :), [], 2));
    personbb = [reshape(bb, 4, size(bb, 3))' compo_score];
end
