function SBJ03b_ERP_plot_stats(SBJ,conditions,proc_id,an_id,plt_id,save_fig,varargin)

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
        elseif strcmp(varargin{v},'write_report')
            write_report = varargin{v+1};
        else
            error(['Unknown varargin ' num2str(v) ': ' varargin{v}]);
        end
    end
end

% Define default options
if ~exist('fig_vis','var'); fig_vis = 'on'; end
if ~exist('fig_ftype','var'); fig_ftype = 'png'; end
if ~exist('write_report','var'); write_report = 0; end
if ischar(save_fig); save_fig = str2num(save_fig); end

%% Load Results
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);
proc_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/proc_vars/' proc_id '_vars.m'];
eval(proc_vars_cmd);
an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' an_id '_vars.m'];
eval(an_vars_cmd);
plt_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/plt_vars/' plt_id '_vars.m'];
eval(plt_vars_cmd);

[cond_lab, cond_colors, cond_styles, ~] = fn_condition_label_styles(conditions);

load([SBJ_vars.dirs.SBJ,'04_proc/',SBJ,'_',conditions,'_',an_id,'.mat']);
load([SBJ_vars.dirs.events SBJ '_behav_' proc_id '_clean.mat']);
% load([SBJ_vars.dirs.events SBJ '_behav_' proc_id '_final.mat']);

% Trim data to plotting epoch
cfg_trim = [];
cfg_trim.latency = plt.plt_lim;
for cond_ix = 1:numel(roi_erp)
    % Get rid of .trial field to avoid following bug that tosses .avg, .var, and .dof:
    %   "Warning: timelock structure contains field with and without repetitions"
%     roi_erp{cond_ix} = rmfield(roi_erp{cond_ix},'trial');    
    roi_erp{cond_ix} = ft_selectdata(cfg_trim,roi_erp{cond_ix});    
end

% Get trials for butterfly plot
if plt.butterfly
    roi = ft_selectdata(cfg_trim, roi);
    
    trials = cell(size(cond_lab));
    cond_idx = fn_condition_index(conditions, bhv);
    for cond_ix = 1:numel(cond_lab)
        trials{cond_ix} = nan([numel(roi.label) sum(cond_idx==cond_ix) numel(roi.time)]);
        for t_ix = 1:numel(roi.trial)
            trials{cond_ix}(:,t_ix,:) = roi.trial{t_ix}(:,cond_idx==cond_ix);
        end
    end
end

%% Plot Results
fig_dir = [root_dir 'PRJ_Error_eeg/results/ERP/' SBJ '/' conditions '/' an_id '/'];
if ~exist(fig_dir,'dir')
    mkdir(fig_dir);
end

% Create a figure for each channel
sig_ch = zeros(size(stat.label));
for ch_ix = 1:numel(stat.label)
    %% Compute plotting data
    % Find significant time periods
    if sum(stat.mask(ch_ix,:))>0
        sig_ch(ch_ix) = 1;
        mask_chunks = fn_find_chunks(stat.mask(ch_ix,:));
        sig_chunks = mask_chunks;
        sig_chunks(stat.mask(ch_ix,sig_chunks(:,1))==0,:) = [];
        % If stat and roi_erp aren't on same time axis, adjust sig_chunk indices
        if (size(stat.time,2)~=size(roi_erp{1}.time,2)) || (sum(stat.time==roi_erp{1}.time)~=numel(stat.time))
            for chunk_ix = 1:size(sig_chunks,1)
                sig_chunks(chunk_ix,1) = find(roi_erp{1}.time==stat.time(sig_chunks(chunk_ix,1)));
                sig_chunks(chunk_ix,2) = find(roi_erp{1}.time==stat.time(sig_chunks(chunk_ix,2)));
            end
        end
        fprintf('%s -- %i SIGNIFICANT CLUSTERS FOUND, plotting with significance shading...\n',...
                                                                stat.label{ch_ix},size(sig_chunks,1));
    else
        sig_chunks = [];
        fprintf('%s -- NO SIGNIFICANT CLUSTERS FOUND, plotting without significance shading...\n',stat.label{ch_ix});
    end
    
    %% Create plot
    fig_name = [SBJ '_' conditions '_' an_id '_' stat.label{ch_ix}];    
    figure('Name',fig_name,'units','normalized',...
        'outerposition',[0 0 0.5 0.5],'Visible',fig_vis);   %this size is for single plots
%     [plot_rc,~] = fn_num_subplots(numel(stat.label));
%     if plot_rc(1)>1; fig_height=1; else fig_height=0.33; end;
%     subplot(plot_rc(1),plot_rc(2),ch_ix);
    ax = gca; hold on;
    
    % Plot individual trials per condition
    if plt.butterfly
        for cond_ix = 1:numel(cond_lab)
            plot(roi_erp{cond_ix}.time,trials{cond_ix}(ch_ix,:),...
                'Color',cond_colors{cond_ix},'LineWidth',plt.butterfly_width);
        end
    end

    % Plot Means (and variance)
    ebars = cell(size(cond_lab));
    main_lines = gobjects([numel(cond_lab)+numel(an.event_type) 1]);
    for cond_ix = 1:numel(cond_lab)
        ebars{cond_ix} = shadedErrorBar(roi_erp{cond_ix}.time, roi_erp{cond_ix}.avg(ch_ix,:),...
            squeeze(sqrt(roi_erp{cond_ix}.var(ch_ix,:))./sqrt(numel(roi_erp{cond_ix}.cfg.previous.trials)))',...
            {'Color',cond_colors{cond_ix},'LineWidth',plt.mean_width,...
            'LineStyle',cond_styles{cond_ix}},plt.errbar_alpha);
        main_lines(cond_ix) = ebars{cond_ix}.mainLine;
    end
    ylims = ylim;
    
    % Plot Significance
    if ~isempty(sig_chunks)
        for sig_ix = 1:size(sig_chunks,1)
            if strcmp(plt.sig_type,'line')
                sig_times = sig_chunks(sig_ix,1):sig_chunks(sig_ix,2);
                for cond_ix = 1:numel(conditions)
                    if strcmp(plt.sig_loc,'below')
                        sig_y = ylims(1) - cond_ix*(ylims(2)-ylims(1))*plt.sig_loc_factor;
                    elseif strcmp(plt.sig_loc,'above')
                        sig_y = ylims(2) + cond_ix*(ylims(2)-ylims(1))*plt.sig_loc_factor;
                    end
                    line(sig_times,repmat(sig_y,size(sig_times)),...
                        'LineWidth',plt.sig_width,'Color',cond_colors{cond_ix});
                end
            elseif strcmp(plt.sig_type,'patch')
                patch([sig_chunks(sig_ix,1) sig_chunks(sig_ix,1) sig_chunks(sig_ix,2) sig_chunks(sig_ix,2)],...
                    [ylims(1) ylims(2) ylims(2) ylims(1)],...
                    plt.sig_color,'FaceAlpha',plt.sig_alpha);
            elseif strcmp(plt.sig_type,'bold')
                sig_times = sig_chunks(sig_ix,1):sig_chunks(sig_ix,2);
                for cond_ix = 1:numel(cond_lab)
                    line(sig_times,roi_erp{cond_ix}.avg(ch_ix,sig_chunks(sig_ix,1):sig_chunks(sig_ix,2)),...
                        'Color',cond_colors{cond_ix},'LineStyle',plt.sig_style,...
                        'LineWidth',plt.sig_width);
                end
            else
                error('unknown sig_type');
            end
        end
    end
    
    % Plot Extra Features (events, significance)
    for evnt_ix = 1:numel(an.event_type)
        main_lines(numel(cond_lab)+evnt_ix) = line([0 0],ylim,...
            'LineWidth',plt.evnt_width(evnt_ix),'Color',plt.evnt_color{evnt_ix},'LineStyle',plt.evnt_style{evnt_ix});
    end
    
    % Axes and Labels
%     ax.YLim          = ylims; %!!! change for plt.sigType=line
    ax.YLabel.String = 'uV';
    ax.XLim          = [plt.plt_lim(1) plt.plt_lim(2)];
    ax.XTick         = plt.plt_lim(1):plt.x_step_sz:plt.plt_lim(2);
    ax.XLabel.String = 'Time (s)';
    ax.Title.String  = stat.label{ch_ix};
    if plt.legend
        legend(main_lines,cond_lab{:},an.event_type,'Location',plt.legend_loc);
    end
    
    % Save figure
    if save_fig
        fig_fname = [fig_dir fig_name '.' fig_ftype];
        fprintf('Saving %s\n',fig_fname);
        saveas(gcf,fig_fname);
        %eval(['export_fig ' fig_filename]);
    end
end

%% Save out list of channels with significant differences
if write_report
    sig_report_fname = [fig_dir 'ch_sig_list.csv'];
    sig_report = fopen(sig_report_fname,'w');
    fprintf(sig_report,'%s\n',an_id);
    fprintf(sig_report,'label,%s\n',conditions);
    for ch_ix = 1:numel(stat.label)
        fprintf(sig_report,'%s,%.0f\n',stat.label{ch_ix},sig_ch(ch_ix));
    end
    fclose(sig_report);
end

end
