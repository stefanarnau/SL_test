% Create headmodel

clear all
close all
clc
PathFT = '/home/plkn/fieldtrip-master/'; addpath(PathFT);ft_defaults;

PathMri='/mnt/data_heap/TestSL/2 mriCtf'; 
PathScans='/mnt/data_heap/TestSL/2 scanDone';
PathMriAligned='/mnt/data_heap/TestSL/3 mriAligned';
PathMriSeg='/mnt/data_heap/TestSL/4 mriSeg'; 


SubjList={'011'}; 


for subj=1:length(SubjList)
    load(fullfile(PathMriAligned,SubjList{subj}))

    % takes 15 mins accroding to tut, faster for me:
    cfg           = [];
    cfg.output    = {'brain','skull','scalp'};
    % only optional, see this faq: https://www.fieldtriptoolbox.org/faq/why_does_my_eegheadmodel_look_funny/
        %cfg.scalpthreshold = 'no'; % 'no', or scalar, relative threshold value which is used to threshold the anatomical data in order to create a volumetric scalpmask (see below),default = 0.1)       
        cfg.scalpsmooth  = 20;  % = 'no', or scalar, the FWHM of the gaussian kernel in voxels, (default = 5)
    segmentedmri  = ft_volumesegment(cfg, mri);  

    % now you should actually plot the skull, bone, etc (it does not say in the tut how)
    % does not work as anatomy is mising: cfg=[]; ft_sourceplot(cfg,segmentedmri);
    figure; cfg=[]; cfg.funparameter = 'brain'; ft_sourceplot(cfg,segmentedmri);
    figure; cfg=[]; cfg.funparameter = 'skull'; ft_sourceplot(cfg,segmentedmri);
    figure; cfg=[]; cfg.funparameter = 'scalp'; ft_sourceplot(cfg,segmentedmri);

    %% create mesh
    cfg=[];
    cfg.tissue={'brain','skull','scalp'};
    cfg.numvertices = [3000 2000 1000];
    bnd=ft_prepare_mesh(cfg,segmentedmri);
    % plot
    figure;
    ft_plot_mesh(bnd(3),'facecolor','none'); %scalp
    figure;
    ft_plot_mesh(bnd(2),'facecolor','none'); %skull
    figure;
    ft_plot_mesh(bnd(1),'facecolor','none'); %brain



    %% Create a volume conduction model using 'dipoli', 'openmeeg', or 'bemcp'.
    % Dipoli doe not work for windows
    cfg        = [];
    cfg.method ='dipoli'; % You can also specify 'openmeeg', 'bemcp', or another method. (NL: openmeeg is BEM according to help text of ft_prepare_headmodel)
    headmodel  = ft_prepare_headmodel(cfg, bnd);

    % plot
    figure;
    ft_plot_mesh(headmodel.bnd(3),'facecolor','none'); %scalp
    figure;
    ft_plot_mesh(headmodel.bnd(2),'facecolor','none'); %skull
    figure;
    ft_plot_mesh(headmodel.bnd(1),'facecolor','none'); %brain


    figure;clf
    % brain: % facecolor=color von Fläche zwischen kanten, edgecolor= color von punkten und Kanten
    ft_plot_mesh(headmodel.bnd(1), 'facecolor','r', 'facealpha', 0.1,...
        'edgecolor', [1 1 1], 'edgealpha', 0.5); % ,'maskstyle','colormix', 'facecolor',[0.2 0.2 0.2],'edgealpha', 0.05
    hold on;
    ft_plot_mesh(headmodel.bnd(2),'facecolor','b','edgecolor','none','facealpha',0.2); % skull
    hold on;
    ft_plot_mesh(headmodel.bnd(3),'edgecolor','none','facecolor',[0.4 0.6 0.4],'facealpha', 0.1);  % scalp


% 
%     % load electrode positions 
%     load (fullfile(PathScans,['elecVP' SubjList{subj}])); % loaded is elec



    save(fullfile(PathMriSeg,SubjList{subj}),'segmentedmri','headmodel'); 

end

