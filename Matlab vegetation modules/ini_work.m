%% script to initialize set up of the work folder and run D3D for time-step 0
% Author: M. Br?ckner
% Date 17/1/2020

% copy all files from initial folder into work-folder
copyfile([directory, 'initial files'],[directory, 'work']);

ets=0; % initialize first run

% read info from original mdf-file
fid_mdf1=fopen(strcat(directory,'work\',ID1,'.mdf'),'r');
mdf1 = textscan(fid_mdf1,'%s','delimiter','\n');
fclose(fid_mdf1);
mdf1=mdf1{1,1};


% Adjust runtime in mdf-file for 1 ecological timestep
for i=1:length(mdf1)
    a5 = strmatch('Tstart', mdf1{i,1});
    if a5==1
        Time_start = mdf1{[i,1]};
        Time_start = Time_start(9:length(Time_start));
        Time_start = str2double(Time_start);
        mdf1{i+1,1}=strcat('Tstop  = ',sprintf('% 2.8g',(Time_start+hydr_timestep)));
    end
end

%     write new mdf-file
fid_mdf1 = fopen(strcat(directory,'work\',ID1,'.mdf'),'w');
for k=1:numel(mdf1)
    fprintf(fid_mdf1,'%s\r\n',mdf1{k,1});
end
fclose(fid_mdf1);

% First model run to produce input data for vegetation model when not
% restart
if Restart==0
    run_line =  [directory, 'work\', 'Startrun.bat'];
    cd([directory, 'work']);
    system(run_line);
end
clear mdf MDF1

