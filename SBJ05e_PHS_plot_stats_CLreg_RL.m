function SBJ05e_PHS_plot_stats_CLreg_RL(SBJ_id,proc_id,an_id,stat_id,save_fig,varargin)
%% Plot group model coeffifient TFR matrix per circular-linear regressor + R2
%   Betas are outlined by significance
%   R2 is plotted as separatefigure, one matrix per regressor
%   Only for single channel
% INPUTS:
%   SBJ_id [str] - ID of subject list for group
%   proc_id [str] - ID of preprocessing pipeline
%   an_id [str] - ID of the analysis parameters to use
%   stat_id [str] - ID of the stats parameters to use
%   save_fig [0/1] - binary flag to save figure
%   varargin:
%       fig_vis [str] - {'on','off'} to visualize figure on desktop
%           default: 'on'
%       fig_ftype [str] - file extension for saving fig
%           default: 'png'
% OUTPUTS:
%   saves figures

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
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);
if an.avgoverfreq; error('why run this with only 1 freq in an_vars?'); end
if ~an.complex; error('why run this without ITPC an_vars?'); end

stat_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' stat_id '_vars.m'];
eval(stat_vars_cmd);
if ~strcmp(st.an_style,'CLreg'); error('stat_id not using circular-linear regression!'); end

% Select SBJs
SBJs = fn_load_SBJ_list(SBJ_id);

% Select Conditions of Interest
[reg_lab, reg_names, ~, ~]  = fn_regressor_label_styles(st.model_lab);

%% Load Stats
% Check stats are run on correct SBJ group
tmp = load([root_dir 'PRJ_Error_eeg/data/GRP/' SBJ_id '_' stat_id '_' an_id '.mat'],'SBJs');
if ~all(strcmp(SBJs,tmp.SBJs))
    fprintf(2,'Loaded SBJs: %s\n',strjoin(tmp.SBJs,', '));
    error('Not all SBJs match input SBJ list!');
end

% Load TFR stats
load([root_dir 'PRJ_Error_eeg/data/GRP/' SBJ_id '_' stat_id '_' an_id '.mat'],'betas','r2s','qvals');

%% Load Example TFR for Axes
load([root_dir 'PRJ_Error_eeg/data/' SBJs{1} '/04_proc/' SBJs{1} '_' proc_id '_' an_id '.mat']);
if numel(tfr.label) > 1; error('only ready for one channel right now!'); end

% Select time and trials of interest
cfgs = []; cfgs.latency = st.stat_lim;
st_tfr = ft_selectdata(cfgs, tfr);
st_time_vec = st_tfr.time;
fois = st_tfr.freq;

%% Plot Results
fig_dir = [root_dir 'PRJ_Error_eeg/results/TFR/' an_id '/' stat_id '/'];
if ~exist(fig_dir,'dir')
    mkdir(fig_dir);
end

% Create a figure for each channel
for ch_ix = 1:numel(st_tfr.label)
    % Get color limits across all regressors
    beta_clim = [-max(abs(betas(:))) max(abs(betas(:)))];
    r2_clim   = [min(r2s(:)) max(r2s(:))];
    
    % Get significance mask
    ns_alpha = 0.4;
    sig_mask = ones(size(qvals))*ns_alpha;
    sig_mask(qvals<=st.alpha) = 1;

    %% Create Beta Plot
    fig_name = [SBJ_id '_' stat_id '_' an_id '_' st_tfr.label{ch_ix} '_betas'];
    figure('Name',fig_name,'units','normalized',...
        'outerposition',[0 0 0.8 0.8],'Visible',fig_vis);
    
    % Beta Plots
    axes = gobjects([numel(reg_lab) 1]);
    [num_rc,~] = fn_num_subplots(numel(reg_lab));
    for reg_ix = 1:numel(reg_lab)
        subplot(num_rc(1),num_rc(2),reg_ix);
        axes(reg_ix) = gca; hold on;
        
        % Plot coefficient matrix
        im = imagesc(st_time_vec, fois, squeeze(betas(reg_ix,:,:)),beta_clim);
        im.AlphaData = squeeze(sig_mask(reg_ix,:,:));
        
        % Axes and parameters
        set(axes(reg_ix),'YDir','normal');
        set(axes(reg_ix),'YLim',[min(fois) max(fois)]);
        set(axes(reg_ix),'XLim',[min(st_time_vec) max(st_time_vec)]);
        set(axes(reg_ix),'XTick',[min(st_time_vec):0.1:max(st_time_vec)]);
        title([st_tfr.label{ch_ix} ': Phase-' reg_names{reg_ix} ' Beta (n=' num2str(numel(SBJs)) ')']);
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        colorbar('northoutside');
        set(axes(reg_ix),'FontSize',16);
    end
    
    % Save figure
    if save_fig
        fig_filename = [fig_dir fig_name '.' fig_ftype];
        fprintf('Saving %s\n',fig_filename);
        saveas(gcf,fig_filename);
    end
    
    %% Report max beta stats
    for reg_ix = 1:numel(reg_lab)
        max_beta = 0; max_f_ix = 0; max_t_ix = 0;
        for f_ix = 1:numel(fois)
            if max(abs(betas(reg_ix,f_ix,:))) > abs(max_beta)
                max_tmp = max(betas(reg_ix,f_ix,:));
                min_tmp = min(betas(reg_ix,f_ix,:));
                if abs(max_tmp) > abs(min_tmp)
                    [max_beta, max_t_ix] = max(betas(reg_ix,f_ix,:));
                else
                    [max_beta, max_t_ix] = min(betas(reg_ix,f_ix,:));
                end
                max_f_ix = f_ix;
            end
        end
        fprintf('%s max beta = %.03f at %.03f s and %.03f Hz; p = %.20f\n',reg_lab{reg_ix},max_beta,...
            st_time_vec(max_t_ix),fois(max_f_ix),qvals(reg_ix,max_f_ix,max_t_ix));
    end
    
    %% Create R2 Plot per Regressor
    fig_name = [SBJ_id '_' stat_id '_' an_id '_' st_tfr.label{ch_ix} '_R2'];
    figure('Name',fig_name,'units','normalized',...
        'outerposition',[0 0 0.8 0.8],'Visible',fig_vis);
    
    % Model Fit R2 Plots
    axes = gobjects([numel(reg_lab) 1]);
    [num_rc,~] = fn_num_subplots(numel(reg_lab));
    for reg_ix = 1:numel(reg_lab)
        subplot(num_rc(1),num_rc(2),reg_ix);
        axes(reg_ix) = gca; hold on;
        
        im = imagesc(st_time_vec, fois, squeeze(r2s(reg_ix,:,:)),r2_clim);
        im.AlphaData = squeeze(sig_mask(reg_ix,:,:));
        set(axes(reg_ix),'YDir','normal');
        set(axes(reg_ix),'YLim',[min(fois) max(fois)]);
        set(axes(reg_ix),'XLim',[min(st_time_vec) max(st_time_vec)]);
        set(axes(reg_ix),'XTick',[min(st_time_vec):0.1:max(st_time_vec)]);
        title([st_tfr.label{ch_ix} ': Phase-' reg_names{reg_ix} ' R2 (n=' num2str(numel(SBJs)) ')']);
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        colorbar('northoutside');
        set(axes(reg_ix),'FontSize',16);
    end
    
    % Save figure
    if save_fig
        fig_filename = [fig_dir fig_name '.' fig_ftype];
        fprintf('Saving %s\n',fig_filename);
        saveas(gcf,fig_filename);
    end
end

end
