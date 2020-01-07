%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
else root_dir='/Volumes/hoycw_clust/';app_dir='/Users/colinhoy/Code/Apps/';end

%%
addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
%addpath([app_dir 'fieldtrip/']);
ft_defaults

%% General parameters
SBJs = {'EEG01','EEG02','EEG03','EEG04','EEG06','EEG07','EEG08','EEG09','EEG10','EEG12'};

%% Run preprocessing
proc_id_ica = 'odd_full_ft';
gen_figs    = 0;
fig_vis     = 'off';
reject_visual = 0;
plot_final_check = 0;

% SBJ_times = zeros(size(SBJs));
% tic;
% for s = 1:numel(SBJs)
%     SBJ02a_artifact_rejection(SBJs{s}, proc_id, gen_figs, fig_vis)
%     SBJ02b_ica_rejection(SBJs{s}, proc_id, proc_id_ica, reject_visual);
%     SBJ02c_trial_rejection(SBJs{s}, proc_id, plot_final_check)
%     SBJ_times(s) = toc;
%     if s==1; elapsed = SBJ_times(s); else; elapsed = SBJ_times(s)-SBJ_times(s-1); end
%     fprintf('%s preprocessed at %.1f s (SBJ time = %.1f)\n',SBJs{s},SBJ_times(s),elapsed);
% end


%% View basic ERPs
proc_id    = 'odd_full_ft';
an_id      = 'ERP_Fz_S2t13_dm2t0_fl05t20';
stat_conds = {'Odd'};%,'DifOutS'};
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';

for st_ix = 1:numel(stat_conds)
    plt_id     = 'ts_F2to13_evnts_sigLine';
    for s = 1:numel(SBJs)
        SBJ03a_ERP_save(SBJs{s},proc_id,an_id);
        SBJ03b_ERP_plot(SBJs{s},stat_conds{st_ix},proc_id,an_id,plt_id,save_fig,...
            'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    end
    SBJ03c_ERP_plot_grp(SBJs,stat_conds{st_ix},proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    
    plt_id = 'ts_F2to13_but_evnts_sigPatch';
    SBJ03c_ERP_plot_grp_butterfly(SBJs,stat_conds{st_ix},proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    
    close all;
end


%{
%% View difference wave ERPs
proc_id    = 'odd_full_ft';
an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
conditions = 'DifOddOS';
plt_id     = 'ts_F2to13_evnts_sigLine';
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';
for s = 1:numel(SBJs)
    SBJ03b_ERP_plot_diffwave(SBJs{s},conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
end
SBJ03c_ERP_plot_grp_diffwave(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

plt_id = 'ts_F2to13_but_evnts_sigPatch';
SBJ03c_ERP_plot_grp_diffwave_butterfly(SBJs,conditions,proc_id,an_id,plt_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

conditions = 'DifOddOS';
%}
%% ERP Stats: Window Mean
proc_id    = 'odd_full_ft';
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';
% for s = 1:numel(SBJs)
%     SBJ03a_ERP_save(SBJs{s},proc_id,an_id);
% end

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOS_anv_mn2t3_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddTS_anv_mn2t3_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOT_anv_mn2t3_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOS_anv_mn3t4_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddTS_anv_mn3t4_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOT_anv_mn3t4_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOS_anv_mn1t2_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddTS_anv_mn1t2_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id      = 'ERP_Z4_S2t13_dm2t0_fl05t20';
stat_id    = 'DifOddOT_anv_mn1t2_jk';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

%% ERP Stats: Peak-to-Peak
proc_id    = 'odd_full_ft';
save_fig   = 1;
fig_vis    = 'on';
fig_ftype  = 'png';

an_id   = 'ERP_Fz_S2t13_dm2t0_fl05t20';
stat_id = 'DifOddOS_anv_p2pFRN';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);

an_id   = 'ERP_Fz_S2t13_dm2t0_fl05t20';
stat_id = 'DifOddTS_anv_p2pFRN';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);
    
an_id   = 'ERP_Fz_S2t13_dm2t0_fl05t20';
stat_id = 'DifOddOT_anv_p2pFRN';
SBJ04c_ERP_grp_stats_ANOVA(SBJs,proc_id,an_id,stat_id,save_fig,...
        'fig_vis',fig_vis,'fig_ftype',fig_ftype);


%% ODDBALL 
% odd_plt_id = 'ts_S2to13_evnts_sigPatch';
% an_id = 'ERP_Cz_F_trl15t28_flt05t20_stat06';
% odd_an_id = 'ERP_Cz_S2t13_flt5t20_st6';
% odd_proc_id = 'odd_full_ft';
% proc_id = 'eeg_full_ft';
% for s = 1:numel(SBJs)
%     PLOTSTAT_HitErr_Individ(SBJs{s}, proc_id, plt_id, an_id, 'off', 1, 'png');
%     PLOT_4Conds_Individ(SBJs{s}, proc_id, plt_id, an_id, 'off', 1, 'png');
%     if startsWith(SBJs{s},'EEG')
%         PLOTSTAT_Oddball_Individ(SBJs{s}, odd_proc_id, odd_plt_id, odd_an_id, 'off', 1, 'png');
%     end
%     %CALC_FRN_Individ(SBJs{s}, proc_id, plt_id, an_id);
% end
% 
% PLOTSTAT_HitErr_Group(SBJs, plt_id, an_id, 'off', 1, 'png');
% PLOT_4Conds_Group(SBJs,  plt_id, an_id, 'off', 1, 'png');
% PLOTSTAT_Oddball_Group(SBJs, odd_plt_id, odd_an_id, 'off', 1, 'png');
% %PLOTSTATS_FRN_Group(SBJs, proc_id, plt_id, an_id, 'off', 1, '.png');
% PLOT_DiffWave_Group(SBJs, plt_id, an_id, 'off', 1, '.png', 'DifWL');
% PLOT_DiffWave_Group(SBJs, plt_id, an_id, 'off', 1, '.png', 'DifEH');
