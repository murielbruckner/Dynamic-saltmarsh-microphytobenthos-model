function[mat] = struct2mat(input, trim)
% function for converting structures (e.g. from Delft3d output) into 3D
% matrices. In case of 3D structures separate matrices are constructed for
% each third dimension
%input = input structure (matrices within structures should have the same
%dimensions!
% trim = use function trout to trim output (remove 1st column and last row)
% 1 = trim file
% else = not trim file

%input = Silt
%trim = 1


[length_mat b] = size(input); % determine length of structure for loop

if trim == 1
[N M dim] = size(input{1}); % extract dimensions of trimmed matrix
N = N-2;
M = M-2;
else
[N M dim] = size(input{1}); % extract dimensions of matrix    
end

mat = zeros(N,M,length_mat); % allocate memory for 3d matrix
matdim  = {dim};

% loop over structure and put in 3D matrix
if dim == 1
    for i = 1:length_mat
        cur_par = input{i}; % parameter under consideration
        
        if trim == 1 % option for trimming file
        cur_par = trout(cur_par);
        end
         
        mat(:,:,i) = cur_par;
    end
else
    for d = 1:dim
        for i = 1:length_mat
            cur_par = input{i}(:,:,d); % parameter under consideration

            if trim == 1 % option for trimming file
            cur_par = trout(cur_par);
            end

            matd(:,:,i) = cur_par;
        end
        matdim{d} = matd;
        mat       = matdim;
    end
end   
end