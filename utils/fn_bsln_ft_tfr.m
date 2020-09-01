function bslnd_tfr = fn_bsln_ft_tfr(tfr, bsln_lim, bsln_type, n_boots)
%% Baseline correct one TFR based on bsln_lim epoch, both from ft_freqanalysis
% INPUTS:
%   tfr [FT dataset] - full output of ft_freqanalysis
%   bsln_lim [int, int]- 2 int array of TIME indices for [start, end] of baseline period
%   bsln_type [str]   - type of baseline to implement
%       'zboot'  = pool all baselines, bootstrap means+SDs, z-score all
%           trials to the mean+SD of the bootstrapped distribution
%       'zscore' = subtract mean and divide by SD
%       'demean' = subtract mean
%       'my_relchange' = subtract mean, divide by mean (results in % change)
%   n_boots [int] - number of bootstrap iterations if using zboot
% OUTPUTS:
%   bslnd_tfr [FT dataset] - same tfr but baseline corrected

% [~, app_dir] = fn_get_root_dir();
% addpath([app_dir 'fieldtrip/']);
% ft_defaults
if strcmp(bsln_type,'zboot'); rng('shuffle'); end % seed randi with time

% Check if power or fourier (complex values for phase data)
if strcmp(tfr.dimord,'rpt_chan_freq_time')
    field = 'powspctrm';
elseif strcmp(tfr.dimord,'rpttap_chan_freq_time')
    field = 'fourierspctrm';
else
    error('Check dimord to be sure trial dimension is first!')
end

% Select baseline data
cfgs = [];
cfgs.latency = bsln_lim;
bsln_tfr = ft_selectdata(cfgs,tfr);

bslnd_tfr = tfr;
for ch = 1:size(tfr.(field),2)
    fprintf('\t%s (%i / %i)\n',tfr.label{ch},ch,numel(tfr.label));
    for f = 1:size(tfr.(field),3)
        % Create bootstrap distribution if necessary
        if strcmp(bsln_type,'zboot')
%             fprintf('\tComputing permutations: # boots / (%i) = ',n_boots);
            sample_means = NaN([n_boots 1]);
            sample_stds  = NaN([n_boots 1]);
            for boot_ix = 1:n_boots
%                 if mod(boot_ix,50)==0
%                     fprintf('%i..',boot_ix);
%                 end
                % Select a random set of trials (sampling WITH REPLACEMENT!)
                shuffle_ix = randi(size(tfr.(field),1),[1 size(tfr.(field),1)]);
                % Pool all baseline data and compute stats
                bsln_data = bsln_tfr.(field)(shuffle_ix,ch,f,:);
                sample_means(boot_ix) = nanmean(bsln_data(:));
                sample_stds(boot_ix)  = nanstd(bsln_data(:));
            end
%             fprintf('\n');
        end
        
        % Perform Baseline Correction
        for t = 1:size(tfr.(field),1)
            trials   = tfr.(field)(t,ch,f,:);
            trl_bsln = bsln_tfr.(field)(t,ch,f,:);
            switch bsln_type
                case 'zboot'
                    bslnd_tfr.(field)(t,ch,f,:) = (trials-mean(sample_means))/mean(sample_stds);                    
                case 'zscore'
                    bslnd_tfr.(field)(t,ch,f,:) = (trials-nanmean(trl_bsln))/nanstd(trl_bsln);
                case 'demean'
                    bslnd_tfr.(field)(t,ch,f,:) = trials-nanmean(trl_bsln);
                case 'my_relchange'
                    bslnd_tfr.(field)(t,ch,f,:) = (trials-nanmean(trl_bsln))/nanmean(trl_bsln);
                otherwise
                    error(['Unknown bsln_type: ' bsln_type])
            end
        end
    end
end

end
