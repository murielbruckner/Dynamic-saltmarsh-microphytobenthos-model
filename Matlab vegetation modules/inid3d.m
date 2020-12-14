%% Code reading the required Delft3D parameters into Matlab
% Author: M. Br?ckner
% Date 17/1/2020
% Reading Delft3D data to set up the model parameters in MATLAB


% Read MDF 
ini_mdf  = mdf('read',[ID1, '.mdf']);   % read initial MDF file

% Extract grid dimensions
dimensions  = str2num(cell2mat(ini_mdf.mdf.Data{1,2}(strmatch('MNKmax', char(ini_mdf.mdf.Data{1,2}(:,1)), 'exact'),2))); % determine size of grid
Mdim        = dimensions(1,1); % grid dimensions M
Ndim        = dimensions(1,2); % grid dimensions N

% Extract Chezy value 
Lchezy = strmatch('Ccofu', char(ini_mdf.mdf.Data{1,2}(:,1)), 'exact'); % find location of value in mdf-file
chezy  = str2double(ini_mdf.mdf.Data{1,2}(Lchezy,2));                  % read chezy value


% Extract morphological acceleration factor for calculation of time-scales

% if there is no morphology, manual morfac is used
if mor ==0 
    morfac = morf;
    
else
    morfac   = strmatch('MorFac', char(ini_mdf.mor.Data{2,2}(:,1)), 'exact'); % find location of morfac in mdf-file
    morfac   = ini_mdf.mor.Data{2,2}(morfac,2);                               % extract morfac data
    C        = strsplit(morfac{1});                                           % split string
    morfac   = str2double(C{1});                                              % convert to number
end
clear C Lchezy dimensions


% read simulations start and stop time
loc_start = strmatch('Tstart', char(ini_mdf.mdf.Data{1,2}(:,1)), 'exact');    % location of Tstart
Tstart    = str2double(ini_mdf.mdf.Data{1,2}(loc_start,2));                   % value of Tstart
loc_stop  = strmatch('Tstop', char(ini_mdf.mdf.Data{1,2}(:,1)), 'exact');     % location of Tstop
Tstop     = str2double(ini_mdf.mdf.Data{1,2}(loc_stop,2));                    % value of Tstop


% calculate additional time-scales
Total_sim_time = Tstop - Tstart;                      % total simulation time in minutes on ecological time-scales
if Restart ==1
hydr_timestep = Total_sim_time/(years*t_eco_year);   % hydrological minutes of one ets if restart  
else
hydr_timestep = Total_sim_time/(years*t_eco_year+1);  % hydrological minutes of one ets if first ETS computed
end

warning(sprintf('ETS is defined as %d', hydr_timestep)); % display value for user

clear Lchezy loc_start loc_stop


% check if generated hydrodynamic time-step is an integer number -
% otherwise not valid
ts_delft3D  = str2double(ini_mdf.mdf.Data{1,2}(strmatch('Dt', char(ini_mdf.mdf.Data{1,2}(:,1)), 'exact'),2)); % timestep in Delft3D in minutes
check_ets = hydr_timestep/ts_delft3D;

% Display error message and stop simulation
if floor(check_ets) ~= check_ets
    msg = 'Error occurred. Time-scales are not synchronized with D3D time-step defined in mdf';
    error(msg)
end

