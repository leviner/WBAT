%---------------------------------------------------------
%--------------WBAT EV File Creation----------------------
%---------------------------------------------------------
%
% This file requires the parameters at the top to be set by the user.  EV
% files will be created, data will be added to the fileset in sets defined
% by par.max_num_wakeups, and a template will be used.  The file can then
% be scrutinized by the user before it is saved, closed and the next one is
% started.
%
%% Set the Mooring Specific Parameters:

par.mooring_no = 2;
par.scrutinizing = 0 ;% 1 to hold exporting to allow user to look through EV file, 0 if no.

par.max_num_wakeups = 84; % How many raw files to put into a single EvFile?

if par.mooring_no == 1;
    par.mooring_dir = 'E:\WBAT\Seward_2016\EK60_format\WBAT_1_inner_mooring';
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_InnerMooring_WBAT1_Final.ecs'; % mooring 1 ecs file goes here
    par.EV_dir_out = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring'
    par.EVTemplate = 'WBAT1_InnerMooring_Resurrection2016_Template.EV'; % EV template to be used goes here
elseif par.mooring_no == 2;
    par.mooring_dir = 'E:\WBAT\Seward_2016\EK60_format\WBAT_2_outer_mooring';% Mooring 2 converted file directoy goes here
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_OuterMooring_WBAT2_Final.ecs'; % mooring 2 ecs file goes here
    par.EV_dir_out = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring'
    par.EVTemplate = 'WBAT2_OuterMooring_Resurrection2016_Template.EV'; % EV template to be used goes here
end

%% Set up the files in Echoview
filelist = dir([par.mooring_dir '\*.raw']); % get all the raw files
for i = 1:length(filelist);
    filenames{i,1} = filelist(i).name;
end

for i = 1:length(filenames)
    name = filenames{i};
    seq(i,1) = str2num(name(end-9:end-6));
    phase(i,1) = str2num(name(end-14));
end
index = unique([phase seq],'rows');
par.num_EV_files = ceil(size(index, 1)/par.max_num_wakeups) ;% determine how many EV files to make

% Start the loop...
EvApp = actxserver('EchoviewCom.EvApplication');  % Open Echoview
EvApp.Minimize;
for j = 1:par.num_EV_files
    EvFile = EvApp.NewFile(par.EVTemplate ); % New File and Name, should be able to open template here as well?  Does not appear to take template
    EvFileSet = EvFile.FileSets.FindByName('Fileset1'); % Pick a fileset
    EvFileSet.SetCalibrationFile(par.mooring_cal);
    display(['Creating EV File #' num2str(j) '...'])
    display('Adding .raw files:')
    
    
    
        for i = 1:par.max_num_wakeups % Add files to fileset
            if i+(par.max_num_wakeups*(j-1)) > length(index)
                break
            end
            files_to_add = find((phase == index(i+(par.max_num_wakeups*(j-1)),1) & (seq == index(i+(par.max_num_wakeups*(j-1)),2))));
            for f = 1:length(files_to_add)
                EvFileSet.DataFiles.Add([par.mooring_dir '\' filenames{files_to_add(f)}]);
                display(filenames{files_to_add(f)})  %% FIGURE THIS OUT TO CONTAIN WHOLE FILE
            end
        end
    
    
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
    
    
    if exist([par.EV_dir_out '\LoadedData']) == 0;
        mkdir([par.EV_dir_out '\LoadedData']);
    else
    end
    
    start_p = num2str(index(1+(par.max_num_wakeups*(j-1)),1));
    start_s = num2str(index(1+(par.max_num_wakeups*(j-1)),2));
    
    if j == par.num_EV_files
        end_p = num2str(index(end,1));
        end_s = num2str(index(end,2));
    else
        end_p = num2str(index((par.max_num_wakeups*(j)),1));
        end_s = num2str(index((par.max_num_wakeups*(j)),2));
    end
    
    if length(start_s) < 4
        for k = 1:4-length(start_s)
            start_s = ['0' start_s];
        end
    end
    if length(end_s) < 4
        for k = 1:4-length(end_s)
            end_s = ['0' end_s];
        end
    end
    
        EvLineSource = EvFile.Lines.FindByName('Surface Line Pick');
        EvNewLine = EvFile.Lines.CreateOffsetLinear(EvLineSource, 1, -5, 1);
        EvLine = EvFile.Lines.FindByName('Surface_exclusion_line');
        EvLine.OverwriteWith(EvNewLine);
        EvFile.SaveAs([par.EV_dir_out '\LoadedData\WBAT' num2str(par.mooring_no) '-LoadedData-' start_p '-' start_s '-' end_p '-' end_s '.EV']);
        EvFile.Close;
        display('File Saved')
    clear EvF* EvN*
end
EvApp.Quit;

%%  Assorted Notes

% I assume the template itself will have line depths fixed (template for
% each mooring).
%     EvNewLine1 = EvFile.Lines.CreateFixedDepth(par.surface_exclusion_line_depth);
%     EvNewLine2.Name = 'surface line';
%     EvNewLine2 = EvFile.Lines.CreateFixedDepth(par.bottom_exclusion_line_depth);
%     EvNewLine2.Name = 'Fixed bottom';

% I assume the template itself will have line depths fixed (template for
% each mooring).
%     EvNewLine1 = EvFile.Lines.CreateOffsetLinear('',-5);
%     EvNewLine1.Name = 'surface_exclusion_line';
%     EvNewLine2 = EvFile.Lines.CreateFixedDepth(par.bottom_exclusion_line_depth);
%     EvNewLine2.Name = 'Fixed bottom';



%     Creating an Offset Line
%     EvSourceLine = EvFile.Lines.FindByName(par.surface_line_pick);
%     EvNewLine1 = EvFile.Lines.CreateOffsetLinear(EvSourceLine,1,-5,1);
%     EvNewLine1.Name = 'holdingLine';
%     EvLineOld = EvFile.Lines.FindByName(par.exclude_below_line_name);
%     EvLineOld.OverwriteWith(EvNewLine1)



