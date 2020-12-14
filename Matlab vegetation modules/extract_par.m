%% create input for dynamic vegetation model
% Author: M. Br?ckner
% Date 17/1/2020
% This code reads the output from Delft3D into matrices that are used for
% the vegetation computations. We compute bed level changes, flow
% velocities, inundation period, desiccation period and mud fraction in the
% top layer. The output is stored in a big matrix called d3dparameters,
% which is saved at the end of each morphological year in the results
% folder for postprocessing.


%% Sedimentation & erosion for mortality

% Extracting bathymetry to calculate burial/scour

if mor ==1     % if morphological computations are included
    
    % extract bed levels
    depth         = vs_get(NFS,'map-sed-series','DPS','quiet'); % bed topography with morphological changes
    depth_begin   = depth{1};                                   % bed level matrix at begin of ETS
    dts           = length(depth);                              % extract number of time-steps that data was saved
    
    % compute bed level difference
    BedLevelDif = depth{dts,:}-depth_begin;   % bed level differences
    A           = find(BedLevelDif<0);        % find cells for burial
    burial(A)   = BedLevelDif(A);             % burial for differences < 0
    A           = find(BedLevelDif>0);        % find cells for scour
    scour(A)    = BedLevelDif(A);             % scour for differences > 0
    clear A
    
else           % in case of no morphological change take initial bathymetry
    
    % initial bathymetry
    depth = vs_get(NFS,'map-const','DPS0','quiet');
    
end

%% extract mud in top layer

    
    % if vegetation requires mud for settling
    if mud_colonization >0

        % extract mud data       
        Slib      = vs_get(NFS,'map-sed-series','FRAC','quiet');
        Slib      = Slib{dts};                                          % at the end of ETS
        mud_fract = Slib(:,:,2);
        d3dparameters.mudfract(year).PerYear(ets,1) = {mud_fract};
    end

%% compute hydroperiod

% extract water levels
WL          = vs_get(NFS,'map-series','S1','quiet');    % Water level data at zeta points for all time-steps
waterdepth  = cell(numel(WL),1);                        % preallocate cell array
flood       = zeros(Ndim, Mdim);                        % preallocate hydroperiod matrix


% calculate water depth from water levels and bathymetry for each saved
% time-step per ETS (dts)

for dts=1:numel(WL) % determine water depth of all saved hydrol ts

    % compute water depth    
    if mor==1
        waterdepth{dts,1}= depth{dts,1}+WL{dts,1}; % sum depth (+) and water level (-)
        
    else
        waterdepth{dts,1}= depth+WL{dts,1};        % sum depth (+) and water level (-)
        
    end

    % determine cells that have a water depth larger than flooding-drying threshold    
    fl=find(waterdepth{dts,1}>fl_dr); % water depth has to be higher than fl-drying threshold
    
    % sum up flooded cells for each dts    
    temp=zeros(Ndim, Mdim); % temporal matrix to count flooded cells per dts
    
    if dts==1
        flood(fl)=1;        % for flooded cells set =1
    else
        temp(fl)=1;
        flood=flood+temp;   % sum of all time-steps
    end
end
clear temp

% compute average flooding and drying period
    flooding_current = zeros(size(flood));
    drying_current   = zeros(size(flood));  
    flooding_current = flood./dts;
    drying_current   = (dts-flood)./dts;

    
%% calculate water depth for colonization
waterdepth              = struct2mat(waterdepth, 2);  % put data of all hydrological timesteps in current trimfile in 3D matrix for further calculations

% calculate minimum/maximum waterdepth of all time-steps in ETS for colonozation
waterdepth_min = min(waterdepth,[],3);
waterdepth_min(waterdepth_min<fl_dr) = 0; % find cells that are less flooded than drying-flooding threshold and set to 0
waterdepth_max = max(waterdepth,[],3);
waterdepth_max(waterdepth_max<fl_dr) = 0; % find cells that are less flooded than drying-flooding threshold and set to 0


%% calculate max/min velocities for mortality
% extract U and V-velozities and compute residuals
U1              = vs_get(NFS,'map-series','U1','quiet'); % extract U velocity in U point
V1              = vs_get(NFS,'map-series','V1','quiet'); % extract V velocity in V point
U1Mat           = struct2mat(U1, 2);                     % putting U1 from d3d-output in 3D matrix
V1Mat           = struct2mat(V1, 2);                     % putting V1 from d3d-output in 3D matrix
velocity_res  = sqrt(U1Mat.^2 + V1Mat.^2);               % calculate residuals

% compute 90%-tile max. flow velocity
velocity_max = quantile(velocity_res,0.9,3);   % find 0.9 quantile and write to 2D-matrix


%% store parameters 
d3dparameters.WaterDepthMin(year).PerYear(ets,1) = {waterdepth_min};
d3dparameters.WaterDepthMax(year).PerYear(ets,1) = {waterdepth_max};
d3dparameters.VelocityMax(year).PerYear(ets,1)   = {velocity_max};
d3dparameters.Desiccation(year).PerYear(ets,1)   = {drying_current};
d3dparameters.Flooding(year).PerYear(ets,1)      = {flooding_current};

if mor ==1
    d3dparameters.Burial(year).PerYear(ets,1) = {burial};
    d3dparameters.Scour(year).PerYear(ets,1)  = {scour};
    d3dparameters.Beddiff(year).PerYear(ets,1)= {BedLevelDif};
end



