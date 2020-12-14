%% Script for colonisation of vegetation with colonization strategy 1;
% Author: M. Br?ckner
% Date 17/1/2020
% This colonisation strategy requires cells that are located in the intertidal area.
% Determines the cells where settling is possible during colonization window.


% compute seedling location when time-step of colonization window

if   ets >= LocEco(1,1) &&  ets <= LocEco(1,2)

    % preallocate matrices for minimum and maximum water levels
    
    min_waterlevel = zeros(Ndim, Mdim); % reset matrix waterlevels minimum     
    max_waterlevel = zeros(Ndim, Mdim); % reset matrix waterlevels maximum  
    
    % open water depth data
    TempMin = d3dparameters.WaterDepthMin(year).PerYear(ets,1); 
    TempMin = struct2mat(TempMin,2); 
    TempMax = d3dparameters.WaterDepthMax(year).PerYear(ets,1); 
    TempMax = struct2mat(TempMax,2); 
    
    % look for cells that are flooded durin high and low water levels
    flooded_min = find(TempMin>0); % locations of min. water levels
    flooded_max = find(TempMax>0); % locations of max. water levels
    
    % find seedling locations in cells that have water depth only at max.
    % water levels
    min_waterlevel([flooded_min]) = 1; % give flooded cells value 1
    max_waterlevel([flooded_max]) = 1; % give flooded cells value 1
    
       
    % determine seed locations
    SeedLoc{1} = find((max_waterlevel-min_waterlevel)==1); % difference between maximum and minimum is the range where seeds are deposited; if 0 then subtidal

    clear TempMin TempMax flooded_max flooded_min
        
    % for random establishment extract random selection of seedling
    % locations
    if random>0
        rng(1)
        SeedLoc{1} = randsample(SeedLoc{1},round(length(SeedLoc{1})/random));
    end
    
end % end statement seed dispersal window checking

