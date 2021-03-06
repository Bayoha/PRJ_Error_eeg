function SBJ03b_ERP_plot_topo_cond(SBJ,conditions,proc_id,an_id,plt_id,save_fig,varargin)
%% Plot ERP topography per condition for single SBJ, single window
%   Window for averaging determined in plt.plt_lim
% INPUTS:
%   SBJ [str] - ID of subject to run
%   conditions [str] - group of condition labels to segregate trials
%   proc_id [str] - ID of preprocessing pipeline
%   an_id [str] - ID of the analysis parameters to use
%   plt_id [str] - ID of the plotting parameters to use
%   save_fig [0/1] - binary flag to save figure
%   varargin:
%       fig_vis [str] - {'on','off'} to visualize figure on desktop
%           default: 'on'
%       fig_ftype [str] - file extension for saving fig
%           default: 'png'
% OUTPUTS:
%   saves figure

%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Documents/MATLAB/';
else; root_dir='/Volumes/hoycw_clust/'; app_dir='/Users/colinhoy/Code/Apps/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% Handle Variable Inputs & Defaults
if ~isempty(varargin)
    for v = 1:2:numel(varargin)
        if strcmp(varargin{v},'fig_vis') && ischar(varargin{v+1})
            fig_vis = varargin{v+1};
        elseif strcmp(varargin{v},'fig_ftype') && ischar(varargin{v+1})
            fig_ftype = varargin{v+1};
        else
            error(['Unknown varargin ' num2str(v) ': ' varargin{v}]);
        end
    end
end

% Define default options
if ~exist('fig_vis','var'); fig_vis = 'on'; end
if ~exist('fig_ftype','var'); fig_ftype = 'png'; end
if ischar(save_fig); save_fig = str2num(save_fig); end

%% Load Results
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);
plt_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/plt_vars/' plt_id '_vars.m'];
eval(plt_vars_cmd);

% Load data
load([SBJ_vars.dirs.SBJ,'04_proc/',SBJ,'_',an_id,'.mat']);
load([SBJ_vars.dirs.events SBJ '_behav_' proc_id '_final.mat']);

% Select conditions (and trials)
[cond_lab, cond_names, cond_colors, cond_styles, ~] = fn_condition_label_styles(conditions);
cond_idx = fn_condition_index(cond_lab, bhv);

% Get trials for plotting
cfgat = [];
cfgat.latency = plt.plt_lim;
cfgat.avgovertime = 'yes';
clim = [0 0];
cfga = [];
er_avg = cell(size(cond_lab));
for cond_ix = 1:numel(cond_lab)
    cfga.trials = find(cond_idx==cond_ix);
    er_avg{cond_ix} = ft_timelockanalysis(cfga, roi);
    
    % Get color limits
    tmp = ft_selectdata(cfgat,er_avg{cond_ix});
    clim = [min([clim(1) min(tmp.avg)]) max([clim(2) max(tmp.avg)])];
end

%% Plot Results
fig_dir = [root_dir 'PRJ_Error_eeg/results/ERP/' an_id '/' conditions '/' plt_id '/'];
if ~exist(fig_dir,'dir')
    mkdir(fig_dir);
end

% Create plot
fig_name = [SBJ '_' conditions '_' an_id '_' plt_id];
[num_rc,~] = fn_num_subplots(numel(cond_lab));
if num_rc(1)>1; fig_height = 0.5; else, fig_height = 0.3; end
figure('Name',fig_name,'units','normalized',...
    'outerposition',[0 0 0.5 fig_height],'Visible',fig_vis);

%% Create a figure for each channel
axes = gobjects(size(cond_lab));
for cond_ix = 1:numel(cond_lab)
    subplot(num_rc(1),num_rc(2),cond_ix);
    axes(cond_ix) = gca; hold on;
    
    cfgp = [];
    cfgp.xlim     = plt.plt_lim;
    %cfgp.zlim     = clim;
    cfgp.layout   = 'biosemi64.lay';
    cfgp.colorbar = 'yes';
    %cfgp.comment  = 'no';
    tmp = ft_topoplotER(cfgp, er_avg{cond_ix});
    title(cond_lab{cond_ix});
    tmp = caxis;
    clim = [min([clim(1) tmp(1)]) max([clim(2) tmp(2)])]; 
    axis tight
end

%% Save figure
if save_fig
    fig_fname = [fig_dir fig_name '.' fig_ftype];
    fprintf('Saving %s\n',fig_fname);
    saveas(gcf,fig_fname);
end

end
