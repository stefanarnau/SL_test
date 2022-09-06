% Convert dicom files (anatomical MRI files) in CTF
% based on the tutorial:
% https://www.fieldtriptoolbox.org/faq/how_can_i_convert_an_anatomical_mri_from_dicom_into_ctf_format/

% by NL (nathalie.liegel@gmail.com), last change: 24.08.22

% Residuals...
clear all;

% Path vars
path_ft =  '/home/plkn/fieldtrip-master/';
path_in =  '/mnt/data_heap/TestSL/1 mri/'; 
path_out = '/mnt/data_heap/TestSL/2 mriCtf/';

% Init ft
addpath(path_ft);
ft_defaults;

% Specify subject file name
subject = '011_AuViBo'; 

% Define path to load
to_load = fullfile(path_in, [subject '_AuViBo'], 'mnt', 'xnat', 'xnat-data', 'archive', '_', 'AuViBo', 'arc001', subject, 'SCANS', '3', 'DICOM');

FolderContent = dir (fullfile(to_load,['*.dcm' ]));
mriRaw = ft_read_mri(fullfile(to_load,FolderContent(1).name)); % give the function one random dicom image of the series

% Interactively transform data to ctf
% this creates transformation matrix that can be used to transform data
% it is important to also assign the z to a point on the top of the head
cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'ctf';
mri = ft_volumerealign(cfg,mriRaw)

% added NL: check if z axis really has postive values for superior and negative for inferior, look at ctf coordinates whenyou click
% around:
cfg=[]; ft_sourceplot(cfg,mri);

% save transformed data: 
save( fullfile(path_out,SubjList{subj}) ,'mri');



