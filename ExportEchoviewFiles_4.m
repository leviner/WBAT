% This has been edited to be used for exporting the WBAT EV files that are
% produced by the WBAT_Echoview.m script, which opens and allows for
% editing of the files.
%
%This is currenlty set to export by cells.  There is a way to export the
%region by cell (using ExportRegionsByCellsAll)however I have been unable
%to get EvVar.CreateLineRelativeRegion COM method to work for Echoview
%6.1.44.
%
%UPDATE 8.20.15 to include SetExportMacebase function for turning on
%database exporting and all of the necessary export items.
%
% UPDATE 11.24.15 to allow for resetting the loction of the .raw files and
% create a new set of EV files with the correct raw files and ecs file
% using the 'UpdateRawFilePath' function.
%

clear all
clc

% --------------------------------------------------------------------------
% ------------------------ edit these variables ----------------------------
% --------------------------------------------------------------------------
% WHICH MOORING?
par.mooring_no = 2;
%  define the thresholds
par.min_thresh_on = 1;
par.max_thresh_on = 0;
par.minimum_integration_threshold = -70;  %typically -70 dB Sv
par.maximum_integration_threshold = 0;  %an Sv of 0 dB seems reasonable
%  define the grid parameters
par.layer_thickness = 1;% In Meters  %surface-reference layer thickness, typically 10 m,
par.EDSU_length = 60;% In Minutes  %typically 0.5 nmi, currently set to use time (60 minutes)

par.exclude_below_line_name= 'Above_surface_line'; % name of new surface exclusion line to be created as an offset of bottom pick and used for analysis
par.exclude_above_line_name= 'XducerFace'; % name of exclude above line
%sets the variable to export from each file, typically '38 kHz for survey'
par.variable_for_export  ='70 kHz for export';

%%  define the input file path - directory paths must end with a slash

% If you need to redirect the file paths for the fileset, set the following
% to 1.  In order for EchoView to look at the new location for the .raw
% files, it has to be unable to find the original files.  Therefore if
% you're trying to force echoview to look in a different spot, rename a
% folder in the original .raw file tree so that it cannot find what it is
% expecting.
par.UpdateRawFiles = 0;

% Set all of these specific to the moorings.  This version is set up for
% the reprocessing of data from Shelikof Strait in 2015 but can be
% adjusted.
if par.mooring_no == 1;
    par.mooring_dir = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring\ForIntegration\'; % Please include '\' at end of directory
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_InnerMooring_WBAT1_Final.ecs'; % mooring 1 ecs file goes here
    par.export_out_dir = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring\IntegrationExports\';
    ExportFileBase =[par.export_out_dir 'v881-s201502-'];
    EvUpdatedFilePath = ''
    par.RawFilePath = ''
elseif par.mooring_no == 2;
    par.mooring_dir = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring\ForIntegration\';% Mooring 2 converted file directoy goes here, Please include '\' at end of directory
    par.mooring_cal = 'G:\ResurrectionBay_2015-2016\Calibration\ECSFiles\Seward2015_OuterMooring_WBAT2_Final.ecs'; % mooring 2 ecs file goes here
    par.export_out_dir = 'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring\IntegrationExports\';
    ExportFileBase =[par.export_out_dir 'v882-s201502-'];
    EvUpdatedFilePath = ''
    par.RawFilePath = ''
end

EVFilePath = [par.mooring_dir];

%set .ecs file (calibration file) to use.
ECSfilename = par.mooring_cal;

%typically it's Fileset 1 in our survey templates
Filesetname = 'Fileset1';


%%  start the show...
disp('Echoview export script is running')

%make a list of the EV files in the above directory
files = dir([EVFilePath '*.EV']);
display(['Found ' num2str(size(files,1)) ' EV Files'])

% loop -- select each file, open file, find variable to export
for i = 1:size(files,1);
    display(['Exporting ' files(i).name])
    
    EvFilename = [EVFilePath files(i).name];
    if par.UpdateRawFiles == 1;  % Update the raw file locations and save a copy of updated EV file in new filepath specified above
        EvUpdatedFile = [EvUpdatedFilePath files(i).name];
        UpdateRawFilePath(EvFilename, EvUpdatedFile, par.RawFilePath);
        EvFilename = EvUpdatedFile  
    end
    %  create the EV COM object "EvApp"
    EvApp = actxserver('EchoviewCom.EvApplication');
    %  minimize it...
    EvApp.Minimize;
    
    % most settings already made in EV files.  Make sure of the following:
    %open file and select the variable for export
    EvFile = EvApp.OpenFile(EvFilename);
    EvVar =  EvFile.Variables.FindByName(par.variable_for_export);
    
    %force pre-read of data files using a method
    EvFile.PreReadDataFiles;
    
    %find the fileset and set the .ecs file (calibration file) to use for it
    Evfileset = EvFile.Filesets.FindByName(Filesetname);
    calfiletest = Evfileset.SetCalibrationFile(ECSfilename);
    %  check to see if .ecs file change was successful
    if calfiletest~=1
        disp(['FATAL: Failed to read the .ecs file: ' ECSfilename]);
        disp('We are out of here!');
        break;
    end
    
    %  set thresholds
    EvVar.Properties.Data.ApplyMinimumThreshold= par.min_thresh_on;
    EvVar.Properties.Data.MinimumThreshold= par.minimum_integration_threshold;
    EvVar.Properties.Data.ApplyMaximumThreshold= par.max_thresh_on;
    EvVar.Properties.Data.MaximumThreshold= par.maximum_integration_threshold;
    
    
    %  set grid settings for range in m and distance in nmi as defined by VL
    EvVar.Properties.Grid.SetDepthRangeGrid(1,par.layer_thickness);
    EvVar.Properties.Grid.SetTimeDistanceGrid(1, par.EDSU_length);%(3,EDSU_length); % 1 is for time, 3 is for nmi
    
    %  set exclusion lines
    EvVar.Properties.Analysis.ExcludeAboveLine = par.exclude_above_line_name;
    EvVar.Properties.Analysis.ExcludeBelowLine = par.exclude_below_line_name;
    %EvFile.RegionClass.Add(par.region_name)
    EvVar = EvFile.Variables.FindByName(par.variable_for_export);
    
    %  export the regions logfile
    ExportFileName = [ExportFileBase, files(i).name(end-15:end-3),' (regions).csv'];
    exporttest = EvVar.ExportRegionsLogAll(ExportFileName);
    %  check to see if export was successful, if not, print error message to screen
    if exporttest~=1
        disp(['The system has failed - unable to regions logbook ' ExportFileName]);
    end
    %  assemble filename and do the export
    SetExportMacebase2(EvFile)
    ExportFileName = [ExportFileBase, files(i).name(end-15:end-3),'-','z0.csv']; % added trailing '-' as required by macebase classic
    exporttest = EvVar.ExportIntegrationByRegionsByCellsAll(ExportFileName);
    
    %  check to see if export was successful, if not, print error message to screen
    if exporttest~=1
        disp(['The system has failed - unable to export ' ExportFileName]);
    end
    
    EvFile.SaveAs(EvFilename);
    %close the EV file and move on to next file
    EvApp.CloseFile(EvFile);
    
    %close application
    EvApp.Quit;
    
end

disp('All done!')


