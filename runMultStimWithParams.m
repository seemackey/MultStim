function runMultStimWithParams(RP, stimParams, exptType, numReps, filename, gimmefiggies)
% Function version of MultStimShellScript

%if nargin < 6
    gimmefiggies = 1;
%end

paramsDir = 'C:\MultStim\';
interstimulusInterval = stimParams.ISI;

% Generate stimuli and write to text files
[varyingParam] = MultStimGenTrialFxn(stimParams, interstimulusInterval, numReps, exptType, paramsDir);

futureDir = fullfile(paramsDir, 'TrialParameters');
if ~exist(futureDir, 'dir')
    mkdir(futureDir);
end

paramFiles = {'ToneAmp_L.txt', 'ToneAmp_R.txt', 'ToneFreq.txt', 'ToneDur.txt', 'ModDepth.txt', 'ModFreq.txt', ...
              'FMSweepTime.txt', 'FM1.txt', 'FM2.txt', 'StimType.txt', 'ISI.txt'};
paramNames = {'Stim Amplitude (L)', 'Stim Amplitude (R)', 'Tone Frequency', 'Tone Duration', 'Modulation Depth', ...
              'Modulation Frequency', 'FM Sweep Time', 'FM1 Frequency', 'FM2 Frequency', 'Stimulus Type', 'Interstimulus Interval'};

allParams = [];
for i = 1:length(paramFiles)
    paramValues = load(fullfile(paramsDir, paramFiles{i}));
    allParams = [allParams, paramValues];
end

cleanParamNames = strrep(paramNames, ' ', '_');
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
ev2FileName = fullfile(futureDir, [filename '_' timestamp '.ev2']);
fid = fopen(ev2FileName, 'w');
fprintf(fid, '%s\t', cleanParamNames{1:end-1});
fprintf(fid, '%s\n', cleanParamNames{end});
fclose(fid);
dlmwrite(ev2FileName, allParams, '-append', 'delimiter', '\t');

datFileName = fullfile(futureDir, [filename '_' timestamp '_@v.DAT']);
dlmwrite(datFileName, varyingParam, 'delimiter', '\n');

if gimmefiggies == 1
    figure('Name', 'Parameter Histograms', 'NumberTitle', 'off', 'Position', [1500, 500, 1000, 600]);
    for i = 1:length(paramFiles)
        paramValues = load(fullfile(paramsDir, paramFiles{i}));
        subplot(3, 4, i);
        histogram(paramValues);
        title(paramNames{i});
        xlabel(paramNames{i});
        ylabel('Frequency');
    end
end

pause(2);

userResponse = '';
while ~strcmpi(userResponse, 'yes') && ~strcmpi(userResponse, 'no')
    userResponse = input('Are the parameters correct? Type "yes" to proceed or "no" to review again: ', 's');

    if strcmpi(userResponse, 'yes') && ~RP.GetStatus()==0
        if contains(exptType,'BBN') || contains(exptType, 'oldtono') || contains(exptType, 'newtono') || contains(exptType, 'Click')
            RP.LoadCOF('C:\MultStim\MultStim2speakerBBN.rcx');
        else
            RP.LoadCOF('C:\MultStim\MultStim2speaker.rcx');
        end

        RP.Run;

        stimDuration = stimParams.ToneDur / 1000;
        if contains(exptType, 'BBN') || contains(exptType, 'Click')
            totalTrials = numReps;
        else
            TheNans = isnan(varyingParam);
            numUniqueNonNan = length(unique(varyingParam(~TheNans)));
            numNanTypes = double(any(TheNans));  % 1 if there's any NaNs, else 0
            
            totalTrials = numReps * (numUniqueNonNan + numNanTypes);

        end

        totalDuration = totalTrials * (stimDuration + interstimulusInterval / 1000);

        fprintf('Experiment running. Estimated duration: %.2f seconds (%.2f minutes).\n', totalDuration, totalDuration / 60);
        fprintf('Type "app.RP.Halt" to stop prematurely.\n');

        t = timer('TimerFcn', @(~,~) RP_Halt_Callback(RP), 'StartDelay', totalDuration);
        start(t);
        break;

    elseif strcmpi(userResponse, 'no')
        disp('Please review the parameters and run the script again.');
        return;
    elseif RP.GetStatus() == 0
        disp('Device not connected. Check USB. Usually the PC needs a reboot.');
    else
        disp('Invalid response. Please type "yes" or "no".');
    end
end
end

function RP_Halt_Callback(RP)
    invoke(RP, 'Halt');
    fprintf('Experiment completed. The RP device has been halted successfully.\n');
end
