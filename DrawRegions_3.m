par.mooring_no = 2;
par.scrutinizing = 0 ;% 1 to hold exporting to allow user to look through EV file, 0 if no.
par.variable_for_export = '70 kHz for export';

if par.mooring_no == 1;
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_InnerMooring_WBAT1_Final.ecs'; % mooring 1 ecs file goes here
    par.EV_dir_in = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring\LoadedData';
    par.EV_dir_out = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring\ForIntegration';
    [~,~,par.MixList] = xlsread('G:\ResurrectionBay_2015-2016\EVFiles\EVMixRecord.csv','A2:B45');
elseif par.mooring_no == 2;
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_OuterMooring_WBAT2_Final.ecs'; % mooring 2 ecs file goes here
    par.EV_dir_in = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring\LoadedData';
    par.EV_dir_out = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring\ForIntegration';
    [~,~,par.MixList] = xlsread('G:\ResurrectionBay_2015-2016\EVFiles\EVMixRecord.csv','D2:E45');
end
display(par)
%  The following is the expected naming convention for the variables and
%  lines that are used to create the regions:
%
%  LINES
%  'XducerFace': Line fixed at a depth of 0
%  '2m_from_xducer': Work line for the front of the xducer containing
%     ringown and noise in front of the xducer
%  'work_line': work line used to seperate mix region from pollock, if mif
%     exists
%  'Surface_exclusion_line': 5m above the bottom and drawn to clean up
%  'Above_surface_line': fixed line for looking at surface integration
%
%  CLASSES
%  'Unid': Used for the mix layer and other unidentified stuff
%  'PK1': Pollock (assumed)
%  'Ringdown': area between xducer face and 2m_from_xducer line to check
%     strength of ringdown over time
%  'Surface_Integration': area between Surface_exclusion_line and
%     Above_surface_line to look at strength of surface integration over time

%% Set up the files in Echoview
filelist = dir([par.EV_dir_in '\*.EV']); % get all the raw files
for j = 1:length(filelist);
    filenames{j,1} = filelist(j).name;
end

EvApp = actxserver('EchoviewCom.EvApplication');  % Open Echoview
EvApp.Minimize;
for i = 1:length(filenames)
    display(['Drawing regions in file ' filenames{i}])
    % check that the right mix boolean is being used
    if strcmp(filenames{i},par.MixList{i,1}) == 0
        display('ERROR')
        display('Something is off with the order of the filenames and the mix identifier list')
        break
    end
    
    EvFile = EvApp.OpenFile([par.EV_dir_in '\' filenames{i}]);
    EvVar = EvFile.Variables.FindByName(par.variable_for_export);

        % Draw Start marker region
    start_marker = ['ST_' num2str(i) '.' num2str(par.mooring_no)];
    EvUpperLine = EvFile.Lines.FindByName('XducerFace');
    EvLowerLine = EvFile.Lines.FindByName('Above_surface_line');
    Region1 = EvVar.CreateLineRelativeRegion(start_marker,EvUpperLine,EvLowerLine,0,1);
    RegClassObj = EvFile.RegionClasses.FindByName('Unclassified');
    EvFile.Regions.FindByName(start_marker).RegionClass = RegClassObj;
    EvFile.Regions.FindByName(start_marker).RegionType = 2 ;% 1 is for analysis
    
    % Draw end marker region
    end_marker = ['ET_' num2str(i) '.' num2str(par.mooring_no)];
    EvUpperLine = EvFile.Lines.FindByName('XducerFace');
    EvLowerLine = EvFile.Lines.FindByName('Above_surface_line');
    Region1 = EvVar.CreateLineRelativeRegion(end_marker,EvUpperLine,EvLowerLine,EvVar.MeasurementCount-1,EvVar.MeasurementCount);
    RegClassObj = EvFile.RegionClasses.FindByName('Unclassified');
    EvFile.Regions.FindByName(end_marker).RegionClass = RegClassObj;
    EvFile.Regions.FindByName(end_marker).RegionType = 2 ;% 1 is for analysis
    
    
    % Draw ringdown region
    EvUpperLine = EvFile.Lines.FindByName('XducerFace');
    EvLowerLine = EvFile.Lines.FindByName('2m_from_xducer');
    Region1 = EvVar.CreateLineRelativeRegion('Ringdown',EvUpperLine,EvLowerLine);
    RegClassObj = EvFile.RegionClasses.FindByName('Ringdown');
    EvFile.Regions.FindByName('Ringdown').RegionClass = RegClassObj;
    EvFile.Regions.FindByName('Ringdown').RegionType = 1 ;% 1 is for analysis
    
    % Draw Surface integration
    EvUpperLine = EvFile.Lines.FindByName('Surface_exclusion_line');
    EvLowerLine = EvFile.Lines.FindByName('Above_surface_line');
    Region1 = EvVar.CreateLineRelativeRegion('Surface',EvUpperLine,EvLowerLine);
    RegClassObj = EvFile.RegionClasses.FindByName('Surface_Integration');
    EvFile.Regions.FindByName('Surface').RegionClass = RegClassObj;
    EvFile.Regions.FindByName('Surface').RegionType = 1; % 1 is for anlysis
    
    if par.MixList{i,2} == 1 % SURFACE MIX EXISTS
        % Draw PK1
        EvUpperLine = EvFile.Lines.FindByName('2m_from_xducer');
        EvLowerLine = EvFile.Lines.FindByName('work_line');
        Region1 = EvVar.CreateLineRelativeRegion('Pollock',EvUpperLine,EvLowerLine);
        RegClassObj = EvFile.RegionClasses.FindByName('PK1');
        EvFile.Regions.FindByName('Pollock').RegionClass = RegClassObj;
        EvFile.Regions.FindByName('Pollock').RegionType = 1; % 1 is for analysis
        
        % Draw Unid
        EvUpperLine = EvFile.Lines.FindByName('work_line');
        EvLowerLine = EvFile.Lines.FindByName('Surface_exclusion_line');
        Region1 = EvVar.CreateLineRelativeRegion('Mix',EvUpperLine,EvLowerLine);
        RegClassObj = EvFile.RegionClasses.FindByName('Unid');
        EvFile.Regions.FindByName('Mix').RegionClass = RegClassObj;
        EvFile.Regions.FindByName('Mix').RegionType = 1; % 1 is for analysis
        
    elseif par.MixList{i,2} == 0 % NO SURFACE MIX
        % Draw PK1
        EvUpperLine = EvFile.Lines.FindByName('2m_from_xducer');
        EvLowerLine = EvFile.Lines.FindByName('Surface_exclusion_line');
        Region1 = EvVar.CreateLineRelativeRegion('Pollock',EvUpperLine,EvLowerLine);
        RegClassObj = EvFile.RegionClasses.FindByName('PK1');
        EvFile.Regions.FindByName('Pollock').RegionClass = RegClassObj;
        EvFile.Regions.FindByName('Pollock').RegionType = 1 ;% 1 is for analysis
    end
    
    % Allow scrutinizing if user wants to check regions
    if par.scrutinizing == 1 % Pause to allow for user to scrutinize
        d = dialog('Position',[600 600 400 150],'Name','Echoview Scruitinizing');
        txt = uicontrol('Parent',d,...
            'Style','text',...
            'Position',[20 80 360 40],...
            'String',{'You may now edit the current file in Echoview.','Click "Continue" when finished editting.'},'FontSize',12);
        btn = uicontrol('Parent',d,...
            'Position',[130 20 140 25],...
            'String','Continue',...
            'Callback','delete(gcf)','FontSize',12);
        uiwait(d);
    else
    end
    
    % create output file name and save
    filename_in = filenames{i};
    ld_s = strfind(filename_in,'LoadedData');
    ld_e = ld_s+9;
    filename_out = [filename_in(1:ld_s-1) 'ForIntegration' filename_in(ld_e+1:end)];
    EvFile.SaveAs([par.EV_dir_out '\' filename_out]);
    EvFile.Close;
    display('File Saved')
    clear EvF* EvN*
end
EvApp.Quit;