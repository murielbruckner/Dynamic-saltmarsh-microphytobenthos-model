%% Dynamic vegetation and microphytobenthos model
% Author Muriel Br?ckner
% Final version 17/1/2020

% The model computes dynamic vegetation and microphytobenthos growth based
% on a coupling with the hydro-morphodynamic software package Delft3D FLOW.
% Below the initial values for the model have to be specified, such as
% path, model name and physical properties of the model run. The values
% with the heading % User - need to be specified manually before starting
% the simulation.
% Moreover, the name of the batch-file (ex. Starun.batch) need to be
% adjusted in the codes 'ini_work.mat' and 'vegetation_model.mat'. Please
% read the guidelines for specifications on time-scales and naming of the
% files.
%% Initialisation path
clear 
close all
clc

% User - Define directory
directory_head = 'C:\Users\bruck001\Documents\Papers\Paper 2 - Mud and vegetation on Walsoorden\Code\Test Inger domain\GVeg\'; % parent folder 
ID1            = '600x2500x5v3';  % name of the simulation file (mdf-file)
name_model     = 'Delft3D model'; % parent folder of Delft3D model and output
directory      = [directory_head, name_model,'\']; % main directory used in computations
cd([directory, 'initial files\']); % directory initial files

% turn this on in case that matlab does not contain delft3D codes (this
% folder contains the functions that read and save delft3d output files)
%  addpath('C:\Program Files (x86)\Deltares\Delft3D 4.01.00\win32\delft3d_matlab')  

% add paths with functions and scripts of the vegetation and MPB-code
addpath([directory_head,'Matlab vegetation modules']);
addpath([directory_head,'Matlab functions']);

%% User defined parameters for dynamic vegetation model

% User - Define parameters of the hydro-morphodynamic computation
VegPres  = 1;    % 1 =  vegetation present, 0 = no vegetation present
mor      = 1;    % 1= include morphology, 0 = exclude morphology 
morf     = 30;   % give manual morfac in case mor = 0
fl_dr    = 0.05; % Boundary for flooding/drying threshold used in the vegetation computations [m]
Restart  = 0;    % if restart from a output-file of vegetation model (NOTE: THIS IS NOT VALIDATED IN THIS VERSION! KEEP AT 0)
phyto    = 0;    % to turn on microphytobenthos computations phyto=1
random   = 5;    % random colonization as described in Bij de Vaate et al., 2020 with n number of cells colonized as fraction: n = SeedlingLocations/random

% User - Define time-scales
t_eco_year = 24; % number ecological time-steps per year (meaning couplings)
years      = 30; % number of morphological years of entire simulation (total simulation time*morfac/hydrodynamic time that defines one year)


%% Run vegetation and microphytobenthos model
Vegetation_model

