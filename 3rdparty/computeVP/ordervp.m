%Copyright (c) October,15 2008 by Varsha Hedau, UIUC.  All rights reserved.
function [vp Pout]=ordervp(vp,h,w,Pin)
%Orders vanishing points as vertical, farther horizontal and closer
%horizontal vanishing points.
%Note this takes VP=[x1 y1; x2 y2; x3 y3 ]as input
%if P is given P is also shuffled 
if nargin < 4
Pin=[];
Pout=[];
end

% vptemp=vp;
% dists = ((vp(:,1)-w/2).^2 + (vp(:,2)-h/2).^2).^0.5;
% [vv,ii] = sort(dists,'descend');
% vp = vp(ii,:);
% dot1 = dot(vp(1,:)-[w/2,h/2],[1 0])/norm(vp(1,:)-[w/2,h/2]);
% dot2 = dot(vp(2,:)-[w/2,h/2],[1 0])/norm(vp(2,:)-[w/2,h/2]);
% if abs(dot1)>abs(dot2)
%     tempvar = vp(1,:);
%     vp(1,:) = vp(2,:);
%     vp(2,:) = tempvar;
% end
% 
% 
%         
%     
% if numel(Pin)>0
% 
% ind=find(vptemp(:,1)==vp(1,1) & vptemp(:,2)==vp(1,2));
% Pout=Pin(:,ind);
% ind=find(vptemp(:,1)==vp(2,1) & vptemp(:,2)==vp(2,2));
% Pout=[Pout Pin(:,ind)];
% ind=find(vptemp(:,1)==vp(3,1) & vptemp(:,2)==vp(3,2));
% Pout=[Pout Pin(:,ind)];
% Pout=[Pout Pin(:,4)];% 4th is outlier
% end

dX = abs(vp(:, 1) - w/2);
dY = abs(vp(:, 2) - h/2);

[~, VP1] = max(dY);  % find vertical VP

others = 1 : 3;
others(VP1) = [];
[~, i] = max(dX(others));  % find farther horizontal VP

VP2 = others(i); % i is 1 or 2
VP3 = others(3-i); % 3 - i is 2 or 1
I = [VP1 VP2 VP3 4];

vp = vp(I(1 : 3), :);
Pout = Pin(:, I);

 return
