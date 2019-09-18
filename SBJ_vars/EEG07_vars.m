%% EEG 07 Processing Variables
if exist('/home/knight/','dir');root_dir='/home/knight/';ft_dir=[root_dir 'PRJ_Error_eeg/Apps/fieldtrip/'];
elseif exist('/Users/sheilasteiner/','dir'); root_dir='/Users/sheilasteiner/Desktop/Knight_Lab/';ft_dir='/Users/sheilasteiner/Downloads/fieldtrip-master/';
elseif exist('/Users/aasthashah/','dir'); root_dir='/Users/aasthashah/Desktop/';ft_dir='/Users/aasthashah/Desktop/fieldtrip/';
else root_dir='/Volumes/hoycw_clust/';ft_dir='/Users/colinhoy/Code/Apps/fieldtrip/';end

addpath([root_dir 'PRJ_Error_eeg/scripts/']);
addpath(ft_dir);
ft_defaults

%--------------------------------------
% Basics
%--------------------------------------
SBJ_vars.SBJ = 'EEG07';
SBJ_vars.raw_file = {'eeg07.bdf'};
SBJ_vars.bhv_file = 'eeg07startover_response_log_20190802155314.txt';
SBJ_vars.oddball_file = {'eeg07_oddball_log_20190802163013.txt'}
SBJ_vars.block_name = {''};

SBJ_vars.dirs.SBJ     = [root_dir 'PRJ_Error_eeg/data/' SBJ_vars.SBJ '/'];
SBJ_vars.dirs.raw     = [SBJ_vars.dirs.SBJ '00_raw/'];
SBJ_vars.dirs.import  = [SBJ_vars.dirs.SBJ '01_import/'];
SBJ_vars.dirs.preproc = [SBJ_vars.dirs.SBJ '02_preproc/'];
SBJ_vars.dirs.events  = [SBJ_vars.dirs.SBJ '03_events/'];
SBJ_vars.dirs.proc    = [SBJ_vars.dirs.SBJ '04_proc/'];
SBJ_vars.dirs.proc_stack    = [SBJ_vars.dirs.SBJ '04_proc/ERP_stacks/'];
if ~exist(SBJ_vars.dirs.import,'dir')
   mkdir(SBJ_vars.dirs.import);
end
if ~exist(SBJ_vars.dirs.preproc,'dir')
   mkdir(SBJ_vars.dirs.preproc);
end
if ~exist(SBJ_vars.dirs.events,'dir')
    mkdir(SBJ_vars.dirs.events);
end
if ~exist(SBJ_vars.dirs.proc,'dir')
    mkdir(SBJ_vars.dirs.proc);
end

SBJ_vars.dirs.raw_filename = strcat(SBJ_vars.dirs.raw, SBJ_vars.raw_file);

%--------------------------------------
% Channel Selection
%--------------------------------------
% Channel Labels
SBJ_vars.ch_lab.ears    = {'EXG1', 'EXG2'};
SBJ_vars.ch_lab.eog_h   = {'EXG3', 'EXG4'};
SBJ_vars.ch_lab.eog_v   = {'EXG5', 'Fp2'};
SBJ_vars.ch_lab.null = {'EXG6', 'EXG7', 'EXG8'}
SBJ_vars.ch_lab.replace = {}; % {{'final','EXG#'},{'final2','EXG#2'}}
SBJ_vars.ch_lab.prefix  = '1-';    % before every channel
SBJ_vars.ch_lab.suffix  = '';    % after every channel
SBJ_vars.ch_lab.trigger = 'Status';
SBJ_vars.ch_lab.bad     = {...
'TP8','T8','T7'
    };
%SBJ_vars.ref_exclude = {}; %exclude from the CAR

%SBJ_vars.trial_reject_ix = [19, 162, 190, 221, 241, 244, 249, 333, 343, 351, 410, 426, 436, 440, 485, 487, 501, 508, 509, 530, 559];
SBJ_vars.trial_reject_ix = [];
SBJ_vars.ica_reject = [];
%--------------------------------------
% Noise Notes
%--------------------------------------
% recording info sheet notes:
    %'PO7','O1','Iz','Oz'... % noisy channels
% PSD Notes:
    %'AF3','CP2','Iz','Oz','O1','O2','PO3','PO7','PO8','POz' - PSD looks noisy
    %'F1' - strange flat PSD
    %'F6','P2','P8' empty
% Raw View notes:
    % POz has big ripples, PO3 at times too
    % TP8 also has big fluctuations
    % PO8 has big noise at times
    % O2 breaks loose at some point
    % AF3 becomes very onisy at some point
% databrowser post-IC rejection:
    % channels: Iz, Oz, PO8, PO3, T8 (trial 31), POz (esp. t 151), 216 starts O2 loose, F6 (t 351), AF3 (t 413), F4(t 417), TP7 (t 436)
    % trials: 142 (EOG missed?), 228, 375, 376, 387, 398 (P5), 402, 409, 410, 420, 441, 462, 463, 479, 490, 497, 513, 533, 543, 548, 552:554, 559?, 570, 576?, 580
% ft summary:
    % Fp1, AF7, AF3, PO3, Iz, Oz, POz, Fpz, Fp2, AF8, F4, T8, PO8, O2, F6
    % trials (n/582): 31, 32, 329

% pre-ICA rejection:
% ft summary notes:
    % channels (n/64): Iz, Oz, PO8, O2
    % trials (n/582): 151, 351, 386, 413, 419, 462, 463, 513, 554
% ft summary EOG notes:
    % trials (n/582): 139, 142, 325, 542, 554, 559, 576, 580bp

%--------------------------------------
% Time Parameters
%--------------------------------------
% SBJ_vars.analysis_time = {};

%-------------------------s-------------
% Trials and Channels to Reject
%--------------------------------------
% These should be indices AFTER SBJ05 has run!
% original trial_reject_ix = [52 61 77 125 154 156 185 187 131 132 133 205 254 265 280 283 4303 311 318 319 320];
%SBJ_vars.trial_reject_ix = [52 61 77 125 154 156 185 187 131 132 133 205 254 265 280 283 303 311 318 319 320];
%SBJ_vars.channels_reject_ix = {'T7','T8'};

%--------------------------------------
% Component Paramaters
%--------------------------------------
% SBJ_vars.top_comp_cut = 0.1;
%SBJ_vars.rejcomp = [1];