%% Initialization of dynamic vegetation
% Author: M. Br?ckner
% Date 17/1/2020
% The main aim of this code is to define all vegetation type properties
% through reading in the veg.txt-files. The number of different vegetation
% types is limited to nn=20. Moreover, this code produces the vegetation
% definition file (trd-file) that is important for the communication with
% Delft3D FLOW. Pre-allocation of vegetation and mortality matrices.

if VegPres > 0 % check if there is dynamic vegetation present
    
    % extract number of vegetation types in folder based on number of veg.txt-files
    
%     for nn = 1:20                                 % maximum 20 vegetation types
%         matFilename = sprintf('Veg%d.txt', nn);
%         Check = exist(matFilename,'file');        % if file is present value check = 2, else zero
%         
%         if Check ==2
%             num_veg_types = nn;                   % save number of veg types in seperate vector
%             
%         else
%             continue;
%         end
%     end
%     
%     clear Check
    
    
    
    %% read and process vegetation information
    
    
    % Initialisation - create struct and matrices that save the imported data
    
    life_veg_char       = {};                          % matrix for recording specific vegetation characteristics per vegetation life stage
    LocEco              = zeros(1,2);    % matrix for capturing start and stop of colonisation per vegetation type in ecological timesteps
    table_veg_dyn       = {};                          % structure for creating dynamic vegetation characteristics of all vegetation types
    general_veg_char    = zeros(1, 16); % matrix for recording constant vegetation characteristics for each vegetation type
    
    
    % compute the necessary parameters for the trd-file from the
    % veg.txt-file and combine to matrix
    
    
        
        % reset matrix between vegetation types
        life_veg_temp       = []; % temporary matrix for recording specific vegetation characteristics per vegetation type
        
        
        % read general data from veg.txt-file
        FID                         = fopen([directory, '\initial files\', 'Veg1.txt']);  % open veg.txt-file
        gen_data                    = textscan(FID, '%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f%7.3f/n%*f', 'HeaderLines', 41);
        fclose(FID);
        mat_veg                     = cell2mat(gen_data);       % extract general vegetation characteristics
        general_veg_char(:, :)      = mat_veg;                  % save general charactersitics per vegetation type
        num_ls                      = mat_veg(6);               % count number of lifestages
        num_mon                     = mat_veg(2);               % extract amount of months for seed dispersal
        age                         = general_veg_char(1,1); % save age of vegetation      
        clear gen_data mat_veg
        
        
        % construct matrix for seed dispersal
        FID             = fopen([directory, '\initial files\', 'Veg1.txt']);    % open veg.txt-file
        ColEco          = textscan(FID, strcat('%f %f ', '/n%*f'), 'HeaderLines', 42);          % ETS that seed dispersal occurs
        fclose(FID);
        LocEco(:,:)  = cell2mat(ColEco);                                                     % save ETS where seed dispersal occurs per vegetation type
        clear ColEco
        
        % extract life-stage data
        for nls = 1:num_ls                              % loop over life stages
            FID                   = fopen([directory, '\initial files\', 'Veg1.txt']);    % open veg.txt-file
            LS_data               = textscan(FID,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f/n%*f', 'HeaderLines', 42+nls);
            fclose(FID);
            mat_veg               = cell2mat(LS_data);  % extract life-stage data
            life_veg_temp(nls, :) = mat_veg;            % save life-stage data  per life-stage
            
        end % end loop over life stages
        
        clear mat_veg LS_data
        
        
        % save life-stage data per vegetation type
        life_veg_char{1} = life_veg_temp;
        

        
        % extract mud threshold for colonization 
        mud_colo = life_veg_temp(nls,8);    % extract mud required
        mud_colonization = mud_colo;  % save mud per veg-type
        
        
        % check growth method vegetation (1 = variation between years)
        if general_veg_char(1,4) == 2
            
        % run code to compute seasonal saltmarsh growth            
        GrowthStrategy_saltmarsh; % seasonal salt marsh growth
        
        elseif general_veg_char(1,4) == 1
        
        % run code to compute tree growth                      
        GrowthStrategy_trees; % logarithmic growth
            
        end
        
        
        % loop over the growth data calculated in growth strategy to combine data
        % into array for all veg-types and life-stages
        
        for k=1:length(table_veg_dyn{1}) % loop over array containing variable vegetation data per vegetation type
            

                dens(k,1)       = round(table_veg_dyn{1,1}(k,20),2);   % density
                height(k,1)     = round(table_veg_dyn{1,1}(k,18),3);   % height
                drag_coeff(k,1) = drag_first(k,1);                      % drag coefficient
                format long
                id=k;                                                   % run id to write data subsequently into array            
  
            
            trd_sep{1}(k,1)=id;                                           % saving ID's per veg-type
        end
    
    
    
    %% Construct TRD file: TrachID, roughness formulation,
    %% vegetation height, drag coefficient, Chezy-value
        
    % replicate static values to length of trd-file
    trach_ids = [1:1:id]';                              % trachytope ids
    chezy_mat = repmat(chezy,id,1);                     % replicate chezy value for length of array
    rough_eq = repmat(general_veg_char(1,5),id,1);   % replicate number of vegetation formula used in trachytopes
    format long
    
    % add all vegetation data to array
    trd = [trach_ids, rough_eq, height, dens, drag_coeff, chezy_mat];
    
    % write trd file to folder
    dlmwrite('veg.trd', trd, '\t');
    
    % pre-allocate matrix that saves and tracks mortalities
        ini_frac_store{1}     = zeros(Ndim,Mdim,age*t_eco_year);
        ini_frac_store_dry{1} = zeros(Ndim,Mdim,age*t_eco_year);
        fract_area_all_veg{1} = zeros(Ndim,Mdim,age*t_eco_year);
        
    
    % read vegetation fractions
    if Restart ==1 % create matrix with twice the run time to ensure continuation of dispersal at right months
        fract_area_all_veg      = load('fract_all_veg.mat', 'fract_area_all_veg'); % load last vegetation fraction cell of previous run (should be added to input folder)
        fract_area_all_veg      = struct2cell(fract_area_all_veg);
        fract_area_all_veg      = fract_area_all_veg{1};

    end   
    
    MortCause = {};              % structure for saving mortality causes and magnitude per morpho pressure
end
