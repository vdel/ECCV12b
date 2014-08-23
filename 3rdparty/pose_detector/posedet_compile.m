if ~exist('posedet_resize', 'file')
    mex -O posedet_resize.cc
    mex -O posedet_reduce.cc
    mex -O posedet_dt.cc
    mex -O posedet_features.cc

    % use one of the following depending on your setup
    % 1 is fastest, 3 is slowest 

    % 1) multithreaded convolution using blas
    %!cp fconvblas.cc posedet_fconv.cc
    % mex CFLAGS="\$CFLAGS -std=c99" -O posedet_fconv.cc -lmwblas -o posedet_fconv
    % 2) mulththreaded convolution without blas
    % !cp fconvMT.cc posedet_fconv.cc
    % mex -O posedet_fconv.cc 
    % 3) basic convolution, very compatible
    !cp fconv.cc posedet_fconv.cc
    mex -O posedet_fconv.cc
end