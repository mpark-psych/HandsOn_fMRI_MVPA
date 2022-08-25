%% ==================================================================
% This hands-on code is to perform MVPA with fMRI data.
% Here's going to use 'Princeton MVPA toolbox'.
% Pre-requisite:  ROI masks, regressors, selector.
%
% Data: time-series data (e.g., raw data, betaseries, fitted data)
%   - RDKs moving either leftward or rightward.
%   - Block design: moving_L(9TR) rest(8TR) moving_R(9TR) rest(8TR)...
%   - See 'main task info' for more detail.
%
% ===================================================================
% Hands-on fMRI workshop @VCN, Korea Univ.
% Presenter: Minsun Park, Ph.D.
% Email:  vd.mpark@gmail.com
% Created on 08/26/2022.
% ===================================================================


clear; close all; clc;

rng('default');
rng(2);                                                                     % control random number generator. rng(seed)
baseDir = '/Users/minsunpark/Desktop/MyWorkshop/Analyzed_data/';
roiSet = {'bothMT.res', 'both.V1.res', 'both.V2.res'};
sbj = 's01';

%=== main task info
LRTR = 136;             % number of TR in a run
LRBlock = 8*2;          % number of block (8block x 2run)
LRBlockTR = 18/2;       % 18s, 9TR for a stimulus presentation
LRBlankTR = 16/2;       % 16s, 8TR for a blank

%=== Directory
sbjDir = strcat(baseDir, sbj, '/');
dataFile = strcat(sbjDir, sbj, '.LRtask.TMdeoblqAI.nii');
% dataFile = strcat(sbjDir, '3dDec/', sbj, '.LRtask.B5.fitts.nii');
roiDir = strcat(sbjDir,'/ROIs/');

%=== Etc.
taskName = 'LRtask';                                                        % need to initialize 'subj'
shftTR = 4;                                                                 % shift n TR to compensate BOLD sluggishness

cd(sbjDir)

for roi = 1:length(roiSet)
    %- this roi
    roiName = roiSet{roi};                                                  % Note using {}, not ().
    roiFile = strcat(roiDir, roiName, '.nii');
    
    %% Initiation and fild loading
    %=== Set 'subj' and Load mask
    cd(roiDir)
    subj = init_subj(taskName, sbj);                                        % initialize subj
    subj = load_spm_mask(subj, roiName, roiFile);                           % load roiFile
                                                                            % if you don't have rois but want to see whole brain, load brainmask.
    
    cd(sbjDir)
    
    %=== Try it
    % Enter 'subj', 'summ', 'summarize(subj)' in command window. 
    % Q. What are the differnces?
    
    
    %=== Load raw timeseries data
    %- when loading 'nii', use 'load_spm_pattern'.
    %- when loading '.+orig/.BRIK', use 'load_afni_pattern'.
    pattName = strcat(taskName, ':raw');                                    % name the pattern to load
    subj = load_spm_pattern(subj, pattName, roiName, dataFile);             % [nVox x TR]
    
    
    %=== Load 'reg' in a regressor file
    load(strcat(sbjDir, '/s01_regressor.mat'))                              % load regressors
    
    regressor = reg.raw.reg_LR;                                             % save regressor. [visdir, TR]
    selector = reg.raw.runIdx';                                             % save selector of run. [1, TR]
    
    %% Selector
    %=== Selector: Run info.
    subj = init_object(subj, 'selector', 'runs');
    subj = set_mat(subj, 'selector', 'runs', selector);
    
    
    %=== Selector: Block info.
    subj = init_object(subj, 'selector', 'blocks');
    blocks=[];
    for i = 1:LRBlock
        blocks = [blocks ones(1,LRBlockTR+LRBlankTR)*i];                    % block here includes offsets(blank)
    end
    subj = set_mat(subj, 'selector', 'blocks', blocks);
        % imagesc(blocks);
    
    %=== Try it.
%     aa = regressor.*blocks;
%     plot(aa(1,:)); hold on; plot(aa(2,:)); hold off;
    


    %% Regressor
    %=== Regressor
    subj = init_object(subj, 'regressors', 'condLR');
    subj = set_mat(subj, 'regressors', 'condLR', regressor);
    condnames = {'L', 'R'};
    subj = set_objfield(subj, 'regressors', 'condLR', 'condnames', condnames);
    
    %- shift TR
    defaults.do_plot = true;                                                % Plot an imagesc of the old and new regressors to confirm that the shift looks right.
    subj = shift_regressors(subj, 'condLR', 'runs', shftTR, defaults);
    shftname = get_name(subj, 'regressors', 2);
    
    
    %- Creates a SELECTOR with 1s for non-rest timepoints
    subj = create_norest_sel(subj, shftname);
        % summ
    
    %=== Tips: if you want to remove object, use 'remove_object'.
        % subj = remove_object(subj, 'regressors', 'condLR_sh2');
    
    
    %=== Z-score by run
    % take an individual voxel's timecourse, and subtract the mean 
    % and divide by its standard deviation, leaving a linearly-transformed 
    % timecourse with mean 0 and standard deviation 1.
    subj = zscore_runs(subj, 'LRtask:raw', 'runs');
        % summ
    
    %% Cross-validation indices
    % The toolbox provies runwise/blockwise or evenodd cross-validation.
    % If you want k-fold CV, which is used the most recently, need to
    % create object with k-fold CV indices made by yourself.
    
    %- Think of the 1s as training TRs and the 2s as testing TRs.
    subj = create_xvalid_indices(subj,'blocks','actives_selname', strcat(shftname,'_norest'), 'new_selstem', 'blocks_norest_xval');
            % plot(subj.selectors{1,4}.mat);
    
    %=== Tips: if you want to remove 16 block_xvals, use 'remove_group'.
        % subj=remove_group(subj, 'selector', 'blocks_norest_xval');
    
     

    %% Training and Testing
    
    %% Classifier: Logistic regressoin (built in the toolbox)
    class_args.train_funct_name = 'train_logreg';
    class_args.test_funct_name = 'test_logreg';
    class_args.penalty = 1;
    
    [subj, thisresults] = cross_validation(subj,'LRtask:raw_z',shftname,'blocks_norest_xval',roiName, class_args);
    
    %=== MVPA performance in each ROI
    if strcmp(roiName, 'bothMT.res')
        results.MT = thisresults;
    elseif strcmp(roiName, 'both.V1.res')
        results.V1 = thisresults;
    elseif strcmp(roiName, 'both.V2.res')
        results.V2 = thisresults;
    end
    
    
    
    %% SVM (ver. 'fitcsvm')
    % NOTE 1: 'train_svm' in the toolbox has an issue.
    %  (see, https://groups.google.com/g/mvpa-toolbox/c/VLnHXYC4zaI/m/oH9IwaivVmYJ)
    %  If you want to use SVM, use 'fitcsvm' the built-in function in
    %  MATLAB, which is also used in 'train_svm' provided by the toolbox.
    %  (note by Minsun Park)
    %  Let me know if you fix the issue! 
    % NOTE 2:  'train_svm' currently does only two category classification only.
    % NOTE 3:  you may learn how to utilize the toolbox from the code below.
    
    patts = get_mat(subj, 'pattern', 'LRtask:raw_z');
    
    regs = get_mat(subj, 'regressors', 'condLR_sh4');
    regs(2,:) = regs(2,:)*2;
    regs = regs(1,:)+regs(2,:);
    % find(regs==3)
    sels_norest = get_mat(subj, 'selector', 'condLR_sh4_norest');
    i_norest = find(sels_norest==1);
    
    patts_norest = patts(:,i_norest);
    label_norest = regs(1,i_norest);
    
    patts_norest = patts_norest';
    label_norest = label_norest';
    
    nfold = 4;                                                              % number of fold
    cvFolds = cvpartition(label_norest,'KFold',nfold,'Stratify',true);      % create stratified cross-validatiion folds
    
    svmResult = [label_norest, NaN(size(label_norest,1), 2)];   
    lenLabel = 1;
    
    for k = 1:nfold
        trainIdx = training(cvFolds, k);                                    % index of training data in this fold
        testIdx = test(cvFolds, k);                                         % index of test data in this fold
        
        train_data = patts_norest(trainIdx,:);                              % training data of this fold
        train_label = label_norest(trainIdx,:);                             % training label of this fold
        test_data = patts_norest(testIdx,:);                                % test data of this fold
        test_label = label_norest(testIdx,:);                               % test label of this fold
        
        disp(strcat('====== MVPA: ', num2str(k), 'th fold======'))
        %=== train SVM
        %- Linear
            svm_model = fitcsvm(...
                train_data, ...
                train_label, ...
                'KernelFunction', 'linear', ...
                'PolynomialOrder', [], ...
                'BoxConstraint', 1, ...
                'Standardize', true, ...
                'ClassNames', [1; 2]);
        %=== test
        predicted_labels = predict(svm_model, test_data);
        svmResult(testIdx,lenLabel+1) = predicted_labels;
        svmResult(testIdx,lenLabel+2) = (predicted_labels==test_label);
        
    end
    
    if strcmp(roiName, 'bothMT.res')
        Acc_MT = mean(svmResult(:,end)) * 100 
    elseif strcmp(roiName, 'both.V1.res')
        Acc_V1 = mean(svmResult(:,end)) * 100
    elseif strcmp(roiName, 'both.V2.res')
        Acc_V2 = mean(svmResult(:,end)) * 100
    end
    
%     clearvars subj class_args thisresults
    
    %% Averaging (Another option)
    % Bonus stage! 
    % One can want to use averaged timeseries data to reduce noise.
    % Here, I wrote some codes of how average data by blocks using the
    % toolbox. 
    
%     %- See 'help create_blocklabels', and try with 'runs' in create_blocklabels.
%     subj = create_blocklabels(subj, shftname, 'blocks');                    % Created blocklabels with 16 unique blocks
%     blocklabels = get_mat(subj, 'selector', 'blocklabels');
%     imagesc(blocklabels);   
%     
%     subj = average_object(subj, 'pattern', 'LRtask:raw_z', 'blocklabels');
%     subj = average_object(subj, 'regressors', shftname, 'blocklabels');
%     subj = average_object(subj, 'selector', 'blocks', 'blocklabels');
%     summ
%     
%     subj = create_xvalid_indices(subj,'blocks_avg');
%     
%     class_args.train_funct_name = 'train_logreg';
%     class_args.test_funct_name = 'test_logreg';
%     class_args.penalty = 1;
%     [subj, thisresults] = cross_validation(subj,'LRtask:raw_z',shftname,'blocks_avg_xval',roiName, class_args);
%     
%     %=== MVPA performance in each ROI
%     if strcmp(roiName, 'bothMT.res')
%         results.MT = thisresults;
%     elseif strcmp(roiName, 'both.V1.res')
%         results.V1 = thisresults;
%     elseif strcmp(roiName, 'both.V2.res')
%         results.V2 = thisresults;
%     end
    
    
end

%% === Appendix. Check if the chosen TR to shift fits well with the timeseries.
% patt = get_mat(subj, 'pattern', 'LRtask:raw_z');
% size(patt)
% avgpatt = mean(patt);
% regshft = get_mat(subj, 'regressors', shftname);
% 
% plot(avgpatt);
% hold on
% plot(regshft(1,:), 'g');
% plot(regshft(2,:), 'r');