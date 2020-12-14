function[to] = trout(mat)
% function to trim parameters from NFS files
% top and bottom rows and first and last columns are removed to fit grid
% mat = output matrix to be trimmed

[row col] = size(mat);
to = mat(2:row-1,2:col-1);

end