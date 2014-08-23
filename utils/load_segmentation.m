function [segments neighbours nbN nbS nbW nbE] = load_segmentation(img)   
    % convert color image into segment ID (starting at 1)
    if size(img, 3) == 3
        img = double(img);
        colorimg = img(:, :, 1) + 256 * (img(:, :, 2) + 256 * img(:, :, 3)) + 1;            
    else
        colorimg = double(img) + 1;
    end
    colors = unique(colorimg);
    colormap = sparse(max(colors), 1);
    colormap(colors) = 1 : length(colors);
    segments = full(colormap(colorimg));
    nsegments = size(colors, 1);
    
    % look for pixels and the border of superpixels (and their ID)
    nbN = get_nb(segments, nsegments, [segments(1, :); segments(1:(end-1), :)]);
    nbS = get_nb(segments, nsegments, [segments(2:end, :); segments(end, :)]);
    nbW = get_nb(segments, nsegments, [segments(:, 1) segments(:, 1:(end-1))]);
    nbE = get_nb(segments, nsegments, [segments(:, 2:end) segments(:, end)]);
       
    neighbours = nbN + nbS + nbW + nbE;
    
    % Somehow, numerical imprecision makes neighbours not symetric
    neighbours = (neighbours + neighbours') / 2;
end

function nb = get_nb(segments, nsegments, offsetSeg)
    border = find(segments ~= offsetSeg);
    from = segments(border);
    to = offsetSeg(border);

    nb = zeros(nsegments, nsegments);
    for k = 1 : nsegments
        borderID = to(from == k);        
        borderID = reshape(borderID, 1, length(borderID));
        
        if ~isempty(borderID)
            for n = unique(borderID)    
                nb(n, k) = length(find(borderID == n));
            end
        end
    end    
    nb = sparse(nb / size(segments, 1));
end