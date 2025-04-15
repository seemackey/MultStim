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
                    'FM1', 2000, 'FM2', 12000, 'StimType', 0, 'OctaveRange', 1, 'dbSPL',60,'ISI',1000);

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

runMultStimWithParams(RP, stimParams, exptType, numReps, filename, gimmefiggies)