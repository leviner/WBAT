%EK80rawCW_to_EK60raw_Seward_1.m
% this script designed to correct for temporary WBAT error. described
% below
%
%The WBAT uses “Fast” and “Slow” for the slope in the RAW files, whereas EK80 uses a number. We will correct this in the next release of WBAT software (probably towards the end of April). For the files already recorded you’ll have to find a workaround. If the slope is “Slow” the correct number is 0.50. 
% If the slope is “Fast” the number is 2 divided with the frequency divided by the pulse length. (Frequency in Hz and pulse length in seconds.)
%
% this script should only be used as a workaround for data files
% ping_capture.ko and ping_storage files you released January 11, 2016. and ( and firmware dated 2015-12-08 loaded with the new mission planner software) 

% step 1
% generate EK60 format raw files from EK80 files using this function and
% save data.  then you can run this code
% EK80rawCW_to_EK60raw
%
% this is a modification of  EK80rawCW_to_EK60raw_1.m
%
% only change is that
% I check to see if par.trasciever.slope is empty if so
% set to value in par.trasciever.slope in EK80_data_reading_for_batch_force_slope_to_be_numerical.m
% this value should not matter for a CW pulse (i.e. value of 0 and 2.9e-8
% give the same value).

% modified for Seward processing -- ADR 5/13/15
%1 I force the correct slope to the data (was 0 in the file)
%2 I drop all the pings with less than the expected number of samples. -
%par.num_valid_samples  - consequences of this need verifying.
% Also added threshold for removal of bad pings by checking for weak
% ringdown.  Tend to occur at start of raw file.



% add the paths I need to make this run
addpath('..\WBAT_Processing_Scripts\Recovery_to_Echoview\EchoviewProcessing\lib\echolab')
addpath('..\WBAT_Processing_Scripts\Recovery_to_Echoview\EchoviewProcessing\lib\readEK80')
addpath('..\WBAT_Processing_Scripts\Recovery_to_Echoview\EchoviewProcessing\lib')

h = warndlg('Please make sure 1) MATLABs clock is in UTC  2)par.transceiver_slope  3)par.FPGA_correction are correct');
waitfor(h)
clear all

% user changes the following paramters
par.cdir = pwd;
par.output_dir = uigetdir(par.cdir,'Select Ouput Directory');
par.rawWriteNamePrefix = '\WBAT1_inner_Mooring_EK60-'; %  % for the inner mooring '\WBAT1_inner_Mooring_EK60-'
par.rawWriteName=[par.output_dir par.rawWriteNamePrefix]; % raw file to write out
par.min_xmit_pulse = -60; % Threshold to remove bac pings at beginning of file.  If maximum in first 10 is not above this, skip ping.  Good pings are ~ -10

%% Define Parameters
% Do not edit these - they are inteneded to provide values needed for the header
% changing them may break echolab
par.SurveyName = char(zeros(1,128));
par.TransectName= char(zeros(1,128));
par.SounderName= char(zeros(1,128));
par.BeamType = 1; %Split beam
par.PulseLengthTable = [0.000128;0.000256;0.000512;0.001024;0.002048];
par.GainTable = [18;18;18;18;18];
par.SaCorrectionTable = [0;0;0;0;0];
par.TransducerMode = 3;
par.AngleOffsetAthwart = 0;
par.AngleOffsetAlong = 0;
par.Heading = 0;
par.TransmitMode = 0;
par.Lat = 0;
par.Lon = 0;
par.Segment = 1;

% paramters for firmware
%
% #1 slope correction as slope not numerical in some firmware.
%if this paramter is not zero, then the
%fast is %The WBAT uses “Fast” and “Slow” for the slope in the RAW files, whereas EK80 uses a number. We will correct this in the next release of WBAT software (probably towards the end of April). For the files already recorded you’ll have to find a workaround. If the slope is “Slow” the correct number is 0.50. 
% If the slope is “Fast” the number is 2 divided with the frequency divided by the pulse length. (Frequency in Hz and pulse length in seconds.)
% 2/(70000/0.001024); % trasciever slope for 1ms pulse and fast taper. 
% slow is 0.5
% previously had a slope of zero in WBAT
%
% set to [] if want to use what is in file
par.transceiver_slope= 2/(70000/0.001024)% Force slope to match expected value as per Simrad communication for 'fast and 1 ms pulse is  2/(70000/0.001024);
%
% FPGA filter correctiion for data with firmware prior to January 11, 2016
% (Last time this should be used is ressurection bay data)
%
par.FPGA_correction=1 % 1 to turn on MPScaling (for correction of filter), 0 to keep scaling off

par.num_valid_samples=3565  % number  of valid samples in a ping (i.e. remove ping with fewer samples  check procdata.sv in 
% FOR CAL, num smaples = 3198


%%
load rawHeader.mat
rawHeader.transceivercount = 1;

[fnames,fpath,FilterIndex] = uigetfile('*.raw','Select EK80 raw files','MultiSelect','on');

if iscell(fnames)
    nfiles = length(fnames);
else
    nfiles = 1;
end
transceiverno = 1;

for nf = 1:nfiles
    if nfiles ==1
    fname =  fnames;
    else
    fname = fnames{nf};
    end
npingsmax = 1e6;
totalpingno = 1;

disp(['Processing file no: ' int2str(nf) ' of ' int2str(nfiles) ' files.']);


%% Load in EK80 Data
EK80_data_reading_for_batch
%%
% Create Header

 Ek80header.surveyname = par.SurveyName;% char(blanks((128 - length(par.SurveyName))))];
 Ek80header.transectname = par.TransectName;% char(blanks((128 - length(par.TransectName))))];
 Ek80header.soundername = par.SounderName; %char(blanks((128 - length(par.SounderName))))];
 Ek80header.spare = char(zeros(1,128));
 Ek80header.transceivercount = transceiverno;
 Ek80header.time = results(1).procdata.sampledata.time;
 
 % Create Data.config
%  Ek80data.config.channelid = char(zeros(1,128));
%  Ek80data.config.channelid(1:7) = char('ES70-7C'); % Channel ID
 Ek80data.config.channelid =configdata.transceivers.channels.ChannelId;
 Ek80data.config.beamtype = par.BeamType; % beamtype
 Ek80data.config.frequency = configdata.transceivers.channels.transducer.Frequency; % frequency
 Ek80data.config.gain = configdata.transceivers.channels.transducer.Gain(1);
 Ek80data.config.equivalentbeamangle = configdata.transceivers.channels.transducer.EquivalentBeamAngle;
 Ek80data.config.beamwidthalongship = configdata.transceivers.channels.transducer.BeamWidthAlongship;
 Ek80data.config.beamwidthathwartship = configdata.transceivers.channels.transducer.BeamWidthAthwartship;
 Ek80data.config.anglesensitivityalongship = configdata.transceivers.channels.transducer.AngleSensitivityAlongship;
 Ek80data.config.anglesensitivityathwartship = configdata.transceivers.channels.transducer.AngleSensitivityAthwartship;
 Ek80data.config.anglesoffsetalongship = par.AngleOffsetAlong; % UNKNOWN
 Ek80data.config.angleoffsetathwartship = par.AngleOffsetAthwart; % UNKNOWN
 Ek80data.config.posx = 0;
 Ek80data.config.posy = 0;
 Ek80data.config.posz = 0;
 Ek80data.config.dirx = 0;
 Ek80data.config.diry = 0;
 Ek80data.config.dirz = 0;
 Ek80data.config.pulselengthtable = par.PulseLengthTable;
 Ek80data.config.spare2 = char(zeros(1,8));
 Ek80data.config.gaintable = par.GainTable;
 Ek80data.config.spare3= char(zeros(1,8));
 Ek80data.config.sacorrectiontable = par.SaCorrectionTable;
 Ek80data.config.spare4= char(zeros(1,52));
 
j=1;
for i = 1:npings
    if (length(results(i).procdata.sp) == par.num_valid_samples) & (max(results(i).procdata.sv(1:10)) > par.min_xmit_pulse);  % only keep the pings with the valid samples and have a strong ringdown
        % Create Data.gps
        Ek80data.gps.time(j,1) = results(i).procdata.sampledata.time;
        Ek80data.gps.lat(j,1) = par.Lat;
        Ek80data.gps.lon(j,1) = par.Lon;
        Ek80data.gps.seg(j,1) = par.Segment;
        
        % Create Data.pings
        
        Ek80data.pings.number(1,j) =  uint32(j);
        Ek80data.pings.time(1,j) = results(i).procdata.sampledata.time;
        Ek80data.pings.mode(1,j) = int8(par.TransducerMode);
        Ek80data.pings.transmitmode(1,j) = int16(par.TransmitMode);
        Ek80data.pings.transducerdepth(1,j) = single(envdata.depth);
        Ek80data.pings.frequency(1,j) = single(configdata.transceivers.channels.transducer.Frequency);
        Ek80data.pings.pulselength(1,j) = single(results(i).procdata.transceiver.pulselength);
        Ek80data.pings.bandwidth(1,j) = single(results(i).procdata.transceiver.bw);
        Ek80data.pings.sampleinterval(1,j) =  single(results(i).procdata.transceiver.sampleinterval);
        Ek80data.pings.soundvelocity(1,j) =  single(results(i).procdata.transceiver.soundspeed);
        Ek80data.pings.absorptioncoefficient(1,j) = single(absorp);
        Ek80data.pings.offset(1,j) = int32(results(i).procdata.sampledata.offset);
        Ek80data.pings.count(1,j) = int32(results(i).procdata.sampledata.count);
        Ek80data.pings.seg(1,j) = int16(par.Segment);
        Ek80data.pings.Sv(:,j) = single(results(i).procdata.sv);
        Ek80data.pings.Sp(:,j) = single(results(i).procdata.sp);
        Ek80data.pings.alongship(:,j) = single(results(i).procdata.phialong);
        Ek80data.pings.athwartship(:,j) = single(results(i).procdata.phiathw);
        Ek80data.pings.transmitpower(1,j) = single(results(i).procdata.transceiver.txpower);
        Ek80data.pings.heading(1,j) = single(par.Heading);
            
        if j==1 % add these from first valid ping
            Ek80data.pings.samplerange = uint16([1, results(i).procdata.sampledata.count]);
            Ek80data.pings.range = double(results(i).procdata.r);
        end
        j=j+1;
        
    end
    
end



 
 %% Convert to EK60
 calParms = readEKRaw_GetCalParms(Ek80header,Ek80data);
 Ek80data = readEKRaw_Sp2Power(Ek80data, calParms, 'tvgCorrection', 'False'); % switch sv to sp, no range correction applied
 Ek80data = readEKRaw_ConvertAngles(Ek80data, calParms, 'ToElec');
 
 writeEKRaw([par.rawWriteName fname], rawHeader, Ek80data);
 disp(['Finished writing file: ' fname]);

 clearvars -except par fname fnames nf fnames fpath FilterIndex transceiverno nfiles rawHeader  
end

disp('All files written to:' )
disp(par.output_dir)

 
 %[rawHeader, Ek80data] = readEKRaw('C:\EkRaw\DY1407-D20140614-T000512.raw','Frequency',70000);