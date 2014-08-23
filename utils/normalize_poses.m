function joints = normalize_poses(joints)
    joints = joints - repmat(mean(joints, 2), 1, size(joints, 2));
    joints = reshape(joints, size(joints, 1) * size(joints, 2), size(joints, 3))';   
    joints = joints ./ repmat(sqrt(sum(joints .* joints, 2)), 1, size(joints, 2));
end

