%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
else root_dir='/Volumes/hoycw_clust/';app_dir='/Users/colinhoy/Code/Apps/';end

%%
addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% General parameters
SBJs = {'EP06','EP07','EP08','EP10','EP11','EP14','EP15','EP16','EP17','EP18','EP19',...
           'EEG01','EEG02','EEG03','EEG04','EEG06','EEG07','EEG08','EEG09','EEG10','EEG12'};

%% Compute ERPs
proc_id   = 'eeg_full_ft';
an_id     = 'POW_FCz_F2t1_dm2t0_fl4t8';%'ERP_FCz_F2t1_dm2t0_fl05t20';%'POW_all_F2t1_dm2t0_fl4t8';%'ERP_all_F2t1_dm2t0_fl05t20';
for s = 1:numel(SBJs)
    SBJ03a_ERP_save(SBJs{s},proc_id,an_id);
%     SBJ03b_ERP_plot(SBJs{s},stat_conds{st_ix},proc_id,an_id,plt_id,save_fig,...
%         'fig_vis',fig_vis,'fig_ftype',fig_ftype);
end

%% Plot ERP Topos
proc_id    = 'eeg_full_ft';
conditions = 'DifFB';
an_id      = 'ERP_all_F2t1_dm2t0_fl05t20';
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';

for s = 1:numel(SBJs)
    % FRN by condition
    plt_id    = 'topo_F18t25';
    SBJ03b_ERP_plot_topo_cond(SBJs{s},conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    
    % P3 by condition
    plt_id    = 'topo_F3t45';
    SBJ03b_ERP_plot_topo_cond(SBJs{s},conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    close all;
end

% FRN Group plot
plt_id    = 'topo_F18t25';
SBJ03c_ERP_plot_grp_topo_cond(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

% P3 Group Plot
plt_id    = 'topo_F3t45';
SBJ03c_ERP_plot_grp_topo_cond(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

%% Plot POW Topos
proc_id    = 'eeg_full_ft';
conditions = 'DifFB';
an_id      = 'POW_all_F2t1_dm2t0_fl4t8';
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';

for s = 1:numel(SBJs)
    % FRN by condition
    plt_id    = 'topo_F18t25';
    SBJ03b_ERP_plot_topo_cond(SBJs{s},conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    
    % P3 by condition
    plt_id    = 'topo_F3t45';
    SBJ03b_ERP_plot_topo_cond(SBJs{s},conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    close all;
end

% FRN Group plot
plt_id    = 'topo_F18t25';
SBJ03c_ERP_plot_grp_topo_cond(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

% P3 Group Plot
plt_id    = 'topo_F3t45';
SBJ03c_ERP_plot_grp_topo_cond(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);



% Full time series by condition


%% Single SBJ RL Model
proc_id   = 'eeg_full_ft';
stat_ids  = {'RL_all_lme_st0t5','RLRT_all_lme_st0t5','RLpRT_all_lme_st0t5','RLpRTlD_all_lme_st0t5'};
% RL models:
%   RL/pWinPEus (original) = pWin, sPE, uPE
%   RLRT = RL + tRT
%   RLpRT = RLRT + ptRT
%   RLpRTlD = RLpRT + lDist
%   RLpRTiD = RLpRT + iDist

for s = 1:numel(SBJs)
    for st_ix = 1:numel(stat_ids)
        SBJ04a_RL_model(SBJs{s},proc_id,stat_ids{st_ix});
    end
    close all;
end

%% ERP: Linear Mixed Effects Model (Over Time)
proc_id   = 'eeg_full_ft';
an_ids    = {'ERP_FCz_F2t1_dm2t0_fl05t20'};%,'ERP_Fz_F2t1_dm2t0_fl05t20','ERP_Pz_F2t1_dm2t0_fl05t20'};
stat_ids  = {'RLpRTlD_all_lme_st0t5'};%'RL_all_lme_st0t5','RLRT_all_lme_st0t5','RLpRT_all_lme_st0t5',
plt_id    = 'ts_F2to1_evnts_sigLine';
save_fig  = 1;
fig_vis   = 'on';
fig_ftype = 'png';

for an_ix = 1:numel(an_ids)
    for st_ix = 1:numel(stat_ids)
        SBJ04c_ERP_grp_stats_LME_RL(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix});
        SBJ04d_ERP_plot_stats_LME_RL_fits(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix},plt_id,save_fig,...
            'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    end
    
    % Model Comparison Plots (Adjusted R-Squared)
%     SBJ04e_ERP_plot_RL_model_comparison(SBJs,proc_id,an_ids{an_ix},stat_ids,plt_id,save_fig,...
%         'fig_vis',fig_vis,'fig_ftype',fig_ftype);
end


%% Power: Linear Mixed Effects Model (Over Time)
% conditions = 'DifFB';
proc_id   = 'eeg_full_ft';
an_ids    = {'POW_FCz_F2t1_dm2t0_fl4t8'};%'POW_Fz_F2t1_dm2t0_fl4t8','POW_Fz_F2t1_dm2t0_fl1t3','POW_Pz_F2t1_dm2t0_fl1t3'};
stat_ids  = {'RLpRTlD_all_lme_st0t5'};%'RL_all_lme_st0t5','RLRT_all_lme_st0t5','RLpRT_all_lme_st0t5',
plt_id    = 'ts_F2to1_evnts_sigLine';
save_fig  = 1;
fig_vis   = 'on';
fig_ftype = 'png';

% for an_ix = 1:numel(an_ids)
%     for s = 1:numel(SBJs)
%         SBJ03a_POW_save(SBJs{s},proc_id,an_ids{an_ix});
%         % SBJ03b_ERP_plot(SBJs{s},conditions,proc_id,an_ids,plt_id,save_fig);
%     end
%     SBJ03c_ERP_plot_grp(SBJs,conditions,proc_id,an_ids{an_ix},plt_id,save_fig);
% end

for an_ix = 1:numel(an_ids)
    for st_ix = 1:numel(stat_ids)
        SBJ04c_ERP_grp_stats_LME_RL(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix});
        SBJ04d_ERP_plot_stats_LME_RL_fits(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix},plt_id,save_fig,...
            'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    end
    
    % Model Comparison Plots (Adjusted R-Squared)
    SBJ04e_ERP_plot_RL_model_comparison(SBJs,proc_id,an_ids{an_ix},stat_ids,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
end

%% ERP: Linear Mixed Effects Model (Mean Windows)
proc_id   = 'eeg_full_ft';
an_ids    = {'ERP_all_F2t1_dm2t0_fl05t20'};
stat_ids  = {'RLpRTlD_all_lme_mn2t3','RLpRTlD_all_lme_mn3t4'};
plt_id    = 'ts_F2to1_evnts_sigLine';
save_fig  = 1;
fig_vis   = 'on';
fig_ftype = 'png';

for an_ix = 1:numel(an_ids)
    for st_ix = 1:numel(stat_ids)
        SBJ04c_ERP_grp_stats_LME_RL(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix});
%         SBJ04d_ERP_plot_stats_LME_RL_fits(SBJs,proc_id,an_ids{an_ix},stat_ids{st_ix},plt_id,save_fig,...
%             'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    end
    
    % Model Comparison Plots (Adjusted R-Squared)
    SBJ04e_ERP_plot_RL_model_comparison(SBJs,proc_id,an_ids{an_ix},stat_ids,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
end

%% TFR Low Frequency Plotting
% conditions = 'DifFB';
% proc_id   = 'eeg_full_ft';
% an_ids     = 'TFR_Fz_F2t1_z2t0_fl2t14';
% save_fig  = 1;
% fig_vis   = 'on';
% fig_ftype = 'png';
% 
% for s = 1:numel(SBJs)
% %     SBJ05a_TFR_save(SBJs{s}, proc_id, an_id);
%     SBJ05b_TFR_plot(SBJs{s}, conditions, proc_id, an_ids, save_fig);
% end
% 
% SBJ05c_TFR_plot_grp(SBJs,conditions,proc_id,an_ids,save_fig);
% 
% %% Compare p values across analyses
% proc_id = 'eeg_full_ft';
% an_ids   = 'ERP_Fz_F2t1_dm2t0_fl05t20';%'ERP_Pz_F2t1_dm2t0_fl05t20';
% do_id   = 'DifOut_lme_st0t5';
% do_lab  = {'Dif','Out','Dif*Out'};
% rl_id   = 'RL_DO_lme_st0t5';
% rl_lab  = {'pWin','sPE','uPE'};
% 
% % Load DO p values
% load([root_dir 'PRJ_Error_eeg/data/GRP/GRP_' do_id '_' an_ids '.mat']);
% do_pvals = nan([numel(do_lab) numel(lme)]);
% for grp_ix = 1:numel(do_lab)
%     for t_ix = 1:numel(lme)
%         do_pvals(grp_ix,t_ix) = lme{t_ix}.Coefficients.pValue(grp_ix+1);
%     end
% end
% 
% % Load RL p values
% load([root_dir 'PRJ_Error_eeg/data/GRP/GRP_' rl_id '_' an_ids '.mat']);
% rl_pvals = nan([numel(rl_lab) numel(lme)]);
% for grp_ix = 1:numel(rl_lab)
%     for t_ix = 1:numel(lme)
%         rl_pvals(grp_ix,t_ix) = lme{t_ix}.Coefficients.pValue(grp_ix+1);
%     end
% end
% 
% % Load time vector
% eval(['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' do_id '_vars.m']);
% eval(['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJs{1} '_vars.m']);
% load([SBJ_vars.dirs.proc,SBJs{1},'_',an_ids,'.mat']);
% cfgs = []; cfgs.latency = st.stat_lim;
% roi = ft_selectdata(cfgs, roi);
% time_vec = roi.time{1};
% 
% % Plot p value comparison
% figure;
% for grp_ix = 1:3
%     subplot(2,3,grp_ix); hold on;
%     plot(time_vec,do_pvals(grp_ix,:),'color','r');
%     plot(time_vec,rl_pvals(grp_ix,:),'color','k');
%     legend(do_lab{grp_ix},rl_lab{grp_ix});
% end
% for grp_ix = 1:3
%     subplot(2,3,3+grp_ix);
%     plot(time_vec,do_pvals(grp_ix,:)-rl_pvals(grp_ix,:),'color','b');
%     legend('DO - RL');
%     ylabel('DO better ... RL better');
% end