function posedet_showboxes(boxes, partcolor, dobb, notext, txt, imgheight)
    % dobb:
    % 0 - stickman only
    % 1 - joints BB
    % 2 - all BB: person + joints
    % 3 - joints BB only: no stickman
    % 4 - same as 0 but with real torso form (not necessary a box)    
    
    partcolor_ref = {'g','g','y','m','m','m','m','y','y','y','r','r','r','r','y','c','c','c','c','y','y','y','b','b','b','b'};
    if nargin < 2 || isempty(partcolor)
        partcolor = partcolor_ref;
    end
    
    if size(boxes, 1) > 1 % we already have the centers
        torso = [mean([min(boxes(1, 11), boxes(1, 23)), min(boxes(1, 4), boxes(1, 16))]), ...
                 mean([boxes(2, 4), boxes(2, 16)]), ...
                 mean([max(boxes(1, 11), boxes(1, 23)), max(boxes(1, 4), boxes(1, 16))]), ...
                 mean([boxes(2, 11), boxes(2, 23)])]';
        boxes = reshape(cat(1, boxes, boxes), 1, numel(boxes) * 2);
        if nargin < 4
            notext = 1;
        end
    else
        torso = [];
        if nargin < 4
            notext = 1;
        end
    end
    if nargin < 3
        dobb = 4;
    end 
    if nargin < 5
        txt = [];
    end    
    
    if ~exist('imgheight', 'var')
        a = axis;        
        imgheight = a(4) - a(3);        
    end    
    lwidth = (max(boxes(4:4:104)) - min(boxes(2:4:104))) / imgheight * 15;        
        
    numparts = floor(size(boxes, 2)/4);
    if ~isempty(boxes) && dobb ~= 0 && dobb ~= 4
      for i = 1:numparts
        x1 = boxes(:,1+(i-1)*4);
        y1 = boxes(:,2+(i-1)*4);
        x2 = boxes(:,3+(i-1)*4);
        y2 = boxes(:,4+(i-1)*4);
        line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','color',partcolor{i},'linewidth',2);
      end
    end
    
    bb = reshape(boxes(1 : (numparts * 4)), 4, numparts);    
    centers = (bb(1:2, :) + bb(3:4, :)) / 2;

    if dobb ~= 4
        I = strcmp(partcolor_ref, 'y');
        if isempty(torso)
            torso = [min(bb(1:2, I), [], 2); max(bb(3:4, I), [], 2)];
            torso_w = torso(3) - torso(1) + 1;
            torso_h = torso(4) - torso(2) + 1;
            torso = torso + ([torso_w torso_h torso_w torso_h] .* [0.1 0.1 -0.1 -0.1])';         
        end       
        c = (torso(1:2) + torso(3:4)) / 2;              
        draw_bb((torso - [c; c]) * 0.8 + [c; c], partcolor{find(I, 1, 'last')}, floor(lwidth * 0.7));
    else
        draw_line([centers(1, 2), centers(1, 3), centers(1, 8), ...
              centers(1, 9), centers(1, 10), centers(1, 22), ...
              centers(1, 21), centers(1, 20), centers(1, 15), centers(1, 2), centers(1, 3)], ...
             [centers(2, 2), centers(2, 3), centers(2, 8), ...
              centers(2, 9), centers(2, 10), centers(2, 22), ...
              centers(2, 21), centers(2, 20), centers(2, 15), centers(2, 2), centers(2, 3)], ... 
             'y', lwidth, 'none', lwidth/10);
    end
    
    if dobb == 3
        return;
    end           
       
    if dobb ~= 3
        I = find(strcmp(partcolor_ref, 'g'));
        I = [I I(end:-1:1) I];        
        draw_line(centers(1, I), centers(2, I), partcolor{I(end)}, lwidth, '.', lwidth/10);    
        I = find(strcmp(partcolor_ref, 'm'));
        I = [3 I];
        I = I(1 : 2 : end); % J14
        I = [I I(end:-1:1) I];
        draw_line(centers(1, I), centers(2, I), partcolor{I(end)}, lwidth, '.', lwidth/10);        
        I = find(strcmp(partcolor_ref, 'r'));
        I = [10 I];
        I = I(1 : 2 : end); % J14
        I = [I I(end:-1:1) I];
        draw_line(centers(1, I), centers(2, I), partcolor{I(end)}, lwidth, '.', lwidth/10);
        I = find(strcmp(partcolor_ref, 'c'));
        I = [15 I];
        I = I(1 : 2 : end); % J14
        I = [I I(end:-1:1) I];
        draw_line(centers(1, I), centers(2, I), partcolor{I(end)}, lwidth, '.', lwidth/10);    
        I = find(strcmp(partcolor_ref, 'b'));
        I = [22 I];
        I = I(1 : 2 : end); % J14
        I = [I I(end:-1:1) I];
        draw_line(centers(1, I), centers(2, I), partcolor{I(end)}, lwidth, '.', lwidth/10);  
    end

    x1 = min(boxes(:,1+((1:numparts)-1)*4));
    y1 = min(boxes(:,2+((1:numparts)-1)*4));
    x2 = max(boxes(:,3+((1:numparts)-1)*4));
    y2 = max(boxes(:,4+((1:numparts)-1)*4));
    
    if dobb == 2
        line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','color', [0.99, 0.99, 0.99], 'linewidth', 4);
    end

    if ~notext
        if isempty(txt)
            txt = sprintf('%d | %.03f', boxes(end-1), boxes(end));
        end        
        text(x1, y1, txt, 'HorizontalAlign', 'Left', 'VerticalAlign', 'Top', 'Color', [1, 0, 0]); 
    end

    %drawnow;
end

function draw_bb(bb, c, w)
  x1 = bb(1);
  y1 = bb(2);
  x2 = bb(3);
  y2 = bb(4);
  draw_line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]', c, w, '.', w/10);
end

function draw_line(X, Y, c, w, m, ms)
    if w <= 0
        w = 1;
    end
    if ms <= 0
        ms = w / 10;
    end
%     line(X, Y, 'color', [0 0 0], 'linewidth', w+max(1, 0.2*w), 'Marker', max(1, m), 'MarkerSize', max(1, ms));  
%     line(X, Y, 'color', c, 'linewidth', w, 'Marker', m, 'MarkerSize', ms);  
    %line(X, Y, 'color', [0 0 0], 'linewidth', w+max(1, 0.3*w));      
    line(X, Y, 'color', [0 0 0], 'linewidth', w+max(1, 0.25*w), 'Marker', m);
    line(X, Y, 'color', c, 'linewidth', w, 'Marker', m, 'MarkerSize', ms * 20, 'MarkerEdgeColor', [0, 0, 0], 'MarkerFaceColor', [0, 0, 0]);  
end
