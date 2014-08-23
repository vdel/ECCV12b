if ~exist('segment_felz', 'file')
    mex -DMEX segment_felz.cpp -lm
end
