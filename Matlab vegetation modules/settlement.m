%% Settlement module assigns initial vegetation fractions to the suitable grid cells when seed dispersal window
% Author: M. Br?ckner
% Date 17/1/2020
% Code to compute settling of the new seedlings in both empty and already
% colonized cells. Seedling locations were defined in the colonization
% strategy code.


    
    % find available space in the vegetation matrix
    if   ets >= LocEco(1,1) &&  ets <= LocEco(1,2) % check if the ecological timestep falls within seed dispersal window

        % preallocation of temporary matrices        
        temp         = zeros(Ndim, Mdim); % matrix for new fractions

        % calculate total vegetation fraction in each cell
        temp_sum_new = sum(fract_area_all_veg{1}, 3); % sum of all area fractions of vegetation type over whole grid 
                
  
        % extract inital fraction from general vegetation matrix
        general_char = table_veg_dyn{1};       % extract general vegetation type characteristics 
        ini_fraction = general_char(ets,7);    % extract initial fraction area of vegetation type            
             
        % calculate space based on the total fractions 
            rest                                = 1- temp_sum_new;                 % calculates available space to still colonize in each cell
            rest(rest<0)                        = 0;                               % reset all negative values to 0 
            fraction_new_plant_loc              = rest([SeedLoc{1}]);              % compare available space with plant locations for colonization
            room                                = find(fraction_new_plant_loc >=ini_fraction);       % check for cells where available space is larger than initial fraction
            no_room                             = find(fraction_new_plant_loc < ini_fraction);       % check for cells where available space is smaller than initial fraction
            temp([SeedLoc{1}([room])])          = ini_fraction;                                % fill available space with initial fraction
            temp([SeedLoc{1}([no_room])])       = rest([SeedLoc{1}([no_room])]);    % fill smaller available space with possible fraction
            
        % sum of newly settled plants with previous colonized plant fractions
        fract_area_all_veg{1}(:,:,LocEco(1,1)) = temp + fract_area_all_veg{1}(:,:,LocEco(1,1));
 
        clear temp temp_sum_new rest room no_room fraction_new_plant_loc
        
    end % end check settlement window
