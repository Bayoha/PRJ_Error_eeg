% Data Selection
an.ROI         = {'Fz'};             % Channel to be analyzed
an.event_type  = 'S';           % event around which to cut trials
an.trial_lim_s = [-0.15 2.8];       % window in SEC for cutting trials

% Surface LaPlacian
an.laplacian = 0;
% cfglap = [];
% cfglap.method = 'spline';

% ERP Filtering
an.demean_yn   = 'yes';
an.bsln_lim    = [-0.15 0];    % window in SEC for baseline correction
an.lp_yn       = 'yes';
an.lp_freq     = 20;
an.hp_yn       = 'yes';
an.hp_freq     = 0.5;
an.hp_filtord  = 4;

% Window Logic Check: bsln_lim is within trial_lim_s
if an.bsln_lim(1) < an.trial_lim_s(1) || an.bsln_lim(2) > an.trial_lim_s(2)
error('an.bsln_lim is outside an.trial_lim_s!');
end

% Wavelet TFR Parameters
% % cfg_tfr.method = 'wavelet'
% % cfg_tfr.output = 'pow';
% % cfg_tfr.taper = 'hanning';
% % cfg_tfr.foi = [2:30];
% % cfg_tfr.width = 2; %default
% % cfg_tfr.toi  = 0:0.004:2.8;



