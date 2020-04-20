function SBJ04a_RL_model(SBJ,proc_id,stat_id)
% Run reinforcement learning model on single SBJ behavior
% INPUTS:
%   SBJ [str] - ID of subject to run
%   proc_id [str] - ID of preprocessing pipeline
%   an_id [str] - ID of the analysis parameters to use
%   stat_id [str] - ID of the stats parameters to use
% OUTPUTS:
%   lme [cell array] - LinearMixedModel output class for each time point

%% Set up paths
if exist('/home/knight/','dir');root_dir='/home/knight/';app_dir=[root_dir 'PRJ_Error_eeg/Apps/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';app_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
elseif exist('Users/aasthashah/', 'dir'); root_dir = 'Users/aasthashah/Desktop/'; ft_dir = 'Users/aasthashah/Applications/fieldtrip';
else; root_dir='/Volumes/hoycw_clust/';app_dir='/Users/colinhoy/Code/Apps/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath([root_dir 'PRJ_Error_eeg/scripts/utils/']);
addpath([app_dir 'fieldtrip/']);
ft_defaults

%% Load Data
SBJ_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/SBJ_vars/' SBJ '_vars.m'];
eval(SBJ_vars_cmd);
proc_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/proc_vars/' proc_id '_vars.m'];
eval(proc_vars_cmd);
stat_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' stat_id '_vars.m'];
eval(stat_vars_cmd);

model_id = [st.model_lab '_' st.trial_cond{1}];
[reg_lab, ~, ~, ~]     = fn_regressor_label_styles(st.model_lab);
[cond_lab, ~, cond_colors, ~, ~] = fn_condition_label_styles(st.trial_cond{1});

%% Load and Select Behavior
% Load data
load([root_dir 'PRJ_Error_eeg/data/' SBJ '/03_events/' ...
    SBJ '_behav_' proc_id '_final.mat'],'bhv');
prdm_vars = load([SBJ_vars.dirs.events SBJ '_prdm_vars.mat']);

% Select Conditions of Interest
full_cond_idx = fn_condition_index(cond_lab, bhv);
bhv_fields = fieldnames(bhv);
final_n_trials = numel(bhv.trl_n);
for f_ix = 1:numel(bhv_fields)
    if numel(bhv.(bhv_fields{f_ix}))==final_n_trials
        bhv.(bhv_fields{f_ix}) = bhv.(bhv_fields{f_ix})(full_cond_idx~=0);
    end
end
n_trials = numel(bhv.trl_n);
fprintf('\t%s: Loaded %d trials, kept %d for modeling...\n',SBJ,final_n_trials,n_trials);

%% Load full trial history
[bhv_orig] = fn_load_behav_csv([SBJ_vars.dirs.events SBJ '_behav.csv']);
orig_n_trials = numel(bhv_orig.trl_n);

% Find full vis
full_vis_trl_n = 1:prdm_vars.n_examples;
full_vis_ix = [];
for t_ix = 1:numel(full_vis_trl_n)
    full_vis_ix = [full_vis_ix find(bhv_orig.trl_n==full_vis_trl_n(t_ix))];
end
full_vis_ix = sort(full_vis_ix(:));

% Find training
train_ix = find(bhv_orig.blk==0);

% Remove full vis and training
bhv_orig_nfv = bhv_orig;
bhv_orig_ntr = bhv_orig;
for f_ix = 1:numel(bhv_fields)
    if numel(bhv_orig.(bhv_fields{f_ix}))==orig_n_trials
        bhv_orig_nfv.(bhv_fields{f_ix}) = bhv_orig.(bhv_fields{f_ix})(setdiff(1:numel(bhv_orig.trl_n),full_vis_ix));
        bhv_orig_ntr.(bhv_fields{f_ix}) = bhv_orig.(bhv_fields{f_ix})(setdiff(1:numel(bhv_orig.trl_n),train_ix));
    end
end

% Find any task restarts
run_idx = ones(size(bhv.trl_n));
if any(strcmp(SBJ,{'EP09','EEG12','EEG24','EEG25'}))
    n_runs = 2;
    new_run_ix = find(abs(diff(bhv.trl_n))>prdm_vars.n_trials)+1;
    run_idx(new_run_ix:end) = 2;
else
    n_runs = 1;
end

%% Compute Reward Value, Likelihood, and Magnitude
if any(strcmp(reg_lab,'RVal')) || any(strcmp(reg_lab,'RMag')) || any(strcmp(reg_lab,'RLik'))
    RVal = nan(size(bhv.trl_n));
    RLik = nan(size(bhv.trl_n));
    RMag = nan(size(bhv.trl_n));
    for cond_ix = 1:numel(cond_lab)
        idx = logical(fn_condition_index(cond_lab(cond_ix),bhv));
        switch cond_lab{cond_ix}
            case 'EzWn'
                RVal(idx) = 1;
                RLik(idx) = 1;
                RMag(idx) = 1;
            case 'EzLs'
                RVal(idx) = -1;
                RLik(idx) = 0;
                RMag(idx) = 1;
            case 'EzSu'
                RVal(idx) = 0;
                RLik(idx) = 0;
                RMag(idx) = 0;
            case 'HdWn'
                RVal(idx) = 1;
                RLik(idx) = 0;
                RMag(idx) = 1;
            case 'HdLs'
                RVal(idx) = -1;
                RLik(idx) = 1;
                RMag(idx) = 1;
            case 'HdSu'
                RVal(idx) = 0;
                RLik(idx) = 0;
                RMag(idx) = 0;
            otherwise
                error(['Unknown trial type: ' cond_lab{cond_ix}]);
        end
    end
end

%% Compute Outcome Likelihood
if any(strcmp(reg_lab,'OLik'))
    OLik = nan(size(bhv.trl_n));
    for cond_ix = 1:numel(cond_lab)
        idx = fn_condition_index(cond_lab(cond_ix),bhv);
        if strcmp(cond_lab{cond_ix}(1:2),'Ez')
            n_trls = sum(strcmp('easy',bhv.cond));
        elseif strcmp(cond_lab{cond_ix}(1:2),'Hd')
            n_trls = sum(strcmp('hard',bhv.cond));
        else
            error('Neither Ez nor Hd, what is it?');
        end
        OLik(logical(idx)) = sum(idx)/n_trls;
    end
end

%% Compute Win Prediction
s_idx = fn_condition_index({'Su'},bhv);
if any(strcmp(reg_lab,'pWin')) || any(strcmp(reg_lab,'sRPE')) || any(strcmp(reg_lab,'uRPE'))
    % Select Data (fit on everything except surprise since no outcome)
    X = bhv.tol(~s_idx);
    y = double(bhv.hit(~s_idx));
    
    % Logistic regression
    betas = glmfit(X,y,'binomial','link','logit');
    
    z = betas(1) + (bhv.tol * betas(2));
    pWin = 1 ./ (1+exp(-z));
    expected_score = pWin*2 - 1;
end
if any(strcmp(reg_lab,'bAcc'))
    % Adjust block numbers for EEG12
    if strcmp(SBJ,'EEG12')
        blk5_starts = find(bhv.blk==5 & bhv.blk_trl_n==1);
        for trl_ix = 1:blk5_starts(2)-1
            bhv.blk(trl_ix) = bhv.blk(trl_ix)-4;
        end
    end
    
    % Get block level accuracy
    blks = unique(bhv.blk);
    blk_acc = nan(size(blks));
    for b_ix = 1:numel(blks)
        blk_acc(b_ix) = mean(strcmp(bhv.fb(bhv.blk==blks(b_ix) & ~s_idx),'W'));
    end
    
    % Format block accuracy as single trial predictor
    bAcc = nan(size(bhv.trl_n));
    for t_ix = 1:numel(bhv.trl_n)
        bAcc(t_ix) = blk_acc(bhv.blk(t_ix)==blks);
    end
    expected_score = bAcc*2 - 1;
elseif any(strcmp(reg_lab,'rAcc'))
    % Analysis Parameters (to be finalized)
    roll_win = 5;
    roll_wi_cond = true;
    
    % Build index of feedback
    fb_idx = nan(size(bhv_orig_nfv.trl_n));
    fb_idx(strcmp(bhv_orig_nfv.fb,'W')) = 1;
    fb_idx(strcmp(bhv_orig_nfv.fb,'L')) = 0;
    
    % Compute rolling accuracy of last 5 trials
    %   Include training trials!
    run_idx_nfv = ones(size(bhv_orig_nfv.trl_n));
    if any(strcmp(SBJ,{'EP09','EEG12','EEG24','EEG25'}))
        new_run_ix_nfv = find(abs(diff(bhv_orig_nfv.trl_n))>prdm_vars.n_trials)+1;
        run_idx_nfv(new_run_ix_nfv:end) = 2;
    end
    
    rAcc = nan(size(bhv.trl_n));
    for t_ix = 1:numel(bhv.trl_n)
        if roll_wi_cond
            prior_cond_ix = find(strcmp(bhv_orig_nfv.cond,bhv.cond(t_ix)) & bhv_orig_nfv.trl_n<bhv.trl_n(t_ix));
            prior_cond_ix = prior_cond_ix(run_idx_nfv(prior_cond_ix)==run_idx(t_ix));
            rAcc(t_ix) = nanmean(fb_idx(prior_cond_ix(end-roll_win+1:end)));
        else
            error('need to set up for double runs EEG12,24,25');
            orig_ix = find(bhv_orig_nfv.trl_n==bhv.trl_n(t_ix));
            rAcc(t_ix) = nanmean(fb_idx(orig_ix-roll_win:orig_ix-1));
        end
    end
    
    expected_score = rAcc*2 - 1;
end

%% Compute Prediction Errors
if any(strcmp(reg_lab,'sRPE'))
    sRPE = double(bhv.score)/100 - expected_score;
end
if any(strcmp(reg_lab,'uRPE'))
    uRPE = abs(double(bhv.score)/100 - expected_score);
end

%% Compute total score
if any(strcmp(reg_lab,'score'))    
    % Compute total score (exclude training trials)
    full_score = zeros(size(bhv_orig_ntr.score));
    new_run_ix_ntr = find(abs(diff(bhv_orig_ntr.trl_n))>prdm_vars.n_trials)+1;
    first_trl_ix = 1;
    for t_ix = 1:numel(bhv_orig_ntr.trl_n)
        if n_runs==2 && t_ix==new_run_ix_ntr
            first_trl_ix = new_run_ix_ntr;
        end
        full_score(t_ix) = sum(bhv_orig_ntr.score(first_trl_ix:t_ix));
    end
    
    % Select trials
    score = zeros(size(bhv.trl_n));
    run_ix = 1;
    for t_ix = 1:numel(bhv.trl_n)
        if n_runs==2 && t_ix==new_run_ix
            run_ix = 2;
        end
        ntr_ix = find(bhv_orig_ntr.trl_n==bhv.trl_n(t_ix));
        if numel(ntr_ix)>1
            ntr_ix = ntr_ix(run_ix);
        end
        score(t_ix) = full_score(ntr_ix);
    end
end

%% Distance from Target
% Signed Target Distance (RT - target_time to center for early/late)
tar = bhv.rt-prdm_vars.target;
if any(strcmp(reg_lab,'sTaEr'))
    % Separately for wins and losses to maintain correct sign
    sTaEr = nan(size(tar));
    sTaEr(tar<0)  = log(-tar(tar<0));
    sTaEr(tar>=0) = -log(tar(tar>=0));
    % Invert to make large distances biggest values
    sTaEr = sTaEr.^-1;
end
if any(strcmp(reg_lab,'sTaPr'))
    % Separately for wins and losses to maintain correct sign
    sTaPr = nan(size(tar));
    sTaPr(tar<0)  = log(-tar(tar<0));
    sTaPr(tar>=0) = -log(tar(tar>=0));
end

% Unsigned Target Distance
if any(strcmp(reg_lab,'uTaEr'))
    % Flip sign to make it positive
    uTaEr = -log(abs(tar));
    % Invert to make large distances biggest values
    uTaEr = uTaEr.^-1;
end
if any(strcmp(reg_lab,'uTaPr'))
    % Flip sign to make it positive
    uTaPr = -log(abs(tar));
end

% Previous trial RTs
if any(strcmp(reg_lab,'psTaEr'))
    error('not using previous trial right now!');
    psTaEr = nan(size(bhv.rt));
    for t_ix = 2:numel(bhv.rt)
        psTaEr(t_ix) = sTaEr(t_ix-1);
    end
end
if any(strcmp(reg_lab,'p2sTaEr'))
    error('not using previous trial right now!');
    p2sTaEr = nan(size(bhv.rt));
    for t_ix = 3:numel(bhv.rt)
        p2sTaEr(t_ix) = psTaEr(t_ix-2);
    end
end

%% Distance from Tolerance Threshold
% Compute distance from closest tolerance bound
%   Positive = win, Negative = loss
early_idx = (bhv.rt-prdm_vars.target)<0;
thr = nan(size(bhv.rt));
thr(early_idx) = bhv.rt(early_idx)-(prdm_vars.target-bhv.tol(early_idx));
thr(~early_idx) = (prdm_vars.target+bhv.tol(~early_idx))-bhv.rt(~early_idx);

% Transform almost hit/miss into large values
if any(strcmp(reg_lab,'sThEr'))
    % Separately for wins and losses to maintain correct sign for beta
    % interpretation (+ for win, - for loss)
    sThEr = nan(size(bhv.rt));
    sThEr(bhv.hit==1) = -log(thr(bhv.hit==1));
    sThEr(bhv.hit==0) = log(-thr(bhv.hit==0));
    sThEr = sThEr.^-1;
    % Remove bad feedback trials in sThPr
    %   (incorrect feedback given due to rounding error)
    sThEr(logical(bhv.bad_fb)) = nan;
end
if any(strcmp(reg_lab,'sThPr'))
    % Separately for wins and losses to maintain correct sign for beta
    % interpretation (+ for win, - for loss)
    sThPr = nan(size(bhv.rt));
    sThPr(bhv.hit==1) = -log(thr(bhv.hit==1));
    sThPr(bhv.hit==0) = log(-thr(bhv.hit==0));
    % Remove bad feedback trials in sThPr
    %   (incorrect feedback given due to rounding error)
    sThPr(logical(bhv.bad_fb)) = nan;
end

% Add unsigned version
if any(strcmp(reg_lab,'uThEr'))
    % Separately for wins and losses to maintain correct sign for beta
    % interpretation (+ for win, - for loss)
    uThEr = nan(size(bhv.rt));
    uThEr(bhv.hit==1) = -log(thr(bhv.hit==1));
    uThEr(bhv.hit==0) = log(-thr(bhv.hit==0));
    uThEr = uThEr.^-1;
    % Keeping bad feedback trials because absolute distance is correct
    uThEr = abs(uThEr);
end
if any(strcmp(reg_lab,'uThPr'))
    % Separately for wins and losses to maintain correct sign for beta
    % interpretation (+ for win, - for loss)
    uThPr = nan(size(bhv.rt));
    uThPr(bhv.hit==1) = -log(thr(bhv.hit==1));
    uThPr(bhv.hit==0) = log(-thr(bhv.hit==0));
    % Keeping bad feedback trials because absolute distance is correct
    uThPr = abs(uThPr);
end

%% Inter-Trial Interval
ITI = bhv.ITI_type;
ITI(ITI==0) = nan;
if any(~isnan(ITI(bhv.blk_trl_n==1)))
    error('First trial in block is not NaN in ITI regressor!');
end

%% Load Data and Build Model
model = nan([sum(n_trials) numel(reg_lab)]);
for r_ix = 1:numel(reg_lab)
    model(:,r_ix) = eval(reg_lab{r_ix});
end
if any(isnan(model(:)))
    fprintf(2,'\tWARNING: %d NaNs detected in model!\n',sum(isnan(model(:))));
end

%% Compute and plot correlations between regressors
reg_corr = corr(model,'rows','complete');

% Create figure directory
fig_dir = [SBJ_vars.dirs.proc model_id '_plots/'];
if ~exist(fig_dir,'dir')
    mkdir(fig_dir);
end

% Plot design matrix
fig_name = [SBJ '_' model_id '_design'];
figure('Name',fig_name);
imagesc(model);
xticklabels(reg_lab);
colorbar;
saveas(gcf,[fig_dir fig_name '.png']);

% Plot regressor correlation matrix
fig_name = [SBJ '_' model_id '_design_corr'];
figure('Name',fig_name);
imagesc(reg_corr);
xticklabels(reg_lab);
yticklabels(reg_lab);
colorbar;
saveas(gcf,[fig_dir fig_name '.png']);

%% Plot Regressors by Condition
cond_idx = fn_condition_index(cond_lab, bhv);

fig_name = [SBJ '_' model_id '_reg_cond'];
figure('Name',fig_name,'units','normalized','outerposition',[0 0 1 1]);
[n_rc,~] = fn_num_subplots(numel(reg_lab));

for reg_ix = 1:numel(reg_lab)
    subplot(n_rc(1),n_rc(2),reg_ix); hold on;
    violin_data = struct;
    for cond_ix = 1:numel(cond_lab)
        violin_data.(cond_lab{cond_ix}) = model(cond_idx==cond_ix,reg_ix);
    end
    violins = violinplot(violin_data);
    
    % Plot properties
    legend_obj = cell(size(cond_lab));
    for cond_ix = 1:numel(cond_lab)
        % Change scatter colors to mark condition
        violins(cond_ix).ViolinColor = cond_colors{cond_ix};
        violins(cond_ix).BoxPlot.FaceColor = cond_colors{cond_ix};
        violins(cond_ix).EdgeColor = cond_colors{cond_ix};
        % Grab violin for legend
        legend_obj{cond_ix} = violins(cond_ix).ViolinPlot;
    end
    title(reg_lab{reg_ix});
    if strcmp(reg_lab{reg_ix},'pWin'); legend([legend_obj{:}],cond_lab); end
    set(gca,'FontSize',16);
end
saveas(gcf,[fig_dir fig_name '.png']);

%% Save Results
stat_out_fname = [SBJ_vars.dirs.proc SBJ '_model_' model_id '.mat'];
fprintf('Saving %s\n',stat_out_fname);
if any(strcmp(reg_lab,'pWin'))
    save(stat_out_fname,'-v7.3','model','betas');
else
    save(stat_out_fname,'-v7.3','model');
end

end
