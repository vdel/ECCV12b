function [segments, neighbours] = segment_back(params, vid)    
    thissegfile = fullfile(params.root, 'tmp', vid, 'segments.mat');        
    if exist(thissegfile, 'file')
        load(thissegfile, 'segments', 'neighbours');
        fprintf('Super-pixels loaded from %s\n', thissegfile);
    else
        fprintf('Computing superpixels for %s.\n', vid);
        if 1 %felsenzwalb
            segfile = fullfile(params.root, 'tmp', vid, 'segment_felz.mat');            
            [d, segimg2] = fileparts(segfile);                
            if exist(segfile, 'file') ~= 2           
                % Put image in the right format
                back = imread(fullfile(params.root, 'annots', 'back', [vid, '.jpg']));
                backresized = imresize(back, [(params.segimwidth * size(back, 1) / size(back, 2)) params.segimwidth]);                    
                
                % <HACK>: same super pixels as before.
                backfile = fullfile(params.root, 'tmp', vid, 'back_resize');
                imwrite(backresized, [backfile '.jpg']);        
                system(sprintf('convert %s %s', [backfile '.jpg'], [backfile '.pnm']));  
                backresized = imread([backfile '.pnm']);        
                % </HACK>

                % Compute superpixels
                nsegs = size(params.sigma_k_min, 2);                
                segments = cell(1, nsegs);
                neighbours = cell(1, nsegs);
                segID = 1;
                for p = params.sigma_k_min
                    sigma = p(1);
                    k = p(2);
                    min = p(3);                      
                    seg = segment_felz(sigma, k, min, backresized);                    

                    % Resize superpixel map to original background size
                    seg = imresize(seg, [size(back, 1) size(back, 2)], 'nearest');
                    segimg = fullfile(d, sprintf('%s_%g_%g_%g.bmp', segimg2, sigma, k, min));
                    imwrite(seg, segimg);                         

                    % Get neighbours
                    [segments{segID} neighbours{segID}] = load_segmentation(seg);                    
                    segID = segID + 1;                    
                end
                save(segfile, 'segments', 'neighbours');
            end
%         else % TurboPixels            
%             segfile = fullfile(params.root, 'tmp', vid, 'segment_turbo.mat');
%             [d, segimg] = fileparts(segfile);
%             segimg = fullfile(d, [segimg '.pnm']);
%             if exist(segfile, 'file') ~= 2          
%                 % Put image in the right format
%                 back = imread(fullfile(params.root, 'annots', 'back', [vid '.jpg']));
%                 w = 100;
%                 backresized = imresize(back, [(w * size(back, 1) / size(back, 2)) w]);
% 
%                 % Compute superpixels
%                 [~, ~, boundaries, seg] = superpixels(im2double(backresized), params.nSuperPixels);
%                 boundaries = imresize(boundaries, [size(back, 1) size(back, 2)]);
%                 imwrite(boundaries, [segimg '.bmp']);
%                 system(sprintf('convert %s %s', [segimg '.bmp'], segimg));                            
% 
%                 % Resize superpixel map to original background size
%                 seg = imresize(seg, [size(back, 1) size(back, 2)], 'nearest');
%                 seg = seg + 1;
%                 seg = uint8(cat(3, mod(seg, 256), mod(floor(seg/256), 256), mod(floor(seg/(256 * 256)), 256))); 
% 
%                 % Get neighbours
%                 [segments{1} neighbours{1}] = load_segmentation(seg);
%                 save(segfile, 'segments', 'neighbours');
%             end            
        end
        copyfile(segfile, thissegfile);
        [d, f] = fileparts(thissegfile);
    end
end
