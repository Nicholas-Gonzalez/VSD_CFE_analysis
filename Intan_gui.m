function Intan_gui


f = figure('Position',[100 50 1300 900]);

it = axes('Units','pixels','Position',[0 0 f.Position(3) f.Position(4)],...
          'Visible','on','XLim',[0 f.Position(3)],'YLim',[0 f.Position(4)],...
          'XGrid','off','YGrid','off','Tag','grid','HitTest','off','YTick',[],'XTick',[]);
it.Toolbar.Visible = 'off';


appfile = fullfile(fileparts(which('Intan_gui.m')),'Intan_gui_appdata.txt');
if exist(appfile,'file')
    fid = fopen(appfile);
    str = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    str = string(str{1});
    recent = struct('file',string(strsplit(str{1}(1:end-1),' '))',...
                    'path',string(strsplit(str{2}(1:end-1),' '))');
else
    recent = struct('file',strings(0,1),'path',strings(0,1));
end


m = uimenu('Text','Intan');
mi(1) = uimenu(m,'Text','Open','Callback',@loadRHS);
mi(2) = uimenu(m,'Text','Open Recent');
for r=1:length(recent.file)
    rm(r) = uimenu(mi(2),'Text',recent.file{r},'Callback',@loadRHS);
end
if isempty(recent.file)
    rm = [];
end
mi(3) = uimenu(m,'Text','Save','Callback',@saveit,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');

guidata(gcf,struct('show',[],'hide',[],'info',[],'recent',recent,'appfile',appfile,'rm',rm,'mi',mi,'mn',m))

text(1000,860,'Show','Parent',it)
uicontrol('Position',[1000 380 100 470],'Style','listbox','Max',1,'Min',1,...
              'Callback',@selection,'String',"",'Tag','showgraph');
uicontrol('Position',[1060 850 40 20],'Style','pushbutton','Tag','showsort',...
              'Callback',@sortlist,'String',[char(8595) 'sort'],'Enable','off');

text(1150,860,'Hide','Parent',it)
uicontrol('Position',[1150 380 100 470],'Style','listbox','Max',1,'Min',1,...
              'Callback',@selection,'String',"",'Tag','hidegraph');

          
uicontrol('Position',[1110 600 30 30],'Style','pushbutton','Tag','adjust',...
              'Callback',@modtxt,'String',char(8594),'FontSize',20,'Enable','off');
uicontrol('Position',[1110 500 30 30],'Style','pushbutton','Tag','adjust',...
              'Callback',@modtxt,'String',char(8592),'FontSize',20,'Enable','off');
          
uicontrol('Position',[1000 350 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','autoscale xy all','Enable','off');
uicontrol('Position',[1000 330 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@centerbl,'String','center zeros','Enable','off');
uicontrol('Position',[1000 310 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String','increase y-scale','Enable','off');
uicontrol('Position',[1000 290 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String','decrease y-scale','Enable','off');
          
uicontrol('Position',[1110 350 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@remove_artifact,'String','Remove Artifact','Enable','off');
uicontrol('Position',[1110 330 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@edit_undo,'String','Edit undo','Enable','off');
text(2, 860,["show","y-axis"],'Visible','off','Tag','yaxis_label')



function edit_undo(hObject,eventdata)
props = guidata(hObject);
props.data = props.databackup;
for c=1:length(props.showidx)
    props.ax(c).Children.YData = props.data(props.showidx(c),:);pause(0.01)
end
guidata(hObject,props)


function remove_artifact(hObject,eventdata)
props = guidata(hObject);
idx = listdlg('liststring',props.showlist);
props.databackup = props.data;

ch = props.showidx(idx);
noart = [];
for c=1:length(idx)
    data = props.data(ch(c),:);
    sidx = find(data<-500);
    if length(sidx)<2
        noart = [noart; props.showlist(idx(c))];
        continue
    end
    sidx = [sidx(1) , sidx([false , diff(sidx)>10])];
    window = max(diff(sidx));
    adata = zeros(length(sidx),window);
    for a=1:length(sidx)
        if sidx(a)+window-1<length(data)
            adata(a,:) = data(sidx(a):sidx(a)+window-1);
        end
    end
    midx = adata>repmat(prctile(adata,25,1),size(adata,1),1) & adata<repmat(prctile(adata,75,1),size(adata,1),1);
    madata = nan(size(adata));
    madata(midx) = adata(midx);
    madata = mean(madata,1,'omitnan');

    for a=1:length(sidx)
        if sidx(a)+window<length(data)
            data(sidx(a):sidx(a)+window-1) = data(sidx(a):sidx(a)+window-1) - int16(madata);
            data(sidx(a)-5:sidx(a)+35) = 0;
            if a==1
                data((-2:-1) + sidx(a)) = 0;
            end
        else
            idxx = sidx(a):length(data);
            data(idxx) = data(idxx) - int16(madata(1:length(idxx)));
        end
    end
    props.data(ch(c),:) = data;
    props.ax(idx(c)).Children.YData = data;pause(0.01)
end

if ~isempty(noart)
    msgbox(sprintf(join(["No artifact detected for channels:"  string(noart')],'\n')))
end
guidata(hObject,props)




function toworkspace(hObject,eventdata)
props = guidata(hObject);
assignin('base', 'out', props);



function sortlist(hObject,eventdata)
props = guidata(hObject);
[~,sidx] = sort(double(string(props.showlist)));
props.showlist = props.showlist(sidx);
set(findobj('Tag','showgraph'),'String',props.showlist);
guidata(hObject,props)


function autoscale(hObject,eventdata)
it = findobj('Tag','grid');
buf = text(500,875,'Centering baseline...','FontSize',15,'Parent',it);
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.01)

props = guidata(hObject);
set(props.ax,'XLim',[0 max(props.ax(1).Children(1).XData)],'YLimMode','auto')

set(allbut,'Enable','on')
delete(buf)


function zoom(hObject,eventdata)
it = findobj('Tag','grid');
buf = text(500,875,'Increasing scale...','FontSize',15,'Parent',it);
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.01)

props = guidata(hObject);
for a=1:length(props.ax)
    yl = props.ax(a).YLim;
    if strcmp(hObject.String,'increase y-scale')
        sc = 0.5;
    else
        sc = 2;
    end
    props.ax(a).YLim = [mean(yl) - (mean(yl) - yl(1))*sc ,...
                        mean(yl) + (yl(2) - mean(yl))*sc ] ;
end

set(allbut,'Enable','on')
delete(buf)


function centerbl(hObject,eventdata)
it = findobj('Tag','grid');
buf = text(500,875,'Centering zeros...','FontSize',15,'Parent',it);
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.01)

props = guidata(hObject);
for a=1:length(props.ax)
    hwidth = diff(props.ax(a).YLim)/2;
    props.ax(a).YLim = [0 - hwidth, 0 + hwidth];
end
set(allbut,'Enable','on')
delete(buf)


function modtxt(hObject,eventdata)
props = guidata(hObject);
tags = ["showgraph","hidegraph"];
if hObject.String==char(8594)
    choose = props.hide;
else
    tags = fliplr(tags);
    choose = props.show;
end

olistobj = findobj('Tag',tags{2});
listobj = findobj('Tag',tags{1});

listobj.String = listobj.String;

olistobj.String = [olistobj.String ; listobj.String(choose)];
olistobj.Max = length(olistobj.String);
if olistobj.Max<3
    olistobj.Value=1;
else
    olistobj.Value = [];
end

listobj.Max = length(listobj.String) - length(choose);
listobj.Value = [];
if listobj.Max<3
    listobj.Value=1;
else
    listobj.Value = [];
end
listobj.String(choose) = [];

% hstring = get(findobj('Tag','hidegraph'),'String');
% [~,sidx] = sort(double(string(hstring)));
% set(findobj('Tag','hidegraph'),'String',hstring(sidx));
props.showlist = get(findobj('Tag','showgraph'),'String');
props.hidelist = get(findobj('Tag','hidegraph'),'String');
if strcmp(listobj.Tag,'showgraph')
    props.hideidx = [props.hideidx   props.showidx(choose)];
    props.showidx(choose) = [];
else
    props.showidx = [props.showidx   props.hideidx(choose)];
    props.hideidx(choose) = [];
end
guidata(hObject,props)
plotdata



function selection(hObject,eventdata)
props = guidata(hObject);
if strcmp(hObject.Tag,'showgraph')
    props.hide = hObject.Value;
else
    props.show = hObject.Value;
end
guidata(hObject,props)


function plotdata
props = guidata(gcf);
if isfield(props,'ax')
    delete(props.ax)
    delete(props.txt)
    delete(props.yaxis)
end

set(findobj('Tag','yaxis_label'),'Visible','on')
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
it = findobj('Tag','grid');
buf = text(500,875,'Plotting...','FontSize',15,'Parent',it);
pause(0.1)

f = gcf;
data = props.data;

% listobj = findobj('Tag','hidegraph');
% lstr = listobj.String;
% lstr = cellfun(@(x) str2double(string(regexp(x,'\d+','match')))+32*contains(x,'stim'),lstr);
% show = true(size(data,1),1);
% if ~isempty(listobj.String)
%     show(lstr) = false;
% end
showstr = get(findobj('Tag','showgraph'),'String');
% idx = cellfun(@(x) str2double(string(regexp(x,'\d+','match')))+32*contains(x,'stim'),showstr);
idx = cellfun(@(x) find(contains(props.ch,x)),showstr);
nch = length(idx);

tm = props.tm;
gsize = f.Position(4) - 100;
posy = linspace(gsize - gsize/nch,0,nch) + 50;
axf = gobjects(nch,1);
txt = gobjects(nch,1);
for d=1:nch
    axf(d) = axes('Units','pixels','Position',[70   posy(d)   880   gsize/nch]);
    plot(tm,data(idx(d),:));
        txt(d) = text(30,posy(d) + gsize/nch/2, props.showlist{d}  ,'Parent',it,'Horizontal','center');
%     txt(d) = text(30,posy(d) + gsize/nch/2,...
%                   {sscanf(props.showlist{d},'%d'),string(regexp(props.showlist{d},'[A-z()]+','match'))},...
%                    'Parent',it,'Horizontal','center');
    if d~=nch
        axf(d).XTick = [];
    end
    chk(d) = uicontrol('Position',[3 posy(d) + gsize/nch/2  15 15],'Style','checkbox',...
              'Callback',@yaxis,'Value',false);
end
set(axf,'YTick',[],'XLim',[0 max(tm)])
linkaxes(axf,'x')
set(findobj('Tag','adjust'),'Enable','on')
set(findobj('Tag','showsort'),'Enable','on')
delete(buf)
props.ax = axf;
props.txt = txt;
props.yaxis = chk;
guidata(gcf,props)
set(allbut,'Enable','on')


function yaxis(hObject,eventdata)
props = guidata(hObject);
for a=1:length(props.ax)
    if props.ax(a).Position(2)<hObject.Position(2) && sum(props.ax(a).Position([2 4]))>hObject.Position(2)
        if hObject.Value
            set(props.ax(a),'YTickMode','auto')
        else
            set(props.ax(a),'YTick',[])
        end
    end
end


function loadRHS(hObject,eventdata)
props = guidata(hObject);
it = findobj('Tag','grid');
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')

if strcmp(hObject.Text,'Open')
    [file, path, id] = uigetfile('C:\Users\cneveu\Desktop\Data\intan_data\*.rhs;*.mat',...
                             'Select an RHS2000 Data File', 'MultiSelect', 'on');
else
    [fstr,file,ext] = fileparts(hObject.Text);
    file = [file ext];
    path = props.recent.path(props.recent.file==hObject.Text);
    path = fullfile(path,fstr);
    path = path{1};
end
    
if ~file
%     fprintf('\nCancelled\n')
    return
end
 

recent = props.recent;

it = findobj('Tag','grid');
buf = text(500,875,'Loading...','FontSize',15,'Parent',it);
pause(0.01)

if contains(file,'.rhs')
    data = int16(zeros(32,0));
    stim = int16(zeros(32,0));
    tm = zeros(1,0);
    cnt = 0;
    if iscell(file)
        for f=1:length(file)
            buf.String = ['Loading...File ' num2str(f) ' of ' num2str(length(file))];
            pause(0.01)
            [amplifier_data,t,stim_data,amplifier_channels, board_adc_channels, board_adc_data] = read_Intan_RHS2000_file(fullfile(path,file{f}));
            if t(1)>0 && f==1
                out = questdlg('Warning!  The selected file is not the first file of this recording',...
                     'Warning!','Continue','Cancel','Cancel');
                if strcmp(out,'Cancel') || isempty(out)
                     set(allbut,'Enable','on')
                     delete(buf)
                     return
                end
            end
            data = [data, int16(amplifier_data)]; %#ok<AGROW>
            stim = [stim, int16(stim_data)]; %#ok<AGROW>
            tm = [tm, t];
            cnt = cnt+1;
        end
    else  
        fdir = dir(path);
        names = {fdir.name}';
        times = {fdir.date}';

        isd = cell2mat({fdir.isdir}');
        wrtype = ~cellfun(@(x) contains(x,'.rhs'),names);

        idx = cellfun(@(x) strcmp(file,x),names);
        cnt = cnt + 1;
        buf.String = 'Loading...File 1';
        pause(0.01);
        [data,t,stim,stim_param,notes,amplifier_channels, board_adc_channels, board_adc_data] = read_Intan_RHS2000_file(fullfile(path,fdir(idx).name));
        if t(1)>0
             out = questdlg('Warning!  The selected file is not the first file of this recording.  Recommend pressing ''Cancel'' and choosing another file',...
                 'Warning!','Continue','Cancel','Cancel');
             if strcmp(out,'Cancel') || isempty(out)
                 set(allbut,'Enable','on')
                 delete(buf)
                 return
             end
        end
        data = int16(data);
        stim = int16(stim);
        tmf = datetime(fdir(idx).date);
        tm = t;        
        dift = cellfun(@(x) seconds(datetime(x) - tmf),times);
        samenm = cellfun(@(x) strcmp(x,file),names);
        dift(dift<0 | isd | samenm | wrtype) = inf;

        while min(dift)<max(t) + 25 
            cnt = cnt + 1;
            buf.String = ['Loading...File ' num2str(cnt)];
            pause(0.01)
            [~,fidx] = min(dift);
            [amplifier_data,t,stim_data,amplifier_channels, board_adc_channels, board_adc_data] = read_Intan_RHS2000_file(fullfile(path,fdir(fidx).name));
            if t(1)>0 
                data = [data, int16(amplifier_data)]; %#ok<AGROW>
                stim = [stim, int16(stim_data)]; %#ok<AGROW>
                tmf = datetime(fdir(fidx).date);

                tm = [tm, t+diff(t(1:2))];


                dift = cellfun(@(x) seconds(datetime(x) - tmf),times);
                samenm = cellfun(@(x) strcmp(x,fdir(fidx).name),names);
                dift(dift<0 | isd | samenm | wrtype) = inf;
            end
        end
    end
    
    props.file = fullfile(path,file);
    props.data = [data;stim];
%     props.ch = [join([string((1:size(data,1))'), repelem(" rec(uV)", size(data,1),1)]);...
%                 join([string((1:size(data,1))'), repelem(" stim(uA)",size(data,1),1)])];

    props.ch = [string({amplifier_channels.native_channel_name})';...
                join([string((1:size(data,1))'), repelem(" stim(uA)",size(data,1),1)])];
            
    listobj = findobj('Tag','showgraph');
    listobj.String = props.ch(1:size(data,1));
    props.showlist = listobj.String;
    props.showidx = 1:size(data,1);
    listobj.Max = size(data,1);
    if listobj.Max==1
        listobj.Value=1;
    else
        listobj.Value = [];
    end
    hlistobj = findobj('Tag','hidegraph');
    hlistobj.String = props.ch(size(data,1)+1:end);
    props.hidelist = hlistobj.String;
    props.hideidx = size(data,1)+1:length(props.ch);
    hlistobj.Max = size(data,1);
    
    props.tm = tm;
    props.finfo.file = file;
    props.finfo.path = path;
    props.finfo.duration = max(tm);
    props.finfo.numfiles = cnt;
    finfo = dir(props.file);
    props.finfo.date = finfo.date;
    props.notes = notes;
elseif contains(file,'.mat')
    if isfield(props,'ax')
        delete(props.ax)
        delete(props.txt)
        delete(props.yaxis)
    end

    props = load(fullfile(path,file));
    props = props.props;
    props.recent = recent;
    
    set(props.ax,'Parent',gcf)
    set(props.txt,'Parent',it)
    
    listobj = findobj('Tag','showgraph');
    listobj.String = props.showlist;
    listobj.Max = length(props.showlist);
    if listobj.Max<3
        listobj.Value=1;
    else
        listobj.Value = [];
    end
    hlistobj = findobj('Tag','hidegraph');
    hlistobj.String = props.hidelist;
    hlistobj.Max = length(props.hidelist);
else
    error('Improper file type')
end

if isfield(props,'info')
    if any(isgraphics(props.info),'all')
        delete(props.info)
    end
    props = rmfield(props, 'info');
end

[ppfold,pfold,ext] = fileparts(path);
if path(end)=='\'
    [ppfold,pfold,ext] = fileparts(fileparts(path));
end

[unfile,idx] = unique([string(fullfile(pfold,file)); props.recent.file],'stable');
paths = [string(ppfold); props.recent.path];
props.recent.file = unfile;
props.recent.path = paths(idx);

if length(props.recent.file)>15
    props.recent.file = props.recent.file(1:15);
    props.recent.path = props.recent.path(1:15);
end

fid = fopen(props.appfile,'w');
fprintf(fid,[repmat('%s ',1,length(props.recent.file)) '\r\n'],props.recent.file,props.recent.path);
fclose(fid);


for r=1:length(props.recent.file)
    if r>length(props.rm)
        props.rm(r) = uimenu(props.mi(2),'Text',props.recent.file{r},'Callback',@loadRHS);
    else
        props.rm(r).Text = props.recent.file{r};
    end
end


delete(findobj('Tag','info'))
props.info(1,1) = text(1020,250,'File:','Parent',it,'Horizontal','right','Tag','info');
props.info(1,2) = text(1030,250,props.finfo.file,'Parent',it,'Interpreter','none','Tag','info');

props.info(2,1) = text(1020,235,'Folder:','Parent',it,'Horizontal','right','Tag','info');
props.info(2,2) = text(1030,235,props.finfo.path,'Parent',it,'Interpreter','none','Tag','info');

props.info(3,1) = text(1020,220,'Duration:','Parent',it,'Horizontal','right','Tag','info');
props.info(3,2) = text(1030,220,[num2str(props.finfo.duration) ' seconds'],'Parent',it,'Tag','info');

props.info(4,1) = text(1020,205,'# of Files:','Parent',it,'Horizontal','right','Tag','info');
props.info(4,2) = text(1030,205,num2str(props.finfo.numfiles),'Parent',it,'Tag','info');

props.info(5,1) = text(1020,190,'Date:','Parent',it,'Horizontal','right','Tag','info');
props.info(5,2) = text(1030,190,props.finfo.date,'Parent',it,'Tag','info');

props.info(6,1) = text(1020,170,'Note 1:','Parent',it,'Horizontal','right','Tag','info');
props.info(6,2) = uicontrol('Position',[1030 160 220 20],'Style','edit','Tag','note1',...
              'Callback',@note,'String',props.notes.note1,'Horizontal','left');
          
props.info(7,1) = text(1020,150,'Note 2:','Parent',it,'Horizontal','right','Tag','info');
props.info(7,2) = uicontrol('Position',[1030 140 220 20],'Style','edit','Tag','note2',...
              'Callback',@note,'String',props.notes.note2,'Horizontal','left');
          
props.info(8,1) = text(1020,130,'Note 3:','Parent',it,'Horizontal','right','Tag','info');
props.info(8,2) = uicontrol('Position',[1030 120 220 20],'Style','edit','Tag','note3',...
              'Callback',@note,'String',props.notes.note3,'Horizontal','left');
props.info(9,2) = text(1030,115,'Press enter to apply','Parent',it,'Horizontal','left','Tag','info');

delete(buf)

set(findobj('Tag','savem'),'Enable','on');
set(findobj('Tag','showlist'),'Enable','on');
set(findobj('Tag','hidelist'),'Enable','on');
if isfield(props,'yaxis')
    set(props.yaxis,'Parent',gcf,'Enable','on')
end
set(findobj('Tag','adjust'),'Enable','on')
set(findobj('Tag','showsort'),'Enable','on')


guidata(hObject,props)

set(allbut(isvalid(allbut)),'Enable','on')
if contains(file,'.rhs')
    plotdata
end


function note(hObject,eventdata)
props = guidata(hObject);
props.notes.(hObject.Tag) = hObject.String;
guidata(hObject,props)




function saveit(hObject,eventdata)
props = guidata(hObject);
it = findobj('Tag','grid');
[file,path,indx] = uiputfile(replace(props.file,'.rhs','.mat'));

if ~file
    return
end

buf = text(500,875,'Saving...','FontSize',15,'Parent',it);
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.01)

if ~isfield(props,'showlist')
    props.showlist = get(findobj('Tag','showgraph'),'String');
end

if ~isfield(props,'hidelist')
    props.hidelist = get(findobj('Tag','hidegraph'),'String');
end

% props = rmfield(props,'info');

save(fullfile(path,file),'props')

set(allbut,'Enable','on')
delete(buf)

