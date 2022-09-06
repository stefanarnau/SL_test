%% Auvibo create headmodel V1

% My understanding: 
% Step 1: read MRI data and bring it in CTF format
% Step 2: Align with electrode position data read from 3D scan
% Step 3: Reslice
% Step 4: Segmentation (BEM headmodel): segment in skin, bones and brain
%Step 4: optional: subtract corical shield using freesurfer

clear all
close all
clc
PathFT = '/home/plkn/fieldtrip-master/'; addpath(PathFT);ft_defaults;
%PathFT = 'H:\Toolboxes\fieldtrip-20210413'; addpath(PathFT);ft_defaults;
PathMri='/mnt/data_heap/TestSL/2 mriCtf'; 
PathScans='/mnt/data_heap/TestSL/2 scanDone';
PathMriAligned='/mnt/data_heap/TestSL/3 mriAligned';

SubjList={'011'}; 


%for subj=1:length(SubjList)
    subj=1; 
    load(fullfile(PathMri,SubjList{subj})) % loaded is mri
    %load (fullfile(PathScans,['elecVP' SubjList{subj}])); % loaded is elec
    load (fullfile(PathScans,['VP' SubjList{subj}])); % loaded is head_surface_new

   


    %% Adjust 3D scan and MRI data - from sourcemodel tut
    % https://www.fieldtriptoolbox.org/tutorial/sourcemodel/
    
    % added NL: to make sure that 3D has right coordiante system
    % ft_plot_mesh(head_surface_new)


    

    %% Option 2: Directly plot
    if 0
       % first align to headshape 
        % if interactive=no does not work well, then make interactive=yes and change the numbers of the transformation matrix. 
        % click on apply and then on quit , once you are done
        cfg                       = [];
        cfg.method                = 'headshape';
        cfg.headshape.headshape   = head_surface_new;
        cfg.headshape.icp         = 'no';
        cfg.headshape.interactive = 'yes'; % if "no", then automatic alignment
        mri                       = ft_volumerealign(cfg, mri);
    end

    %% Option 2: Automatic realignment and plot
    if 0
        % first align to headshape 
        % if interactive=no does not work well, then make interactive=yes and change the numbers of the transformation matrix. 
        % click on apply and then on quit , once you are done
        cfg                       = [];
        cfg.method                = 'headshape';
        cfg.headshape.headshape   = head_surface_new;
        cfg.headshape.icp         = 'yes';
        cfg.headshape.interactive = 'no'; % if "no", then automatic alignment
        mri                       = ft_volumerealign(cfg, mri);
        
        % second call, but this time interactive to check result and potentially perform manual correction.
        cfg                       = [];
        cfg.method                = 'headshape';
        cfg.headshape.headshape   = head_surface_new;
        cfg.headshape.interactive = 'yes';
        cfg.headshape.icp         = 'no';
        mri                       = ft_volumerealign(cfg, mri);
    end

        %% Reslice and save
    
        cfg            = [];
        cfg.resolution = 1;
        cfg.dim        = [256 256 256];  % what freesurfer accepts
        mri            = ft_volumereslice(cfg, mri);
        
%         cfg                       = [];
%         cfg.method                = 'headshape';
%         cfg.headshape.headshape   = head_surface_new;
%         cfg.headshape.interactive = 'yes';
%         cfg.headshape.icp         = 'no';
%         mri                       = ft_volumerealign(cfg, mri);
    
    if 0
        %% saving
        save(fullfile(PathMriAligned,SubjList{subj}),'mri'); 
    end
%end