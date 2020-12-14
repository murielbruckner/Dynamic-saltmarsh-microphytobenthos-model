%% Mortality computations
% Author: M. Br?ckner
% Date 17/1/2020
% This code computes the mortalities linked with the defined pressures and reduces
% the fractions of all plant fractions present according to the strength of
% the pressure and the initially present fraction. The code tracks
% the fraction at first occurrence of the pressure and substracts mortalities
% from that fraction. This means that we track all fractions and the
% initial occurrence of three pressures that reduce fractions linearly: flow velocity,
% inundation period and desiccation period.
% Scour and burial of each plant fraction leads to immediate mortality of
% the entire fraction.
% At the end of the code, the plant aging is computed and the fractions are
% saved as new trv-file.


%% Reading matrices and vegetation fractions

% load pressure data of mature vegetation
dry_cor_sub            = cell2mat(d3dparameters.Desiccation(year).PerYear(ets,1));      % matrix with dry period
flood_cor_sub          = cell2mat(d3dparameters.Flooding(year).PerYear(ets,1));         % matrix with hydroperiod
FlowVelocityCurrent    = cell2mat(d3dparameters.VelocityMax(year).PerYear(ets,1));      % matrix with velocity


% skip loop if there is not vegetation present, yet
if year==1 && ets < LocEco(1,1) && Restart==0
    
    display('Vegetation type not present');
    
else
    
    % extract general vegetation type characteristics from trd-file
    general_char = table_veg_dyn{1};
    
    
    % read vegetation fractions
    veg_fract_data = fract_area_all_veg{1};   % extract matrix with fraction data of each vegetation type in each cell
    [r,c,xl] = size(veg_fract_data);          % determine length of vegetation fraction data
    
    
    % loop over IDs of vegetation type
    for av = 1:xl
        
        mat_cur = veg_fract_data(:,:,av);     % extract existing fractions
        [loc_n, loc_m] = find(mat_cur > 0);   % find cells that contain vegetation
        
        
        % if there are no plants in matrix, skip computations
        if isempty(loc_n)==0
            
            
            % find mortality thresholds and slopes of year of vegetation type
            mort_flo_th1 = general_char(av, 10);            % extract threshold for desiccation
            mort_flo_sl1 = general_char(av, 11);            % extract slope for desiccation
            mort_flo_th2 = general_char(av, 12);            % extract threshold for flooding
            mort_flo_sl2 = general_char(av, 13);            % extract slope for flooding
            mort_vel_th  = general_char(av, 14);            % extract threshold for flow velocity
            mort_vel_sl  = general_char(av, 15);            % extract slope for flow velocity
            
            % extract critical values for burial and scour
            LengthRoot   = general_char(av,21);             % extract length of root for corresponding age class
            LengthShoot  = general_char(av,18);             % extract length of shoot for corresponding age class
            
            
            % skip calculations when there is no above-ground biomass
            if  LengthShoot==0
                
                display('no shoot')
                
            else
                
                
                % preallocation of temporary matrices per vegetation age that track vegetation
                % fractions throughout the mortality code
                ini_frac_av_fl       = zeros(Ndim, Mdim);
                ini_frac_av_dry      = zeros(Ndim, Mdim);
                ini_frac_av_fl_prev  = ini_frac_av_fl;
                ini_frac_av_dry_prev = ini_frac_av_dry;
                
                
                
                
                % find cells that have a hydroperiod/dry period
                fldx = flood_cor_sub~=0;                                    % indices with wet cells=1
                drdx = dry_cor_sub~=0;                                      % indices with dry cells=1
                
                % computing flooded cells
                ini_frac_av_fl_prev = ini_frac_store{1}(:,:,av);            % extract previous fractions from last ets
                ini_frac_av_fl = ini_frac_av_fl_prev.*fldx;                 % deleting all cells that have fallen dry during this ETS
                new_idx = find(ini_frac_av_fl_prev==0 & flood_cor_sub~=0);  % find cells that are newly flooded during this ETS
                ini_frac_av_fl(new_idx) = mat_cur(new_idx);                 % add initial fractions in cells that are newly flooded in matrix
                
                % computing dry cells
                ini_frac_av_dry_prev = ini_frac_store_dry{1}(:,:,av);       % extract previous fractions from last ets
                ini_frac_av_dry = ini_frac_av_dry_prev.*drdx;               % deleting all cells that have fallen wet during this ETS
                new_idx = find(ini_frac_av_dry_prev==0 & dry_cor_sub~=0);   % find cells that are newly dry during this ETS
                ini_frac_av_dry(new_idx) = mat_cur(new_idx);                % add initial fractions in cells that are newly dry in matrix
                
                %% Burial/scour of mature vegetation
                
                % if morphology is on then compute burial/scour by
                % comparing root length & plant height with erosion
                % and sedimentation depth
                if mor==1
                    
                    % extract pressure data
                    ScourCurrent   = cell2mat(d3dparameters.Scour(year).PerYear(ets,1));
                    BurialCurrent  = cell2mat(d3dparameters.Burial(year).PerYear(ets,1));
                    
                    % compute erosion of the root
                    fract_scour=zeros(Ndim,Mdim);                                    % create empty matrix
                    fract_scour(abs(ScourCurrent) > LengthRoot)=1;                   % find cells with mortality
                    fract_scour=fract_scour.*mat_cur;                                % save killed fractions for mortlality causes
                    mat_cur(abs(ScourCurrent) > LengthRoot) = 0;                     % remove fractions from current vegetation matrix
                    
                    % compute burial of the plant
                    fract_burial=zeros(Ndim,Mdim);                                   % create empty matrix
                    fract_burial(abs(BurialCurrent) > LengthShoot)=1;                % find cells with mortality
                    fract_burial=fract_burial.*mat_cur;                              % save killed fractions for mortlality causes
                    mat_cur(abs(BurialCurrent) > LengthShoot) = 0;                   % remove fractions from current vegetation matrix
                end
                
                
                % calculate new fractions after flooding mortality
                
                if mort_flo_th2 ~=0 % when flooding activated as pressure then mortality calculations
                    
                    % determine flooding mortalities based on
                    % linear relationship
                    mort_flood           = mortality_flood_frequencyMB(flood_cor_sub, mort_flo_th2, mort_flo_sl2, Ndim, Mdim); % mortality fractions due to flooding strength
                    fraction_dead_flood  = mort_flood.*ini_frac_av_fl;                                                         % relative mortality fractions based on present vegetation fraction
                    
                else
                    fraction_dead_flood = zeros(size(dry_cor_sub)); % final mortality fractions
                    
                end
                
                % calculate new fractions after dessication mortality
                
                if mort_flo_th1 ~=0 % when dessication activated as pressure then mortality calculations
                    
                    % determine desiccation mortalities based on
                    % linear relationship
                    mort_des           = mortality_flood_frequencyMB(dry_cor_sub, mort_flo_th1, mort_flo_sl1, Ndim, Mdim); % mortality fractions due to desiccation strength
                    fraction_dead_des  = (mort_des.*ini_frac_av_dry);                                                      % relative mortality fractions based on present vegetation fraction
                    
                else
                    fraction_dead_des = zeros(size(dry_cor_sub));                                                          % final mortality fractions
                end
                
                % calculate new fractions after flow velocity mortality
                if  mort_vel_th ~=0 % when velocity activated as pressure then mortality calculations
                    
                    % determine velocity mortalities based on
                    % linear relationship
                    mort_flow = mortality_flowMB(FlowVelocityCurrent, mort_vel_th, mort_vel_sl, Ndim, Mdim); % mortality matrix with percentage mortality due to flow velocity at plant location
                    fraction_dead_upr = (mort_flow .* mat_cur);                                              % relative mortality fractions based on present vegetation fraction
                else
                    fraction_dead_upr = zeros(size(dry_cor_sub));                                            % final mortality fraction
                end
                
                % calculation new fractions
                fraction_new = mat_cur-fraction_dead_des-fraction_dead_flood-fraction_dead_upr;         % substract mortality fractions from matrix
                fraction_new(fraction_new<0) = 0;                                               % replace negative values with 0
                veg_fract_data(:,:,av) = fraction_new;                                                  % update data matrix with new plants
                
                % update all matrices
                ini_frac_av_dry(fraction_new==0) = 0;                                     % update initial fraction tracking matrix by removal of empty cells
                ini_frac_av_fl(fraction_new==0) = 0;                                      % update initial fraction tracking matrix by removal of empty cells
                ini_frac_store{1}(:,:,av+1) = ini_frac_av_fl;                          % store new fractions in storage matrix under subsequent ETS ID
                ini_frac_store_dry{1}(:,:,av+1) = ini_frac_av_dry;                     % store new fractions in storage matrix under subsequent ETS ID
                
                % store mortality
                Mort(ets).Flooding(av)    = {fraction_dead_flood};
                Mort(ets).Desiccation(av) = {fraction_dead_des};
                Mort(ets).velocity(av)    = {fraction_dead_upr};
                Mort(ets).Scour(av)       = {fract_scour};
                Mort(ets).Burial(av)      = {fract_burial};
                
            end % end if shoot length==0
            %                 end % end if statement one year old plants
        end % end if statement no plants in matrix
    end % end loop over year matrices of vegetation type
    
    
    % update vegetation type matrix with new plant fractions
    fract_area_all_veg{1} = veg_fract_data;
    
    
end % end loop over if veg present


%% computation of aging of plants

MatrixSizeVeg = general_veg_char(1,1)*t_eco_year;  % preallocation of matrix
current_plant = fract_area_all_veg{1};               % new fractions per vegetation type

for tt = MatrixSizeVeg:-1:2  % computes aging of plant fractions: from maximum age backwards to the first ets to overwrite matrix with next ID;
    
    current_plant(:,:,tt)   = current_plant(:,:,tt-1);  % write the fraction properties from each plant age into new plant age location
    current_plant(:,:,tt-1) = zeros(Ndim,Mdim);         % reset ets-1 with zero for collection of new plants
    
end
fract_area_all_veg{1} = current_plant;                 % save fractions in vegetation matrix

%% saving data

% save d3d-outout and mortality data for post-processing
if ets == t_eco_year
    try
    savefile = strcat('d3dparameters',num2str(ets));
    savefile = strcat(directory, 'results_', num2str(year),'\', savefile);
    save(savefile, 'd3dparameters');
    
    savefile = strcat('Mort',num2str(ets));
    savefile = strcat(directory, 'results_', num2str(year),'\', savefile);
    save(savefile, 'Mort');
    catch
    end
end

% save vegetation fractions for post-processing
savefile = ['fract_all_veg',num2str(ets)];
savefile = [directory, 'results_', num2str(year),'\', savefile];
save(savefile, 'fract_area_all_veg');


%% loop over vegetation matrix to create trv-file for Delft3D computations


% extract data
MatrixSizeVeg  = general_veg_char(1,1)*t_eco_year;    % preallocation of matrix
veg_fract_data = fract_area_all_veg{1};                 % fractions per vegetation type


% Saving the data in trv-file

fid = fopen([directory, 'work\veg.trv'], 'w+'); % open file for writing, discard any content

% add new fractions to matrix to create new trv-file

for av = 1:MatrixSizeVeg
    cur_mat   = veg_fract_data(:,:,av);    % current vegetation matrix with new fraction areas of ID
    cur_plant = find(cur_mat>0);           % indices of cells with plant fractions
    
    for rr = 1:length(cur_plant)                            % loop over indices where plant fractions
        [row, col] = ind2sub(size(cur_mat),cur_plant(rr));  % look up M and N index of plant
        trach = trd_sep{1}(av,1);                          % extract trachytope id from initial matrix
        frac_area = cur_mat(cur_plant(rr));                 % extract fraction of plant from current matrix
        output = [row col trach frac_area];                 % combine all data into matrix in trv-file format
        fprintf(fid,'%d\t%d\t%d\t%0.3f\n', output) ;        % write trv to folder
    end
end
fclose(fid);

% sort trv-file after M- and N-coordinates
try
    % sort the vegetation in trv-file and save
    trv = dlmread([directory, 'work\veg.trv'],'');
    trv = sortrows(trv,1:2);
    dlmwrite([directory, 'work\veg','.trv'],trv, '\t');
    % update fraction areas of all vegetation types based on changed trv file
    fract_area_all_veg = trv2mat(Ndim, Mdim, trv, trd_sep, year,Restart) ; % translate trv file into vegetation fraction area file and sort rows
    
catch
    display('veg.trv is empty');  % if there is no vegetation present
end

