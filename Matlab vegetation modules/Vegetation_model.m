%% Vegetation model coupled to hydromorphological model Delft3D
% Author: M. Br?ckner
% Date: 17/1/2020
% The main code of the dynamic vegetation model calling the various modules
% that define the computations. The model consists of three pre-processing
% codes that are called once at the start of the simulation
% (inid3d: Delft3D setup, iniveg: vegetation setup, iniwork: generation of
% the first output from the hydro-morphodynamic computations). The loops
% over the years of the simulations and the couplings (ETS) within each year define the
% dynamic change in vegetation settling, growth and mortality through five
% main codes (d3dadmin: handling Delft3D output and input files, extract_par:
% extraction and post-processing of Deflt3D output parameters
% relevant for vegetation computations, colonisation & settlement: computes newly
% establishing seedlings, mortality_fract_av: the mortality of the present
% vegetation). After finishing the vegetation computations Delft3D is
% called. All results are stored in resuls folder per morphological year.

%% Preprocessing

% set up D3D parameters from mdf-file
inid3d

% set up vegetation parameters from txt-file
iniveg

% set up working directory and run initial run to create trim-file with initial parameters
ini_work

%% Start dynamic vegetation model simulation

% Start year loop
for year = 1:years
    
        
    % create result folders per year for storage of output
    mkdir(strcat(directory,'results_', num2str(year), '\'));
    
   
    % Start loop over ecological time-steps (ETS)
    for ets = 1:t_eco_year
        
        % handle Delft3D administration by reading and adjusting Delft3D
        % in- and output files
        d3dadmin
        
        if VegPres > 0 % check if dynamic vegetation is present then reset matrices after ets
            
            % reset matrices at the beginning of each coupling

            BurialCurrent    = zeros(Ndim, Mdim); % reset current burial matrix
            ScourCurrent     = zeros(Ndim, Mdim); % reset current scour matrix
            burial           = zeros(Ndim, Mdim); % reset year matrix for burial
            scour            = zeros(Ndim, Mdim); % reset year matrix for scour
            BedLevelDif      = zeros(Ndim, Mdim); % reset year matrix for bed level difference
            fract_scour      = zeros(Ndim, Mdim); % reset year matrix for scour mortality
            fract_burial     = zeros(Ndim, Mdim); % reset year matrix for burial mortality
            

                % extract and calculate parameters from delft3D
                extract_par
                
                % runs colonisation module for seed dispersal and establishment
                colonisation
                
                % vegetation is assigned to grid cells
                settlement
                
                % Run mortality processes
                mortality_fract_av
                
                % copy trv-file to results folder
                copyfile([directory, 'work\veg.trv'], [directory,'results_', num2str(year), '\veg', num2str(ets), '.trv']);
                
            
        end % end of vegetation processes


         % if microphytobenthos present
        if phyto==1 
            phyto_calc
        end
        
        
        % if no vegetation present extract and save data
        if VegPres==0 && ets~=1
            data_save
        end       
        
      
        
        
        % call the batch-file of Delft3D and run    
        run_line =  strcat(directory, 'work\', 'Startrun.bat');
        cd(strcat(directory, 'work'));
        system(run_line);
               
        
        % copy results to result folder for analysis
        
        % save one full results-file per year
        if ets==t_eco_year
            
            copyfile([directory, 'work\trim-', ID1, '.def'], [directory, 'results_', num2str(year), '/trim-', ID1, '_', num2str(ets),'.def']);
            copyfile([directory, 'work\trim-', ID1, '.dat'], [directory, 'results_', num2str(year), '/trim-', ID1, '_', num2str(ets),'.dat']);
           
        end
        
        
        % to reduce output sizes average Delft3D results file of each
        % coupling
        average_trim([directory, 'work\trim-', ID1, '.dat'],[directory, 'results_', num2str(year), '/trim-avg', ID1, '_', num2str(ets)]);

              
    end % end loop over ecological timesteps
    
    
    % happy message if no crash over the entire simulation
    if year == years
        display('Yeah! You made it!!!');
    end
    
end % end year-loop




