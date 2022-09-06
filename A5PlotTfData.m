% Vorlage: https://www.fieldtriptoolbox.org/tutorial/beamformer/

clear all 
close all
clc


%% Params
PlotSgSubj=1; 


PathMain = 'H:';
    PathEeglab = fullfile(PathMain,'Toolboxes','eeglab2021.1'); addpath(PathEeglab); eeglab; 
    PathFT = fullfile(PathMain,'Toolboxes','fieldtrip-20210413'); addpath(PathFT); ft_defaults;
    PathLib1 = fullfile(PathMain,'Toolboxes','FunctionLib'); addpath(genpath(PathLib1));
      
ProjectName='Auvibo';
AnalysisName='SF001PR010'; % analysis code of outcome of this script, if ='C004P103'; then P001 is loaded
    PathPreProcMat = fullfile(PathMain,[ProjectName AnalysisName(6:end)],'OutputMats');
    PathPreProc = fullfile(PathMain,[ProjectName AnalysisName(6:end)],'3 preprocessed'); 
    PathTrialInfo = fullfile(PathMain,[ProjectName AnalysisName(6:end)], 'Trialinfo' ); 
%     PathSpatFiltMat = fullfile(PathMain,[ProjectName AnalysisName], 'OutputMats' ); mkdir(PathSpatFiltMat);
%     PathSpatFilt= fullfile(PathMain,[ProjectName AnalysisName], '3 preprocessed' ); mkdir(PathSpatFilt);
%     PathTrialInfoNew = fullfile(PathMain,[ProjectName AnalysisName], 'Trialinfo' ); mkdir(PathTrialInfoNew);
    PathMri='H:\AuviboDataBase\2 mriCtf'; 
    PathScans='H:\AuviboDataBase\2 scanDone';
    PathMriAligned='H:\AuviboDataBase\3 mriAligned';
    PathMriSeg='H:\AuviboDataBase\4 mriSeg'; 
    PathLeadfield = 'H:\AuviboDataBase\5 leadfield'; 
CondName='All'; Version='_V1_';    % normally it is V1, only if you use different versions within the same PRxxx number change it
    CondLabel={'BreakAll','NoBreakAll','Bon','Stan','Au','Vi','Prcue','Imprcue','Aucue','Vicue',... % 1-10
        'AuBon','AuStan','ViBon','ViStan',...% 11-14
        'PrcueBon','PrcueStan','ImprcueBon','ImprcueStan','ImprcueAuBon','ImprcueAuStan',... % 15-20
        'AucueBon','AucueStan','VicueBon','VicueStan',... % 21-24
        'PrcueAuBon','PrcueAuStan','PrcueViBon','PrcueViStan','ImprcueViBon','ImprcueViStan',... % 27-30,all conditions until here are without break trials!
        'BreakBon','BreakStan',...
        };
    Conditions = {'Au','Vi'};

SubjList={...
    '011',... 
    };  

% Atlas info
atlas = ft_read_atlas([PathFT '\template\atlas\aal\ROI_MNI_V4.nii']);
    IdxPoi=[1:20,23:36,39,40,43:70,79:90];  % parcels of interest
    AtlasStr='tissue'; 
% atlas = ft_read_atlas([PathFT '\template\atlas\afni\TTatlas+tlrc.BRIK']);
%     %Brodman areas: 
%     IdxPoi=16:54;
%     AtlasStr='brick1';
% anderer afni atlas: 
% atlas = ft_read_atlas([PathFT '\template\atlas\brainnetome\BNA_MPM_thr25_1.25mm.nii']); 


%% Plot atlas
% % brain von vorne, von oben und von Seite, only works for Colin27 brain, not the anatTempl
% cfg=[]; cfg.atlas=atlas; ft_sourceplot(cfg,mri);


%% Load leadfield and electrode positions
subj=1; 
load(fullfile(PathMriAligned,SubjList{subj})) % loaded is mri
load(fullfile(PathLeadfield,SubjList{subj})) % loaded is 'leadfield', 'sourcemodel'
load(fullfile(PathMriSeg,SubjList{subj})) % loaded is 'segmentedmri','headmodel'
     vol=headmodel; 
%load([PathFT '\template\headmodel\standard_bem.mat']);   % loaded is vol
load (fullfile(PathScans,['elecVP' SubjList{subj}])); % loaded is elec
    if or(strcmpi(SubjList{subj},'005'),strcmpi(SubjList{subj},'006'))
        idx=strIdx(elec.label,'AF6');
        elec.label{idx}='AF8';
    end


%% Load data and adjust elec to data structure
EEG=pop_loadset('filepath',PathPreProc,'filename',[SubjList{1} '.set']);
% Extract idx of chan order in data. idx can be applied on elec:
label={EEG.chanlocs.labels}; 
chanIdx=nan(length(label),1);
for chan=1:length(label)
    chanIdx(chan)=strIdx(elec.label,label{chan});
end
% shorten elec structure so that elec only includes the channels present in the data
elec.chanpos=elec.chanpos(chanIdx,:); % double
elec.elecpos=elec.elecpos(chanIdx,:); % double
%elec.chantype=elec.chantype(chanIdx); % cell
%elec.chanunit=elec.chanunit(chanIdx); % cell
elec.label=elec.label(chanIdx); % cell
elec.tra=elec.tra(chanIdx,chanIdx);
% Plot result:
figure
    ft_plot_mesh(vol.bnd(1), 'edgecolor','none','facealpha',0.8,'facecolor',[0.6 0.6 0.8]);
    hold on;
    % plot electrodes
    ft_plot_sens(elec);


%%
Cell={{'NotNorm',10,1,2,3}}; 
for analysis=1:length(Cell)
AnalysisCell=Cell{1,analysis};
NormStr=AnalysisCell{1,1};
Freq=AnalysisCell{1,2};
FreqRange=AnalysisCell{1,3};
StartSec=AnalysisCell{1,4};
EndSec=AnalysisCell{1,5};


%% EEGLab 2 Fieldtrip

    % Convert EEGLAB data to fieldtrip data
    EEG=pop_loadset('filepath',PathPreProc,'filename',[SubjList{subj} '.set']);
    
    %EEG=pop_epoch(EEG,{'trialcue_real'},[0,2.6]);  % concentrate on cue interval
    dataRaw=eeglab2fieldtrip( EEG, 'raw', 'none' );  % all information here that I need for the leadfield
    
    % Load trialinfo 
    load( fullfile( PathTrialInfo,[CondName 'CondIdx2D' Version SubjList{subj}] ) ); % loaded is CondIdx2D: trial x cond, logical indices
    % From tut beamformer: It is important that the length of each data piece matches an integer number of oscillatory cycles. Here 9 cycles are used resulting in a 9/18 Hz = 0.5 s time window
    
    cfg = [];  
        cfg.toilim = [StartSec EndSec];
        data = ft_redefinetrial(cfg, dataRaw);
    cfg = []; cfg.trials = CondIdx2D(:,strIdx(CondLabel,Conditions{1})); 
        cfg.toilim = [StartSec EndSec];
        ogtSgTr = ft_redefinetrial(cfg, dataRaw);
    cfg = []; cfg.trials = CondIdx2D(:,strIdx(CondLabel,Conditions{2})); 
        cfg.toilim = [StartSec EndSec];
        ebtSgTr = ft_redefinetrial(cfg, dataRaw);
    
    % make sure to have the right electrode positions : 
    data.elec=elec;
    ogtSgTrial.elec=elec; 
    ebtSgTrial.elec=elec; 
    

    %% Calculate cross power spectral density

    cfg = [];
    cfg.method    = 'mtmfft'; % multitapers fast fourier transformation
    cfg.output    = 'powandcsd';
    cfg.tapsmofrq = FreqRange;
    cfg.foilim    = [Freq Freq]; % Achtung wichtig: 2 Zahlen !!!
    freqOgt = ft_freqanalysis(cfg, ogtSgTr);
    
    cfg = [];
    cfg.method    = 'mtmfft';
    cfg.output    = 'powandcsd';
    cfg.tapsmofrq = FreqRange;
    cfg.foilim    = [Freq Freq];
    freqEbt = ft_freqanalysis(cfg, ebtSgTr);

    % dataAll = ft_appenddata([], dataPre, dataPost);
    cfg = [];
    cfg.method    = 'mtmfft';
    cfg.output    = 'powandcsd';
    cfg.tapsmofrq = FreqRange;
    cfg.foilim    = [Freq Freq];
    freqAll = ft_freqanalysis(cfg, data);

    %% Source analysis
    % Compute filter
    cfg              = [];
        cfg.method       = 'dics';  % 'dics'
        cfg.frequency    = Freq;
        cfg.sourcemodel  = sourcemodel;
        cfg.headmodel    = vol;
%         cfg.dics.projectnoise = 'yes';
        cfg.dics.lambda       = '5%';
        cfg.dics.keepfilter   = 'yes';
        cfg.dics.realfilter   = 'yes';
        sourceAll = ft_sourceanalysis(cfg, freqAll);  % problem: filter field is nan, this is not the case if the template headmodel is used
        
    % Apply filter to conditions
    cfg.sourcemodel.filter = sourceAll.avg.filter;
        sourceOgt  = ft_sourceanalysis(cfg, freqOgt );
        sourceEbt = ft_sourceanalysis(cfg, freqEbt);
    
    %% Calculate difference between conditions, interpolate to MRI data
    sourceDiff = sourceOgt;
        if strcmpi(NormStr,'Norm')
            sourceDiff.avg.pow = (sourceOgt.avg.pow - sourceEbt.avg.pow)./(sourceOgt.avg.pow + sourceEbt.avg.pow); 
        elseif strcmpi(NormStr,'NotNorm')
             sourceDiff.avg.pow = (sourceOgt.avg.pow - sourceEbt.avg.pow); 
        else 
            error(['check Param NormStr' 'subj ' SubjList{subj}]);
        end
    % mri is Colin brain, im Tut werden echte anatomische Daten genommen
    mri = ft_volumereslice([], mri);   
    cfg            = [];
        %cfg.downsample = 2;
        cfg.parameter  = 'pow';
        sourceDiffInt  = ft_sourceinterpolate(cfg, sourceDiff , mri);    
   
    maxval = max(sourceDiffInt.pow);
    if 0
    cfg = [];
        cfg.method        = 'slice';
        cfg.funparameter  = 'pow';
        cfg.maskparameter = cfg.funparameter;
        cfg.funcolorlim   = [0.0 maxval];  % default : auto
        cfg.opacitylim    = [0.0 maxval];
        cfg.opacitymap    = 'rampup';
        ft_sourceplot(cfg, sourceDiffInt); 
    end
    % Interpolate atlas to match output structure of inverse algorithm, braucht man hier gar nicht
    cfg = []; 
    cfg.interpmethod= 'nearest'; 
    cfg.parameter = AtlasStr;  % aal: 'tissue', afni: 'brick1'
    atlas = ft_sourceinterpolate(cfg, atlas, sourceDiffInt); % note: normally first functional then anatomical, but here, it needs to be the other way round   
    if PlotSgSubj
    maxval = max(sourceDiffInt.pow);
    cfg = [];
        cfg.method        = 'ortho';
        cfg.funparameter  = 'pow';
        cfg.maskparameter = cfg.funparameter;
        cfg.atlas=atlas; 
        cfg.funcolorlim   = [0.0 maxval];
        cfg.opacitylim    = [0.0 maxval];
        cfg.opacitymap    = 'rampup';
        ft_sourceplot(cfg, sourceDiffInt);
    end
end 