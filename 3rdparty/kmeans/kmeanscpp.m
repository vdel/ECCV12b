function [clusters assign obj] = kmeanscpp(data, ncluster, maxiter)
    global JOB_INFO;

    data = single(data);
    [dim ndata] = size(data);

    path = mfilename('fullpath');
    d = fileparts(path);

    if isempty(JOB_INFO)
        r = round(rand() * 1000000);
        datafile = sprintf('data_kmeans_%d_%d.txt', r, now);
        resfile = sprintf('cluster_kmeans_%d_%d.txt', r, now);			
    else
        datafile = fullfile(JOB_INFO.user_dir, 'data_kmeans.txt');
        resfile = fullfile(JOB_INFO.user_dir, 'cluster_kmeans.txt');
    end		

    fid = fopen(datafile, 'wb');
    fwrite(fid, dim, 'int32');
    fwrite(fid, ndata, 'int32');
    fwrite(fid, data, 'single');
    fclose(fid);

    exec = fullfile(d, 'kmeans');
    system(sprintf('%s %s %d %d %s', exec, datafile, ncluster, maxiter, resfile));

    fid = fopen(resfile, 'rb');
    clusters = fread(fid, dim * ncluster, 'single');
    assign = fread(fid, ndata, 'single');
    obj = fread(fid, 1, 'single');
    fclose(fid);

    delete(datafile);
    delete(resfile);		
end
