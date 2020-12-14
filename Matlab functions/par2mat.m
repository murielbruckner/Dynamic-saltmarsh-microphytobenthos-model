function[mat] = par2mat(dir, N, M, Years,RunName, EcoTs, group, parameter)
% function to extract parameters from trimfiles in vegetation model per
% year at the chosen ecological timestep
% [mat] = par2mat(dir, N, M, Years,RunName, EcoTs, group, parameter)
% dir = main directory with model results
% N = number of cells in N direction
% M = number of cells in M direction
% Years = total run time in years
% RunName = name of trimfile (trim- 'RunName'.dat)
% EcoTs = ecological timestep to extract the result (last matrix) from (can
% not exceed maximum number of ecological timesteps)
% group = parameter group of Delft3D (e.g. sediment: 'map-sed-series', hydrology: 'map-series')
% parameter = parameter (e.g. DPS or CFUROU)
% DPS = bed level (in map-sed-series)
% U1 = flow velocity in U direction (in map-series)
% S1 = water level (in map-series)

% for testing
%  N = Ndim
%  M = Mdim
%  EcoTs = 24
%  parameter = 'CFUROU'; %'SBUU'
%  group ='map-series'; %'map-sed-series'
%  dir = strcat(directory, ModelName)
 
mat = zeros(N,M,Years); % matrix for saving results

% optional: loop for extracting one result each year
for i = 1:Years % loop over year   
   directory = strcat(dir, '\results_', num2str(i)); % go to directory
   cd(directory);  
   NFS     = vs_use(strcat('trim-', RunName, '_', num2str(EcoTs), '.dat'), 'quiet'); % extract parameter data
   par     = vs_get(NFS, group, parameter, 'quiet');
   
   if size(par{1},3)==1; % if there is only one fraction
    par     = trout(par{end});
   else
    a       = par{end};
    par     = trout(a(:,:,1)); % if there are more fractions take first
   end 
    
   mat(:,:,i) = par;
end % end year loop

end