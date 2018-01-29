% Use this to create master structure of all of the fish targets from the
% .csv exports

addpath FishTrackingFunc

mooring = 1\2;
nv = 0;

if mooring == 1
    path =  'G:\ResurrectionBay_2015-2016\EVFiles\WBAT1_InnerMooring\FishTracks\Exports'
elseif mooring == 2
    path =  'G:\ResurrectionBay_2015-2016\EVFiles\WBAT2_OuterMooring\FishTracks\Exports'
end

if nv == 0
    ad = dir([path '\*FishTracks-*(cells)*'])
elseif nv ==1
    ad = dir([path '\*FishTracksNv-*(cells)*'])
end

h = waitbar(0,'Initializing waitbar...');
for j = 1:length(ad)
    cur_cells = ad(j).name;
    [struct] = import_fishtrack_cells2struct([path '\' cur_cells]);
    struct.file = nan(size(struct.Interval));
    struct.file(:) = j;
    numtargets(j) = length(struct.Region_ID);
    if j == 1
        Targets = struct;
    else
        Targets = concat_struct(Targets,struct);
    end
    waitbar((j/length(ad)),h,'Loading Cells...');
end

if nv == 0
    int = dir([path '\*FishTracks-*(intervals)*'])
elseif nv ==1
    int = dir([path '\*FishTracksNv-*(intervals)*'])
end

for j = 1:length(int)
    cur_intervals = int(j).name;
        [struct] = import_fishtrack_intervals2struct([path '\' cur_intervals]);
        time = datevec(struct.Time_S);
        time = [0 0 0 time(4) 0 0];
        Intervals(j,1) = struct.Interval;
        Intervals(j,2) = datenum(struct.Date_S)+datenum(time);
        waitbar((j/length(ad)),h,'Loading Intervals...');
end

Targets.start_hour = nan(size(Targets.Interval));
for i = 1:length(Targets.Interval)
    Targets.start_hour(i) = Intervals(find(Intervals(:,1) == Targets.Interval(i)),2);
end
plot(unique(Targets.start_hour))


% %%
% if mooring == 1
%     load  G:\Moored_Echosounders\Analysis\Shelikof_2015_Analysis\Analysis_Input_Data\Mooring_Data\Mooring1_Data_Zones.mat
%     data = data_881_201501_zones;
% elseif mooring == 2
%     load  G:\Moored_Echosounders\Analysis\Shelikof_2015_Analysis\Analysis_Input_Data\Mooring_Data\Mooring2_Data_Zones.mat
%     data = data_882_201501_zones;
% elseif mooring == 3
%     load  G:\Moored_Echosounders\Analysis\Shelikof_2015_Analysis\Analysis_Input_Data\Mooring_Data\Mooring3_Data_Zones.mat
%     data = data_883_201501_zones;
% end
% 
% WBAT3_Targets = Targets;
% WBAT3_Targets.zone = nan(size(WBAT3_Targets.Target_range_mean));
% for i = 1:length(WBAT3_Targets.Target_range_mean)
%     
%     if floor(WBAT3_Targets.Target_range_mean(i)) < 2
%         WBAT3_Targets.zone(i) = 3;
%     else
%         a = find((floor(WBAT3_Targets.Target_range_mean(i)) == data.range_from_reference_upper) & (WBAT3_Targets.start_hour(i) == data.start_hour));
%         if isempty(a);
%             WBAT3_Targets.zone(i) = nan;
%         else
%             WBAT3_Targets.zone(i) = data.zone(a);
%         end
%     end
%     waitbar((i/length(WBAT3_Targets.Target_range_mean)),h,'Assigning Zone...');
%     
% end
% close(h)
% %%
% WBAT3_Targets.Target_range_mean(find(WBAT3_Targets.Target_range_mean == -9999)) = nan;
% data = WBAT3_Targets;
% 
% z1 = find(data.zone == 1);
% z2 = find(data.zone == 2);
% z3 = find(data.zone == 3);
% 
% plot(data.start_hour(z1),data.Target_range_mean(z1),'.b')
% hold on
% plot(data.start_hour(z2),data.Target_range_mean(z2),'.g')
% plot(data.start_hour(z3),data.Target_range_mean(z3),'.r')
% set(gcf, 'Position',[1 1 1100 800])
% %%
% if Nv == 0
%     save G:\Moored_Echosounders\Analysis\Shelikof_2015_Analysis\Analysis_Input_Data\Fish_Track_Data\WBAT3_FishTracks  WBAT3_Targets
% elseif Nv == 1
%     save G:\Moored_Echosounders\Analysis\Shelikof_2015_Analysis\Analysis_Input_Data\Fish_Track_Data\WBAT3_FishTracksNv  WBAT3_Targets
% end
