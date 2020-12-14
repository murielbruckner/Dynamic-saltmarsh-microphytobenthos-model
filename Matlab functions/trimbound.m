function[op] = trimbound(mat, side)
% function to trim matrices 
% mat = matrix to be trimmed
% side = vector containing information on which sides have to be trimmed
% with the value representing the amount of cells to trim
% [left right top bottom]

% for testing
% mat = zeros(100, 50, 3);
% side = [10 10 20 20]

[row col t]   = size(mat);

op = zeros(row-side(3)-side(4),col-side(1)-side(2),t); % initialize matrix
for i = 1:t % loop over 3rd dimension of matrix
    op(:,:,i) = mat(side(3)+1: row-side(4), side(1)+1:col-side(2),i);
end % end loop over 3rd dimension of matrix

end % end of function