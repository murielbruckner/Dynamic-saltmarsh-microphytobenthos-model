function[FractionAreas] = trv2mat(N,M,trv,trd,Years,res)
% function convert trv file into fraction areas for vegetation types and
% Input:
% NumVeg = number of vegetation types
% N = size of N dimension
% M = size of M dimension
% trv = trv file
% trd = trd_sep
% Res = value for restart (if 1 = restart, otherwise 0)
% Output FractionAreas: fraction areas of vegetation separated in different structures
% for different vegetation types

%trv = dlmread(strcat(directory, 'work\veg.trv'),'');  
% sort trv file
%trv = dlmread('veg10.trv','');

%for testing
%  N       = Ndim;
%  M       = Mdim;
%  trd     = trd_sep;
% ------------------------

% sort rows of trv file
[d NumVeg] = size(trd); 

% input parameters function


% --------------------------------
FractionAreas = {NumVeg};
Sizes = zeros(NumVeg,1);

% to do!!
% pas formule toe in settlement en mortality
% check resultaten

% find sizes of vegetation matrices and pre_allocate memory
for i = 1:NumVeg % loop over vegetation types    
    [LM a] = size(trd{i}); % determine size of matrix
    FractionAreas{i} = zeros(N,M,LM); % pre allocate size of matrix
    Sizes(i,1) = LM;
end

Ranges      = [1; cumsum(Sizes)];
TotalMat    = zeros(N,M, sum(Sizes));


    
    for jj = 1:length(trv); % loop over coordinates
        CurrentPlant = trv(jj, 1:2); %Index = sub2ind([N M], CurrentPlant(1), CurrentPlant(2)); % current plant index
        CurrentArea  = trv(jj, 4);
%             if Years == 1 && res == 0 % correct for first timestep has one eco ts extra
%                 CurrentTrach = trv(jj, 3)+1;
%             else
                CurrentTrach = trv(jj, 3);
%             end
        TotalMat(CurrentPlant(1), CurrentPlant(2), CurrentTrach) = CurrentArea;
    end    
        % fill area fraction of vegetation in right trach file

%end


% split the matrix into separate matrices per vegetation types
for j = 1:NumVeg
  
    if j == 1
        Plant1 = TotalMat(:,:,Ranges(j):Ranges(j+1));
        FractionAreas{j} = Plant1;
    else
        PlantO = TotalMat(:,:,Ranges(j)+1:Ranges(j+1));
        FractionAreas{j} = PlantO;
    end

end

end % end of function