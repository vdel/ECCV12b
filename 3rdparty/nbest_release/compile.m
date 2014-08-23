if ~exist('fconv', 'file')
    mex -O resize.cc
    mex -O reduce.cc
    mex -O dt.cc
    mex -O features.cc
    mex -O shiftdt.cc

    % use one of the following depending on your setup
    % 1 is fastest, 3 is slowest 

    % 1) multithreaded convolution using blas
    %   !cp fconvblas.cc fconv.cc
    %	mex -O fconv.cc -lmwblas
    % 2) mulththreaded convolution without blas
    % !cp fconvMT.cc fconv.cc
    % mex -O fconv.cc 
    % 3) basic convolution, very compatible
     !cp fconv_basic.cc fconv.cc
     mex -O fconv.cc
end