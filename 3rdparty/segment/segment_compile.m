if ~exist('segment_felz', 'file')
    mex -DMEX segment.cpp -lm -o segment_felz
end
