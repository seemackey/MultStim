
clear
clear classes
clear functions
close all
rehash toolboxcache

defaultParams = struct('ToneAmp', 0.5, 'ToneFreq', 5656, 'ToneDur', 100, ...
    'ModDepth', 1, 'ModFreq', [4,8,16,32,64,128,256], 'FMSweepTime', 100, ...
    'FM1', 2000, 'FM2', 12000, 'StimType', 0, 'OctaveRange', 1, 'dbSPL', 50, ...
    'ISI', 524);
app = MultStimGUI(defaultParams);


