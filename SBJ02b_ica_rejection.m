function SBJ02b_ica_rejection(SBJ, proc_id, reject_visual)
%This function does the ICA rejection and repairs the bad channels.  Do visual trial rejection and %record the bad trials in SBJ_vars.trial_reject_ix.
%SBJ = 'EEG#'
%Proc_id = 'egg_full_ft' or 'odd_full_ft' for oddball trials
%gen_figs = 0 (if no, don't generate), 1 (if yes)
%fig_vis = 1 if a data_browser view of the time course of the ICA
%components is desired
%reject_visual = 0 if don't want to do visual trial rejection, 1 if do

if exist('/home/knight/','dir');root_dir='/home/knight/';ft_dir=[root_dir 'PRJ_Error_eeg/Apps/fieldtrip/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';ft_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
elseif exist('Users/aasthashah/', 'dir'); root_dir = 'Users/aasthashah/Desktop/', ft_dir = 'Users/aasthashah/Applications/fieldtrip';
else root_dir='/Volumes/hoycw_clust/';ft_dir='/Users/colinhoy/Code/Apps/fieldtrip/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath(ft_dir);
ft_defaults

%% Load the data
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);

load([SBJ_vars.dirs.preproc SBJ '_' proc_id '_02a.mat']);

%% IC rejection
cfg = [];
cfg.component = unique([SBJ_vars.ica_reject, heog_ics, veog_ics]);
cfg.demean = 'no';
clean_trials = ft_rejectcomponent(cfg, ica);

%% Repair Bad Channels
%   Adding them back in enables ft_databrowser to plot full cap correctly
cfg = [];
cfg.method         = 'average';
cfg.missingchannel = SBJ_vars.ch_lab.bad(:); % not in data (excluded from ica)
cfg.layout         = 'biosemi64.lay';

cfgn = [];
cfgn.channel = 'all';
cfgn.layout  = 'biosemi64.lay';
cfgn.method  = 'template';
cfg.neighbours = ft_prepare_neighbours(cfgn);

clean_trials = ft_channelrepair(cfg, clean_trials);

%% Visual Trial Rejection
if reject_visual
    cfg = [];
    cfg.method = 'summary';  % 'summary' for trials+channels; 'channel' for individual trials
    clean_sum = ft_rejectvisual(cfg, clean_trials);
    cfg = [];
    cfg.derivative = 'yes';
    clean_deriv = ft_preprocessing(cfg, clean_trials);
    cfg = [];
    cfg.method = 'summary';
    clean_summ_deriv = ft_rejectvisual(cfg, clean_deriv);
    cfg_plot.viewmode = 'vertical';
    cfg_plot.ylim = [-15 15];
    ft_databrowser(cfg_plot, clean_trials);
    % Report channels and trials identified above in SBJ_vars, then re-run
    % these aren't saved to clean trials because that will mess up the
    % indices for the data rejection
else
    fprintf('\nGo run SBJ02c_trial_rejection please!\n');
end

%% Save outputs
clean_data_fname = [SBJ_vars.dirs.preproc SBJ '_' proc_id '_02b.mat'];
save(clean_data_fname, '-v7.3', 'clean_trials');

end
