classdef EEGAnalyzer_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        InputsPanel                  matlab.ui.container.Panel
        InputFilepathEditFieldLabel  matlab.ui.control.Label
        InputFilepathEditField       matlab.ui.control.EditField
        PatientIDEditFieldLabel      matlab.ui.control.Label
        PatientIDEditField           matlab.ui.control.EditField
        AnalyzePanel                 matlab.ui.container.Panel
        GridLayout2                  matlab.ui.container.GridLayout
        BaselineAlphaButton          matlab.ui.control.Button
        BaselineRestButton           matlab.ui.control.Button
        BaselineAlphaRestButton      matlab.ui.control.Button
        RightPanel                   matlab.ui.container.Panel
        TabGroup                     matlab.ui.container.TabGroup
        PSDTab                       matlab.ui.container.Tab
        GridLayout3                  matlab.ui.container.GridLayout
        UIAxes_Pz                    matlab.ui.control.UIAxes
        UIAxes_PO1                   matlab.ui.control.UIAxes
        UIAxes_PO2                   matlab.ui.control.UIAxes
        UIAxes_O1                    matlab.ui.control.UIAxes
        UIAxes_Oz                    matlab.ui.control.UIAxes
        UIAxes_O2                    matlab.ui.control.UIAxes
        Tab2                         matlab.ui.container.Tab
        PlotControlPanel             matlab.ui.container.Panel
        FrequencyHzSliderLabel       matlab.ui.control.Label
        FrequencyHzSlider            matlab.ui.control.Slider
        Label                        matlab.ui.control.Label
        EditFieldFrequencyHzSlider   matlab.ui.control.NumericEditField
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    methods (Access = private)
        
        %% 1 - EC
        %% 2 - EO
        function results = proc_baseline_(app,EEG, ev_idx)
            EEG_ = EEG; % store the ori EEG set with all data
            for ev_idx=1:2 % EC and EO, EC=1, EO=2

                EEG = pop_eegfiltnew(EEG_, 'locutoff',1,'hicutoff',40);
                EEG = eeg_checkset( EEG );
                EEG = clean_artifacts(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
                EEG = eeg_checkset( EEG );
                
                if ev_idx == 1 % Close
                    event_marker='Close';
                    event_type='EC';
                else
                    event_marker='Open';
                    event_type='EO';
                end            
                
                EEG = pop_epoch( EEG, {  event_marker  }, [0  60], 'newname', ['ECEO BP ASR ' event_type], 'epochinfo', 'yes');
                EEG = eeg_checkset( EEG );
                EEG = pop_rmbase( EEG, [],[]);
                EEG = eeg_checkset( EEG );     
                
                if ev_idx == 1 % Close
                    [EC, freq] = pop_spectopo(EEG, 1, [0  59998], 'EEG' , 'freqrange',[2 25],'electrodes','off');        
                else
                    [EO, freq] = pop_spectopo(EEG, 1, [0  59998], 'EEG' , 'freqrange',[2 25],'electrodes','off');        
                end
            end
                
            % Plot
            for chan=1:6
                if strcmp(EEG.chanlocs(chan).labels, 'Pz') == 1
                    hPlot = app.UIAxes_Pz;

                elseif strcmp(EEG.chanlocs(chan).labels, 'PO1') == 1
                    hPlot = app.UIAxes_PO1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'PO2') == 1
                    hPlot = app.UIAxes_PO2;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O1') == 1
                    hPlot = app.UIAxes_O1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'Oz') == 1
                    hPlot = app.UIAxes_Oz;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O2') == 1
                    hPlot = app.UIAxes_O2;
                    
                end
                
                plot(hPlot, freq, [EC(chan,:)', EO(chan,:)']);

            end
        end
        
        function results = xlimAllPlots(app, value)
            app.UIAxes_Pz.XLim = [0 value];
            app.UIAxes_PO1.XLim = [0 value];
            app.UIAxes_PO2.XLim = [0 value];
            app.UIAxes_O1.XLim = [0 value];
            app.UIAxes_Oz.XLim = [0 value];
            app.UIAxes_O2.XLim = [0 value];               
        end
        
        %% return only working channels
        function EEG = trimWorkingChannels(app, EEG)
            %% rearrange the channel location for new backpiece because the LSL stream channel info 
            %% is hard coded and not updated to the latest backpiece
            channelNameList = {'CH1', 'CH2', 'O1', 'PO1', 'PO2', 'Pz', 'Oz', 'O2' };
            for chidx=1:8
                EEG.chanlocs(chidx).labels= channelNameList{chidx};
            end
            
            %% select working channels
            EEG = pop_select( EEG,'channel',{'PO1' 'O1' 'Pz' 'O2' 'Oz' 'PO2'});
            EEG = eeg_checkset (EEG);             
        end
        
        function [EEG_p, freq] = proc_baseline2(app,EEG, ev_idx)
            EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',40);
            EEG = eeg_checkset( EEG );
            EEG = clean_artifacts(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
            EEG = eeg_checkset( EEG );
            
            if ev_idx == 1 % Close
                event_marker='Close';
                event_type='EC';
            else
                event_marker='Open';
                event_type='EO';
            end            
            
            EEG = pop_epoch( EEG, {  event_marker  }, [0  60], 'newname', ['ECEO BP ASR ' event_type], 'epochinfo', 'yes');
            EEG = eeg_checkset( EEG );
            EEG = pop_rmbase( EEG, [],[]);
            EEG = eeg_checkset( EEG );     
            
            [EEG_p, freq] = pop_spectopo(EEG, 1, [0  59998], 'EEG' , 'freqrange',[2 25],'electrodes','off');        
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: BaselineAlphaButton
        function BaselineAlphaButtonPushed(app, event)
            input_filepath = strrep(app.InputFilepathEditField.Value,'"','');
            disp([ 'Analyzing file=' input_filepath]);
            
            % convert xdf to set
            EEG = convert_xdf_to_set(input_filepath);
            
            EEG = trimWorkingChannels(app, EEG);
            [EC, freq] = proc_baseline2(app,EEG,1);
            
            % Plot
            for chan=1:6
                if strcmp(EEG.chanlocs(chan).labels, 'Pz') == 1
                    hPlot = app.UIAxes_Pz;

                elseif strcmp(EEG.chanlocs(chan).labels, 'PO1') == 1
                    hPlot = app.UIAxes_PO1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'PO2') == 1
                    hPlot = app.UIAxes_PO2;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O1') == 1
                    hPlot = app.UIAxes_O1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'Oz') == 1
                    hPlot = app.UIAxes_Oz;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O2') == 1
                    hPlot = app.UIAxes_O2;
                    
                end
                
                plot(hPlot, freq, [EC(chan,:)']);

            end 

            close all;
        end

        % Value changed function: FrequencyHzSlider
        function FrequencyHzSliderValueChanged(app, event)
            value = round(app.FrequencyHzSlider.Value); 
            app.EditFieldFrequencyHzSlider.Value = value;
            xlimAllPlots(app, value);
        end

        % Value changing function: FrequencyHzSlider
        function FrequencyHzSliderValueChanging(app, event)
            value = round(event.Value);
            app.EditFieldFrequencyHzSlider.Value = value;
            xlimAllPlots(app, value);          
        end

        % Value changed function: EditFieldFrequencyHzSlider
        function EditFieldFrequencyHzSliderValueChanged(app, event)
            value = app.EditFieldFrequencyHzSlider.Value;
            app.FrequencyHzSlider.Value = value; % update slider value too
            xlimAllPlots(app, value);
        end

        % Button pushed function: BaselineAlphaRestButton
        function BaselineAlphaRestButtonPushed(app, event)
%             input_filepath = strrep(app.InputFilepathEditField.Value,'"','');
%             disp([ 'Analyzing file=' input_filepath]);
%             
%             % convert xdf to set
%             EEG = convert_xdf_to_set(input_filepath);
%             
%             proc_baseline_(app,EEG,1);         
            input_filepath = strrep(app.InputFilepathEditField.Value,'"','');
            disp([ 'Analyzing file=' input_filepath]);
            
            % convert xdf to set
            EEG = convert_xdf_to_set(input_filepath);
            EEG = trimWorkingChannels(app, EEG);
            
            EEG_Ori = EEG;
            for ev_idx=1:2                
                if ev_idx==1
                    [EC, freq] = proc_baseline2(app,EEG,1);
                elseif ev_idx==2
                    [EO, freq] = proc_baseline2(app,EEG,2);
                end
            end
            
            % Plot
            for chan=1:6
                if strcmp(EEG.chanlocs(chan).labels, 'Pz') == 1
                    hPlot = app.UIAxes_Pz;

                elseif strcmp(EEG.chanlocs(chan).labels, 'PO1') == 1
                    hPlot = app.UIAxes_PO1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'PO2') == 1
                    hPlot = app.UIAxes_PO2;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O1') == 1
                    hPlot = app.UIAxes_O1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'Oz') == 1
                    hPlot = app.UIAxes_Oz;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O2') == 1
                    hPlot = app.UIAxes_O2;
                    
                end
                
                plot(hPlot, freq, [EC(chan,:)' EO(chan,:)']);
                legend(hPlot, 'EC','EO');
            end   
            
            close all;
            
        end

        % Button pushed function: BaselineRestButton
        function BaselineRestButtonPushed(app, event)
            input_filepath = strrep(app.InputFilepathEditField.Value,'"','');
            disp([ 'Analyzing file=' input_filepath]);
            
            % convert xdf to set
            EEG = convert_xdf_to_set(input_filepath);
            
            EEG = trimWorkingChannels(app, EEG);
            [EO, freq] = proc_baseline2(app,EEG,2);
            
            % Plot
            for chan=1:6
                if strcmp(EEG.chanlocs(chan).labels, 'Pz') == 1
                    hPlot = app.UIAxes_Pz;

                elseif strcmp(EEG.chanlocs(chan).labels, 'PO1') == 1
                    hPlot = app.UIAxes_PO1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'PO2') == 1
                    hPlot = app.UIAxes_PO2;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O1') == 1
                    hPlot = app.UIAxes_O1;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'Oz') == 1
                    hPlot = app.UIAxes_Oz;
                    
                elseif strcmp(EEG.chanlocs(chan).labels, 'O2') == 1
                    hPlot = app.UIAxes_O2;
                    
                end
                
                plot(hPlot, freq, [EO(chan,:)']);

            end
             
            close all;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {692, 692};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {341, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1010 692];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {341, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create InputsPanel
            app.InputsPanel = uipanel(app.LeftPanel);
            app.InputsPanel.Title = 'Inputs';
            app.InputsPanel.Position = [26 553 302 116];

            % Create InputFilepathEditFieldLabel
            app.InputFilepathEditFieldLabel = uilabel(app.InputsPanel);
            app.InputFilepathEditFieldLabel.HorizontalAlignment = 'right';
            app.InputFilepathEditFieldLabel.Position = [32 55 78 22];
            app.InputFilepathEditFieldLabel.Text = {'Input Filepath'; ''};

            % Create InputFilepathEditField
            app.InputFilepathEditField = uieditfield(app.InputsPanel, 'text');
            app.InputFilepathEditField.Position = [124 55 165 22];
            app.InputFilepathEditField.Value = '"C:\Recordings\visual-oddball\USE THIS DATA\sbj2\sbj2_eceo.xdf"';

            % Create PatientIDEditFieldLabel
            app.PatientIDEditFieldLabel = uilabel(app.InputsPanel);
            app.PatientIDEditFieldLabel.HorizontalAlignment = 'right';
            app.PatientIDEditFieldLabel.Position = [51 17 58 22];
            app.PatientIDEditFieldLabel.Text = {'Patient ID'; ''};

            % Create PatientIDEditField
            app.PatientIDEditField = uieditfield(app.InputsPanel, 'text');
            app.PatientIDEditField.Position = [124 17 165 22];

            % Create AnalyzePanel
            app.AnalyzePanel = uipanel(app.LeftPanel);
            app.AnalyzePanel.Title = 'Analyze';
            app.AnalyzePanel.Position = [27 306 260 221];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.AnalyzePanel);
            app.GridLayout2.ColumnWidth = {'1x', 50};
            app.GridLayout2.RowHeight = {'1x', '1x', '1x'};

            % Create BaselineAlphaButton
            app.BaselineAlphaButton = uibutton(app.GridLayout2, 'push');
            app.BaselineAlphaButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineAlphaButtonPushed, true);
            app.BaselineAlphaButton.Layout.Row = 1;
            app.BaselineAlphaButton.Layout.Column = 1;
            app.BaselineAlphaButton.Text = {'Baseline Alpha'; ''};

            % Create BaselineRestButton
            app.BaselineRestButton = uibutton(app.GridLayout2, 'push');
            app.BaselineRestButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineRestButtonPushed, true);
            app.BaselineRestButton.Layout.Row = 2;
            app.BaselineRestButton.Layout.Column = 1;
            app.BaselineRestButton.Text = {'Baseline Rest'; ''};

            % Create BaselineAlphaRestButton
            app.BaselineAlphaRestButton = uibutton(app.GridLayout2, 'push');
            app.BaselineAlphaRestButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineAlphaRestButtonPushed, true);
            app.BaselineAlphaRestButton.Layout.Row = 3;
            app.BaselineAlphaRestButton.Layout.Column = 1;
            app.BaselineAlphaRestButton.Text = 'Baseline Alpha+Rest';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.RightPanel);
            app.TabGroup.Position = [38 196 611 448];

            % Create PSDTab
            app.PSDTab = uitab(app.TabGroup);
            app.PSDTab.Title = 'PSD';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.PSDTab);
            app.GridLayout3.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x'};

            % Create UIAxes_Pz
            app.UIAxes_Pz = uiaxes(app.GridLayout3);
            title(app.UIAxes_Pz, {'Pz'; ''})
            xlabel(app.UIAxes_Pz, 'Frequency (Hz)')
            ylabel(app.UIAxes_Pz, 'PSD (Log)')
            app.UIAxes_Pz.FontSize = 9;
            app.UIAxes_Pz.XLim = [0 25];
            app.UIAxes_Pz.GridColor = [0.15 0.15 0.15];
            app.UIAxes_Pz.GridAlpha = 0.15;
            app.UIAxes_Pz.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_Pz.MinorGridAlpha = 0.25;
            app.UIAxes_Pz.Box = 'on';
            app.UIAxes_Pz.XColor = [0.15 0.15 0.15];
            app.UIAxes_Pz.YColor = [0.15 0.15 0.15];
            app.UIAxes_Pz.ZColor = [0.15 0.15 0.15];
            app.UIAxes_Pz.XGrid = 'on';
            app.UIAxes_Pz.Layout.Row = 1;
            app.UIAxes_Pz.Layout.Column = 2;

            % Create UIAxes_PO1
            app.UIAxes_PO1 = uiaxes(app.GridLayout3);
            title(app.UIAxes_PO1, 'PO1')
            xlabel(app.UIAxes_PO1, 'X')
            ylabel(app.UIAxes_PO1, 'Y')
            app.UIAxes_PO1.FontSize = 9;
            app.UIAxes_PO1.XLim = [0 25];
            app.UIAxes_PO1.GridColor = [0.15 0.15 0.15];
            app.UIAxes_PO1.GridAlpha = 0.15;
            app.UIAxes_PO1.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_PO1.MinorGridAlpha = 0.25;
            app.UIAxes_PO1.Box = 'on';
            app.UIAxes_PO1.XColor = [0.15 0.15 0.15];
            app.UIAxes_PO1.YColor = [0.15 0.15 0.15];
            app.UIAxes_PO1.ZColor = [0.15 0.15 0.15];
            app.UIAxes_PO1.XGrid = 'on';
            app.UIAxes_PO1.Layout.Row = 2;
            app.UIAxes_PO1.Layout.Column = 1;

            % Create UIAxes_PO2
            app.UIAxes_PO2 = uiaxes(app.GridLayout3);
            title(app.UIAxes_PO2, 'PO2')
            xlabel(app.UIAxes_PO2, 'X')
            ylabel(app.UIAxes_PO2, 'Y')
            app.UIAxes_PO2.FontSize = 9;
            app.UIAxes_PO2.XLim = [0 25];
            app.UIAxes_PO2.GridColor = [0.15 0.15 0.15];
            app.UIAxes_PO2.GridAlpha = 0.15;
            app.UIAxes_PO2.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_PO2.MinorGridAlpha = 0.25;
            app.UIAxes_PO2.Box = 'on';
            app.UIAxes_PO2.XColor = [0.15 0.15 0.15];
            app.UIAxes_PO2.YColor = [0.15 0.15 0.15];
            app.UIAxes_PO2.ZColor = [0.15 0.15 0.15];
            app.UIAxes_PO2.XGrid = 'on';
            app.UIAxes_PO2.Layout.Row = 2;
            app.UIAxes_PO2.Layout.Column = 3;

            % Create UIAxes_O1
            app.UIAxes_O1 = uiaxes(app.GridLayout3);
            title(app.UIAxes_O1, 'O1')
            xlabel(app.UIAxes_O1, 'X')
            ylabel(app.UIAxes_O1, 'Y')
            app.UIAxes_O1.FontSize = 9;
            app.UIAxes_O1.XLim = [0 25];
            app.UIAxes_O1.GridColor = [0.15 0.15 0.15];
            app.UIAxes_O1.GridAlpha = 0.15;
            app.UIAxes_O1.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_O1.MinorGridAlpha = 0.25;
            app.UIAxes_O1.Box = 'on';
            app.UIAxes_O1.XColor = [0.15 0.15 0.15];
            app.UIAxes_O1.YColor = [0.15 0.15 0.15];
            app.UIAxes_O1.ZColor = [0.15 0.15 0.15];
            app.UIAxes_O1.XGrid = 'on';
            app.UIAxes_O1.Layout.Row = 3;
            app.UIAxes_O1.Layout.Column = 1;

            % Create UIAxes_Oz
            app.UIAxes_Oz = uiaxes(app.GridLayout3);
            title(app.UIAxes_Oz, 'Oz')
            xlabel(app.UIAxes_Oz, 'X')
            ylabel(app.UIAxes_Oz, 'Y')
            app.UIAxes_Oz.FontSize = 9;
            app.UIAxes_Oz.XLim = [0 25];
            app.UIAxes_Oz.GridColor = [0.15 0.15 0.15];
            app.UIAxes_Oz.GridAlpha = 0.15;
            app.UIAxes_Oz.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_Oz.MinorGridAlpha = 0.25;
            app.UIAxes_Oz.Box = 'on';
            app.UIAxes_Oz.XColor = [0.15 0.15 0.15];
            app.UIAxes_Oz.YColor = [0.15 0.15 0.15];
            app.UIAxes_Oz.ZColor = [0.15 0.15 0.15];
            app.UIAxes_Oz.XGrid = 'on';
            app.UIAxes_Oz.Layout.Row = 3;
            app.UIAxes_Oz.Layout.Column = 2;

            % Create UIAxes_O2
            app.UIAxes_O2 = uiaxes(app.GridLayout3);
            title(app.UIAxes_O2, 'O2')
            xlabel(app.UIAxes_O2, 'X')
            ylabel(app.UIAxes_O2, 'Y')
            app.UIAxes_O2.FontSize = 9;
            app.UIAxes_O2.XLim = [0 25];
            app.UIAxes_O2.GridColor = [0.15 0.15 0.15];
            app.UIAxes_O2.GridAlpha = 0.15;
            app.UIAxes_O2.MinorGridColor = [0.1 0.1 0.1];
            app.UIAxes_O2.MinorGridAlpha = 0.25;
            app.UIAxes_O2.Box = 'on';
            app.UIAxes_O2.XColor = [0.15 0.15 0.15];
            app.UIAxes_O2.YColor = [0.15 0.15 0.15];
            app.UIAxes_O2.ZColor = [0.15 0.15 0.15];
            app.UIAxes_O2.XGrid = 'on';
            app.UIAxes_O2.Layout.Row = 3;
            app.UIAxes_O2.Layout.Column = 3;

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create PlotControlPanel
            app.PlotControlPanel = uipanel(app.RightPanel);
            app.PlotControlPanel.Title = 'Plot Control';
            app.PlotControlPanel.Position = [39 47 609 129];

            % Create FrequencyHzSliderLabel
            app.FrequencyHzSliderLabel = uilabel(app.PlotControlPanel);
            app.FrequencyHzSliderLabel.HorizontalAlignment = 'right';
            app.FrequencyHzSliderLabel.Position = [23 71 88 22];
            app.FrequencyHzSliderLabel.Text = 'Frequency (Hz)';

            % Create FrequencyHzSlider
            app.FrequencyHzSlider = uislider(app.PlotControlPanel);
            app.FrequencyHzSlider.ValueChangedFcn = createCallbackFcn(app, @FrequencyHzSliderValueChanged, true);
            app.FrequencyHzSlider.ValueChangingFcn = createCallbackFcn(app, @FrequencyHzSliderValueChanging, true);
            app.FrequencyHzSlider.Position = [132 80 150 3];
            app.FrequencyHzSlider.Value = 25;

            % Create Label
            app.Label = uilabel(app.PlotControlPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [326 70 25 22];
            app.Label.Text = '';

            % Create EditFieldFrequencyHzSlider
            app.EditFieldFrequencyHzSlider = uieditfield(app.PlotControlPanel, 'numeric');
            app.EditFieldFrequencyHzSlider.ValueChangedFcn = createCallbackFcn(app, @EditFieldFrequencyHzSliderValueChanged, true);
            app.EditFieldFrequencyHzSlider.Position = [366 70 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = EEGAnalyzer_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end