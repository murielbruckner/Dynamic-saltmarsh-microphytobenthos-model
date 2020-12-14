% Author: M. Br?ckner
% Date 17/1/2020
% Colonisation processes in vegetation model to to determine the available
% cells that can be colonized according to two distinguished strategies.

%initialize seed coordinate array
clear SeedLoc
SeedLoc = {1};


% call right strategy determined in veg.txt-file 1.3
if general_veg_char(1,3) == 1    % Colonisation strategy 1;
    
    ColonisationStrategyV1sand  % calling colonization only dependent on water levels
    
elseif general_veg_char(1,3) == 2 % Colonistion strategy 2; 
    
    ColonisationStrategyV2mud % calling colonization dependent on water levels + mud content
end

