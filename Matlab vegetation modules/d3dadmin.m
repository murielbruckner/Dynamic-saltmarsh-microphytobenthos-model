%% Delft3D administration module
% Author Muriel Br?ckner
% Final version 17/1/2020
% Reading the main definition file (MDF) and the results-file (TRIM) of the Delft3D simulation
 

%% Copy the results from the working directory to the results storage
 
% read the MDF-file
    fid_mdf1=fopen([directory,'work\',ID1,'.mdf'],'r');
    mdf1 = textscan(fid_mdf1,'%s','delimiter','\n');
    fclose(fid_mdf1);

% read the TRIM-file    
    NFS    = vs_use([directory, 'work\', 'trim-', ID1,'.dat'],'quiet'); % read last trim file from previous year coarse domein
   

%% Prepare MDF-file for next simulation time-step

% Determine the start time-step of the new ETS
    if Restart==1
        Tref = vs_let(NFS,'map-info-series','ITMAPC','quiet')*ts_delft3D;  % open list of all time-steps saved in the results-file 
        Tref=Tref(length(Tref));                                           % find last time-step
    else
        Tref=1; % first time-step if no restart
    end

% Run Delft3D administration function to adjust time-steps in mdf-file 
d3d_admin_v5(directory, ID1, hydr_timestep, ets, mdf1{1,1}, year, mor, Restart,Tref);
