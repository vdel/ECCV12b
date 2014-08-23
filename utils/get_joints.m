function joints = get_joints(bb)
    n_box = size(bb, 1);
    if n_box == 0
        joints = [];
    else
        n_parts = (size(bb, 2)-2) / 4;
        bb = reshape(bb(:, 1:(end-2))', [4, n_parts, n_box]);
        joints = cat(1, mean(bb([1 3],:,:), 1), mean(bb([2 4],:,:), 1)); 
    end
end