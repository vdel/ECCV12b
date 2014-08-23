function assign = gmmAssign(gmm, feat) % feat, assign, fishervec: --> one per row 
    assign = double(gmm.posterior(feat));
end
