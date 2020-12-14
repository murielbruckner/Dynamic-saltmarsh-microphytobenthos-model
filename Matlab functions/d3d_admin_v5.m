function[mdf] = d3d_admin_v5(dir, ID, ts, ets, mdf, year, m,res,Tref)
% Function to handle administration in Delft3D when coupling the vegetation
% model to Delft3D by changing the mdf/mor file to according time-scales
% Author: M. Br?ckner
% Date 17/1/2020
% dir = parent directory
% ID = ID of the run (each run is copied every ecological timestep to the results folder carrying the ID)
% ts = minutes of ecological timestep. The start and stop times of the runs are
% adjusted to this value
% ets = running ID for the ecological loop
% mdf = mdf-files read into MATLAB
% year = running ID for the year loop
% m  = if morphology is taken into account
% res = is restart from previous data
% Tref = reference start time from restart run

%% adjust mdf- and mor-file time-scales

% delete initial conditions for first ets  
if year ==1 && ets ==1  % after first timestep ets=0 the initial conditions have to be deleted

try 
    a1 = strmatch('Zeta0', mdf); % find location of zeta0
    
    a2 = strmatch('C0',mdf); % find location of C0
         for n=(a1+1):a2(end)
            mdf{n,1}  = []; % Delete the rows containing initial hydromorphology conditions
         end    
catch
    a1 = strmatch('Restid', mdf); % find location of restID
end

% overwrite restID with the new ID
mdf{a1,1} = sprintf('%s',strcat('Restid = trim-', ID)); %Replace position of Zeta0 by Restid corresponds to Trim-file containing conditions of previous run to set as new initial condition
end


% adjust mor-file spin-up time        
    if m==1 % only if morphology is taken into account (otherwise no morfac)
    % open mor-file 
    fid_mor=fopen(strcat(dir,'work\',ID,'.mor'),'r');
    mor = textscan(fid_mor,'%s','delimiter','\n');
    fclose(fid_mor);    
    % find location of morstt and replace by actual time     
    try
    a3 = strmatch('MorStt', mor{1,1}); % find morphological start time
        Time_mor = mor{1,1}{a3,1}; % find morphological start time
        Time_mor = Time_mor(8:19);
        Time_mor = str2double(Time_mor);
        % determine if spin-up interval is still to consider
        if Time_mor/ts > sum(1:year)*ets 
        a4 = Time_mor-sum(1:ets)*(ts); % in case spin-up still going on
        mor{1,1}{a3,1} = sprintf('%s',strcat('MorStt =        ', num2str(a4),'     [min]    Spin-up interval from TStart till start of morphological changes')); % Set morphological start time to 0
        else
        mor{1,1}{a3,1} = []; % in case spin-up is over
        end  
    catch     
    end
        % write mor-file to folder
        fid_mor = fopen(strcat(dir,'work\',ID,'.mor'),'w');
        for k=1:numel(mor{1,1})
        fprintf(fid_mor,'%s\r\n',mor{1,1}{k,1}); 
        end
        fclose(fid_mor);
    end
    
% for restart only change start and stop time from moment of restart       
if res==1 && ets==1 && year==1
    % extract start and stop time from mdf-file_0 as integer 
 for i=1:length(mdf)
    a5 = strmatch('Tstart', mdf{i,1});
    if a5==1   
    Time_start = mdf{[i,1]};
    Time_start = Time_start(9:length(Time_start));
    Time_start = str2double(Time_start);
    mdf{i,1}=strcat('Tstart = ',sprintf('% 2.8g',(Tref))); % add the end time-step from trim before
    mdf{i+1,1}=strcat('Tstop  = ',sprintf('% 2.8g',(Tref+ts)));
    end
 end
else
    
% extract start and stop time from mdf-file_0 as integer 
 for i=1:length(mdf)
    a6 = strmatch('Tstop', mdf{i,1});
    if a6==1
Time_stop = mdf{[i,1]};
Time_stop = Time_stop(9:length(Time_stop));
Time_stop = str2double(Time_stop);
    mdf{i-1,1}=strcat('Tstart = ',sprintf('% 2.8g',(Time_stop)));
    mdf{i,1}=strcat('Tstop  = ',sprintf('% 2.8g',(Time_stop+ts)));
    end
 end
end
    
% write new mdf-file into work-folder
    fid_mdf = fopen(strcat(dir,'work\',ID,'.mdf'),'w');
    for k=1:numel(mdf)
    fprintf(fid_mdf,'%s\r\n',mdf{k,1}); 
    end
      fclose(fid_mdf);  
end
