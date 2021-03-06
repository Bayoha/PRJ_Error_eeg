function SBJ08a_CPA_candidate_TFR_save(SBJ, eeg_proc_id, odd_proc_id, cpa_id, an_id)
% Reconstruct TFR of only Candidate ICs
% Filter SBJ data to create time-frequency representation (TFR):
%   Reconstruct and clean raw data, filter, cut trials to event, select channels, save
%   If POW (an_avgoverfreq == 1), average across frequencies
% OUTPUTS:
%   tfr [ft struct] - filtered data

%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Documents/MATLAB/';
else root_dir='/Volumes/hoycw_clust/';app_dir='/Users/colinhoy/Code/Apps/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% Load Data
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);
proc_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/proc_vars/' eeg_proc_id '_vars.m'];
eval(proc_vars_cmd);
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);
cpa_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' cpa_id '_vars.m'];
eval(cpa_vars_cmd);

%% Load BHV, ICA, reconstruct and clean
% Load Behavioral Data
load([SBJ_vars.dirs.events SBJ '_behav_' eeg_proc_id '_final.mat']);

% Load EEG Data
load([SBJ_vars.dirs.preproc SBJ '_preproc_' eeg_proc_id '.mat'],'data','icaunmixing','icatopolabel');
load([SBJ_vars.dirs.preproc SBJ '_' eeg_proc_id '_02a.mat'], 'heog_ics','veog_ics');
load([SBJ_vars.dirs.proc SBJ '_' cpa_id '_' odd_proc_id '_prototype.mat']);

% Rebuild ICs from full session data
cfg           = [];
cfg.unmixing  = icaunmixing;
cfg.topolabel = icatopolabel;
ica           = ft_componentanalysis(cfg, data);

% Rebuild Data with Clean ICA Components
cfg = [];
cfg.component = setdiff(1:numel(ica.label),final_ics);
cfg.demean = 'no';
recon = ft_rejectcomponent(cfg, ica);

% Repair Bad Channels
cfg = [];
cfg.method         = 'average';
cfg.missingchannel = SBJ_vars.ch_lab.bad(:); % not in data (excluded from ica)
cfg.layout         = 'biosemi64.lay';

cfgn = [];
cfgn.channel = 'all';
cfgn.layout  = 'biosemi64.lay';
cfgn.method  = 'template';
cfg.neighbours = ft_prepare_neighbours(cfgn);

full_recon = ft_channelrepair(cfg, recon);

% Check for null channels (EEG17-23, EEG29)
null_neg = {};
for null_ix = 1:numel(SBJ_vars.ch_lab.null)
    null_lab = [SBJ_vars.ch_lab.prefix SBJ_vars.ch_lab.null{null_ix} SBJ_vars.ch_lab.suffix];
    if any(strcmp(full_recon.label,null_lab))
        null_neg = [null_neg {['-' null_lab]}];
    end
end

% Remove null if needed
if ~isempty(null_neg)
    fprintf(2,'Removing null channels: '); disp(null_neg);
    cfgs = [];
    cfgs.channel = [{'all'}, null_neg];
    full_recon = ft_selectdata(cfgs, full_recon);
end

%% Determine Filter Padding
%   At a minimum, trial_lim_s must extend 1/2*max(filter_window) prior to 
%   the first data point to be estimated to avoid edges in the filtering window.
%   (ft_freqanalysis will return NaN for partially empty windows, e.g. an edge pre-trial,
%   but ft_preprocessing would return a filtered time series with an edge artifact.)
%   Also note this padding buffer should be at least 3x the slowest cycle
%   of interest.
if strcmp(cfg_tfr.method,'mtmconvol')
    pad_len = 0.5*max(cfg_tfr.t_ftimwin)*3;
elseif strcmp(cfg_tfr.method,'wavelet')
    % add 250 ms as a rule of thumb, or longer if necessary
    pad_len = 0.5*max([cfg_tfr.width/min(cfg_tfr.foi) 0.25]);
else
    error(['Unknown cfg_tfr.method: ' cfg_tfr.method]);
end
% Cut data to bsln_lim to be consistent across S and R locked (confirmed below)
%   Add extra 10 ms just because trimming back down to trial_lim_s exactly leave
%   one NaN on the end (smoothing that will NaN out everything)
trial_lim_s_pad = [min(an.bsln_lim)-pad_len an.trial_lim_s(2)+pad_len+0.01];

% Check that baseline will be included in data cut to trial_lim_s
if an.trial_lim_s(1) < an.bsln_lim(1)
    error(['ERROR: an.trial_lim_s does not include an.bsln_lim for an_id = ' an_id]);
end
% Check that trial_lim_s includes full baseline (e.g., zbtA)
if trial_lim_s_pad(2) < an.bsln_lim(2)+pad_len+0.01
    trial_lim_s_pad(2) = an.bsln_lim(2)+pad_len+0.01;
end

%% Obtain epoching events
% Load original trigger times for epoching
cfg_trl_unconcat = cell(size(SBJ_vars.block_name));
for b_ix = 1:numel(SBJ_vars.block_name)
    cfg = [];
    cfg.dataset             = SBJ_vars.dirs.raw_filename{b_ix};
    cfg.blocknum            = b_ix;
    cfg.trialdef.eventtype  = 'STATUS';%SBJ_vars.ch_lab.trigger;
    if strcmp(an.event_type,'S')
        cfg.trialdef.eventvalue = 1;%proc.event_code;
    elseif strcmp(an.event_type,'F')
        cfg.trialdef.eventvalue = 2;
    else
        error(['Unknown an.event_type: ' an.event_type]);
    end
    cfg.trialdef.prestim    = trial_lim_s_pad(1);
    cfg.trialdef.poststim   = trial_lim_s_pad(2);
    cfg.tt_trigger_ix       = SBJ_vars.tt_trigger_ix;
    cfg.odd_trigger_ix      = SBJ_vars.odd_trigger_ix;
    cfg.trialfun            = 'tt_trialfun';
    if b_ix > 1
        cfg.endb1 = cfg_trl_unconcat{b_ix - 1}.endb1;
    end
    % Add downsample frequency since triggers are loaded from raw file
    cfg.resamp_freq         = proc.resample_freq;
    cfg_trl_unconcat{b_ix}  = ft_definetrial(cfg);
    if b_ix == 1
        cfg_trl_unconcat{b_ix}.endb1 = length(cfg_trl_unconcat{b_ix}.trl);
    end
end

% Concatenate event times across blocks after adjusting times for gaps
cfg_trl = cfg_trl_unconcat{1};
if numel(SBJ_vars.block_name)>1
    % Get length of first block
    hdr = ft_read_header(SBJ_vars.dirs.raw_filename{1});
    endsample = hdr.nSamples;
    origFs = hdr.Fs;
    
    % Adjust event times for concatenated blocks
    cfg_trl_unconcat{2}.trl(:,1) = cfg_trl_unconcat{2}.trl(:,1)+endsample/origFs*proc.resample_freq;
    cfg_trl_unconcat{2}.trl(:,2) = cfg_trl_unconcat{2}.trl(:,2)+endsample/origFs*proc.resample_freq;
    cfg_trl.trl = vertcat(cfg_trl.trl, cfg_trl_unconcat{2}.trl);
end

% If the recording was started part way through, toss events not recorded
if any(cfg_trl.trl(:,1)<1)
    cfg_trl.trl(cfg_trl.trl(:,1)<1,:) = [];
end

% Cut trials
trials = ft_redefinetrial(cfg_trl, full_recon);

% Check trial_lim_s is within trial time (round to avoid annoying computer math)
if round(trial_lim_s_pad(1)+1/trials.fsample,3) < round(trials.time{1}(1),3) || ...
        round(trial_lim_s_pad(2)-1/trials.fsample,3) > round(trials.time{1}(end),3)
    warning('trial_lim_s_pad is outside data time bounds!');
end

%% Remove bad trials
[bhv_orig] = fn_load_behav_csv([SBJ_vars.dirs.events SBJ '_behav.csv']);
load([SBJ_vars.dirs.events SBJ '_' eeg_proc_id '_02a_orig_exclude_trial_ix.mat']);
fprintf(2,'\tWarning: Removing %d trials (%d bad_raw, %d training, %d rts)\n', numel(exclude_trials),...
    numel(bad_raw_trials), numel(training_ix), numel(rt_low_ix)+numel(rt_high_ix));

% Exclude original bad trials from SBJ02a (bad_epochs, training, RT outliers)
%   Also select only channels in an.ROI!
cfgs = [];
cfgs.trials = setdiff([1:numel(trials.trial)], exclude_trials');
cfgs.channel = an.ROI;
trials = ft_selectdata(cfgs, trials);

bhv_fields = fieldnames(bhv_orig);
for f_ix = 1:numel(bhv_fields)
    bhv_orig.(bhv_fields{f_ix})(exclude_trials) = [];
end

% Exclude variance-based outlier trials from SBJ02b/c
cfgs = [];
cfgs.trials  = setdiff([1:numel(trials.trial)], SBJ_vars.trial_reject_ix);
clean_trials = ft_selectdata(cfgs, trials);

for f_ix = 1:numel(bhv_fields)
    bhv_orig.(bhv_fields{f_ix})(SBJ_vars.trial_reject_ix) = [];
end

% Check that behavioral and EEG event triggers line up
if numel(bhv_orig.trl_n)~=numel(bhv.trl_n)
    error(['Mismatch in loaded and reconstructed final behavioral trial counts: ' ...
        num2str(numel(bhv.trl_n)) ' loaded; ' num2str(numel(bhv_orig.trl_n)) ' reconstructed']);
end

%% Filter data
% all cfg_tfr options are specified in the an_vars
tfr_full = ft_freqanalysis(cfg_tfr, clean_trials);

% Trim padding off
cfgs = [];
cfgs.latency = an.trial_lim_s;
tfr = ft_selectdata(cfgs, tfr_full);
clear tfr_full

%% Baseline Correction
switch an.bsln_type
    case {'zscore', 'demean', 'my_relchange'}
        tfr = fn_bsln_ft_tfr(tfr,an.bsln_lim,an.bsln_type,an.bsln_boots);
    case {'relchange','db'}
        cfgbsln = [];
        cfgbsln.baseline     = an.bsln_lim;
        cfgbsln.baselinetype = an.bsln_type;
        cfgbsln.parameter    = 'powspctrm';
        tfr = ft_freqbaseline(cfgbsln,tfr);
    case 'none'
        if an.complex
            fprintf('\tNo baseline correction for ITPC data...\n');
        else
            error('Why no baseline correction if not ITPC?');
        end
    otherwise
        error(['No baseline implemented for an.bsln_type: ' an.bsln_type]);
end

%% Merge multiple bands
if an.avgoverfreq
    cfg_avg = [];
    cfg_avg.freq = 'all';
    cfg_avg.avgoverfreq = 'yes';
    tfr = ft_selectdata(cfg_avg,tfr);
end

%% Save Results
data_out_fname = [SBJ_vars.dirs.proc SBJ '_' eeg_proc_id '_' cpa_id '_' an_id '.mat'];
fprintf('Saving %s\n',data_out_fname);
save(data_out_fname,'-v7.3','tfr');

end

