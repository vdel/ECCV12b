posedet_compile;

% load and display model
load('PARSE_final');
posedet_visualizemodel(model);
disp('model template visualization');
disp('press any key to continue'); 
pause;
posedet_visualizeskeleton(model);
disp('model tree visualization');
disp('press any key to continue'); 
pause;

imlist = dir('images/*.jpg');
for i = 1:length(imlist)
    % load and display image
    im = imread(['images/' imlist(i).name]);
    
    % call detect function
    tic;
    boxes = posedet_detect(im, model, min(model.thresh,-1));
    dettime = toc; % record cpu time
    fprintf('detection took %.1f seconds\n',dettime);    
    boxes = posedet_nms(boxes, 0.5); % nonmaximal suppression
    colorset = {'g','g','y','m','m','m','m','y','y','y','r','r','r','r','y','c','c','c','c','y','y','y','b','b','b','b'};
    for j = 1 : size(boxes, 1)
        clf; imagesc(im); axis image; axis off; drawnow;
        posedet_showboxes(boxes(j,:),colorset); % show the best candidate
        disp('press any key to continue');
        pause;
    end
end

disp('done');
