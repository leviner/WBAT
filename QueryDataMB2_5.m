
addpath 'G:\\Robert\\WBAT\\database'
par.dbName='AFSC-64'; % name of database ODBC link - robert needs this to be 'AFSC-64'
par.dbUser = 'macebase2';
par.dbPass = 'pollock';
db = dbOpen(par.dbName,par.dbUser, par.dbPass,'provider','ODBC');

% All of the datasets, with the corresponding survey and ship
survey = [201502 201502];
ship = [881 882];
dataset = [1 1];
data_all = [];

for set = 2%1:length(survey) % For every dataset defined above...
    sql = ['select y.survey, y.ship, y.data_set_id, x.start_time, x.end_time,',...
        ' x.start_latitude, x.start_longitude, x.end_latitude, x.end_longitude,',...
        ' w.transect,y.interval, y.layer,  x.mean_bottom_depth, z.range_from_reference_upper, ',...
        ' z.range_from_reference_lower,y.class, y.prc_nasc',...
        ' from (select survey, ship, data_set_id, interval, start_time, end_time, start_latitude, ',...
        ' start_longitude, end_latitude, end_longitude, mean_bottom_depth from intervals) x',...
        ' join',...
        ' (select survey, ship, data_set_id, interval, layer, class, prc_nasc from integration_results) y',...
        ' on ((y.interval = x.interval) and (y.survey = x.survey) and (y.ship = x.ship) and (y.data_set_id = x.data_set_id))',...
        ' join',...
        ' (select survey, ship, data_set_id, layer, range_from_reference_upper, range_from_reference_lower from Layers) z',...
        ' on  ((z.layer = y.layer) and (z.survey = y.survey) and (z.ship = y.ship) and (z.data_set_id = y.data_set_id))',...
        ' join',...
        ' (select ship, survey, data_set_id, transect, start_time, end_time from transect_bounds) w ',...
        ' on ((x.start_time >= w.start_time) and (x.end_time <= w.end_time) ',...
        ' and (w.survey = x.survey) and (w.ship = x.ship) and (w.data_set_id = x.data_set_id)) ',...
        ' where( x.survey = ' num2str(survey(set)) ') and (x.ship = ' num2str(ship(set)) ') ',...
        ' and (x.data_set_id = ' num2str(dataset(set)) ') ',...
        ' order by y.ship ASC, y.survey ASC, w.transect ASC, y.interval ASC, y.layer ASC'];
    
    data= dbQuery(db, sql, 'outtype', 'struct', 'timeout', 1500);
    eval(['data_' num2str(ship(set)) '_' num2str(survey(set)) ' = data;'])
    
    
    for i = 1:length(data.class)
        if strcmp(data.class{i},'PK1') == 1
            data.class_i(i,1) = 1;
        elseif strcmp(data.class{i},'Ringdown') == 1
            data.class_i(i,1) = 3;
        elseif strcmp(data.class{i},'Surface_Integration') == 1
            data.class_i(i,1) = 4;
        elseif strcmp(data.class{i},'Unid') == 1
            data.class_i(i,1) = 2;
        end
    end
    
    
    data.start_time_datetime = datetime(data.start_time,'Format','MM/dd/uuuu hh:mm:ss aa');
    data.end_time_datetime = datetime(data.end_time,'Format','MM/dd/uuuu hh:mm:ss aa');
    for i = 1:length(data.start_time_datetime)
        cur_time = datevec(data.start_time_datetime(i));
        cur_time(5:6) = 0;
        data.start_hour(i,1) = datenum(cur_time);
    end
    
    classes = unique(data.class_i);
    class_names = {'Pollock','Unid Mix','Ringdown','Surface Integration'}
    intervals = unique(data.interval);
    figure(set)
    for j = 1:length(classes)
        nasc = [];
        for i = 1:length(intervals)
            cur_int = find((data.interval == intervals(i)) & (data.class_i == j));
            cur_int_date = data.start_time_datetime(find((data.interval == intervals(i))));
            if isempty(cur_int)
                nasc(i,1) = nan;
                dtime(i,1) = cur_int_date(1);
            else
                nasc(i,1) = sum(data.prc_nasc(cur_int));
                dtime(i,1) = cur_int_date(1);
            end
        end
        subplot(2,2,j)
        plot(dtime,nasc)
        title(class_names{j})
    end
end
