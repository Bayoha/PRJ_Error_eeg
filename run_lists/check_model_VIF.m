SBJ_id = 'good1';
stat_id = 'RVLMsRPE_all_lme_st05t5';

%% Load Data 
stat_vars_cmd = ['run ' root_dir 'PRJ_Error_eeg/scripts/stat_vars/' stat_id '_vars.m'];
eval(stat_vars_cmd);

% Select SBJs
SBJs = load_SBJ_file(SBJ_id);

model_id = [st.model_lab '_' st.trial_cond{1}];
[reg_lab, ~, ~, ~]     = fn_regressor_label_styles(st.model_lab);

%%
for s = 1:numel(SBJs)
    load([root_dir 'PRJ_Error_eeg/data/' SBJs{s} '/04_proc/' SBJs{s} '_model_' model_id '.mat']);
    vifs = fn_variance_inflation_factor(model);
    fprintf('%s:\n');
    for r = 1:numel(reg_lab)
        fprintf('\t%s VIF = %.3f\n',reg_lab{r},vifs(r));
    end
end