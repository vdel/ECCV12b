if ~exist('posedet_resize', 'file')
    mex -O posedet_resize.cc
    mex -O posedet_reduce.cc
    mex -O posedet_dt.cc
    mex -O posedet_features.cc

    % use one of the following depending on your setup
    % 1 is fastest, 3 is slowest 

    % 1) multithreaded convolution using blas
    %mex CFLAGS="\$CFLAGS -std=c99" -O fconvblas.cc -lmwblas -o posedet_fconv
    % 2) mulththreaded convolution without blas
    % mex -O fconvMT.cc -o posedet_fconv 
    % 3) basic convolution, very compatible
    mex -O fconv.cc -o posedet_fconv
end