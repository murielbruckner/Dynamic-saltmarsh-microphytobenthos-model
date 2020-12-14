%% Extract data for postprocessing
% Read data from trim-file to extract parameters for analysis: bed level
% changes, inundation period and 90%-percentile flow velocities; possibly
% mud fraction in top layer

%% Extracting bathymetry to calculate burial/scour

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

for nv=1:num_veg_types
    
    % if vegetation requires mud for settling
    if mud_colonization(nv,1) >0

        % extract mud data       
        Slib      = vs_get(NFS,'map-sed-series','FRAC','quiet');
        Slib      = Slib{dts};                                          % at the end of ETS
        mud_fract = Slib(:,:,2);
        d3dparameters.mudfract(year).PerYear(ets,1) = {mud_fract};
    end
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
    drying_current = zeros(size(flood));  
    flooding_current=flood./dts;
    drying_current=(dts-flood)./dts;
    eco_day = 1;                            % ecological timestep in days for mortality

    % save data
    d3dparameters.depth(year).PerYear(ets,1) = {depth};
    d3dparameters.Flooding(year).PerYear(ets,1) = {flooding_current};
    d3dparameters.Desiccation(year).PerYear(ets,1) = {drying_current};
    

%% calculate max/min velocities for mortality
% extract U and V-velozities and compute residuals
U1              = vs_get(NFS,'map-series','U1','quiet'); % extract U velocity in U point
V1              = vs_get(NFS,'map-series','V1','quiet'); % extract V velocity in V point
U1Mat           = struct2mat(U1, 2);                     % putting U1 from d3d-output in 3D matrix
V1Mat           = struct2mat(V1, 2);                     % putting V1 from d3d-output in 3D matrix
velocity_res  = sqrt(U1Mat.^2 + V1Mat.^2);               % calculate residuals

% compute 90%-tile max. flow velocity
velocity_max = quantile(velocity_res,0.9,3);             % compute 0.9-percentile
d3dparameters.VelocityMax(year).PerYear(ets,1) = {velocity_max};

% save matrix with data per year
if ets == t_eco_year

    savefile = strcat('d3dparameters',num2str(ets));
    savefile = strcat(directory, 'results_', num2str(year),'\', savefile);
    save(savefile, 'd3dparameters');
end