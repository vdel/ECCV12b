function [horizonY h] = get_horizon(params, vid)
    backdir = fullfile(params.root, 'annots', 'back');
    outdir = fullfile(params.root, 'tmp', vid);
    
    [VP P All_lines] = getVP(backdir, [vid '.jpg'], 0, outdir);
    
    if numel(VP)<6
        error('VP estimation failed');
    end
    
    img = imread(fullfile(backdir, [vid '.jpg']));
    [h w ~]=size(img);

    VP=[VP(1) VP(2);VP(3) VP(4);VP(5) VP(6)];
    [VP P]=ordervp(VP,h,w,P);
        
    V = VP(2, :) - VP(3, :);
    if norm(V) < max(size(img, 1), size(img, 2)) / 2 % bad configuration, just take the mean.
        horizonY = mean(VP([2:3], 2));
    else    
        horizonY = VP(3, 2) + V(2) / V(1) * (w /2 - VP(3, 1));
    end
    
    j = round(horizonY) + (-2:2);
    if min(j) <= 0
        img = cat(1, zeros(1-min(j), w, 3), img);
        h = h + 1 - min(j);
    end
    img(j, :, 1) = 255;
    img(j, :, 2:3) = 0;
    
%     %plot(VP(3, 1), VP(3, 2), 'o', 'MarkerEdgeColor','r', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
%     hold on;    
%     imagesc(img);     
%     %plot(VP(3, 1), VP(3, 2), 'o', 'MarkerEdgeColor','r', 'MarkerFaceColor', 'r', 'MarkerSize', 10);    
%     %plot(VP(2, 1), VP(2, 2), 'o', 'MarkerEdgeColor','g', 'MarkerFaceColor', 'g', 'MarkerSize', 10);    
%     %plot(VP(1, 1), VP(1, 2), 'o', 'MarkerEdgeColor','b', 'MarkerFaceColor', 'b', 'MarkerSize', 10);    
%     axis equal ij;    
%     hold off;
%     pause
    
    imwrite(img, fullfile(outdir, 'horizon.jpg'));
    save(fullfile(outdir, 'horizon.mat'), 'VP', 'P', 'All_lines', 'horizonY', 'h');
end