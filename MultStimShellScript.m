tic

clear
close all
clc

% Set up actx server/control
handles.RP = actxcontrol('RPco.x');
RP = handles.RP;

% Connect to the device and halt any ongoing processes
RP.ConnectRX6('USB', 1);
RP.Halt;
RP.ClearCOF;

% Directory for the text files
paramsDir = 'C:\MultStim\';  % Your directory
gimmefiggies = 1; % Set to 1 to generate parameter histograms
filename = 'ch'; % unique filename string

% Define the parameters for the stimulus
stimParams = struct('ToneAmp', 0.5, 'ToneFreq', 5656, 'ToneDur', 500, ...
                    'ModDepth', 1, 'ModFreq', [4,8,16,32,64,128,256], 'FMSweepTime', 100, ...
                    'FM1', 2000, 'FM2', 12000, 'StimType', 0, 'OctaveRange', 1, 'dbSPL',60);

% Define interstimulus interval (in milliseconds)
interstimulusInterval = 1000;

% Experiment type - User defines the type of experiment
exptType = 'AMfreqnoise'; % Change this based on experiment type
% exptType = 'AMfreqtone'; % Change this based on experiment type
% exptType = 'BBN'; % Change this based on experiment type
% exptType = 'Click';
%exptType = 'oldtono'; % Change this based on experiment type
% exptType = 'newtono'; % Change this based on experiment type

% Number of repetitions per unique stimulus
numReps = 70;

% Generate stimuli and write to text files
[varyingParam] = MultStimGenTrialFxn(stimParams, interstimulusInterval, numReps, exptType, paramsDir);

% "TrialParameters" directory
futureDir = fullfile(paramsDir, 'TrialParameters');
if ~exist(futureDir, 'dir')
    mkdir(futureDir);
end

% Define the list of parameter files
paramFiles = {'ToneAmp_L.txt', 'ToneAmp_R.txt', 'ToneFreq.txt', 'ToneDur.txt', 'ModDepth.txt', 'ModFreq.txt', ...
              'FMSweepTime.txt', 'FM1.txt', 'FM2.txt', 'StimType.txt', 'ISI.txt'};

% Define the corresponding parameter names
paramNames = {'Stim Amplitude (L)', 'Stim Amplitude (R)' 'Tone Frequency', 'Tone Duration', 'Modulation Depth', ...
              'Modulation Frequency', 'FM Sweep Time', 'FM1 Frequency', 'FM2 Frequency', ...
              'Stimulus Type', 'Interstimulus Interval'};

% Initialize matrix to hold all parameters
allParams = [];

% Loop through each parameter file and concatenate the data into allParams
for i = 1:length(paramFiles)
    paramValues = load(fullfile(paramsDir, paramFiles{i}));
    allParams = [allParams, paramValues];
end

% Clean headers: Replace spaces with underscores
cleanParamNames = strrep(paramNames, ' ', '_');

% Generate output file names based on the current date and time
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
ev2FileName = fullfile(futureDir, [filename '_' timestamp '.ev2']); % keep .ev2 if needed

% Open the ev2 file for writing
fid = fopen(ev2FileName, 'w');

% Write the headers using tab delimiter
fprintf(fid, '%s\t', cleanParamNames{1:end-1});
fprintf(fid, '%s\n', cleanParamNames{end});

% Close the file after writing headers
fclose(fid);

% Append the actual data with tab delimiter
dlmwrite(ev2FileName, allParams, '-append', 'delimiter', '\t');

% Save `varyingParam` to a .DAT file with "@v" appended to the filename
datFileName = fullfile(futureDir, [filename '_' timestamp '_@v.DAT']);
dlmwrite(datFileName, varyingParam, 'delimiter', '\n');


%% CHECK THE PARAMETER SETTINGS WITH THIS PLOT
if gimmefiggies == 1
    % Create a figure for the histograms
    figure('Name', 'Parameter Histograms', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);

    % Loop through each parameter file
    for i = 1:length(paramFiles)
        paramValues = load(fullfile(paramsDir, paramFiles{i}));
        subplot(3, 4, i);
        histogram(paramValues);
        title(paramNames{i});
        xlabel(paramNames{i});
        ylabel('Frequency');
    end
end

% Pause to allow user review
pause(2);

% Ask the user if the parameters are okay and if they are ready to proceed
userResponse = '';
while ~strcmpi(userResponse, 'yes') && ~strcmpi(userResponse, 'no')
    userResponse = input('Are the parameters correct? Type "yes" to proceed or "no" to review again: ', 's');

    if strcmpi(userResponse, 'yes') && ~RP.GetStatus()==0
        % Load the appropriate RCX file based on experiment type
        if contains(exptType,'BBN') || (contains(exptType, 'oldtono') || contains(exptType, 'newtono')) || contains(exptType, 'Click')
            RP.LoadCOF('C:\MultStim\MultStim2speakerBBN.rcx');
        else
            RP.LoadCOF('C:\MultStim\MultStim2speaker.rcx');
        end

        RP.Run;
        
        % Calculate the total duration of the experiment
        % Extract stimulus duration from stimParams
        stimDuration = stimParams.ToneDur / 1000; % Convert ms to seconds

        % Calculate total number of trials
        % special for BBN here
        if contains(exptType,'BBN') || (contains(exptType,'Click'))
            totalTrials = numReps;
        else
            totalTrials = numReps * length(unique(varyingParam));
        end

        % Calculate the total duration: (Stimulus duration + ISI) * number of trials
        totalDuration = totalTrials * (stimDuration + interstimulusInterval/1000);

        % Notify user about expected run time
        fprintf('Experiment running. Estimated duration: %.2f seconds (%.2f minutes).\n', totalDuration, totalDuration / 60);
        fprintf('Type "RP.Halt" to stop prematurely.\n');

        % Set up a timer to automatically halt the RP after totalDuration seconds
        t = timer('TimerFcn', @(~,~) RP_Halt_Callback(RP), 'StartDelay', totalDuration);

        % Start the timer
        start(t);
        break; % Exit the loop and proceed

    elseif strcmpi(userResponse, 'no')
        disp('Please review the parameters and run the script again.');
        return; % Exit the script
    elseif RP.GetStatus()==0
        disp('Device not connected. Check USB. Usually the PC needs a reboot.');
    else
        disp('Invalid response. Please type "yes" or "no".');
    end
end

% Timer callback function to halt the RP device
function RP_Halt_Callback(RP)
    invoke(RP, 'Halt');
    fprintf('Experiment completed. The RP device has been halted successfully.\n');
end




% Initialize the timer
%startTime = tic;

% Try-Catch block to ensure event files are updated correctly even if stopped prematurely
% try
%     while true
%         elapsedTime = toc(startTime);
%         if elapsedTime >= interstimulusInterval * numReps / 1000
%             RP.Halt;
%             disp('Experiment complete. Circuit halted.');
%             break;
%         end
%     end
% catch exception
%     disp('Experiment was interrupted. Halting the circuit.');
%     RP.Halt;
%     rethrow(exception);
% end
