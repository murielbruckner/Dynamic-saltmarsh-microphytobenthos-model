%% Code to compute the seasonal growth curves for saltmarsh vegetation that are used for the construction of the TRD-file
% Calculates the growth curve of the vegetation for all life-stages and ETS within year.
% Saves all data in table_veg_dyn{}.


%% Preallocation of temporary and permanent matrices
data_all_LS      = [];                                         % create temporary matrix
data_all_LS(:,1) = transpose([1:1:general_veg_char(1,1)]);  % generate list of vegetation years for vegetation type

temp1         = [];                                         % create temporary matrix
rep_mat       = [];                                         % create temporary matrix
num_y_prev    = [];                                         % create temporary matrix

[age, col]   = size(data_all_LS);                           % determine size of vegetation matrix that represents the trd-file
clear col


% define the size of the matrices for each vegetation type and life-stage
veg_height = zeros(age,t_eco_year);                         % matrix for vegetation height
stem_dia   = zeros(age,t_eco_year);                         % matrix for stem diameter
veg_root   = zeros(age,t_eco_year);                         % matrix for root length


% define the size of the final matrices that contain the vegetation
% parameters used for the trd-file
veg_dens    = zeros(age*t_eco_year,1);                      % matrix for vegetation density
veg_r       = zeros(age*t_eco_year,1);                      % matrix for root length 
veg_h       = zeros(age*t_eco_year,1);                      % matrix for vegetation height
drag_first  = zeros(age*t_eco_year,1);                      % matrix drag coefficient
stem        = zeros(age*t_eco_year,1);                      % matrix for vegetation stem diameter


%% create matrix with data that are not variable within each life stage

for nls = 1:num_ls  % loop over number of life stages of vegetation type
    
    rep_mat  = life_veg_temp(nls,:);                    % extract specific data for current lifestage
    num_yls  = life_veg_temp(nls,4);                    % number of years in lifestage
    temp1    = repmat(rep_mat, num_yls,1);              % extrapolate specific data of lifestages along number of years that lifestage lasts
    
    
    % fill matrix with data of life stages
    if nls ==1 
        data_all_LS(1:num_yls, 2:length(rep_mat)+1)                                 = temp1; % first rows are for first life stages
    else
        data_all_LS(sum(num_y_prev)+1:num_yls+sum(num_y_prev), 2:length(rep_mat)+1) = temp1; % add data from other life stage below previous life-stages
    end
    
    num_y_prev(1,nls)  = num_yls; % remember years of previous life stage
    
    clear temp1;
    
end

%% Compute linear slope of the vegetation growth

% preallocate arrays that define the slopes
m_height = zeros(nls,life_veg_temp(nls,4)) ;
m_root   = zeros(nls,life_veg_temp(nls,4)) ;
m_stemdia = zeros(nls,life_veg_temp(nls,4)) ;


% extract growth period
start_growth = general_veg_char(:,14);           % eco timestep start annual growth (e.g. in spring)
end_growth   = general_veg_char(:,15);           % eco timestep stop annual growth - begin constant biomass (e.g. in summer)
dead_growth  = general_veg_char(:,16);           % eco timestep start decay (e.g. in winter)

% calculate growth period for above and belowground biomass
timesteps_shoot     = end_growth - start_growth;    % number of ecological timesteps with shoot growth 
timesteps_below     = dead_growth - start_growth;   % number of ecological timesteps with root growth



% Computation of the variable slopes within each year for vegetation height, stem diameter and root 
% length (for shoot slope depends on winter height, root/diameter grow until decay)

for nls = 1:num_ls  % loop over number of life stages of vegetation type
    
    for y = 1:life_veg_temp(nls,4) % loop over years of each life-stage
        
        if nls==1 % if first life-stage
            
            % if first year: take initial values for height
            if y==1
                m_height(nls,y) = (life_veg_temp(nls,1)-general_veg_char(1, 8))/timesteps_shoot;   % m_height: meters per ets that plant grows
                
            else % if year n: take initial value as last value from winter height of present life-stage
                m_height(nls,y) = (life_veg_temp(nls,1)-life_veg_temp(nls,15))/timesteps_shoot;       % m_height: meters per ets that plant grows in growth period
                
            end
            
            % diameter and root length for first life-stage from initial values
            m_stemdia(nls,y) = (life_veg_temp(nls,2)-general_veg_char(1,9))/timesteps_below/life_veg_temp(nls,4);  % slope: meters per ets that diameter grows based on no of years in life-stage
            m_root(nls,y)    = (life_veg_temp(nls,3)-general_veg_char(1,7))/timesteps_below/life_veg_temp(nls,4);  % slope: meters per ets that root grows based on no of years in life-stage
            
        elseif nls>1 % if not first life-stage, take values from last time-step of previous life-stage
            
            if y==1 % if first year: take winter height of previous life-stage
                m_height(nls,y) = (life_veg_temp(nls,1)-life_veg_temp(nls-1,15))/timesteps_shoot;     % slope: meters per ets that plant grows
                
            else    % if year n: take winter height of this life-stage
                m_height(nls,y) = (life_veg_temp(nls,1)-life_veg_temp(nls,15))/timesteps_shoot;       % slope: meters per ets that plant grows
                
            end
            
            % the intitial value for root and diameter is the last value previous life-stage
            m_root(nls,y)    = (life_veg_temp(nls,3)-life_veg_temp(nls-1,3))/timesteps_below/life_veg_temp(nls,4);        % slope: meters per ets that root grows
            m_stemdia(nls,y) = (life_veg_temp(nls,2)-life_veg_temp(nls-1,2))/timesteps_below/life_veg_temp(nls,4);        % slope: meters per ets that diameter grows
        end
        
        % drag is constant for each life-stage
        drag(nls, y) = life_veg_temp(nls,7);
        
    end
end


%% Calculation of array with vegetation parameters for each ID in trd-file
% 3 parts: one for the first year and life-stage; one for first year and n
% life-stage; one for n years and n life-stages


for nls = 1:num_ls  % loop over number of life stages of vegetation type
    
    for y = 1:life_veg_temp(nls,4) % loop over years of life-stage
        
        if y ==1 && nls==1
            
            % loop within year: to track growth between ets
            for i=1:t_eco_year
                
                    % before growth period no vegetation present
                if i<start_growth
                    
                    veg_height(y,i) = 0; % vegetation height
                    stem_dia(y,i)   = 0; % stem diameter
                    veg_root(y,i)   = 0; % root length
                    
                    
                    % read initial plant traits at start of growth period
                elseif  i==start_growth
                    
                    veg_height(y,i) = general_veg_char(1, 8); % initial shoot height from general characteristics
                    stem_dia(y,i)   = general_veg_char(1, 9); % initial stem diameter from general characteristics
                    veg_root(y,i)   = general_veg_char(1, 7); % initial root length from general characteristics
                    
                    
                    % lin. growth over growth period with slopes defined above
                elseif i>start_growth && i<=end_growth
                    
                    veg_height(y,i) = veg_height(y,i-1) + m_height(nls,y);      % linear vegetation height growth
                    stem_dia(y,i)   = stem_dia(y,i-1) + m_stemdia(nls,y);       % linear stem diameter growth
                    veg_root(y,i)   = veg_root(y,i-1) + m_root(nls,y);          % linear root length growth
                    
                    
                    % constant values for shoot height and linear
                    % root/diameter growth at end of growth period
                elseif i>end_growth && i<=dead_growth
                    veg_height(y,i) = veg_height(y,i-1);                        % constant heigth
                    stem_dia(y,i)   = stem_dia(y,i-1)+ m_stemdia(nls,y);        % linear stem diameter growth
                    veg_root(y,i)   = veg_root(y,i-1)+ m_root(nls,y);           % linear root length growth
                    
                    % reduction in vegetation height in winter; constant root/diameter
                else 
                    if i==dead_growth+1
                        veg_height(y,i) = life_veg_temp(nls,15);    % reduce vegetation height from general characteristics
                        
                    else
                        veg_height(y,i) = veg_height(y,i-1);        % keep constant winter height
                        
                    end
                    
                    stem_dia(y,i)   = stem_dia(y,i-1);              % keep constant winter stem diameter
                    veg_root(y,i)   = veg_root(y,i-1);              % keep constant root length
                end
                
                
                % saving all parameters for trachytope
                % ID's in trd-file as array per ETS
                
                veg_dens(i,:)   = data_all_LS(y,6).*stem_dia(y,i); % determine density (stem diameter * number of stems) for Baptist formula
                veg_h(i,:)      = veg_height(y,i);                 % save vegetation height
                veg_r(i,:)      = veg_root(y,i);                   % save vegetation root length
                drag_first(i,:) = drag(nls,y);                     % save drag coefficient
                stem(i,:)       = stem_dia(y,i);                   % save stem diameter
                
            end
            
            lastID = t_eco_year+1; % save the last ID to continue with next year
            
        % for life-stage >1 and year 1
        elseif y==1 && nls>1
            
            % loop within year: to track growth between ets
            for i=1:t_eco_year 
                
                % before growth period take initial value from previous life-stage
                if i<=start_growth
                    veg_height(y,i) = veg_height(life_veg_temp(nls-1,4),t_eco_year);  % initial vegetation height from previous life-stage
                    stem_dia(y,i)   = stem_dia(life_veg_temp(nls-1,4),t_eco_year);    % initial stem diameter from  previous life-stage
                    veg_root(y,i)   = veg_root(life_veg_temp(nls-1,4),t_eco_year);    % initial root length from  previous life-stage
                    
                    % lin. growth over growth period
                elseif i>start_growth && i<=end_growth
                    veg_height(y,i) = veg_height(y,i-1) + m_height(nls,y);            % linear growth with slope from above
                    stem_dia(y,i)   = stem_dia(y,i-1) + m_stemdia(nls,y);             % linear growth with slope from above
                    veg_root(y,i)   = veg_root(y,i-1) + m_root(nls,y);                % linear growth with slope from above
                    
                    % constant values for shoot height and linear root/diameter growth
                elseif i>end_growth && i<=dead_growth
                    veg_height(y,i) = veg_height(y,i-1);                               % initial vegetation height from previous ETS
                    stem_dia(y,i)   = stem_dia(y,i-1)+ m_stemdia(nls,y);               % linear growth stem diameter 
                    veg_root(y,i)   = veg_root(y,i-1)+ m_root(nls,y);                  % linear growth root length
                    
                    % reduction in vegetation height in winter; constant root/diameter
                else
                    
                    if i==dead_growth+1 
                        veg_height(y,i) = life_veg_temp(nls,15);     % vegetation height in winter from general characteristics
                        
                    else  
                        veg_height(y,i) = veg_height(y,i-1);         % vegetation shoot height in winter for rest of winter period
                        
                    end
                    
                    stem_dia(y,i) = stem_dia(y,i-1);    % constant stem diameter in winter
                    veg_root(y,i) = veg_root(y,i-1);    % constant root length in winter
                end
            end
            
            
            % saving all parameters for trachytope
            % ID's in trd-file as array per ETS             
            for i=1:t_eco_year
                
                veg_dens(lastID,1)   = data_all_LS(y,6).*stem_dia(y,i); % density (stem diameter * number of stems) for Baptist formula
                veg_h(lastID,1)      = veg_height(y,i);                 % save vegetation height
                veg_r(lastID,1)      = veg_root(y,i);                   % save root length
                drag_first(lastID,1) = drag(nls,y);                     % save drag coefficient
                stem(lastID,1)       = stem_dia(y,i);                   % save stem diameter
                
                lastID = lastID+1;   % running ID to save data
                
            end
            
            
        else % for life-stage >1 and years >1
            
            for i=1:t_eco_year % loop over all ETS in year
                
                % before growth period
                if i<=start_growth 
                    veg_height(y,i) = veg_height(y-1,t_eco_year);   % initial vegetation height from previous year
                    stem_dia(y,i)   = stem_dia(y-1,t_eco_year);     % initial stem diameter from previous year
                    veg_root(y,i)   = veg_root(y-1,t_eco_year);     % initial root length from previous year
                    
                    % lin. growth over growth period
                elseif i>start_growth && i<=end_growth
                    veg_height(y,i)= veg_height(y,i-1)+ m_height(nls,y); % linear growth with slope from above
                    stem_dia(y,i)   = stem_dia(y,i-1)+ m_stemdia(nls,y); % linear growth with slope from above
                    veg_root(y,i)   = veg_root(y,i-1)+ m_root(nls,y); 	 % linear growth with slope from above
                    
                    % constant values for shoot height and linear root/diameter growth
                elseif i>end_growth && i<=dead_growth
                    veg_height(y,i) = veg_height(y,i-1);                  %  initial vegetation height from previous ETS
                    stem_dia(y,i)   = stem_dia(y,i-1)+ m_stemdia(nls,y);  %  linear growth stem diameter 
                    veg_root(y,i)   = veg_root(y,i-1)+ m_root(nls,y);     %  linear growth root length 
                    
                    % reduction in vegetation height in winter; constant root/diameter
                else
                    
                    if i==dead_growth+1  
                        veg_height(y,i) = life_veg_temp(nls,15);     % vegetation height in winter from general characteristics
                    else    
                        veg_height(y,i) = veg_height(y,i-1);         % vegetation shoot height in winter for rest of winter period
                    end
                    
                    stem_dia(y,i) = stem_dia(y,i-1);                 % constant stem diameter in winter
                    veg_root(y,i) = veg_root(y,i-1);                 % constant root length in winter
                    
                end
            end
            
            % saving all parameters for trachytope
            % ID's in trd-file as array per ETS  
            for i=1:t_eco_year
                
                veg_dens(lastID,1)   = data_all_LS(y,6).*stem_dia(y,i); % density (stem diameter * number of stems) for Baptist formula
                veg_h(lastID,1)      = veg_height(y,i);                 % save vegetation height per ETS
                veg_r(lastID,1)      = veg_root(y,i);                   % save root length per ETS
                drag_first(lastID,1) = drag(nls,y);                     % save drag per ETS
                stem(lastID,1)       = stem_dia(y,i);                   % save stem diameter per ETS
                
                lastID = lastID+1;   % running ID to save data
                
            end
        end
    end
end


%% combine all life-stage data into matrix qq_total
for nn = 1:age
    
    % for first ID replicate life-stage data and create current matrix
    if nn == 1
        qq_current = repmat(data_all_LS(nn,:), t_eco_year,1);
        qq_previous = qq_current;
        qq_total = qq_current;
    
    % for subsequent ID combine previous and present data
    else
        qq_current = repmat(data_all_LS(nn,:), t_eco_year,1);
        qq_total = [qq_previous; qq_current;];
        qq_previous = qq_total;
    end
end

% combine constant and variable parameters of vegetation type in table 
table_veg_dyn{1}=horzcat(qq_total, veg_h, stem, veg_dens, veg_r); % values for all years including calculated root length, density and stem height

clear qq_total qq_current data_all_LS qq_previous
