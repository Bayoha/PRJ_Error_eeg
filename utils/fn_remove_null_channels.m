function fn_remove_null_channels(SBJ, proc_id)
%% Used to remove null channels from early pipeline bug
%   Resaves data after removing those channels according to SBJ_vars

%% Check which root directory
if exist('/home/knight/','dir');root_dir='/home/knight/';ft_dir=[root_dir 'PRJ_Error_eeg/Apps/fieldtrip/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';ft_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
else root_dir='/Volumes/hoycw_clust/';ft_dir='/Users/colinhoy/Code/Apps/fieldtrip/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath(ft_dir);
ft_defaults

%% Set up processing and SBJ variables
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);

load([SBJ_vars.dirs.preproc SBJ '_' proc_id '_final.mat']);

null_neg = cell(size(SBJ_vars.ch_lab.null));
for null_ix = 1:numel(SBJ_vars.ch_lab.null)
    null_neg{null_ix} = ['-' SBJ_vars.ch_lab.prefix SBJ_vars.ch_lab.null{null_ix} SBJ_vars.ch_lab.suffix];
end

cfg = [];
cfg.channel = [{'all'}, null_neg];
clean_trials = ft_selectdata(cfg, clean_trials);

clean_data_fname = [SBJ_vars.dirs.preproc SBJ '_' proc_id '_final.mat'];
save(clean_data_fname, '-v7.3', 'clean_trials');

end
