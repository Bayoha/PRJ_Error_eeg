function SBJ03c_ERP_save_grp_ERP_cond(SBJ_id,conditions,proc_id,an_id)
%% Save group ERP per condition
%   Peaks in group ERPs can provide data-driven window timing for analyses
%   e.g., used in SBJ04c_ERP_grp_stats_LME_mean_window
% INPUTS:
%   SBJ_id [str] - ID of subject list for group
%   conditions [str] - group of condition labels to segregate trials
%   proc_id [str] - ID of preprocessing pipeline
%   an_id [str] - ID of the analysis parameters to use
% OUTPUTS:
%   er_grp [FT struct] - group aligned/averaged ERPs

%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Documents/MATLAB/';
else; root_dir='/Volumes/hoycw_clust/'; app_dir='/Users/colinhoy/Code/Apps/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% Load Results
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);

% Select SBJs
SBJs = fn_load_SBJ_list(SBJ_id);

% Select conditions (and trials)
[cond_lab, ~, ~, ~, ~] = fn_condition_label_styles(conditions);

%% Load data
er_avg = cell([numel(cond_lab) numel(SBJs)]);
for s = 1:numel(SBJs)
    % Load data
    fprintf('========================== Processing %s ==========================\n',SBJs{s});
    load([root_dir 'PRJ_Error_eeg/data/',SBJs{s},'/04_proc/',SBJs{s},'_',an_id,'.mat'],'roi');
    load([root_dir 'PRJ_Error_eeg/data/',SBJs{s},'/03_events/',SBJs{s},'_behav_',proc_id,'_final.mat'],'bhv');
    cond_idx = fn_condition_index(cond_lab,bhv);
    
    % Separate out each condition
    cfg_er = [];
    for cond_ix = 1:numel(cond_lab)
        cfg_er.trials = find(cond_idx==cond_ix);
        er_avg{cond_ix,s} = ft_timelockanalysis(cfg_er,roi);
    end
    clear roi bhv
end

%% Average ERPs for plotting
cfg_gavg = [];
er_grp = cell(size(cond_lab));
for cond_ix = 1:numel(cond_lab)
    er_grp{cond_ix} = ft_timelockgrandaverage(cfg_gavg, er_avg{cond_ix,:});
end

%% Save topo
topo_fname = [root_dir 'PRJ_Error_eeg/data/GRP/' SBJ_id '_' conditions '_' an_id '.mat'];
fprintf('Saving %s\n',topo_fname);
save(topo_fname,'-v7.3','er_grp');

end
