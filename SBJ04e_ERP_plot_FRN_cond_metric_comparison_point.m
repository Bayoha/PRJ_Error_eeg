function SBJ04e_ERP_plot_FRN_cond_metric_comparison_point(SBJ_id,proc_id,an_id,stat_ids,plt_id,save_fig,varargin)
% Plots point estimates for FRN by condition to compare FRN metrics
%   Only for single channel right now...
%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Documents/MATLAB/';
elseif exist('Users/aasthashah/', 'dir'); root_dir = 'Users/aasthashah/Desktop/'; app_dir = 'Users/aasthashah/Applications/';
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
        elseif strcmp(varargin{v},'flip_mean')
            flip_mean = varargin{v+1};
        elseif strcmp(varargin{v},'flip_p2p')
            flip_p2p = varargin{v+1};
        elseif strcmp(varargin{v},'mirror_p2p')
            flip_p2p = varargin{v+1};
        else
            error(['Unknown varargin ' num2str(v) ': ' varargin{v}]);
        end
    end
end

% Define default options
if ~exist('fig_vis','var');   fig_vis = 'on'; end
if ~exist('fig_ftype','var'); fig_ftype = 'png'; end
if ~exist('flip_mean','var'); flip_mean = 0; end
if ~exist('flip_p2p','var');  flip_p2p = 0; end
if ~exist('mirror_p2p','var');  mirror_p2p = 1; end
if ischar(save_fig); save_fig = str2num(save_fig); end
if mirror_p2p && flip_p2p; error('why flip and mirror p2p?'); end

%% Analysis and Plotting Parameters
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);
plt_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/plt_vars/' plt_id '_vars.m'];
eval(plt_vars_cmd);

% Select SBJs
SBJs = fn_load_SBJ_list(SBJ_id);

sts        = cell(size(stat_ids));
for st_ix = 1:numel(stat_ids)
    stat_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' stat_ids{st_ix} '_vars.m'];
    eval(stat_vars_cmd);
    sts{st_ix} = st;
    if strcmp(st.measure,'ts'); error('this script is for point estimates!');end
    
    if st_ix>1
        if ~strcmp(sts{1}.trial_cond{1},sts{st_ix}.trial_cond{1})
            error('st.trial_cond does not match!');
        end
    end
    clear st stat_vars_cmd
end

% Get Plotting Parameters
[cond_lab, cond_names, ~, ~, ~] = fn_condition_label_styles(sts{1}.trial_cond{1});
ez_idx = ~cellfun(@isempty,strfind(cond_lab,'Ez'));
st_colors = repmat([0 0 0],[numel(stat_ids) 1]);    %distinguishable_colors(numel(stat_ids));
if mirror_p2p
    mir_str = '_mirp2p';
    % Set up double axis
    amp_lr = plt.nonmirror_side;
    p2p_lr = plt.mirror_side;
    p2p_st_idx = ~cellfun(@isempty,strfind(stat_ids,'p2p'));
    st_colors(p2p_st_idx,:) = plt.mirror_color;
else
    mir_str = '';
end
st_styles = {'-','--',':'};
flip_str = '';

load([root_dir 'PRJ_Error_EEG/data/' SBJs{1} '/04_proc/' SBJs{1} '_' an_id '.mat'],'roi');
ch_list = roi.label;
if numel(ch_list)>1; error('only for 1 channel now...'); end

%% Load FRN Data
data        = cell(size(stat_ids));
measure_str = cell(size(stat_ids));
for st_ix = 1:numel(stat_ids)
    tmp = load([root_dir 'PRJ_Error_eeg/data/GRP/' SBJ_id '_' stat_ids{st_ix} '_' an_id '.mat']);
    if strcmp(sts{st_ix}.measure,'mean')
        st_lim = sts{st_ix}.stat_lim + tmp.reg_pk_time;
        measure_str{st_ix} = ['Mean(' num2str(st_lim(1)) '-' num2str(st_lim(2)) ' s)'];
        if flip_mean; measure_str{st_ix} = [measure_str{st_ix} '*-1']; end
        
        % Compute Mean Window Amplitude
        data{st_ix} = NaN([numel(cond_lab) numel(SBJs)]);
        cfgs = []; cfgs.latency = st_lim; cfgs.avgovertime = 'yes';
        for s = 1:numel(SBJs)
            % Load data
            fprintf('========================== Mean Window: %s ==========================\n',SBJs{s});
            load([root_dir 'PRJ_Error_eeg/data/' SBJs{s} '/03_events/' ...
                SBJs{s} '_behav_' proc_id '_final.mat'],'bhv');
            load([root_dir 'PRJ_Error_eeg/data/',SBJs{s},'/04_proc/',SBJs{s},'_',an_id,'.mat'],'roi');
            
            % Select time of interest
            st_roi = ft_selectdata(cfgs, roi);
            
            % Load and add data
            cond_idx = fn_condition_index(cond_lab, bhv);
            for cond_ix = 1:numel(cond_lab)
                cond_trl_ix = find(cond_idx==cond_ix);
                sbj_data = nan([numel(cond_trl_ix) 1]);
                for t_ix = 1:numel(cond_trl_ix)
                    sbj_data(t_ix) = st_roi.trial{cond_trl_ix(t_ix)};
                end
                data{st_ix}(cond_ix,s) = mean(sbj_data);
            end
            
            clear roi st_roi sbj_data cond_idx bhv cond_trl_ix
        end
    elseif strcmp(sts{st_ix}.measure,'p2p')
        measure_str{st_ix} = 'Peak-to-Peak';
        if flip_p2p; measure_str{st_ix} = [measure_str{st_ix} '*-1']; end
        if mirror_p2p; measure_str{st_ix} = [measure_str{st_ix} ' (mirror)']; end
        data{st_ix} = tmp.data;
    elseif strcmp(sts{st_ix}.measure,'ts')
        measure_str{st_ix} = 'Time Series';
        error('st.measure = ts not ready yet');
    else
        error(['Unknown metric: ' metric]);
    end
end

%% Compute plotting data
plot_means = nan([numel(stat_ids) numel(cond_lab)]);
plot_sems  = nan([numel(stat_ids) numel(cond_lab)]);
for st_ix = 1:numel(stat_ids)
    for cond_ix = 1:numel(cond_lab)
        plot_means(st_ix,cond_ix) = nanmean(data{st_ix}(cond_ix,:),2);
        plot_sems(st_ix,cond_ix)  = nanstd(data{st_ix}(cond_ix,:),[],2)./sqrt(size(data{st_ix},2))';
    end
    if strcmp(sts{st_ix}.measure,'mean') && flip_mean
        mn_frn = mean(plot_means(st_ix,:));
        plot_means(st_ix,:) = 2*mn_frn-plot_means(st_ix,:);
        flip_str = [flip_str '_flipmn'];
    end
    if strcmp(sts{st_ix}.measure,'p2p') && flip_p2p
        mn_frn = mean(plot_means(st_ix,:));
        plot_means(st_ix,:) = 2*mn_frn-plot_means(st_ix,:);
        flip_str = [flip_str '_flipp2p'];
    end
end

%% Plot Model Performance
fig_name = [SBJ_id '_FRN_metric_comparison_' an_id flip_str mir_str];
figure('Name',fig_name,'units','normalized',...
    'outerposition',[0 0 0.5 0.5],'Visible',fig_vis);   %this size is for single plots
if mirror_p2p; set(gcf,'defaultAxesColorOrder',[plt.nonmirror_color; plt.mirror_color]); end

cond_x = 1:numel(cond_lab);
ez_ix = cond_x(ez_idx);
hd_ix = cond_x(~ez_idx);

st_lines = gobjects(size(stat_ids));
for st_ix = 1:numel(stat_ids)
    if mirror_p2p
        if p2p_st_idx(st_ix)
            eval(['yyaxis ' p2p_lr]);
            ax2 = gca; hold on;
            ax2.YLabel.String = 'Peak-to-Peak Amplitude (uV)';
            set(ax2,'FontSize',16);
            ax2.YDir = 'reverse';
        else
            eval(['yyaxis ' amp_lr]);
            ax = gca; hold on;
            ax.YLabel.String = 'ERP Amplitude (uV)';
        end
    else
        ax = gca; hold on;
        ax.YLabel.String = 'FRN Amplitude (uV)';
    end
    st_lines(st_ix) = errorbar(ez_ix+plt.x_fudge*(st_ix-1),...
        plot_means(st_ix,ez_ix),plot_sems(st_ix,ez_ix),...
        'Color',st_colors(st_ix,:),'LineStyle',st_styles{st_ix},'LineWidth',plt.width);
    errorbar(hd_ix+plt.x_fudge*(st_ix-1),...
        plot_means(st_ix,hd_ix),plot_sems(st_ix,hd_ix),...
        'Color',st_colors(st_ix,:),'LineStyle',st_styles{st_ix},'LineWidth',plt.width);
end

% Add label and min RT for perspective
ax = gca;
ax.XLim          = [0 numel(cond_lab)+1];
ax.XTick         = 1:numel(cond_lab);
ax.XTickLabel    = cond_names;
ax.XLabel.String = 'Conditions';
ax.Title.String  = ['FRN Metric Comparison (' ch_list{1} '; n = ' num2str(numel(SBJs)) ')'];
set(ax,'FontSize',16');

legend(st_lines,measure_str,'Location',plt.leg_loc,'Interpreter','none');
set(gca,'FontSize',16);

%% Save figure
if save_fig
    fig_dir = [root_dir 'PRJ_Error_eeg/results/ERP/' an_id '/' strjoin(stat_ids,'-') '/FRN_' plt_id '/'];
    if ~exist(fig_dir,'dir')
        mkdir(fig_dir);
    end
    
    fig_fname = [fig_dir fig_name '.' fig_ftype];
    fprintf('Saving %s\n',fig_fname);
    % Ensure vector graphics if saving
    if any(strcmp(fig_ftype,{'svg','eps'}))
        set(gcf, 'Renderer', 'painters');
    end
    saveas(gcf,fig_fname);
end

end
