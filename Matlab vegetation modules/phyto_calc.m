%% module for microphytobenthos computations
% Author Muriel Br?ckner
% Final version 17/1/2020
% The module computes microphytobenthos settling and expansion for growth
% period specified in txt-file. Data extraction from d3d-output in case no
% vegetation in simulation

% open grid and critical bed shear stress data
GRID = wlgrid('read',[directory,'work\',ID1,'.grd']);
Taucrit = (wldep('read',[directory,'work\',ID1,'.tce'],GRID))';
Taucrit(isnan(Taucrit==1))=0;

% if no vegetation present in simulation then first import of d3d-output
% data
if VegPres==0
    
% Extracting bathymetry to calculate burial/scour
if mor ==1     % if morphological computations are included
    
    % extract bed levels
    depth         = vs_get(NFS,'map-sed-series','DPS','quiet'); % bed topography with morphological changes
    depth_begin   = depth{1};                                   % bed level matrix at begin of ETS
    dts           = length(depth);                              % extract number of time-steps that data was saved

else           % in case of no morphological change take initial bathymetry
    
    % initial bathymetry
    depth = vs_get(NFS,'map-const','DPS0','quiet');
    dts   = length(depth);                              % extract number of time-steps that data was saved
    
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

% compute average flooding period
    flooding_current = zeros(size(flood));
    flooding_current=flood./dts;
    d3dparameters.Flooding(year).PerYear(ets,1)={flooding_current};

    

    


end

%% compute microphytobenthos distribution

%% extract mud in top layer
    
        % extract mud data in case no vegetation with mud       
        Slib      = vs_get(NFS,'map-sed-series','FRAC','quiet');
        Slib      = Slib{dts};                                          % at the end of ETS
        mud_fract = Slib(:,:,2);
        d3dparameters.mudfract(year).PerYear(ets,1) = {mud_fract};
        

        % read data from txt-file
        FID = fopen([directory, '\work\', 'Phyto1', '.txt']);
        data_phyto = textscan(FID, '%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f', 'HeaderLines', 3);
        fclose(FID);
        tau_sed = data_phyto{1,2};  % tau crit of sediment
          
        % if in growth period then compute cover
        if ets >=data_phyto{1,3} && ets <=data_phyto{1,4}
            
                
                % species parameters from txt-file
                tau_bio = data_phyto{1,1};      % new tau crit for colonized cells
                habitat_in1 = data_phyto{1,5};  % inundation threshold 1
                habitat_in2 = data_phyto{1,6};  % inundation threshold 2
                mud_th = data_phyto{1,7};       % mud threshold 
                
                % habitat parameters from d3d matrix
                inundation = d3dparameters.Flooding(year).PerYear(ets,1);
                inundation = cell2mat(inundation);
                mud_fract=d3dparameters.mudfract(year).PerYear(ets,1);
                mud_fract = cell2mat(mud_fract);
                
                
                % calculation of microphytobenthos presence/absence
                 phyto_pres = find(inundation>habitat_in1 & inundation<habitat_in2 & mud_fract>mud_th); % find suitable habitat for turbators
                 Taucrit(phyto_pres)=tau_bio; % replace by new value for new colonization; here the old distribution remains
                 
                 
                 % save locations for postprocessing 
                    PHYTO(phyto_pres)=1;
                    savefile = ['PHYTO',num2str(ets)];
                    savefile = [directory, 'results_', num2str(year),'\', savefile];
                    save(savefile, 'PHYTO');
                 % write new critical bed shear stress distribution to results-folder   
                    wldep('write',[directory,'results_', num2str(year),'\',ID1,num2str(ets),'.tce'],'',Taucrit');
            
            % clear temporal matrix for clearing memory space
            clear inundation mud_fract data_bio
            
        else % if outise growth period then remove cover
          PHYTO=zeros(size(GRID.X)+1)';  
          Taucrit = ones(size(GRID.X)+1)'*tau_sed;   % add sediment threshold
            
        end
        


% write file to work-folder and to matrix
Taucrit(Taucrit==0)=nan;
d3dparameters.taucrit(year).PerYear(ets,1)  = {Taucrit};               
wldep('write',[directory,'work\',ID1,'.tce'],'',Taucrit');
