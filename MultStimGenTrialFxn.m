function [varyingParam] = MultStimGenTrialFxn(stimParams, interstimulusInterval, numReps, exptType, paramsDir)
    
    
% Determine the number of trials based on experiment type
trialsPerStim = numReps; % Default
stimType = []; % Placeholder for stimulus type assignment
varyingParam = []; % Placeholder for parameter that varies

% Load calibration data for left and right speakers
calibrationFile = fullfile(paramsDir, 'Calibration.xlsx');
calibData_L = readmatrix(calibrationFile, 'Sheet', 'Calibration_L');
calibData_R = readmatrix(calibrationFile, 'Sheet', 'Calibration_R');

% Extract frequency and voltage calibration data
calibFreqs_L = calibData_L(:, 1); % Frequencies (Left)
calibVoltages_L = calibData_L(:, 2:end); % Voltages for different dB SPLs (Left)
calibFreqs_R = calibData_R(:, 1); % Frequencies (Right)
calibVoltages_R = calibData_R(:, 2:end); % Voltages for different dB SPLs (Right)
% **Identify the row in calibration that contains Noise Calibration**
noiseIdx_L = find(isnan(calibData_L));
noiseIdx_R = find(isnan(calibData_R));

% dB SPL levels available in calibration MUST AGREE WITH SPREADSHEEET****
calibdBSPLs = [40, 50, 60, 70]; 

% The user specifies the type of experiment we're running
if contains(exptType, 'BBN')
    % **Broadband Noise** (Unmodulated) 
    % Set StimType to 3 (Noise)
    trialsPerStim = numReps;
    varyingParam = NaN(1, trialsPerStim); % placeholder so paramValues has correct shape
    stimParams.ModFreq = 1;
    stimTypeList = ones(1, trialsPerStim) * 3; % Noise
    % **Initialize lists**
    toneAmpList_L = zeros(1, trialsPerStim);
    toneAmpList_R = zeros(1, trialsPerStim);

    % **Find noise calibration values**
    [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));

    if calibdBSPLs(dbIdx) == stimParams.dbSPL
        % Exact match in calibration
        noiseAmp_L = calibVoltages_L(noiseIdx_L, dbIdx);
        noiseAmp_R = calibVoltages_R(noiseIdx_R, dbIdx);
    else
        % Interpolate between available dB SPL levels
        lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
        upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');

        V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
        V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
        V2_R = calibVoltages_R(noiseIdx_R, upperIdx);

        dB1 = calibdBSPLs(lowerIdx);
        dB2 = calibdBSPLs(upperIdx);

        noiseAmp_L = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
        noiseAmp_R = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
    end

    % **Fill amplitude lists with noise amplitude**
    toneAmpList_L(:) = noiseAmp_L;
    toneAmpList_R(:) = noiseAmp_R;
elseif contains(exptType,'Click')
        % Click
    % Set StimType to 3 (Noise)
    trialsPerStim = numReps;
    varyingParam = NaN(1, trialsPerStim); % placeholder so paramValues has correct shape
    stimParams.ModFreq = 1;
    stimTypeList = ones(1, trialsPerStim) * 2; % Noise
    % **Initialize lists**
    toneAmpList_L = zeros(1, trialsPerStim);
    toneAmpList_R = zeros(1, trialsPerStim);

    % **Find noise calibration values**
    [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));

    if calibdBSPLs(dbIdx) == stimParams.dbSPL
        % Exact match in calibration
        noiseAmp_L = calibVoltages_L(noiseIdx_L, dbIdx);
        noiseAmp_R = calibVoltages_R(noiseIdx_R, dbIdx);
    else
        % Interpolate between available dB SPL levels
        lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
        upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');

        V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
        V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
        V2_R = calibVoltages_R(noiseIdx_R, upperIdx);

        dB1 = calibdBSPLs(lowerIdx);
        dB2 = calibdBSPLs(upperIdx);

        noiseAmp_L = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
        noiseAmp_R = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
    end

    % **Fill amplitude lists with noise amplitude**
    toneAmpList_L(:) = noiseAmp_L;
    toneAmpList_R(:) = noiseAmp_R;

elseif contains(exptType, 'AMfreqtone')
    % **AM TONE**

    % old way of creating rand param list
    %trialsPerStim = numReps * length(unique(stimParams.ModFreq));
    % varyingParam = repmat(unique(stimParams.ModFreq), 1, numReps);
    % varyingParam = varyingParam(randperm(length(varyingParam)));
    %stimTypeList = ones(1, trialsPerStim) * 3; % Noise


    % Create rand param list, new way %%
    % Get unique modulation frequencies
    modFreqs = unique(stimParams.ModFreq);
    
    % Generate trials ensuring exactly numReps per ModFreq
    varyingParam = [];
    stimTypeList = [];
    
    for i = 1:length(modFreqs)
        varyingParam = [varyingParam, repmat(modFreqs(i), 1, numReps)];
        stimTypeList = [stimTypeList, repmat(0, 1, numReps)];  % Assuming 3 = Noise, change to 0 for tones
    end
    
    % Shuffle the entire set of trials AFTER creating the block
    shuffledIdx = randperm(length(varyingParam));
    varyingParam = varyingParam(shuffledIdx);
    stimTypeList = stimTypeList(shuffledIdx);
    
    % Update the total number of trials accordingly
    trialsPerStim = length(varyingParam);


    % **Retrieve noise amplitude from calibration**
    [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));

    if calibdBSPLs(dbIdx) == stimParams.dbSPL
        noiseAmp_L = calibVoltages_L(noiseIdx_L, dbIdx);
        noiseAmp_R = calibVoltages_R(noiseIdx_R, dbIdx);
    else
        % Interpolate between available dB SPL levels
        lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
        upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');

        V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
        V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
        V2_R = calibVoltages_R(noiseIdx_R, upperIdx);

        dB1 = calibdBSPLs(lowerIdx);
        dB2 = calibdBSPLs(upperIdx);

        noiseAmp_L = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
        noiseAmp_R = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
    end

    % **Fill amplitude lists**
    toneAmpList_L = ones(1, trialsPerStim) * noiseAmp_L;
    toneAmpList_R = ones(1, trialsPerStim) * noiseAmp_R;

elseif contains(exptType, 'AMfreqnoise')
    % **AM Noise**

    % old way of creating rand param list
    %trialsPerStim = numReps * length(unique(stimParams.ModFreq));
    % varyingParam = repmat(unique(stimParams.ModFreq), 1, numReps);
    % varyingParam = varyingParam(randperm(length(varyingParam)));
    %stimTypeList = ones(1, trialsPerStim) * 3; % Noise


    % Create rand param list, new way %%
    % Get unique modulation frequencies
    modFreqs = unique(stimParams.ModFreq);
    
    % Generate trials ensuring exactly numReps per ModFreq
    varyingParam = [];
    stimTypeList = [];
    
    for i = 1:length(modFreqs)
        varyingParam = [varyingParam, repmat(modFreqs(i), 1, numReps)];
        stimTypeList = [stimTypeList, repmat(3, 1, numReps)];  % Assuming 3 = Noise, change to 0 for tones
    end
    
    % Shuffle the entire set of trials AFTER creating the block
    shuffledIdx = randperm(length(varyingParam));
    varyingParam = varyingParam(shuffledIdx);
    stimTypeList = stimTypeList(shuffledIdx);
    
    % Update the total number of trials accordingly
    trialsPerStim = length(varyingParam);


    % **Retrieve noise amplitude from calibration**
    [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));

    if calibdBSPLs(dbIdx) == stimParams.dbSPL
        noiseAmp_L = calibVoltages_L(noiseIdx_L, dbIdx);
        noiseAmp_R = calibVoltages_R(noiseIdx_R, dbIdx);
    else
        % Interpolate between available dB SPL levels
        lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
        upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');

        V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
        V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
        V2_R = calibVoltages_R(noiseIdx_R, upperIdx);

        dB1 = calibdBSPLs(lowerIdx);
        dB2 = calibdBSPLs(upperIdx);

        noiseAmp_L = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
        noiseAmp_R = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
    end

    % **Fill amplitude lists**
    toneAmpList_L = ones(1, trialsPerStim) * noiseAmp_L;
    toneAmpList_R = ones(1, trialsPerStim) * noiseAmp_R;

elseif contains(exptType, 'AMdepthtone')
    % **AM Depth Variation for Tones**
    trialsPerStim = numReps * length(unique(stimParams.ModDepth));
    varyingParam = repmat(unique(stimParams.ModDepth), 1, numReps);
    varyingParam = varyingParam(randperm(length(varyingParam)));
    stimTypeList = ones(1, trialsPerStim) * 0; % Tones 

    % Initialize amplitude lists
    toneAmpList_L = ones(1, trialsPerStim) * stimParams.ToneAmp;
    toneAmpList_R = ones(1, trialsPerStim) * stimParams.ToneAmp;

elseif contains(exptType, 'AMdepthnoise')
    % **AM Depth Variation for Noise**
    trialsPerStim = numReps * length(unique(stimParams.ModDepth));
    varyingParam = repmat(unique(stimParams.ModDepth), 1, numReps);
    varyingParam = varyingParam(randperm(length(varyingParam)));
    stimTypeList = ones(1, trialsPerStim) * 3; %  Noise

    % **Retrieve noise amplitude from calibration**
    [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));

    if calibdBSPLs(dbIdx) == stimParams.dbSPL
        noiseAmp_L = calibVoltages_L(noiseIdx_L, dbIdx);
        noiseAmp_R = calibVoltages_R(noiseIdx_R, dbIdx);
    else
        % Interpolate between available dB SPL levels
        lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
        upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');

        V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
        V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
        V2_R = calibVoltages_R(noiseIdx_R, upperIdx);

        dB1 = calibdBSPLs(lowerIdx);
        dB2 = calibdBSPLs(upperIdx);

        noiseAmp_L = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
        noiseAmp_R = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
    end

    % **Fill amplitude lists**
    toneAmpList_L = ones(1, trialsPerStim) * noiseAmp_L;
    toneAmpList_R = ones(1, trialsPerStim) * noiseAmp_R;

elseif contains(exptType, 'FM')
    % **FM Sweeps**
    trialsPerStim = numReps;
    stimTypeList = ones(1, trialsPerStim) * 0; % Tones % FM
    toneAmpList_L = ones(1, trialsPerStim) * stimParams.ToneAmp;
    toneAmpList_R = ones(1, trialsPerStim) * stimParams.ToneAmp;

    varyingParam = repmat(unique(stimParams.FM1), 1, numReps);
    varyingParam = varyingParam(randperm(length(varyingParam)));
        


    elseif contains(exptType, 'oldtono')
    
        % **Old Tuning Curve: 14 tone frequencies + 1 noise**
        predefinedFreqs = [0.353, 0.5, 0.707, 1, 1.414, 2, 2.828, 4, 5.656, ...
                           8, 11.312, 16, 22.624, 32] * 1000; % Convert to Hz
        predefinedFreqs(end+1) = NaN; % Add noise burst
    
        % **Generate randomized trials (numReps per unique stimulus)**
        uniqueStimCount = length(predefinedFreqs); 
        varyingParam = repelem(predefinedFreqs, numReps); % (16 unique × numReps)
        varyingParam = varyingParam(randperm(length(varyingParam))); % Shuffle trials
    
        % **Set corresponding StimType values**
        stimTypeList = zeros(size(varyingParam)); % Default to tones (StimType = 0)
        stimTypeList(isnan(varyingParam)) = 3; % Set noise trials to StimType = 3
    
        % **Initialize tone amplitude arrays for left and right speakers**
        toneAmpList_L = zeros(size(varyingParam));
        toneAmpList_R = zeros(size(varyingParam));

        stimParams.ModFreq = 1;

    % **Compute required voltage for each frequency based on user-specified dB SPL**
        for i = 1:length(varyingParam)
            if isnan(varyingParam(i)) % Noise trial
                % **Use Noise Calibration**
                [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));
                
                if calibdBSPLs(dbIdx) == stimParams.dbSPL
                    % Exact dB SPL match for noise
                    toneAmpList_L(i) = calibVoltages_L(noiseIdx_L, dbIdx);
                    toneAmpList_R(i) = calibVoltages_R(noiseIdx_R, dbIdx);
                else
                    % Interpolate noise voltage using dB-to-voltage conversion
                    lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
                    upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');
        
                    % Noise voltages (Left)
                    V1_L = calibVoltages_L(noiseIdx_L, lowerIdx);
                    V2_L = calibVoltages_L(noiseIdx_L, upperIdx);
        
                    % Noise voltages (Right)
                    V1_R = calibVoltages_R(noiseIdx_R, lowerIdx);
                    V2_R = calibVoltages_R(noiseIdx_R, upperIdx);
        
                    % dB SPL values
                    dB1 = calibdBSPLs(lowerIdx);
                    dB2 = calibdBSPLs(upperIdx);
        
                    % **Estimate noise voltage using inverse dB-to-voltage conversion**
                    toneAmpList_L(i) = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
                    toneAmpList_R(i) = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
                end
            else
                % **Handle Tone Trials as before**
                [~, closestIdx_L] = min(abs(calibFreqs_L - varyingParam(i)));
                [~, closestIdx_R] = min(abs(calibFreqs_R - varyingParam(i)));
                [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));
        
                if calibdBSPLs(dbIdx) == stimParams.dbSPL
                    % Exact dB SPL match for tones
                    toneAmpList_L(i) = calibVoltages_L(closestIdx_L, dbIdx);
                    toneAmpList_R(i) = calibVoltages_R(closestIdx_R, dbIdx);
                else
                    % Interpolate voltage for tones
                    lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
                    upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');
        
                    % Tone voltages (Left)
                    V1_L = calibVoltages_L(closestIdx_L, lowerIdx);
                    V2_L = calibVoltages_L(closestIdx_L, upperIdx);
        
                    % Tone voltages (Right)
                    V1_R = calibVoltages_R(closestIdx_R, lowerIdx);
                    V2_R = calibVoltages_R(closestIdx_R, upperIdx);
        
                    % dB SPL values
                    dB1 = calibdBSPLs(lowerIdx);
                    dB2 = calibdBSPLs(upperIdx);
        
                    % **Estimate tone voltage using inverse dB-to-voltage conversion**
                    toneAmpList_L(i) = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
                    toneAmpList_R(i) = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
                end
            end
        end

    % **Set total trials correctly**
    trialsPerStim = numReps * uniqueStimCount; % Now correctly = 16 × numReps
   
    
    elseif contains(exptType, 'newtono')
        % **Tuning Curve: User-defined center frequency and octave spacing**
        centerFreq = stimParams.ToneFreq; 
        numOctaves = stimParams.OctaveRange; 
        freqs = centerFreq * 2.^linspace(-numOctaves, numOctaves, 5 * numOctaves); % Log-spaced
        trialsPerStim = numReps * length(freqs);
        varyingParam = repmat(freqs, 1, numReps); % Repeat for numReps
        varyingParam = varyingParam(randperm(length(varyingParam))); % Shuffle trials
        stimTypeList = ones(1, trialsPerStim) * 0; % Tones
        stimParams.ModFreq = 1;
        
    
        % **Load calibration data for left and right speakers**
        calibrationFile = fullfile(paramsDir, 'Calibration.xlsx');
        calibData_L = readmatrix(calibrationFile, 'Sheet', 'Calibration_L');
        calibData_R = readmatrix(calibrationFile, 'Sheet', 'Calibration_R');
    
        % **Extract frequency and voltage calibration data (L & R)**
        calibFreqs_L = calibData_L(:, 1); % Column 1: Frequencies (Hz)
        calibVoltages_L = calibData_L(:, 2:end); % Remaining columns: Voltages at different dB SPLs
    
        calibFreqs_R = calibData_R(:, 1); % Column 1: Frequencies (Hz)
        calibVoltages_R = calibData_R(:, 2:end); % Remaining columns: Voltages at different dB SPLs
    
        % **Define available dB SPL levels in calibration**
        calibdBSPLs = [40, 50, 60, 70]; 
    
        % **Initialize calibrated amplitude lists for L & R speakers**
        toneAmpList_L = zeros(size(varyingParam)); 
        toneAmpList_R = zeros(size(varyingParam));

        % **Find the required voltage for each frequency based on user-specified dB SPL**
        for i = 1:length(varyingParam)
            % **Find the closest frequency in the calibration table (L & R)**
            [~, closestIdx_L] = min(abs(calibFreqs_L - varyingParam(i)));
            [~, closestIdx_R] = min(abs(calibFreqs_R - varyingParam(i)));
    
            % **Find the closest dB SPL level in the calibration**
            [~, dbIdx] = min(abs(calibdBSPLs - stimParams.dbSPL));
    
            if calibdBSPLs(dbIdx) == stimParams.dbSPL
                % **Exact dB SPL match: Use corresponding voltage**
                toneAmpList_L(i) = calibVoltages_L(closestIdx_L, dbIdx);
                toneAmpList_R(i) = calibVoltages_R(closestIdx_R, dbIdx);
            else
                % **Interpolate voltage if exact dB SPL is not available**
                if stimParams.dbSPL < min(calibdBSPLs) || stimParams.dbSPL > max(calibdBSPLs)
                    disp('Requested dB SPL is outside calibration range (40-70 dB SPL)');
                end
    
                % **Find the two nearest dB SPL values**
                lowerIdx = find(calibdBSPLs < stimParams.dbSPL, 1, 'last');
                upperIdx = find(calibdBSPLs > stimParams.dbSPL, 1, 'first');
    
                % **Voltages (L Speaker)**
                V1_L = calibVoltages_L(closestIdx_L, lowerIdx);
                V2_L = calibVoltages_L(closestIdx_L, upperIdx);
    
                % **Voltages (R Speaker)**
                V1_R = calibVoltages_R(closestIdx_R, lowerIdx);
                V2_R = calibVoltages_R(closestIdx_R, upperIdx);
    
                % **Corresponding dB SPL values**
                dB1 = calibdBSPLs(lowerIdx);
                dB2 = calibdBSPLs(upperIdx);
    
                % **Estimate required voltage using dB-to-voltage conversion**
                toneAmpList_L(i) = V1_L * 10^((stimParams.dbSPL - dB1) / 20);
                toneAmpList_R(i) = V1_R * 10^((stimParams.dbSPL - dB1) / 20);
            end
        end
end
    
    % Randomize the order of varying parameter if applicable (but NOT for oldtono/tono)
    % if ~isempty(varyingParam) && ~(contains(exptType, 'oldtono') || ~contains(exptType, 'newtono')) || ~contains(exptType, 'AMfreqnoise')
    %     varyingParam = repmat(varyingParam, 1, numReps);
    %     varyingParam = varyingParam(randperm(length(varyingParam)));
    % end

    
    % Open text files for writing
    toneAmpFile_L = fopen(fullfile(paramsDir, 'ToneAmp_L.txt'), 'w');
    toneAmpFile_R = fopen(fullfile(paramsDir, 'ToneAmp_R.txt'), 'w');
    toneFreqFile = fopen(fullfile(paramsDir, 'ToneFreq.txt'), 'w');
    toneDurFile = fopen(fullfile(paramsDir, 'ToneDur.txt'), 'w');
    modAmpFile = fopen(fullfile(paramsDir, 'ModDepth.txt'), 'w');
    modFreqFile = fopen(fullfile(paramsDir, 'ModFreq.txt'), 'w');
    sweepTimeFile = fopen(fullfile(paramsDir, 'FMSweepTime.txt'), 'w');
    f1File = fopen(fullfile(paramsDir, 'FM1.txt'), 'w');
    f2File = fopen(fullfile(paramsDir, 'FM2.txt'), 'w');
    stimTypeFile = fopen(fullfile(paramsDir, 'StimType.txt'), 'w');
    isiFile = fopen(fullfile(paramsDir, 'ISI.txt'), 'w');

    try

    for trial = 1:trialsPerStim
        currentParams = stimParams; % Copy the default parameters for this trial
        % **Make sure we update ToneFreq**
        if contains(exptType,'oldtono') || contains(exptType,'newtono')
            currentParams.ToneFreq = varyingParam(trial);
        elseif contains(exptType,'AMfreqnoise') || contains(exptType,'AMfreqtone')
            currentParams.ModFreq = varyingParam(trial);
        end
        currentParams.StimType = stimTypeList(trial);

        % **Write parameters to text files**
        fprintf(toneAmpFile_L, '%f\n', toneAmpList_L(trial));
        fprintf(toneAmpFile_R, '%f\n', toneAmpList_R(trial));
        fprintf(toneFreqFile, '%f\n', currentParams.ToneFreq);
        fprintf(toneDurFile, '%f\n', currentParams.ToneDur);
        fprintf(modAmpFile, '%f\n', currentParams.ModDepth);
        fprintf(modFreqFile, '%f\n', currentParams.ModFreq);
        fprintf(sweepTimeFile, '%f\n', currentParams.FMSweepTime);
        fprintf(f1File, '%f\n', currentParams.FM1);
        fprintf(f2File, '%f\n', currentParams.FM2);
        fprintf(stimTypeFile, '%d\n', currentParams.StimType);
        fprintf(isiFile, '%f\n', interstimulusInterval);
    end

catch exception
    disp('An error occurred: something stopped the loop before it could finish. Closing files and saving data.');
    disp(exception.message);
end

% **Close text files**
fclose(toneAmpFile_L);
fclose(toneAmpFile_R);
fclose(toneFreqFile);
fclose(toneDurFile);
fclose(modAmpFile);
fclose(modFreqFile);
fclose(sweepTimeFile);
fclose(f1File);
fclose(f2File);
fclose(stimTypeFile);
fclose(isiFile);
end
