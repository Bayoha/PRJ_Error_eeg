root_dir='/Volumes/hoycw_clust/';
SBJ_id = 'goodEEG';
proc_id   = 'odd_full_ft';
cpa_id    = 'CPA_odd_comb10';

%%
SBJs = fn_load_SBJ_list(SBJ_id);

%%
proc_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/proc_vars/' proc_id '_vars.m'];
eval(proc_vars_cmd);
cpa_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' cpa_id '_vars.m'];
eval(cpa_vars_cmd);
% an_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/an_vars/' cpa.erp_an_id '_vars.m'];
% eval(an_vars_cmd);

%% Load ICs and weights
topo_weights = cell(numel(SBJs));
ic_list = cell(numel(SBJs));
for s = 1:numel(SBJs)
    % Load clean_ica
    load([root_dir 'PRJ_Error_eeg/data/' SBJs{s} '/04_proc/' SBJs{s} '_' cpa_id '_' proc_id '_prototype.mat']);
    ic_list{s} = final_ics;
    
    % Plot topos of final_ics
    topo_weights{s} = nan([numel(final_ics) size(clean_ica.label)]);
    for f_ix = 1:numel(final_ics)
        comp_ix = final_ics(f_ix);
        topo_weights{s}(f_ix,:) = clean_ica.topo(:,comp_ix);
    end
end

%% Compute thresholds
sd_thresh = 3;
tmp_colors = distinguishable_colors(100);
figure; hold on;
fprintf('\nthresh = %d\n',sd_thresh);

bad_cnt = 0;
topo_means = cell(numel(SBJs));
topo_sds   = cell(numel(SBJs));
out_cnt    = cell(numel(SBJs));
for s = 1:numel(SBJs)
    topo_means{s} = nan(size(ic_list{s}));
    topo_sds{s} = nan(size(ic_list{s}));
    out_cnt{s} = nan(size(ic_list{s}));
    for f_ix = 1:numel(ic_list{s})
        topo_means{s}(f_ix) = mean(topo_weights{s}(f_ix,:));
        topo_sds{s}(f_ix) = std(topo_weights{s}(f_ix,:));
        hi_idx = topo_weights{s}(f_ix,:)>topo_means{s}(f_ix)+sd_thresh*topo_sds{s}(f_ix);
        lo_idx = topo_weights{s}(f_ix,:)<topo_means{s}(f_ix)-sd_thresh*topo_sds{s}(f_ix);
        out_idx = any([hi_idx; lo_idx],1);
        out_cnt{s}(f_ix) = sum(out_idx);
        if out_cnt{s}(f_ix)>0
            bad_cnt = bad_cnt+1;
            fprintf('%s #%d outliers: %d\n',SBJs{s},ic_list{s}(f_ix),out_cnt{s}(f_ix));
            plot(topo_weights{s}(f_ix,:),'Color',tmp_colors(bad_cnt,:));
            scatter(find(out_idx),topo_weights{s}(f_ix,find(out_idx)),50,tmp_colors(bad_cnt,:));
        end
    end
end
fprintf('\n\n');

%% Plot
SBJ_colors = distinguishable_colors(numel(SBJs));
eeg26_ix = find(strcmp(SBJs,'EEG26'));

figure; hold on;
plot_s = eeg26_ix;


