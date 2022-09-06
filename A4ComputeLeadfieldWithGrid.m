% 

clear all
close all
clc
PathFT = 'H:\Toolboxes\fieldtrip-20220104'; addpath(PathFT);ft_defaults;

PathMri='H:\AuviboDataBase\2 mriCtf'; 
PathScans='H:\AuviboDataBase\2 scanDone';
PathMriAligned='H:\AuviboDataBase\3 mriAligned';
PathMriSeg='H:\AuviboDataBase\4 mriSeg'; 
PathLeadfield = 'H:\AuviboDataBase\5 leadfield'; 


SubjList={'011'};
subj=1; 

load(fullfile(PathMriAligned,SubjList{subj})) % loaded is mri
load(fullfile(PathMriSeg,SubjList{subj})) % loaded is 'segmentedmri','headmodel'
load (fullfile(PathScans,['elecVP' SubjList{subj}])); % loaded is elec
load (fullfile(PathScans,['VP' SubjList{subj}])); % loaded is head_surface_new

% electrodes inward
cfg = [];
cfg.method     = 'moveinward';
cfg.moveinward = 12; % 12 mm
cfg.elec       = elec;
elec = ft_electroderealign(cfg);


% Plot electrodes
figure;
% head surface (scalp)
ft_plot_mesh(headmodel.bnd(1), 'edgecolor','none','facealpha',0.8,'facecolor',[0.6 0.6 0.8]);
hold on;
% electrodes
%ft_plot_sens(elec,'style', 'sk');
ft_plot_sens(elec)


% electrodes can be aligned automatically to MRI
% see lower part of https://www.fieldtriptoolbox.org/tutorial/headmodel_eeg_bem/



% % Create sourcemodel=grid, hab ich selbst so gemacht based on help text of ft_prepare_sourcemdoel
% % leadfield can be done without a grid but then the inverse algorithmen did not work
% cfg=[]; 
% cfg.method = 'basedonmri';
%   cfg.mri             =mri;   %can be filename, MRI structure or segmented MRI structure
%   cfg.threshold       = 0.1;   %, relative to the maximum value in the segmentation
%   cfg.smooth          = 5 ; %, smoothing in voxels 
%   cfg.unit            = 'mm';
% sourcemodel = ft_prepare_sourcemodel(cfg);


% create the subject specific grid, using the template grid that has just been created
load(fullfile(PathFT, 'template/sourcemodel/standard_sourcemodel3d10mm'));
template_grid = sourcemodel;
clear sourcemodel;
cfg           = [];
cfg.warpmni   = 'yes';
cfg.template  = template_grid;
cfg.nonlinear = 'yes';
cfg.mri       = mri;
cfg.unit      ='mm';
sourcemodel          = ft_prepare_sourcemodel(cfg);

% make a figure of the single subject headmodel, and grid positions
figure; hold on;
ft_plot_headmodel(headmodel, 'edgecolor', 'none', 'facealpha', 0.4);
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));


% Create leadfield
cfg = [];   
    cfg.channel         = 'all';  % use elec.label = {}
    cfg.grad            = elec;
    cfg.headmodel       = headmodel;
    %cfg.lcmv.reducerank = 3; % default for MEG is 2, for EEG is 3
    cfg.resolution = 10;
    cfg.grid = sourcemodel;
    leadfield = ft_prepare_leadfield(cfg);

    save (fullfile(PathLeadfield,SubjList{subj}),'leadfield','sourcemodel'); 