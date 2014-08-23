function [feat featpos] = myfeatures(img, grid_spacing)
    %%%% SIFTs
    [feat, grid_x, grid_y] = dense_sift(img, grid_spacing * 2, grid_spacing);
    featpos = cat(3, grid_x, grid_y);

    %%%% Resize arrays
    feat = reshape(feat, size(feat, 1) * size(feat, 2), size(feat, 3));
    featpos = reshape(featpos, size(featpos, 1) * size(featpos, 2), size(featpos, 3));    
end
