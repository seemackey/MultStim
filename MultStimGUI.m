classdef MultStimGUI < handle
    properties
        fig
        exptTypeDropdown
        paramPanel
        paramFields
        soaLabel
        stimParams
        runButton
        RP
        numRepsField
        filenameField
    end

    methods
        function obj = MultStimGUI(customParams)
            obj.fig = uifigure('Name', 'MultStim Parameter Editor', 'Position', [100, 100, 500, 580]);

            % Apply custom parameters if provided
            if nargin > 0
                obj.stimParams = customParams;
            else
                obj.stimParams = struct('ToneAmp', 0.5, 'ToneFreq', 5656, 'ToneDur', 100, ...
                    'ModDepth', 1, 'ModFreq', [4,8,16,32,64,128,256], 'FMSweepTime', 100, ...
                    'FM1', 2000, 'FM2', 12000, 'StimType', 0, 'OctaveRange', 1, 'dbSPL', 50, ...
                    'ISI', 524);
            end

            % Initialize RP controller
            obj.RP = actxserver('RPco.x');
            obj.RP.ConnectRX6('USB', 1);
            obj.RP.Halt;
            obj.RP.ClearCOF;

            % Experiment Type Dropdown
            uilabel(obj.fig, 'Position', [20, 540, 150, 20], 'Text', 'Select Experiment Type:');
            obj.exptTypeDropdown = uidropdown(obj.fig, 'Position', [180, 540, 150, 20], ...
                'Items', {'BBN', 'Click', 'oldtono', 'newtono', 'AM noise', 'FM'}, ...
                'ValueChangedFcn', @(src, event) obj.updateParams());

            % Set default value explicitly to trigger correct param init
            obj.exptTypeDropdown.Value = 'BBN';

            % Parameter Panel
            obj.paramPanel = uipanel(obj.fig, 'Title', 'Parameters', 'Position', [20, 120, 460, 400]);
            obj.paramFields = struct();

            % SOA Display
            obj.soaLabel = uilabel(obj.fig, 'Position', [20, 100, 460, 20], 'Text', 'SOA: N/A ms');

            % Filename
            uilabel(obj.fig, 'Position', [20, 70, 100, 20], 'Text', 'Filename:');
            recentFile = obj.getMostRecentFilename('C:\MultStim\TrialParameters');
            obj.filenameField = uieditfield(obj.fig, 'text', 'Position', [130, 70, 200, 20], 'Value', recentFile);

            % Number of repetitions
            uilabel(obj.fig, 'Position', [20, 40, 100, 20], 'Text', 'Repetitions:');
            obj.numRepsField = uieditfield(obj.fig, 'numeric', 'Position', [130, 40, 100, 20], 'Value', 50);

            % Run Button
            obj.runButton = uibutton(obj.fig, 'Text', 'Run Experiment', 'Position', [350, 30, 120, 40], 'ButtonPushedFcn', @(src, event) obj.runExperiment());

            % Update parameter UI fields
            obj.updateParams();
        end

        function updateParams(app)
            delete(allchild(app.paramPanel));
            app.paramFields = struct();

            exptType = app.exptTypeDropdown.Value;

            % Set experiment-specific defaults
            switch exptType
                case 'Click'
                    app.stimParams.ToneDur = 1;
                    app.stimParams.ISI = 524;
                case 'AM noise'
                    app.stimParams.ToneDur = 500;
                    app.stimParams.ISI = 1000;
                case 'FM'
                    app.stimParams.ToneDur = 100;
                    app.stimParams.ISI = 524;
                    app.createParamField('FM1', app.stimParams.FM1, 'FM Start Freq (Hz)');
                    app.createParamField('FM2', app.stimParams.FM2, 'FM End Freq (Hz)');

                otherwise
                    app.stimParams.ToneDur = 100;
                    app.stimParams.ISI = 524;
            end

            % Always present common parameters
            app.createParamField('ToneDur', app.stimParams.ToneDur, 'Duration (ms)');
            app.createParamField('ISI', app.stimParams.ISI, 'Interstimulus Interval (ms)');
            app.createParamField('dbSPL', app.stimParams.dbSPL, 'Sound Level (dB SPL)');

            % Dynamic parameter fields based on experiment type
            switch exptType
                case 'BBN'
                case 'Click'
                case 'oldtono'
                    %app.createParamField('ToneFreq', app.stimParams.ToneFreq);
                case 'newtono'
                    app.createParamField('ToneFreq', app.stimParams.ToneFreq);
                    app.createParamField('OctaveRange', app.stimParams.OctaveRange);
                case 'AM noise'
                    app.createParamField('ModFreq', mat2str(app.stimParams.ModFreq));
            end

            app.updateSOA();
        end

        function createParamField(app, paramName, defaultValue, displayName)
            if nargin < 4
                displayName = paramName;
            end
            yPos = 340 - numel(fieldnames(app.paramFields)) * 40;
            label = uilabel(app.paramPanel, 'Text', displayName, 'Position', [20, yPos, 200, 20]);
            edit = uieditfield(app.paramPanel, 'text', 'Position', [230, yPos, 200, 20]);
            edit.Value = num2str(defaultValue);
            edit.ValueChangedFcn = @(src, event) app.updateSOA();
            app.paramFields.(paramName) = edit;
        end

        function updateSOA(app)
            try
                toneDur = str2double(app.paramFields.ToneDur.Value);
                ISI = str2double(app.paramFields.ISI.Value);

                if isnan(toneDur) || isnan(ISI)
                    app.soaLabel.Text = 'SOA: Invalid input';
                else
                    soa = toneDur + ISI;
                    app.soaLabel.Text = sprintf('SOA: %.2f ms', soa);
                end
            catch
                app.soaLabel.Text = 'SOA: Error calculating';
            end
        end

        function runExperiment(app)
            fields = fieldnames(app.paramFields);
            for i = 1:length(fields)
                val = str2num(app.paramFields.(fields{i}).Value); %#ok<ST2NM>
                if isempty(val)
                    val = app.paramFields.(fields{i}).Value;
                end
                app.stimParams.(fields{i}) = val;
            end
            if contains(app.exptTypeDropdown.Value,'AM noise')
                exptType = 'AMfreqnoise'; % the param fxn looks for this string specifically
            else
                exptType = app.exptTypeDropdown.Value;
            end
            stimParams = app.stimParams;
            numReps = app.numRepsField.Value;
            filename = app.filenameField.Value;

            runMultStimWithParams(app.RP, stimParams, exptType, numReps, filename);
        end

        function fname = getMostRecentFilename(~, dirPath)
            files = dir(fullfile(dirPath, '*.ev2'));
            if isempty(files)
                fname = 'guiRun';
            else
                [~, idx] = max([files.datenum]);
                [~, name, ~] = fileparts(files(idx).name);
                fname = name;
            end
        end
    end
end
