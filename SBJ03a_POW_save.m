function SBJ03a_POW_save(SBJ,proc_id,an_id)
% Preprocess data and extract band-limited power:
%   Re-align data to event, select channels and epoch, filter, power, save
% INPUTS:
%   SBJ [str] - ID of subject to run
%   proc_id [str] - ID of preprocessing pipeline
%   an_id [str] - ID of the analysis parameters to use
% OUTPUTS:
%   roi [ft struct] - preprocessed data (can be averaged to get ERP)

%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
elseif exist('Users/aasthashah/', 'dir'); root_dir = 'Users/aasthashah/Desktop/'; app_dir = 'Users/aasthashah/Applications/';
else root_dir='/Volumes/hoycw_clust/';app_dir='/Users/colinhoy/Code/Apps/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% Load Data 
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);
proc_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/proc_vars/' proc_id '_vars.m'];
eval(proc_vars_cmd);
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);

% Load Data
load([SBJ_vars.dirs.preproc SBJ '_' proc_id '_final.mat']);
load([SBJ_vars.dirs.events SBJ '_behav_' proc_id '_final.mat']);

%% Preprocess Data for ERP
% Select channels of interest
cfgs = [];
cfgs.channel = an.ROI;
roi = ft_selectdata(cfgs, clean_trials);

cfgpp = [];
cfgpp.hpfilter  = an.hp_yn;
cfgpp.hpfreq    = an.hp_freq;
cfgpp.hpfiltord = an.hp_filtord; % Leaving blank causes instability error, 1 or 2 works 
cfgpp.lpfilter  = an.lp_yn;
cfgpp.lpfreq    = an.lp_freq;
cfgpp.demean    = an.demean_yn;
cfgpp.hilbert   = an.hilbert;
roi = ft_preprocessing(cfgpp, roi);

%% Select Data for ERP
% Realign data to desired event
if ~strcmp(proc.event_type,an.event_type)
    cfg = [];
    % Match desired time to closest sample index
    if strcmp(proc.event_type,'S') && strcmp(an.event_type,'F')
        prdm_vars = load([SBJ_vars.dirs.events SBJ '_prdm_vars.mat']);
        cfg.offset = -(prdm_vars.target + prdm_vars.fb_delay)*clean_trials.fsample;
    elseif strcmp(proc.event_type,'S') && strcmp(an.event_type,'R')
        cfg.offset = round(-bhv.rt*clean_trials.fsample);
    elseif strcmp(proc.event_type,'F')
        error('F-locked preprocessing can only be used for F-locked analysis!');
    elseif strcmp(proc.event_type,'R')% && strcmp(an.event_type,'S')
        error('Why were you doing R-locked preprocessing?');
        %error('cannot do S-locked analysis with R-locked data!');
    else
        error('unknown combination of proc and an event_types');
    end
    % Convert time axis to new event:
    %   basically: data.time{i} = data.time{i} + offset(i)/data.fsample;
    %   therefore, negative offset will shift time axis "back"
    roi = ft_redefinetrial(cfg, roi);
end

% Check window consistency
%   Check trial_lim_s is within trial time (round to avoid annoying computer math)
if round(an.trial_lim_s(1)+1/roi.fsample,3) < round(roi.time{1}(1),3) || ...
        round(an.trial_lim_s(2)-1/roi.fsample,3) > round(roi.time{1}(end),3)
    error('an.trial_lim_s is outside data time bounds!');
end

% Select window and channels of interest
cfgs = [];
cfgs.latency = an.trial_lim_s;
roi = ft_selectdata(cfgs, roi);

%% Baseline Correction
if any(strcmp(an.bsln_type,{'zscore','zboot','my_relchange'}))
    roi = fn_bsln_ft_filtered(roi,an.bsln_lim,an.bsln_type,an.bsln_boots);
else
    error(['Unknown bsln type for filtered data: ' an.bsln_type]);
end

%% Downsample
if an.dsamp_yn
    cfgds = [];
    cfgds.resamplefs = an.dsamp_freq;
    cfgds.detrend    = 'no';
    roi = ft_resampledata(cfgds, roi);
end

%% Save Results
data_out_fname = strcat(SBJ_vars.dirs.SBJ,'04_proc/',SBJ,'_',an_id,'.mat');
fprintf('Saving %s\n',data_out_fname);
save(data_out_fname,'-v7.3','roi');

end
