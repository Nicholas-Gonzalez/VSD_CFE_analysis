function Intan_gui(monitor) % main app
% Input:
% monitor = which monitor you would like to use for the GUI, default is largest. 


intan_tag = ['intan_tag' num2str(randi(1e4,1))];
mpos = get(0,'MonitorPositions');
if nargin==0
    [~,monitor] = max(prod(mpos(:,3:end),2));% gets the larger monitor
end
figsize = mpos(monitor,:);
f = figure('OuterPosition',figsize,'Name','Intan_Gui','NumberTitle','off','Tag',intan_tag);
% f = figure('Position',[100 0 1700 900],'Name','Intan_Gui','NumberTitle','off','Tag',intan_tag);

% it = axes('Units','pixels','Position',[0 0 f.Position(3) f.Position(4)],...
%           'Visible','on','XLim',[0 f.Position(3)],'YLim',[0 f.Position(4)],...
%           'XGrid','off','YGrid','off','Tag','grid','HitTest','off','YTick',[],'XTick',[]);
% it.Toolbar.Visible = 'off';


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
mi(1) = uimenu(m,'Text','Open','Callback',@loadapp);
% mi(2) = uimenu(m,'Text','Open Recent');%Depricated
% for r=1:length(recent.file)%Depricated
%     rm(r) = uimenu(mi(2),'Text',recent.file{r},'Callback',@loadRHS);%Depricated
% end
% if isempty(recent.file)%Depricated
%     rm = [];%Depricated
% end
mi(3) = uimenu(m,'Text','Generate Tiffs','Callback',@all_kframe,'Enable','on','Tag','kframe');
mi(4) = uimenu(m,'Text','Save','Callback',@saveit,'Enable','off','Tag','savem');
mi(5) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');
mi(6) = uimenu(m,'Text','Help','Callback',@help,'Enable','on','Tag','help');

% ---- formatting parameters --------
fontsz = 10;

csz = [nan 300 figsize(3)*0.25];% size of ROI and channels
menusz = 90;
insz = 250;
% ----------------------------------
axpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[0                       10     figsize(3)-sum(csz(2:3)) figsize(4)-menusz ],'Title','Graph','Tag','axpanel');
chpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-sum(csz(2:3)) insz   csz(2)                 figsize(4)-insz-menusz],'Title','channels','Tag','chpanel');
cmpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-sum(csz(2:3)) 0     sum(csz(2:3))-300       insz],'Title','Controls','Tag','cmpanel');
inpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-300           0     300                     insz],'Title','File information','Tag','inpanel');
ropanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-csz(3)        insz   csz(3)                  figsize(4)-insz-menusz],'Title','ROI','Tag','ropanel');


guidata(f,struct('show',[],'hide',[],'info',[],'recent',recent,'appfile',appfile,'mi',mi,'mn',m,...
                 'intan_tag',intan_tag,'axpanel',axpanel,'chpanel',chpanel,'cmpanel',cmpanel,'inpanel',inpanel,'ropanel',ropanel,'figsize',figsize))

% text(1000,860,'Show','Parent',it)
uicontrol(axpanel,'Units','pixels','Position',[0 axpanel.Position(4)-40 50 40],'Style','text','FontSize',fontsz,'String',["Show","Y-axis"])

% ======== channel panel ==========
uicontrol(chpanel,'Units','normalized','Position',[0 0.95 0.45 0.04],'Style','text','FontSize',fontsz,'String','Show')
uicontrol(chpanel,'Units','normalized','Position',[0 0    0.45 0.94],'Style','listbox','Max',1,'Min',1,...
              'Callback',@selection,'String',"",'Tag','showgraph');

uicontrol(chpanel,'Units','normalized','Position',[0.55 0.95 0.45 0.04],'Style','text','FontSize',fontsz,'String','Hide')
uicontrol(chpanel,'Units','normalized','Position',[0.55 0    0.45 0.94],'Style','listbox','Max',1,'Min',1,...
              'Callback',@selection,'String',"",'Tag','hidegraph');

uicontrol(chpanel,'Units','normalized','Position',[0.43 0.97 0.15 0.03],'Style','pushbutton','Tag','showsort',...
              'Callback',@sortlist,'String',[char(8593) 'sort'],'Enable','off');
uicontrol(chpanel,'Units','normalized','Position',[0.43 0.94 0.15 0.03],'Style','pushbutton','Tag','showsort',...
              'Callback',@sortlist,'String',[char(8595) 'sort'],'Enable','off');

uicontrol(chpanel,'Units','normalized','Position',[0.45 0.55 0.1 0.04],'Style','pushbutton','Tag','adjust',...
              'Callback',@modtxt,'String',char(8594),'FontSize',20,'Enable','off');
uicontrol(chpanel,'Units','normalized','Position',[0.45 0.45 0.1 0.04],'Style','pushbutton','Tag','adjust',...
              'Callback',@modtxt,'String',char(8592),'FontSize',20,'Enable','off');

% --------------------------
  
% ======== control panel ==========

uicontrol(cmpanel,'Units','normalized','Position',[0 0.9 0.20 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','autoscale xy','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.20 0.9 0.05 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','x','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.25 0.9 0.05 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','y','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.8 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@centerbl,'String','center zeros','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.7 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String','increase y-scale','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.6 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String','decrease y-scale','Enable','off');

          
uicontrol(cmpanel,'Units','normalized','Position',[0.3 0.9 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@remove_artifact,'String','Remove Artifact','Enable','off',...
              'TooltipString','Attempts to remove artifact by stimulation.  Sometimes it is not effective');
uicontrol(cmpanel,'Units','normalized','Position',[0.3 0.8 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@edit_undo,'String','Edit undo','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.3 0.7 0.3 0.1],'Style','pushbutton','Tag','adjust_not_finished',...
              'Callback',@decimateit,'String','Reduce sampling','Enable','off',...
              'TooltipString','Reduces the number or samples by half using the decimate function');
uicontrol(cmpanel,'Units','normalized','Position',[0.3 0.6 0.3 0.1],'Style','pushbutton','Tag','filter',...
              'Callback',@filterit,'String','Filter','Enable','off',...
              'Tag','filter','TooltipString','Filters the data');


uicontrol(cmpanel,'Units','normalized','Position',[0.6 0.9 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@xcorrelation,'String','XCorr','Enable','off',...
              'Tag','filter','TooltipString','Calculates the cross correlation');
uicontrol(cmpanel,'Units','normalized','Position',[0.6 0.8 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@spiked,'String','spike detection','Enable','off',...
              'Tag','filter','TooltipString','detect');
uicontrol(cmpanel,'Units','normalized','Position',[0.6 0.7 0.2 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@scalebar,'String','scale bar Add','Enable','off',...
              'Tag','filter','TooltipString','add scale bar');
uicontrol(cmpanel,'Units','normalized','Position',[0.8 0.7 0.1 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@scalebar,'String','Remove','Enable','off',...
              'Tag','filter','TooltipString','remove scale bar');
uicontrol(cmpanel,'Units','normalized','Position',[0.6 0.6 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@baseline,'String','remove baseline','Enable','off',...
              'Tag','filter','TooltipString','detect');
uicontrol(cmpanel,'Units','normalized','Position',[0.6 0.5 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@videoprompt,'String','Video','Enable','off',...
              'Tag','filter','TooltipString','generate a video of recording');

uicontrol(cmpanel,'Units','normalized','Position',[0 0.4 0.3 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@imhistogram,'String','Image histogram','Enable','off',...
              'Tag','filter','TooltipString','Filters the data');


uicontrol(cmpanel,'Units','normalized','Position',[0.3 0.2 0.3 0.1],'Style','pushbutton','Tag','plotagain',...
              'Callback',@loadplotwidgets,'String','Plot again','Enable','off',...
              'Tag','filter','TooltipString','Plots the data again');



% ======== ROI panel ==========
uicontrol(ropanel,'Units','pixels','Position',[0 0 50 20],'Style','togglebutton','Value',1,'Tag','fillroi',...
            'Callback',@updateroi,'String','fill ROI','Enable','off','Visible','on','ForegroundColor','w')



function all_kframe(hObject,eventdata)
props = guidata(hObject);
[fnames, fpath] = uigetfile('*.tsm',"MultiSelect",'on');
files = fullfile(fpath,fnames);
buf = uicontrol(props.axpanel,'Units','pixels',...
    'Position',[props.axpanel.Position(3)/2, props.axpanel.Position(4)-60,200, 40],...
    'Style','text','String','Generating Tiffs...','FontSize',13);
pause(0.1)
if ischar(files)
    disp(['find_kframes   ',files])
    find_kframe(files,false);
else
    for f=1:length(files)
        disp(['find_kframes   ',files{f}])
        set(buf,'String',files{f})
        pause(0.1)
        try
            find_kframe(files{f},false);
        catch
            warning(['could not execute for ' files{f}])
        end
    end
end
disp('finished')
delete(buf)

function scalebar(hObject,eventdata)
props = guidata(hObject);
xlim = props.ax(1).XLim;
pos = xlim(1)+range(xlim)*0.05;
delete(findobj('Tag','scaleb'));
if contains(hObject.String,'Add')
    for a = 1:length(props.ax)
        line(props.ax(a),[pos pos],-[0.0005 0.0015],'Color','k','Tag','scaleb')
    end
end

%% loading methods
% This is the app that loads that data into the guidata
function loadapp(hObject,eventdata)
props = guidata(hObject);
f2 = figure('MenuBar','None','Name','Open File','NumberTitle','off');
f2.Position = [props.figsize(1:2)+props.figsize(3:4)/2 540 300];


uicontrol('Position',[480 280 60 20],'Style','text','String','Include');

uicontrol('Position',[50 280 200 20],'Style','text','String',"Select Frame file (.tif)");
frm = uicontrol('Position',[10 260 315 20],'Style','edit','String','','Tag','tiffns','HorizontalAlignment','left','Callback',@setvsdfile);
uicontrol('Position',[325 260 60 20],'Style','pushbutton','String',"Browse",'Callback',@getvsdfile,'Tag','tiffn');
uicontrol('Position',[385 260 60 20],'Style','pushbutton','String',"Generate",'Callback',@findkframe,'Tag','tiffn');
uicontrol('Position',[445 260 60 20],'Style','text','String','','Tag','tifp');
uicontrol('Position',[505 260 60 20],'Style','checkbox','Tag','tifc','Value',1);

uicontrol('Position',[50 230 200 20],'Style','text','String',"Select ROI file (.det)");
vsd = uicontrol('Position',[10 210 315 20],'Style','edit','String','','Tag','detfns','HorizontalAlignment','left','Callback',@setvsdfile);
uicontrol('Position',[325 210 60 20],'Style','pushbutton','String',"Browse",'Callback',@getvsdfile,'Tag','detfn');
uicontrol('Position',[445 210 60 20],'Style','text','String','','Tag','detp');
uicontrol('Position',[505 210 60 20],'Style','checkbox','Tag','detc','Value',1);

uicontrol('Position',[50 180 200 20],'Style','text','String',"Select VSD file (.tsm)");
vsd = uicontrol('Position',[10 160 315 20],'Style','edit','String','','Tag','tsmfns','HorizontalAlignment','left','Callback',@setvsdfile);
uicontrol('Position',[325 160 60 20],'Style','pushbutton','String',"Browse",'Callback',@getvsdfile,'Tag','tsmfn');
uicontrol('Position',[445 160 60 20],'Style','text','String','','Tag','tsmp');
uicontrol('Position',[505 160 60 20],'Style','checkbox','Tag','tsmc','Value',1);

uicontrol('Position',[50 130 200 20],'Style','text','String',"Select CFE file (.rhs)");
vsd = uicontrol('Position',[10 110 315 20],'Style','edit','String','','Tag','rhsfns','HorizontalAlignment','left','Callback',@setvsdfile);
uicontrol('Position',[325 110 60 20],'Style','pushbutton','String',"Browse",'Callback',@getvsdfile,'Tag','rhsfn');
uicontrol('Position',[445 110 60 20],'Style','text','String','','Tag','rhsp');
uicontrol('Position',[505 110 60 20],'Style','checkbox','Tag','rhsc','Value',1);

uicontrol('Position',[50 80 200 20],'Style','text','String',"Select notes file (.xlsx)");
vsd = uicontrol('Position',[10 60 315 20],'Style','edit','String','','Tag','xlsxfns','HorizontalAlignment','left','Callback',@setvsdfile);
uicontrol('Position',[325 60 60 20],'Style','pushbutton','String',"Browse",'Callback',@getvsdfile,'Tag','xlsxfn');
uicontrol('Position',[445 60 60 20],'Style','text','String','','Tag','xlsxp');
uicontrol('Position',[505 60 60 20],'Style','checkbox','Tag','xlsxc','Value',1);

uicontrol('Position',[480 10 60 20],'Style','pushbutton','String',"Open",'Callback',@loadall);
uicontrol('Position',[420 10 60 20],'Style','pushbutton','String',"Cancel",'Callback',@cancelvsd);
uicontrol('Position',[360 10 60 20],'Style','pushbutton','String',"Help",'Callback',@helpvsd);
uicontrol('Position',[125 10 90 20],'Style','pushbutton','String',"Load Matlab File",'Callback',@loadmat);
uicontrol('Position',[65 10 60 20],'Style','text','String','','Tag','matprog');

load_tag = ['load_tag' num2str(randi(1e4,1))];
hmenu = hObject.Parent;
hintan = hmenu.Parent;

vsdprops.files = strings(5,2);
vsdprops.files(:,1) = ["tiffns";"detfns";"tsmfns";"rhsfns";"xlsxfns"];
vsdprops.load_tag = load_tag;
vsdprops.intan_tag = hintan.Tag;

allbut = findobj(hintan,'Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
vsdprops.allbut = allbut;

guidata(f2,vsdprops)

function loadmat(hObject,eventdata)
vsdprops = guidata(hObject);
[file, path, id] = uigetfile('C:\Users\cneveu\Desktop\Data\*.mat','Select frame file');
if ~file;return;end
matprog = findobj('Tag','matprog');
set(matprog,'String','loading...','ForeGroundColor','b')
pause(0.1)
matprops = load(fullfile(path,file));
set(matprog,'String','loaded','ForeGroundColor','k')
vsdprops.matprops.intan = matprops.props.vsdprops.intan;
vsdprops.matprops.intan.data = vsdprops.matprops.intan.data;
vsdprops.matprops.vsd.data = matprops.props.vsdprops.vsd.data;
vsdprops.matprops.vsd.tm = matprops.props.vsdprops.vsd.tm;
vsdprops.matprops.data = matprops.props.data;
vsdprops.matprops.min = matprops.props.min;
vsdprops.matprops.d2uint = matprops.props.d2uint;
vsdprops.matprops.showlist = matprops.props.showlist;
vsdprops.matprops.hidelist = matprops.props.hidelist;
vsdprops.matprops.showidx = matprops.props.showidx;
vsdprops.matprops.hideidx = matprops.props.hideidx;
vsdprops.matprops.notes = matprops.props.notes;
vsdprops.matprops.finfo = matprops.props.finfo;
if isfield(matprops.props,'video')
    vsdprops.matprops.video = matprops.props.video;
end
if isfield(matprops.props,'note')
    vsdprops.matprops.note = matprops.props.note;
else    
    try
        vsdprops.matprops.note = string(readcell(matprops.props.vsdprops.files{5,2}));
        disp('Note.xlsx was not found in file.  Successfully loaded')
    catch
        warning([matprops.props.vsdprops.files{5,2} , 'not found'])
    end  
end
vsdprops.matprops.Max = matprops.props.Max;
vsdprops.matprops.tm = matprops.props.tm;
vsdprops.matprops.ch = matprops.props.ch;

vsdprops.matprops.im = matprops.props.im;
vsdprops.matprops.det = matprops.props.det;
vsdprops.matprops.kern_center = matprops.props.kern_center;
vsdprops.matprops.kernpos = matprops.props.kernpos;

imfn = fullfile(path,replace(file,'.','_imdata.'));
if exist(imfn,'file')
    vsdprops.matprops.video = load(imfn);
end

imfn = fullfile(path,replace(file,'.','_imdata11.'));
if exist(imfn,'file')
    video11 = load(imfn);
    disp(['loaded:   ' imfn])

    imfn2 = replace(imfn,'imdata11.','imdata12.');
    video12 = load(imfn2);
    disp(['loaded:   ' imfn2])

    video.imdata = cat(3,video11.imdata1,video12.imdata2);
    fields = {'climv','d2uint1','fparam','fun','min1','reference','tm'};
    for f=1:length(fields)
        video.(fields{f}) = video11.(fields{f});
    end

    imfn3 = replace(imfn,'imdata11.','imdata21.');
    video21 = load(imfn3);
    disp(['loaded:   ' imfn3])

    imfn4 = replace(imfn,'imdata11.','imdata22.');
    video22 = load(imfn4);
    disp(['loaded:   ' imfn4])

    fields = {'climv','d2uint2','fparam','fun','min2','reference','tm'};
    for f=1:length(fields)
        video.(fields{f}) = video21.(fields{f});
    end
    video.imdataroi = cat(3,video21.imdataroi1,video22.imdataroi2);
    vsdprops.matprops.video = video;
end

if isfield(matprops.props,'filter')
    vsdprops.matprops.filter = matprops.props.filter;
end
if isfield(matprops.props,'databackup')
    vsdprops.matprops.databackup = matprops.props.databackup;
end
vsdprops.files = matprops.props.files;


for f=1:size(matprops.props.vsdprops.files,1)
    ft = matprops.props.vsdprops.files{f,1};
    set(findobj('Tag',ft),'String',matprops.props.vsdprops.files{f,2})
    set(findobj('Tag',[ft(1:end-3) 'p']),'String','loaded')
end
guidata(hObject,vsdprops)

function helpvsd(hObject,eventdata)
msgbox(['Add each file.  If the file names are the same, then the other',...
        ' fields will populate automatically.  For example, 001.tif for frame,',...
        ' 001.det for roi file, and 001.tsm for vsd.  The CFE should be stored',...
        ' in a folder with the name 001/*.rhs.  The CFE file will be populated',...
        ' automatically regardless of the file name as long as it is in a folder',...
        ' of the same name as files and that folder is within',...
        ' the same parent directory as the other files.  If the file names don''t',...
        ' follow this system then you will need to add each file manually.  ',...
        'check the box on left for files you would like to include when loading.'])

function findkframe(hObject,eventdata)
[file, path, id] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select frame file');
if ~file;return;end
find_kframe(fullfile(path,file),false);
set(findobj(hObject.Parent,'Tag','tiffns'),'String',fullfile(path,replace(file,'.tsm','_frame.tif')));
uicontrol(hObject.Parent,'Position',[380 240 60 20],'Style','text','String',"complete");
getvsdfile(findobj(hObject.Parent,'Tag','tiffns'))

function loadall(hObject,eventdata)% loads all the data into vsdprops
allbut = findobj(hObject.Parent,'Type','Uicontrol','Enable','on','-not','Style','text');
set(allbut,'Enable','off')
pause(0.1)

vsdprops = guidata(hObject);
iObject = findobj('Tag',vsdprops.intan_tag);

fex = false(1,size(vsdprops.files,1));
for f=1:size(vsdprops.files,1)
    fn = vsdprops.files(f,2);
    if contains(fn,';')
        fstr = split(fn,';  ');
        fexist = false(size(fstr));
        for e=1:length(fstr)
            fexist(e) = exist(fstr{e},'file');
        end 
        fex(f) = all(fexist);
    else
        fex(f) = exist(fn,'file');
    end
end


if ~strcmp(get(findobj(hObject.Parent,'Tag','tifp'),'String'),'loaded')
    if fex(vsdprops.files(:,1)=="tiffns") && get(findobj(hObject.Parent,'Tag','tifc'),'Value')==1
        im = imread(vsdprops.files(vsdprops.files(:,1)=="tiffns",2));
        vsdprops.im = repmat(im,1,1,3/size(im,3));
        set(findobj(hObject.Parent,'Tag','tifp'),'String',"loaded");
    elseif get(findobj(hObject.Parent,'Tag','tifc'),'Value')==1
        set(findobj(hObject.Parent,'Tag','tifp'),'String',"not found",'ForegroundColor','r');
    end
end

if ~strcmp(get(findobj(hObject.Parent,'Tag','detp'),'String'),'loaded')
    if fex(vsdprops.files(:,1)=="detfns") && get(findobj(hObject.Parent,'Tag','detc'),'Value')==1
        [vsdprops.det,vsdprops.pixels,vsdprops.kern_center,kernel_size,vsdprops.kernpos] = ...
            readdet(vsdprops.files(vsdprops.files(:,1)=="detfns",2),size(vsdprops.im,2));
        set(findobj(hObject.Parent,'Tag','detp'),'String',"loaded");
    elseif get(findobj(hObject.Parent,'Tag','detc'),'Value')==1
        set(findobj(hObject.Parent,'Tag','detp'),'String',"not found",'ForegroundColor','r');
    end
end

if ~strcmp(get(findobj(hObject.Parent,'Tag','xlsxp'),'String'),'loaded')
    if fex(vsdprops.files(:,1)=="xlsxfns") && get(findobj(hObject.Parent,'Tag','xlsxc'),'Value')==1
        vsdprops.note = string(readcell(vsdprops.files(vsdprops.files(:,1)=="xlsxfns",2)));
        set(findobj(hObject.Parent,'Tag','xlsxp'),'String',"loaded");
    elseif get(findobj(hObject.Parent,'Tag','xlsxc'),'Value')==1
        set(findobj(hObject.Parent,'Tag','xlsxp'),'String',"not found",'ForegroundColor','r');
    end
end

if ~strcmp(get(findobj(hObject.Parent,'Tag','tsmp'),'String'),'loaded')
    tsm_prog = findobj(hObject.Parent,'Tag','tsmp');
    if fex(vsdprops.files(:,1)=="tsmfns") && get(findobj(hObject.Parent,'Tag','tsmc'),'Value')==1
        tsm = vsdprops.files(vsdprops.files(:,1)=="tsmfns",2);
        det = vsdprops.files(vsdprops.files(:,1)=="detfns",2);
        if ~fex(vsdprops.files(:,1)=="detfns")
            set(findobj(hObject.Parent,'Tag','tsmp'),'String',"no det",'ForegroundColor','r');
        else
            set(tsm_prog,'String',"loading...",'ForegroundColor','b');
            pause(0.1)
%             [~, fparam, ~] = getimdata(tsm);
%             vsdprops.vsd.fparam = fparam;
%             fun = @(p1,p2,p3,p4,x) p1.*(1-exp(x./-p2))-p3.*(1-exp(x./-p4));
%             save(replace(tsm,'.tsm','_pixelfit'),'fparam','fun')
            [data,tm,info,imdata,imtm,imdataf] = extractTSM(tsm{1}, det);
%             save(replace(tsm,'.tsm','_pixelfit'),'imdata','imtm','imdataf','-append')
            data = data';
            vsdprops.vsd.min = min(data,[],2);
            vsdprops.vsd.d2uint = repelem(2^16,size(data,1),1)./range(data,2);
            vsdprops.vsd.data = convert_uint(data, vsdprops.vsd.d2uint, vsdprops.vsd.min,'uint16');
            vsdprops.vsd.tm = tm;
            vsdprops.vsd.info = info;
            set(tsm_prog,'String','saving...')
            save(replace(vsdprops.files(vsdprops.files(:,1)=="tsmfns",2),'.tsm','.mat'),'vsdprops')
            set(tsm_prog,'String','loaded','ForegroundColor','k')
        end
    elseif  get(findobj('Tag','tsmc'),'Value')==1
        set(findobj(hObject.Parent,'Tag','tsmp'),'String',"not found",'ForegroundColor','r');
    end 
end

if ~strcmp(get(findobj(hObject.Parent,'Tag','rhsp'),'String'),'loaded')
    rhs_prog = findobj(hObject.Parent,'Tag','rhsp');
    if fex(vsdprops.files(:,1)=="rhsfns") && get(findobj(hObject.Parent,'Tag','rhsc'),'Value')==1
        rfn = vsdprops.files{vsdprops.files(:,1)=="rhsfns",2};
        set(rhs_prog,'String',"loading...",'ForegroundColor','b');
        pause(0.1)
        rfn = split(rfn,';  ');
        for r=1:length(rfn)
            if r==1
                [data, tm, stim, ~, notes, amplifier_channels] = read_Intan_RHS2000_file(rfn{r});
            else
                [datap, tmp, stimp] = read_Intan_RHS2000_file(rfn{r});
                data = [data, datap];
                tm = [tm, tmp];
                stim = [stim, stimp];
            end
        end
        vsdprops.intan.tm = tm;

        vsdprops.intan.data = [data;stim];
        
        sz = size(vsdprops.intan.data);
        vsdprops.intan.min = min(vsdprops.intan.data,[],2);
        vsdprops.intan.d2uint = repelem(2^16,sz(1),1)./range(vsdprops.intan.data,2);
        vsdprops.intan.data = convert_uint(vsdprops.intan.data, vsdprops.intan.d2uint, vsdprops.intan.min,'uint16');

        vsdprops.intan.ch = [string({amplifier_channels.native_channel_name})';...
                    join([string((1:size(data,1))'), repelem(" stim(uA)",size(data,1),1)])];
        [path,file] = fileparts(rfn);

        vsdprops.intan.finfo.file = join(file,';  ');
        vsdprops.intan.finfo.path = join(path,';  ');
        if isa(rfn,'cell')
            finfo = dir(rfn{1});
        end
        vsdprops.intan.finfo.date = finfo.date;
        vsdprops.intan.finfo.duration = max(vsdprops.intan.tm);
        
        vsdprops.intan.notes = notes;
        set(rhs_prog,'String','loaded','ForegroundColor','k')
    elseif  get(findobj('Tag','rhsc'),'Value')==1
        set(findobj(hObject.Parent,'Tag','rhsp'),'String',"not found",'ForegroundColor','r');
    end 
end

strs = ["tifc"   ,"detc"  ,"tsmc"  ,"rhsc"  ,"xlsxc";...
         "tifp"   ,"detp"  ,"tsmp"  ,"rhsp"  ,"xlsxp";...
         ".tif"  ,".det"  ,".tsm"  ,".rhs"  ,".xlsx"];
str = strings(0,1);
for e=1:size(strs,2)
    vals = get(findobj(hObject.Parent,'Tag',strs{1,e}),'Value');
    loadeds = get(findobj(hObject.Parent,'Tag',strs{2,e}),'String');
    loaded = strcmp(loadeds,'loaded');
    if vals && ~loaded
        str = [str; string( ['file '  strs{3,e} ' not loaded'])];
    end
end
answer = 'Continue anyway';
if ~isempty(str)
    answer = questdlg(["The following files are not loaded because not found.  Please change file name or unselect the file."; str],...
        'Alert','Continue anyway','Cancel','Cancel');
end

if strcmp(answer,'Cancel')
    set(allbut,'Enable','on')
    pause(0.1)
else
    guidata(hObject,vsdprops)
    stitchvsd(hObject)
    close(hObject.Parent)
    loadplotwidgets(iObject,eventdata)
end

function stitchvsd(hObject)
% combines the vsd and the intan data.  Function used by loadall.
vsdprops = guidata(hObject);
props = guidata(findobj('Tag',vsdprops.intan_tag));
intch = isfield(vsdprops,'intan') || (isfield(vsdprops,'matprops') && isfield(vsdprops.matprops,'intan'));
vsdch = isfield(vsdprops,'vsd') || (isfield(vsdprops,'matprops') && isfield(vsdprops.matprops,'vsd'));
if intch && vsdch
    if isfield(vsdprops,'intan')
        intan = convert_uint(vsdprops.intan.data(:,1:2:end), vsdprops.intan.d2uint, vsdprops.intan.min,'double');
        itm = vsdprops.intan.tm(1:2:end);
        if isfield(vsdprops,'vsd')
            vsd = convert_uint(vsdprops.vsd.data, vsdprops.vsd.d2uint, vsdprops.vsd.min,'double');
            tm = vsdprops.vsd.tm;
            if isfield(vsdprops.vsd,'fparam')
                props.fparam = vsdprops.vsd.fparam;
            end
        else
            vsd = convert_uint(vsdprops.matprops.vsd.data, vsdprops.matprops.vsd.d2uint,...
                vsdprops.matprops.vsd.min,'double');
            tm = vsdprops.matprops.vsd.tm;
        end
        sr = diff(vsdprops.vsd.tm(1:2));
        vtm = min(itm):sr:max(itm);
        prsz = length(min(itm):sr:min(tm)-sr);
        posz = length(max(tm)+sr:sr:max(itm));
        vsd = [repmat(vsd(:,1),1,prsz),  vsd, repmat(vsd(:,end),1,posz)];
        if length(vtm)>size(vsd,2)
            vtm = vtm(1:size(vsd,2));
        end
        vsd = interp1(vtm, vsd', itm);
        vsd = vsd';
        
        props.data = [intan ; vsd];
        if isfield(vsdprops,'note')
            for c=1:length(vsdprops.intan.ch)
                nstr = replace(vsdprops.intan.ch(c),'A-','A');
                idx = contains(vsdprops.note(:,1),nstr);
                if any(idx) && ~ismissing(vsdprops.note(idx,2))           
                    vsdprops.intan.ch(c) = join([replace(vsdprops.intan.ch(c),'-0','') vsdprops.note(idx,2)],'-');
                end
            end
        end
        
        props.ch = [vsdprops.intan.ch ;  string([repelem('V-',size(vsd,1),1) num2str((1:size(vsd,1))','%03u')])];
        props.tm = itm;
        showidx = [(1:size(intan,1)/2)  (1:size(vsd,1))+size(intan,1)];
        props.showlist = props.ch(showidx);
        props.showidx = showidx;
        hideidx = size(intan,1)/2+1:size(intan,1);
        props.hidelist = props.ch(hideidx);
        props.hideidx = hideidx;
        props.Max = size(props.data,1);
        props.finfo = vsdprops.intan.finfo;
        props.finfo.files = vsdprops.files;
        props.notes = vsdprops.intan.notes;
        props.note = vsdprops.note;
    else
        if isfield(vsdprops,'vsd')
            intan = convert_uint(vsdprops.matprops.intan.data, vsdprops.matprops.intan.d2uint,...
                vsdprops.matprops.intan.min, 'double');
            itm = vsdprops.matprops.intan.tm;  
            vsd = vsdprops.vsd.data;
            tm = vsdprops.vsd.tm;
            sr = diff(vsdprops.vsd.tm(1:2));
            vtm = min(itm):sr:max(itm);
            prsz = length(min(itm):sr:min(tm)-sr);
            posz = length(max(tm)+sr:sr:max(itm));
            vsd = [repmat(vsd(:,1),1,prsz),  vsd, repmat(vsd(:,end),1,posz)];

            vsd = convert_uint(vsd, vsdprops.vsd.d2uint, vsdprops.vsd.min,'double');% removed d from vsdprops.vsd.mind
            vsd = interp1(vtm, vsd', itm);
            vsd = vsd';
            
            props.data = [intan ; vsd];
            props.ch = [vsdprops.matprops.intan.ch ;  string([repelem('V-',size(vsd,1),1) num2str((1:size(vsd,1))','%03u')])];
            props.tm = itm;
            showidx = [(1:size(intan,1)/2)  (1:size(vsd,2))+size(intan,1)];
            props.showlist = props.ch(showidx);
            props.showidx = showidx;
            hideidx = size(intan,1)/2+1:size(intan,1);
            props.hidelist = props.ch(hideidx);
            props.hideidx = hideidx;
            props.Max = size(props.data,1);
            props.finfo = vsdprops.matprops.intan.finfo;
            props.finfo.files = vsdprops.files;
            props.notes = vsdprops.matprops.intan.notes;
            if isfield(vsdprops.matprops,'note')
                props.note = vsdprops.matprops.note;
            end
            if isfield(vsdprops.matprops,'video')
                props.video = vsdprops.matprops.video;disp('added video')
                d2uint1 = vsdprops.matprops.video.d2uint1;
                min1 = vsdprops.matprops.video.min1;
                props.video.imdata = double(props.video.imdata)/d2uint1 + min1;
                d2uint2 = vsdprops.matprops.video.d2uint1;
                min2 = vsdprops.matprops.video.min1;
                props.video.imdataroi = double(props.video.imdataroi)/d2uint2 + min2;
            end
        else
            props.d2uint = vsdprops.matprops.d2uint;
            props.min = vsdprops.matprops.min;
            props.data = convert_uint(vsdprops.matprops.data, props.d2uint, props.min,'double');  
            props.tm = vsdprops.matprops.tm;
            props.ch = vsdprops.matprops.ch;
            props.showlist = vsdprops.matprops.showlist;
            props.hidelist = vsdprops.matprops.hidelist;
            props.showidx = vsdprops.matprops.showidx;
            props.hideidx = vsdprops.matprops.hideidx;  
            props.Max = vsdprops.matprops.Max;
            props.finfo = vsdprops.matprops.finfo;
            props.finfo.files = vsdprops.files;
            props.notes = vsdprops.matprops.notes;
            if isfield(vsdprops.matprops,'note')
                props.note = vsdprops.matprops.note;
            end
            if isfield(vsdprops.matprops,'video')
                props.video = vsdprops.matprops.video;disp('added video')
                d2uint1 = vsdprops.matprops.video.d2uint1;
                min1 = vsdprops.matprops.video.min1;
                props.video.imdata = double(props.video.imdata)/d2uint1 + min1;
                d2uint2 = vsdprops.matprops.video.d2uint1;
                min2 = vsdprops.matprops.video.min1;
                props.video.imdataroi = double(props.video.imdataroi)/d2uint2 + min2;
            end
            props.im = vsdprops.matprops.im;
            props.det = vsdprops.matprops.det;
            props.kern_center = vsdprops.matprops.kern_center;
            props.kernpos = vsdprops.matprops.kernpos;
            if isfield(vsdprops.matprops,'filter')
                props.filter = vsdprops.matprops.filter;
            end
            if isfield(vsdprops.matprops,'backup')
                props.backup = vsdprops.matprops.backup;
            end
            vsdprops.intan = vsdprops.matprops.intan;
            vsdprops.vsd = vsdprops.matprops.vsd;
        end
    end
elseif vsdch
    nch = size(vsdprops.vsd.data,1);
    props.ch = string([repelem('V-',nch,1) num2str((1:nch)','%03u')]);
    
    props.tm = vsdprops.vsd.tm;
    props.showlist = props.ch;
    props.showidx = 1:nch;
    props.hidelist = [];
    props.hideidx = [];
    props.data = convert_uint(vsdprops.vsd.data, vsdprops.vsd.d2uint, vsdprops.vsd.min,'double');
    [path,filename ] = fileparts(vsdprops.vsd.info.Filename);
    props.finfo.file = filename;
    props.finfo.files = vsdprops.files;
    props.finfo.path = path;
    props.finfo.duration = max(props.tm);
    props.finfo.date = vsdprops.vsd.info.FileModDate;
    props.notes = struct('note1',"",'note2',"",'note3',"");
else
    nch = length(vsdprops.intan.ch);
    props.ch = vsdprops.intan.ch;
    props.tm = vsdprops.intan.tm;
    props.showlist = vsdprops.intan.ch;
    props.showidx = 1:nch;
    props.hidelist = [];
    props.hideidx = [];
    props.data = convert_uint(vsdprops.intan.data, vsdprops.intan.d2uint, vsdprops.intan.min,'double');
    props.finfo = vsdprops.intan.finfo;
    props.finfo.files = vsdprops.files;
    props.notes = struct('note1',"",'note2',"",'note3',"");
    props.im = ones(512,512,3);
end
props.files = vsdprops.files;
try vsdprops = rmfield(vsdprops,'matprops'); end %#ok<TRYNC>

props.vsdprops = vsdprops;
props.newim = true;

if isfield(vsdprops,'im')
    props.im = vsdprops.im;
end

if isfield(vsdprops,'det')
    props.det = vsdprops.det;
    props.kern_center = vsdprops.kern_center;
    props.kernpos = vsdprops.kernpos;
end
set(vsdprops.allbut,'Enable','on')
guidata(findobj('Tag',props.intan_tag),props)

function out = convert_uint(data,d2uint,mind,vtype)% converts data from uint16 2 double, vica versa
% data must be 2d array.  d2uint is the conversion factor from double
% to uint16, mind is the minimun subtracted from the data when in original
% double format. vtype is the desired output class (double or uint16).  If
% data is already in the type specified by vtype, the out will be
% indentical to the input data.
sz = size(data);
[~, didx] = max(sz);
if didx==1% making the second dimension time, converts output back.
    data = data';
end

if strcmp(vtype,'double') && isa(data,'uint16')
    out = double(data)./repmat(d2uint,1,size(data,2)) + repmat(mind,1,size(data,2));
elseif strcmp(vtype,'uint16') && isa(data,'double')
    out = uint16((data - repmat(mind,1,size(data,2))).*repmat(d2uint,1,size(data,2)));
elseif isa(data,vtype)
    out = data;
else
    error('data not in correct format')
end

if didx==1
    out = out';
end

function cancelvsd(hObject,eventdata)
vsdprops = guidata(hObject);
set(vsdprops.allbut,'Enable','on')
close(hObject.Parent)

function setvsdfile(hObject,eventdata)
vsdprops = guidata(hObject);
vsdprops.files(vsdprops.files(:,1)==hObject.Tag,2) = hObject.String;
validate(hObject)
guidata(hObject,vsdprops)

function validate(hObject)
hstr = hObject.Tag;
if hstr(end)=='n'
    hstr = [hstr 's'];
end
fstr = get(findobj(hObject.Parent,'Tag',hstr),'String');
fph = findobj(hObject.Parent,'Tag',replace(hstr,'fns','p'));

fstr = split(fstr,';  ');
fexist = false(size(fstr));
for f=1:length(fstr)
    fexist(f) = exist(fstr{f},'file');
end


if ~all(fexist)
    set(fph,'String', 'not found', 'ForegroundColor','r')
else
    set(fph, 'String','found', 'ForegroundColor','k')
end

function getvsdfile(hObject,eventdata)
vsdprops = guidata(hObject);
multsel = 'off';
if strcmp(hObject.Tag,'rhsfn')
    multsel = 'on';
end

[file, path, id] = uigetfile(['C:\Users\cneveu\Desktop\Data\*.' hObject.Tag(1:end-2)],'Select file','MultiSelect',multsel);

if ~isa(file,'cell') && ~any(file);return;end
if isa(file,'cell')
    filestr = join(string(fullfile(path,file)),';  ');
else
    filestr = fullfile(path,file);
end
vsdprops.files(vsdprops.files(:,1)==string([hObject.Tag 's']),2) = filestr;
guidata(hObject,vsdprops);
set(findobj(hObject.Parent,'Tag',[hObject.Tag 's']),'String',filestr)  
if isa(file,'cell')
    guessfiles(hObject,fullfile(path,file{1}))
else
    guessfiles(hObject,fullfile(path,file))
end

function guessfiles(hObject,fname)
vsdprops = guidata(hObject);
[fpath,fn,extn] = fileparts(fname);
fn = replace(fn,'_frame','');

strs = ["tiffns"   ,"detfns","tsmfns","rhsfns","xlsxfns";...
        "_frame.tif",".det" ,".tsm"  ,".rhs",".xlsx"];


dfolder = dir(fullfile(fpath));
fnames = string({dfolder.name});

noten = fullfile(fpath,'notes.xlsx');
if exist(noten,"file")
    notes = readcell(fullfile(fpath,'notes.xlsx'));
    cfename = notes{ismember(notes(:,1),'001'),2};
    if any(contains(fnames,cfename))
       cfename = fullfile(fpath,cfename,[cfename '.rhs']);
    else
       for f=3:length(dfolder)
           if dfolder(f).isdir
                sf = dir(fullfile(dfolder(f).folder,dfolder(f).name));
                idx = contains(string({sf.name}),cfename);
                if any(idx)
                    cfename = fullfile(sf(idx).folder,sf(idx).name);break
                end
           end
       end
    end
end


for s=1:size(strs,2)
    chk = isempty(get(findobj(hObject.Parent,'Tag',strs{1,s}),'String'));
    fns = fullfile(fpath,[fn strs{2,s}]);
    if chk && exist(fns,'file')
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns);
    elseif chk && strs(1,s)=="rhsfns" && exist("cfename",'var') && exist(cfename,'file')
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',cfename)
    elseif chk && strs(1,s)=="rhsfns" && exist(fullfile(fpath,fn),'dir')
        fstr = fullfile(fpath,fn);
        sfolder = dir(fstr);
        fns = sfolder(contains(string({sfolder.name}),'.rhs')).name;
        fns = fullfile(fstr,fns);
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns)
    elseif chk && strs(1,s)=="rhsfns" && exist(fullfile(fpath,replace(fn,'VSD_','')),'dir')
        fstr = fullfile(fpath,replace(fn,'VSD_',''));
        sfolder = dir(fstr);
        fns = sfolder(contains(string({sfolder.name}),'.rhs')).name;
        fns = fullfile(fstr,fns);
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns)        
    elseif chk && strs(1,s)=="xlsxfns"
        idx = contains(fnames,'notes') & contains(fnames,'.xlsx');
        if ~any(idx)
            idx = contains(fnames,'.xlsx');
        end
        
        if ~any(idx)
            idx = contains(fnames,'.csv');
        end
        
        if any(idx)
            fns = dfolder(find(idx,1,'first')).name; 
            fns = fullfile(fpath,fns);
            set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns)
        end
    end
    vsdprops.files( vsdprops.files(:,1)==strs(1,s),:) = [strs(1,s)  string(get(findobj(hObject.Parent,'Tag',strs{1,s}),'String'))];
    validate(findobj(hObject.Parent,'Tag',strs(1,s)))
end
guidata(hObject,vsdprops)
%% main app methods
% does the plotting and the adjusting y axis
function loadplotwidgets(hObject,eventdata)% sets up the widgets to contain all the traces and adds file information on bottom right
props = guidata(hObject);

allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')

slistobj = findobj(props.chpanel,'Tag','showgraph');
slistobj.String = props.showlist;
slistobj.Max = length(props.showlist);
hlistobj = findobj(props.chpanel,'Tag','hidegraph');
hlistobj.String = props.hidelist;
hlistobj.Max = length(props.hidelist);


if isfield(props,'info')
    if any(isgraphics(props.info),'all')
        delete(props.info)
    end
    props = rmfield(props, 'info');
end


% it = findobj('Tag','grid');
delete(findobj(props.inpanel,'Tag','info'))
[~,name,ext] = fileparts(props.finfo.files{4,2});
inpos = props.inpanel.Position;
props.info(1,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-40, 50,20],'String','RHS File:','Horizontal','right','Tag','info');
props.info(1,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[60, inpos(4)-40, inpos(3)-60, 20],'String',[name,ext],'Horizontal','left','Tag','info');

[folder,name,ext] = fileparts(props.finfo.files{3,2});
props.info(2,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-55, 50,20],'String','TSM File:','Horizontal','right','Tag','info');
props.info(2,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[60, inpos(4)-55, inpos(3)-60, 20],'String',[name,ext],'Horizontal','left','Tag','info');

props.info(3,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-70, 50,20],'String','Folder:','Horizontal','right','Tag','info');
props.info(3,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[60, inpos(4)-70, inpos(3)-60, 20],'String',folder,'Horizontal','left','Tag','info');

props.info(4,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-85, 50,20],'String','Duration:','Horizontal','right','Tag','info');
props.info(4,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[60, inpos(4)-85, inpos(3)-60, 20],'String',[num2str(props.finfo.duration) ' seconds'],'Horizontal','left','Tag','info');

% props.info(4,1) = text(1020,205,'# of Files:','Parent',it,'Horizontal','right','Tag','info');
% props.info(4,2) = text(1030,205,num2str(props.finfo.numfiles),'Parent',it,'Tag','info');

props.info(5,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-100, 50,20],'String','Date:','Horizontal','right','Tag','info');
props.info(5,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[60, inpos(4)-100, inpos(3)-60, 20],'String',props.finfo.date,'Horizontal','left','Tag','info');

props.info(6,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-115, 50,20],'String','Note 1:','Horizontal','right','Tag','info');
props.info(6,2) = uicontrol(props.inpanel,'Units','pixels','Position',[60, inpos(4)-115, inpos(3)-60, 20],'Style','edit','Tag','note1',...
              'Callback',@note,'String',props.notes.note1,'Horizontal','left');
          
props.info(7,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-130, 50,20],'String','Note 2:','Horizontal','right','Tag','info');
props.info(7,2) = uicontrol(props.inpanel,'Units','pixels','Position',[60, inpos(4)-130, inpos(3)-60, 20],'Style','edit','Tag','note2',...
              'Callback',@note,'String',props.notes.note2,'Horizontal','left');
          
props.info(8,1) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-145, 50,20],'String','Note 3:','Horizontal','right','Tag','info');
props.info(8,2) = uicontrol(props.inpanel,'Units','pixels','Position',[60, inpos(4)-145, inpos(3)-60, 20],'Style','edit','Tag','note3',...
              'Callback',@note,'String',props.notes.note3,'Horizontal','left');
props.info(9,2) = uicontrol(props.inpanel,'Units','pixels','Style','text','Position',[0, inpos(4)-165, 100,20],'String','Press enter to apply','Horizontal','left','Tag','info');

if props.newim
    delete(findobj(props.ropanel,'Tag','roiax'))
    axes(props.ropanel,'Units','pixels','Position', [0 450 100 100],'YTick',[],'XTick',[],'Box','on','Tag','roiax');
    if length(size(props.im))==3
        props.imsh = image(props.im);
    else
        props.im = repmat(props.im,1,1,3);
        props.imsh = image(props.im);
    end
    sz = size(props.im);  
    panelsz = props.ropanel.Position;
    set(props.imsh.Parent,'Units','pixels','Position', [0   panelsz(4)-panelsz(3)*sz(1)/sz(2)   panelsz(3)   panelsz(3)*sz(1)/sz(2)],...
        'YTick',[],'XTick',[],'Box','on','Tag','roiax')
    props.newim = false;
end



if isfield(props,'im')
    set(findobj(props.ropanel,'Tag','fillroi'),'Enable','on','Visible','on')
end
set(findobj(hObject.Parent,'Tag','savem'),'Enable','on');
set(findobj(props.chpanel,'Tag','showgraph'),'Enable','on');
set(findobj(props.chpanel,'Tag','hidegraph'),'Enable','on');
if isfield(props,'yaxis')
    set(props.yaxis,'Parent',hObject.Parent,'Enable','on')
end

set(findobj(props.chpanel,'Tag','showsort'),'Enable','on')
set(findobj(props.cmpanel,'Tag','adjust'),'Enable','on')
set(findobj(props.cmpanel,'Tag','filter'),'Enable','on')

guidata(hObject,props)
updateroi(hObject)
set(allbut(isvalid(allbut)),'Enable','on')
plotdata(hObject)
% set(findobj(hObject.Parent,'Tag','fillroi'),'BackgroundColor',[0.2 0.2 0.2],'ForegroundColor',[1 1 1]);

function plotdata(hObject)
props = guidata(hObject);

set(findobj('Tag','yaxis_label'),'Visible','on')
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
buf = uicontrol(props.axpanel,'Units','pixels','Position',[props.axpanel.Position(3)/2, props.axpanel.Position(4)-60,200, 40],'Style','text','String','Plotting...','FontSize',15);
pause(0.1)

data = props.data;

showstr = get(findobj(props.chpanel,'Tag','showgraph'),'String');
idx = cellfun(@(x) find(strcmp(props.ch,x)),showstr);
nch = length(idx);

tm = props.tm;
gsize = props.axpanel.Position(4) - 100;
posy = linspace(gsize - gsize/nch,0,nch) + 50;


if isfield(props,'plt')
    delete(props.plt)
    delete(props.ax)
    delete(props.ylim.scplus)
    delete(props.ylim.scminus)
    delete(props.ylim.up)
    delete(props.ylim.dwn)
    delete(props.chk)
    delete(props.txt)
end

props.plt = gobjects(nch,1);
props.ax = gobjects(nch,1);
props.chk = gobjects(nch,1);
props.txt = gobjects(nch,1);
props.ylim.scplus = gobjects(nch,1);
props.ylim.scminus = gobjects(nch,1);
props.ylim.up = gobjects(nch,1);
props.ylim.dwn = gobjects(nch,1);

disp('plotting')

for d=1:nch
    chpos = posy(d) + gsize/nch/2 - 8;
    if ~isgraphics(props.plt(d))
        props.ax(d) = axes(props.axpanel,'Units','pixels','Position',[85   posy(d)   props.axpanel.Position(3)-115   gsize/nch]);
        props.plt(d) = plot(tm,data(idx(d),:));
        props.chk(d) = uicontrol(props.axpanel,'Units','pixels','Style','checkbox','Callback',@yaxis,'Value',false,'Position',[3 chpos  15 15],...
            'Value',false,'Visible','off','Tag',['c' num2str(d)]);
        props.txt(d) = uicontrol(props.axpanel,'Units','pixels','Style','text','Position',[18 chpos  60 15],'String',props.showlist{d},'HorizontalAlignment','left','Visible','off','Tag',['t' num2str(d)]);
        props.ylim.scplus(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[ props.axpanel.Position(3)-30 chpos+8  15 15],'String','+','Callback',@adjylim,'Visible','off','Tag',['p' num2str(d)],'TooltipString','increase yscale');
        props.ylim.scminus(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-30 chpos-8  15 15],'String','-','Callback',@adjylim,'Visible','off','Tag',['m' num2str(d)],'TooltipString','decrease yscale');
        props.ylim.up(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-15 chpos+8  15 15],'String',char(708),'Callback',@adjylim,'Visible','off','Tag',['u' num2str(d)],'TooltipString','shift y-range up');
        props.ylim.dwn(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-15 chpos-8  15 15],'String',char(709),'Callback',@adjylim,'Visible','off','Tag',['d' num2str(d)],'TooltipString','shift y-range down');
    else
        props.ax(d) = props.plt(d).Parent;
        set(props.plt(d).Parent,'Units','pixels','Position',[85   posy(d)   props.axpanel.Position(3)-115   gsize/nch])
        set(props.plt(d),'XData',tm,'YData',data(idx(d),:))
        
        set(props.chk(d),'Position',[3 chpos  15 15],'Value',false,'Visible','off');
        set(props.txt(d),'Position',[18 chpos  40 15],'String',props.showlist{d},'Visible','off');
        set(props.ylim.scplus(d),'Position',[props.axpanel.Position(3)-30 chpos+8  15 15],'Visible','off');% I don't think i need to set string here.  I am removing.
        set(props.ylim.scminus(d),'Position',[props.axpanel.Position(3)-30 chpos-8  15 15],'Visible','off');
        set(props.ylim.up(d),'Position',[props.axpanel.Position(3)-15 chpos+8  15 15],'Visible','off');
        set(props.ylim.dwn(d),'Position',[props.axpanel.Position(3)-15 chpos-8  15 15],'Visible','off');
    end
    
    
    if props.showlist{d}(1)=='B'
        outrange = abs(props.ax(d).YLim)>49;
        if outrange(1)
            props.ax(d).YLim(1) = -50;
        end
        if outrange(2)
           props.ax(d).YLim(2) = 50;
        end
    end
    
    if d~=nch
        props.plt(d).Parent.XTick = [];
        props.plt(d).Parent.Box = 'off';
        props.plt(d).Parent.XAxis.Color = 'w';
    else
        set(props.plt(d).Parent,'XTickMode','auto','XTickLabelMode', 'auto');
        props.plt(d).Parent.Box = 'off';
    end
end 

set(props.ax,'YTick',[],'XLim',[0 max(tm)])% somehow is also modifying im, but only when loading new files, 05-23-22: not sure if this comment is still applicable
linkaxes(props.ax,'x')
set(findobj(props.chpanel,'Tag','adjust'),'Enable','on')
set(findobj(props.chpanel,'Tag','showsort'),'Enable','on')
set(findobj(props.axpanel,'Visible','off'),'Visible','on')


delete(buf)
guidata(gcf,props)
set(allbut(isvalid(allbut)),'Enable','on');

function adjylim(hObject,eventdata)
props = guidata(hObject);
tag = hObject.Tag;

idx = str2double(tag(2:end));
ylim = props.ax(idx).YLim;
if tag(1)=='p'
    nylim = [ylim(1) + range(ylim)*0.15 , ylim(2) - range(ylim)*0.15];
elseif tag(1)=='m'
    nylim = [ylim(1) - range(ylim)*0.25 , ylim(2) + range(ylim)*0.25];
elseif tag(1)=='u'
    nylim = [ylim(1) + range(ylim)*0.1 , ylim(2) + range(ylim)*0.1];
elseif tag(1)=='d'
    nylim = [ylim(1) - range(ylim)*0.1 , ylim(2) - range(ylim)*0.1];
end
set(props.plt(str2double(tag(2:end))).Parent,'YLim',nylim)
guidata(gcf,props)

function decimateit(hObject,eventdata)
props = guidata(hObject);
guidata(hObject,props)

function edit_undo(hObject,eventdata)
props = guidata(hObject);
props.data = convert_uint(props.databackup, props.bd2uint, props.bmin, 'double');
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

function sortlist(hObject,eventdata)
props = guidata(hObject);
[~,sidx] = sort(props.showlist);
if contains(hObject.String,char(8595))
    sidx = flipud(sidx);
end
props.showlist = props.showlist(sidx);
props.showidx = props.showidx;
set(findobj('Tag','showgraph'),'String',props.showlist);
guidata(hObject,props)
plotdata(findobj('Tag',props.intan_tag))

function autoscale(hObject,eventdata)
it = findobj('Tag','grid');
buf = text(500,875,'Centering baseline...','FontSize',15,'Parent',it);
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.01)

props = guidata(hObject);
if contains(hObject.String,'x')
    ylims = {props.ax.YLim}';
    set(props.ax,'XLim',[0 max(props.ax(1).Children(1).XData)])
    for a=1:length(props.ax)
        props.ax(a).YLim = ylims{a};
    end
end
if contains(hObject.String,'y')
    set(props.ax,'YLimMode','auto')
end

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

function modtxt(hObject,eventdata)% should sort list but doesn't
props = guidata(hObject);
tags = ["showgraph","hidegraph"];
if hObject.String==char(8594)
    choose = props.hide;
else
    tags = fliplr(tags);
    choose = props.show;
end

olistobj = findobj(props.chpanel,'Tag',tags{2});
listobj = findobj(props.chpanel,'Tag',tags{1});

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
props.showlist = get(findobj(props.chpanel,'Tag','showgraph'),'String');
props.hidelist = get(findobj(props.chpanel,'Tag','hidegraph'),'String');
if strcmp(listobj.Tag,'showgraph')
    props.hideidx = [props.hideidx   props.showidx(choose)];
    props.showidx(choose) = [];
else
    props.showidx = [props.showidx   props.hideidx(choose)];
    props.hideidx(choose) = [];
end
guidata(hObject,props)
plotdata(hObject)
updateroi(hObject)

function selection(hObject,eventdata)
props = guidata(hObject);
if strcmp(hObject.Tag,'showgraph')
    props.hide = hObject.Value;
else
    props.show = hObject.Value;
end
guidata(hObject,props)

function yaxis(hObject,eventdata)% turns on/off the y-axis
props = guidata(hObject);
tag = hObject.Tag;
if hObject.Value
    set(props.plt(str2double(tag(2:end))).Parent,'YTickMode','auto')
else
    set(props.plt(str2double(tag(2:end))).Parent,'YTick',[])
end

%% filtering methods
% Opens the app to filters the data
function filterit(hObject,eventdata)% main app for filtering data
props = guidata(hObject);
mfpos = get(findobj('Tag',props.intan_tag),'Position');
f2 = figure('MenuBar','None','Name','Filter Data','NumberTitle','off');
f2.Position = [mfpos(1:2)+200 500 600];
f2.Tag = ['filt_tag' num2str(randi(1e4,1))];


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(props.ch),1);
str(props.hideidx,2) = "gray";
str(:,4) = string(props.ch);
str = join(str,'');

meth = {'butter';'cheby1';'cheby2';'ellip'};

% default filter properties
filterp.meth = 'ellip';
filterp.fr = 0.1;
filterp.fatt = [40,40];
filterp.fpass = [1,50];
filterp.fstop = [0.1,1000];


uicontrol('Position',[400 565 100 20],'Style','text','String','Select channel');
uicontrol('Position',[400 40 100 530],'Style','listbox','Max',length(props.ch),...
    'Min',1,'String',str','Tag','channels');
uicontrol('Position',[400 10 100 20],'Style','pushbutton','String','Apply Filter','Callback',@applyfilter); 

uicontrol('Position',[20  575 60 20],'Style','text','String','Properties','HorizontalAlignment','left');
uicontrol('Position',[20  552 100 20],'Style','text','String','Filter type','HorizontalAlignment','right');
uicontrol('Position',[125 555 100 20],'Style','popupmenu','String',meth,'Tag','ftype','Callback',@fvalidate,...
          'Tag','fmeth','Value',find(ismember(meth,filterp.meth)));

bg = uibuttongroup('Visible','off','Units','Pixels','Position',[60 510 200 40],'SelectionChangedFcn',@bpass,'Tag','fband');

uicontrol(bg,'Style','text',       'Position',[10  13 60 20],'String','Lowpass','HandleVisibility','off');
uicontrol(bg,'Style','text',       'Position',[70  13 60 20],'String','Bandpass','HandleVisibility','off');
uicontrol(bg,'Style','text',       'Position',[130 13 60 20],'String','Highpass','HandleVisibility','off');
uicontrol(bg,'Style','radiobutton','Position',[30  0 60 20],'HandleVisibility','off','Tag','lowpass');     
uicontrol(bg,'Style','radiobutton','Position',[90  0 60 20],'HandleVisibility','off','Tag','bandpass','Value',1);
uicontrol(bg,'Style','radiobutton','Position',[150 0 60 20],'HandleVisibility','off','Tag','highpass');
bg.Visible = 'on';

uicontrol('Position',[20  480 150 20],'Style','text','String','Filter Parameters','HorizontalAlignment','left');
uicontrol('Position',[20  457 100 20],'Style','text','String','Order','HorizontalAlignment','right',...
    'TooltipString','Number of times the data is passed through the filter.');
uicontrol('Position',[125 460 20 20],'Style','edit','String','1','Callback',@fvalidate,'Tag','forder','Enable','off');

uicontrol('Position',[20  432 100 20],'Style','text','String','Passband Ripple','HorizontalAlignment','right',...
    'TooltipString','Variation of amplitude within passband.');
uicontrol('Position',[125 435 40 20],'Style','edit','String',num2str(filterp.fr),'Tag','fripple','Callback',@fvalidate);

uicontrol('Position',[125 410 40 20],'Style','text','String','Lower');
uicontrol('Position',[170 410 40 20],'Style','text','String','Upper');

uicontrol('Position',[20  392 100 20],'Style','text','String','Attenuation','HorizontalAlignment','right',...
    'TooltipString','The amount of suppression outside passband.');
uicontrol('Position',[125 395 40 20],'Style','edit','String',num2str(filterp.fatt(1)),'Tag','fattlower','Callback',@fvalidate);
uicontrol('Position',[170 395 40 20],'Style','edit','String',num2str(filterp.fatt(2)),'Tag','fatthigher','Callback',@fvalidate);

uicontrol('Position',[20  367 100 20],'Style','text','String','Passband','HorizontalAlignment','right',...
    'TooltipString','The frequence range that is not attenuated.');
uicontrol('Position',[125 370 40 20],'Style','edit','String',num2str(filterp.fpass(1)),'Tag','fplower','Callback',@fvalidate);
uicontrol('Position',[170 370 40 20],'Style','edit','String',num2str(filterp.fpass(2)),'Tag','fphigher','Callback',@fvalidate);

uicontrol('Position',[20  342 100 20],'Style','text','String','Stopband','HorizontalAlignment','right',...
    'TooltipString','The frequency range beyond which is attenuated.');
uicontrol('Position',[125 345 40 20],'Style','edit','String',num2str(filterp.fstop(1)),'Tag','fslower','Callback',@fvalidate);
uicontrol('Position',[170 345 40 20],'Style','edit','String',num2str(filterp.fstop(2)),'Tag','fshigher','Callback',@fvalidate);

uicontrol('Position',[10  310 50 20],'Style','text','String','Preview','HorizontalAlignment','right');
pr = uicontrol('Position',[65  312 100 20],'Style','popupmenu','String',props.ch,'Callback',@fvalidate,'Tag','preview');

uicontrol('Position',[10  10 320 40],'Style','text','String','','HorizontalAlignment','center',...
    'ForegroundColor','r','Tag','errorcode');

ax = axes('Position',[50  70  320 220]./f2.Position([3 4 3 4]),'Tag','faxis');
plot(props.tm,props.data(props.showidx(1),:),'Tag','fdata');hold on
plot(props.tm,props.data(props.showidx(1),:),'Tag','fdata_filt');hold on
ax.Toolbar.Visible = 'on';

ax2 = axes('Position',[260 350 120 120]./f2.Position([3 4 3 4]),'Tag','fpaxis');
rectangle('FaceColor','r','Tag','fproprec');hold on
plot(nan(1,5),nan(1,5),'Tag','fpropline');hold on
ax2.Title.String = 'Filter Properties';
ax2.YLabel.String = 'dB';
ax2.XLabel.String = 'Frequency (Hz)';
ax2.XLim = [0 diff(props.tm(1:2))^-1/2];
ax2.XTick = [1 10 100 1000];
ax2.XScale = 'log';

guidata(f2,props)
bpass(bg)

function bpass(hObject,eventdata)% change available parameters based on passband type
type = get(hObject.SelectedObject,'Tag');
uil = findobj(hObject.Parent,'Tag','fattlower','-or',  'Tag','fplower','-or',  'Tag','fslower');
uih = findobj(hObject.Parent,'Tag','fatthigher','-or',  'Tag','fphigher','-or',   'Tag','fshigher');
switch type
    case 'lowpass'
        set(uil,'Visible','off')
        set(uih,'Visible','on')
    case 'bandpass'
        set(uil,'Visible','on')
        set(uih,'Visible','on')
    case 'highpass'
        set(uil,'Visible','on')
        set(uih,'Visible','off')
end
filterprops(hObject)
preview(hObject)
    
function filterprops(hObject)% displaying the properties of the filter
ax = findobj(hObject.Parent,'Tag','fpaxis');

fr = str2double(get(findobj(hObject.Parent,'Tag','fripple'),'String'));
fatt = [str2double(get(findobj(hObject.Parent,'Tag','fattlower'),'String')),...
        str2double(get(findobj(hObject.Parent,'Tag','fatthigher'),'String'))];
fpass = [str2double(get(findobj(hObject.Parent,'Tag','fplower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fphigher'),'String'))];
fstop = [str2double(get(findobj(hObject.Parent,'Tag','fslower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fshigher'),'String'))];

plt = findobj(hObject.Parent,'Tag','fpropline'); 
plt.XData = [0 fstop(1) fpass fstop(2) ax.XLim(2)];
rec = findobj(hObject.Parent,'Tag','fproprec');
     
hband = get(findobj(hObject.Parent,'Tag','fband'),'SelectedObject');
switch hband.Tag
    case 'lowpass'
        plt.YData = [0 0 0 0 -fatt([2 2])];
        rec.Position = [ax.XLim(1)+0.001   0   fpass(2)-ax.XLim(1)   fr];
    case 'bandpass'      
        plt.YData = [-fatt([1 1]) 0 0 -fatt([2 2])];
        rec.Position = [fpass(1)   0   diff(fpass)   fr];
    case 'highpass'
        plt.YData = [-fatt([1 1]) 0 0 0 0];
        rec.Position = [fpass(1)   0   ax.XLim(2)-fpass(1)   fr];
end

ax.YLim(2) = round(fr+10);

function applyfilter(hObject,eventdata)%<--- print out ignores lowpass highpass,   apply filter to data and close filter app
props = guidata(hObject);
hObject.String = 'Applying...';
hObject.BackgroundColor = [0.6 1 0.6];
pause(0.1)
idx = get(findobj(hObject.Parent,'Tag','channels'),'Value');

fr = str2double(get(findobj(hObject.Parent,'Tag','fripple'),'String'));
fatt = [str2double(get(findobj(hObject.Parent,'Tag','fattlower'),'String')),...
        str2double(get(findobj(hObject.Parent,'Tag','fatthigher'),'String'))];
fpass = [str2double(get(findobj(hObject.Parent,'Tag','fplower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fphigher'),'String'))];
fstop = [str2double(get(findobj(hObject.Parent,'Tag','fslower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fshigher'),'String'))]; 
meth =   get(findobj(hObject.Parent,'Tag','fmeth'),'String'); 
midx =   get(findobj(hObject.Parent,'Tag','fmeth'),'Value'); 
    
hband = get(findobj(hObject.Parent,'Tag','fband'),'SelectedObject');
switch hband.Tag
    case 'lowpass'
        h = fdesign.lowpass('Fp,Fst,Ap,Ast',  fpass(2), fstop(2), fr, fatt(2), diff(props.tm(1:2))^-1);
    case 'bandpass'      
        h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',  fstop(1), fpass(1), ...
            fpass(2), fstop(2), fatt(1), fr, fatt(2), diff(props.tm(1:2))^-1);
    case 'highpass'
        h = fdesign.highpass('Fst,Fp,Ast,Ap', fstop(1), fpass(1), fatt(1), fr, diff(props.tm(1:2))^-1);
end
Hd = design(h, meth{midx}, 'MatchExactly', 'passband', 'SOSScaleNorm', 'Linf');

fprintf(['\nfilter parameters\n',...
         'type\t'       meth{midx}            '\t' class(meth) '\n',...
         'ripple\t'      num2str(fr)   '\t' class(fr) '\n',...
         'attenuation\t' 'low\t' num2str(fatt(1)) '\thigh\t' num2str(fatt(2)) '\n',...
         'passband\t'    'low\t' num2str(fpass(1)) '\thigh\t' num2str(fpass(2)) '\n',...
         'stopband\t'    'low\t' num2str(fstop(1)) '\thigh\t' num2str(fstop(2)) '\n\n'])

filterp.fr = fr;
filterp.fatt = fatt;
filterp.fpass = fpass;
filterp.fstop = fstop;
filterp.meth = meth{midx};
filterp.idx = idx;

props.bmin = min(props.data,[],2);
props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16'); 


for d=idx
    disp(num2str(d))
    props.data(d,:) = filter(Hd,props.data(d,:));
end

if ~isfield(props,'filter')
    props.filter = filterp;
else
    props.filter(end+1) = filterp;
end

guidata(findobj('Tag',props.intan_tag),props)
close(hObject.Parent)
plotdata(findobj('Tag',props.intan_tag))

function preview(hObject,eventdata)% get a preview of the data to optimize filtering parameters

allbut = findobj(hObject.Parent,'Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
pause(0.1)

filterprops(hObject)
props = guidata(hObject);
plt1 = findobj(hObject.Parent,'Tag','fdata');
val = get(findobj(hObject.Parent,'Tag','preview'),'Value');
plt1.YData = props.data(val,:);

fr = str2double(get(findobj(hObject.Parent,'Tag','fripple'),'String'));
fatt = [str2double(get(findobj(hObject.Parent,'Tag','fattlower'),'String')),...
        str2double(get(findobj(hObject.Parent,'Tag','fatthigher'),'String'))];
fpass = [str2double(get(findobj(hObject.Parent,'Tag','fplower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fphigher'),'String'))];
fstop = [str2double(get(findobj(hObject.Parent,'Tag','fslower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fshigher'),'String'))]; 
meth =   get(findobj(hObject.Parent,'Tag','fmeth'),'String'); 
midx =   get(findobj(hObject.Parent,'Tag','fmeth'),'Value'); 
    
hband = get(findobj(hObject.Parent,'Tag','fband'),'SelectedObject');
switch hband.Tag
    case 'lowpass'
        h = fdesign.lowpass('Fp,Fst,Ap,Ast', fpass(2), fstop(2), fr, fatt(2), diff(props.tm(1:2))^-1);
    case 'bandpass'      
        h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', fstop(1), fpass(1), ...
            fpass(2), fstop(2), fatt(1), fr, fatt(2), diff(props.tm(1:2))^-1);
    case 'highpass'
        h = fdesign.highpass('Fst,Fp,Ast,Ap', fstop(1), fpass(1), fatt(1), fr, diff(props.tm(1:2))^-1);
end
try
    Hd = design(h, meth{midx}, 'MatchExactly', 'passband', 'SOSScaleNorm', 'Linf');
    plt2 = findobj(hObject.Parent,'Tag','fdata_filt');
    plt2.YData = filter(Hd,props.data(val,:));
    set(findobj(hObject.Parent,'Tag','errorcode'),'String','')
catch ME
    set(findobj(hObject.Parent,'Tag','errorcode'),'String',ME.message)
end

set(allbut,'Enable','on')

function fvalidate(hObject,eventdata)% validates the filtering prameters to prevent errors
fr = str2double(get(findobj(hObject.Parent,'Tag','fripple'),'String'));
fatt = [str2double(get(findobj(hObject.Parent,'Tag','fattlower'),'String')),...
        str2double(get(findobj(hObject.Parent,'Tag','fatthigher'),'String'))];
fpass = [str2double(get(findobj(hObject.Parent,'Tag','fplower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fphigher'),'String'))];
fstop = [str2double(get(findobj(hObject.Parent,'Tag','fslower'),'String')), ...
         str2double(get(findobj(hObject.Parent,'Tag','fshigher'),'String'))]; 
meth =   get(findobj(hObject.Parent,'Tag','fmeth'),'String'); 
midx =   get(findobj(hObject.Parent,'Tag','fmeth'),'Value'); 

if diff(fpass)<=0
    set(hObject,'ForegroundColor','r','TooltipString','Upper value must be greater than lower');
    return
end

if fpass(1) - fstop(1)<=0
    set(hObject,'ForegroundColor','r','TooltipString','Lower passband value must be greater than lower stopband');
    return
end

if fstop(2) - fpass(2)<=0
    set(hObject,'ForegroundColor','r','TooltipString','Upper stopband value must be greater than upper passband');
    return
end

obj = findobj(hObject.Parent,'Tag','fripple','-or','Tag','fattlower','-or','Tag','fatthigher','-or','Tag','fplower',...
    '-or','Tag','fphigher','-or','Tag','fslower','-or','Tag','fshigher');
set(obj,'ForegroundColor','k','TooltipString','')
preview(hObject)

%%
function xcorrelation(hObject,eventdata)% calculates the cross correlation of the channels shown
props = guidata(hObject);

win = 379;% window for calculating the cross correlation
nch = length(props.showidx);
showidx = props.showidx;
ch = props.ch;
idx = nchoosek(1:nch,2);
props.xcorr = nan(nch);
props.xcorr_lag = nan(nch);
props.xcorr_fulltrace = nan(length(idx),win*2+1);
signit = [1,-1];
sr = diff(props.tm([1 100]))/100*1000;

disp('running xcorr')
disp(['          ' repelem('_',round(length(idx)/10))])
fprintf('Progress: ')

for i=1:length(idx)
%     disp([num2str(i) ' of ' num2str(length(idx)) '    ' num2str(idx(i,1)) 'x' num2str(idx(i,2))])
    if mod(i,10)==0
        fprintf('|')
    end
    x = props.data(showidx(idx(i,1)),:)*signit(contains(props.ch(showidx(idx(i,1))),'V')+1);
    y = props.data(showidx(idx(i,2)),:)*signit(contains(props.ch(showidx(idx(i,2))),'V')+1);
    x(isnan(x)) = 0;
    y(isnan(y)) = 0;
%     x = abs(x);
%     y = abs(y);
%     x = decimate(x,20);
%     y = decimate(y,20);
    r = xcorr(x,y,win,'normalized');
    [val,id] = max(r);
    props.xcorr(idx(i,2),idx(i,1)) = val;
    props.xcorr(idx(i,1),idx(i,2)) = val;
    props.xcorr_lag(idx(i,2),idx(i,1)) = (id-win)*sr;
    props.xcorr_lag(idx(i,1),idx(i,2)) = (id-win)*sr;
    props.xcorr_fulltrace(i,:) = r;
end
fprintf(newline)

props.xcorr(find(eye(size(props.xcorr,1)))) = 1;
Z = linkage(props.xcorr);

figure('Position',[100 100 1108 782])

ax(2) = subplot(2,2,3);

ax(1) = axes('Position',[ax(2).Position(1) 0.45 0.28 0.2]);
[~,~,didx] = dendrogram(Z);
ax(1).Title.String = 'Correlation';
ax(1).XLim = [0.5 size(props.xcorr,1)+0.5];
ax(1).Color = 'none';

axes(ax(2))
imagesc(props.xcorr(didx,didx),'AlphaData', 1-isnan(props.xcorr))

% tcmap = [(0:0.02:2)', (0:0.01:1)' , (1:-0.01:0)'];
% tcmap(tcmap>1) = 1;
% lower = min(props.xcorr(:))/max(props.xcorr(:))*50;
% if lower>0
%     cmap = tcmap(50:end,:);
% else
%     cmap = tcmap(round(50-lower):end,:);
% end
% colormap(cmap)
colormap(parula)
caxis([0 0.6])
colorbar

ax(3) = subplot(2,2,4);
imagesc(props.xcorr_lag,'AlphaData', 1-isnan(props.xcorr_lag))
colorbar
set(ax,'YTick',1:length(props.showlist),'YTickLabel',props.showlist(didx),'XTick',1:length(props.showlist),'XTickLabel',props.showlist(didx),'XTickLabelRotation',90)
ax(1).XTick = [];
ax(1).YTick = [];
ax(3).Title.String = 'Time lag';

guidata(hObject,props)

function spiked(hObject,eventdata)% spike detection 
props = guidata(hObject);
spikedetection(props)

%% baseline app
function baseline(hObject,eventdata)
props = guidata(hObject);
% data can either be a 2D array or the structure properties from the intan
% GUI. Each row is each channel.  If array, then time can optionally be
% included as a second input.

ofigsize = props.figsize;
intan_tag = props.intan_tag;

apptag = ['apptag' num2str(randi(1e4,1))];
bfig = figure('Position',[ofigsize(1) ofigsize(4)*0.1+ofigsize(2) ofigsize(3) ofigsize(4)*0.7],...
    'Name','Remove Baseline','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Baseline tools');
mi(1) = uimenu(m,'Text','Open Parameters','Callback',@opensaveparams,'Enable','off','Tag','open');
mi(3) = uimenu(m,'Text','Save Parameters','Callback',@opensaveparams,'Enable','off','Tag','save');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');

ch = props.ch;
hideidx = props.hideidx;
showidx = props.showidx;
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Units','normalized','Position',[0.002 0.96 0.07 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.002 0.23 0.07 0.73],'Style','listbox',...
    'Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@chchannel);

cpanel = uipanel('Title','Controls','Units','normalized','FontSize',12,'Position',[0.75 0 0.25 1],'Tag','cpanel');
uicontrol(cpanel,'Units','normalized','Position',[0.31 0.8 0.1 0.05],'Style','edit',...
    'String','2','Callback',@fitequation,'Enable','on','TooltipString','Number of coefficients','Tag','coeff');
uicontrol(cpanel,'Units','normalized','Position',[0 0.79 0.3 0.05],'Style','text','String','Coefficients','HorizontalAlignment','right');

uicontrol(cpanel,'Units','normalized','Position',[0.60 0.9 0.3 0.05],'Style','text','String','Select channel');
uicontrol(cpanel,'Units','normalized','Position',[0.60 0.1 0.3 0.8],'Style','listbox','Max',length(ch),...
    'Min',1,'String',str','Tag','chapply');
uicontrol(cpanel,'Units','normalized','Position',[0.60 0.05 0.3 0.05],'Style','pushbutton','String','Apply','Callback',@applyrm); 


ax = axes('Position',[0.12 0.1 0.6 0.8]);
plt = plot(props.tm,props.data(showidx(1),:));hold on
splt = plot(props.tm,zeros(1,length(props.tm)));hold on

fun = makefun(3);

guidata(bfig,intan_tag)

[data,tm] = getdata(apptag);
ds = 20000;%downsample

opts = optimset('Display','off','Algorithm','levenberg-marquardt');
p0 = ones(1,15);
flimits = inf([1,15]);

fparam = lsqcurvefit(fun,p0,tm(1:ds:end),data(1:ds:end),-flimits,flimits,opts);

fplt = plot(props.tm,fun(fparam,props.tm));

ax.YLim = [min(data) max(data)];

props.blapp = struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                    'fplt',fplt,        'fun',fun,...
                    'p0',p0,            'flimits',flimits,   'tm',tm,...
                    'splt',splt,        'intan_tag',intan_tag);
guidata(hObject,props)

function chchannel(hObject,eventdata)
intan_tag = guidata(hObject);
props = guidata(findobj('Tag',intan_tag));
idx = get(findobj(hObject,'Tag','channels'),'Value');
set(props.blapp.plt,'YData',props.data(idx,:))
fitequation(hObject)

function [fun] = makefun(coef)
estr = 'fun = @(p,x) 0 ';
for c=1:2:coef*2
    str = sprintf('+ p(%i).*(1 - exp((x - p(1))./-p(%i)))',c+1,c+2);
    estr = [estr, str];
end
estr = [estr, ';'];
eval(estr);

function [data,tm] = getdata(apptag)
fig = findobj('Tag',apptag);
idx = get(findobj(fig,'Tag','channels'),'Value');
intan_tag = guidata(fig);
props = guidata(findobj('Tag',intan_tag));
tm = props.tm;
data = props.data(idx,:);
data(isnan(data)) = 0;
tm(data(:)==data(1)) = [];
data(:,data(:)==data(1)) = [];

function fitequation(hObject,eventdata)
intan_tag = guidata(hObject);
if nargin==2% for when function is called by the coeffient uicontrol
    fig = hObject.Parent.Parent;
else
    fig = hObject.Parent;
end
props = guidata(findobj('Tag',intan_tag));
disp('fitting')
buf = uicontrol(fig,'Units','normalized','Position',[0.3 , 0.9, 0.4 0.1],...
    'Style','text','String','Fitting...','FontSize',15);
pause(0.1)

idx = get(findobj(fig,'Tag','channels'),'Value');
coef = str2double(get(findobj(fig,'Tag','coeff'),'String'));
props.blapp.fun = makefun(coef);

tm = props.tm;
data = props.data(idx,:);
data(isnan(data)) = 0;
tm(data(:)==data(1)) = [];
data(:,data(end,:)==data(end,1)) = [];
flimits = props.blapp.flimits;
p0 = props.blapp.p0;
fun = props.blapp.fun;

opts = optimset('Display','off','Algorithm','levenberg-marquardt');
ds = 20000;%downsample
tic
fparam = lsqcurvefit(fun, p0, tm(1:ds:end), data(1:ds:end),-flimits, flimits,opts);
toc
disp(num2str(256^2*toc/60))
set(props.blapp.fplt,'YData',props.blapp.fun(fparam,props.tm))
sdata = props.data(idx,:) - props.blapp.fun(fparam,props.tm);
sdata(props.tm<1) = sdata(find(props.tm>=1,1)); 
set(props.blapp.splt,'YData',sdata)
set(props.blapp.ax,'YLim',[min(props.data(idx,:)) max(sdata)])
disp('plotted')
guidata(findobj('Tag',intan_tag),props)
delete(buf)

function applyrm(hObject,eventdata)
intan_tag = guidata(hObject);
props = guidata(findobj('Tag',intan_tag));
panel = hObject.Parent;
hObject.String = 'Applying...';
hObject.BackgroundColor = [0.6 1 0.6];
pause(0.1)
idx = get(findobj(panel,'Tag','chapply'),'Value');
coef = str2double(get(findobj(panel,'Tag','coeff'),'String'));
fun = makefun(coef);

flimits = props.blapp.flimits;
p0 = props.blapp.p0;

props.blapp.applyparam = nan(length(idx),15);
props.blapp.applyidx = idx;
props.blapp.fun = fun;
props.blapp.coef = coef;
opts = optimset('Display','off','Algorithm','levenberg-marquardt');
ds = 20000;%downsample

props.bmin = min(props.data,[],2);
props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16');

for i=1:length(idx)
    hObject.String = ['Applying..' num2str(i)];
    pause(0.1)

    tm = props.tm;
    data = props.data(idx(i),:);
    data(isnan(data)) = 0;
    tm(data(:)==data(1)) = [];
    data(:,data(end,:)==data(end,1)) = [];

    fparam = lsqcurvefit(fun, p0, tm(1:ds:end), data(1:ds:end), -flimits, flimits, opts);
    props.blapp.applyparam(i,:) = fparam;
    sdata = props.data(idx(i),:) - fun(fparam,props.tm);
    sdata(props.tm<1) = sdata(find(props.tm>=1,1)); 
    props.data(idx(i),:) = sdata;
end

guidata(findobj('Tag',intan_tag),props)
close(panel.Parent)
plotdata(findobj('Tag',intan_tag))

%% video
function videoprompt(hObject,eventdata)
props = guidata(hObject);
answ = 'No';
if isfield(props,'video')
    answ = questdlg('Use the current video data?');
end

if strcmp(answ,'Yes')
    video(hObject, diff(props.video.tm(1:2))*1000,false)
elseif strcmp(answ,'No')
    answ2 = inputdlg('Frame rate (ms)','Input',[1 35],{'20'});
    if ~isempty(answ2) && ~isempty(answ2{1})
        video(hObject,str2double(answ2),true)
    end
end

function video(hObject,fr,redo)
props = guidata(hObject);
ofigsize = props.figsize;

apptag = ['apptag' num2str(randi(1e4,1))];
vfig = figure('Position',[ofigsize(1) ofigsize(4)*0.1+ofigsize(2) ofigsize(3)*0.7 ofigsize(4)*0.7],...
    'Name','Make Video','NumberTitle','off','Tag',apptag);

guidata(vfig,props.intan_tag)

pax = axes('Units','normalized','Position',[10 0.05 0.25 0.05],'XTick',[],'YTick',[],'Box','on','Tag','progax');
prog = rectangle('Position',[0 0 0 1],'FaceColor','b','Tag','progress');
pax.XLim = [0 1];

uicontrol('Units','normalized','Position',[0.72 0.12 0.25 0.04],...
    'Style','text','Tag','progtxt','String',' ','Enable','on');

pause(0.1)

vsd = props.files(contains(props.files(:,2),'tsm'),2);



if redo
    [imdatas,fparam,fun,imdata,tm,imdataroi] = getimdata(vsd,1,vfig,fr);
    props.video.imdata = permute(imdatas,[2,1,3]);
    props.video.imdataroi = permute(imdataroi,[2,1,3]);
    props.video.tm = tm;% + diff(tm(1:2))*5;% don't know why this 5* needs to be done but it does
    props.video.fun = fun;
    props.video.fparam = fparam;
    props.video.reference = 1;
end


figure(vfig)
% props.video.tm = props.video.tm + diff(props.video.tm(1:2))*5;
slidepos = 10;
sf = diff(props.video.tm(1:2));


iaxr = axes('Units','normalized','Position',[0.3 0.35 0.4 0.6],'Tag','imgax');
props.video.img = image(props.im);
iaxr.XTick = [];
iaxr.YTick = [];

iax = axes('Units','normalized','Position',[0.3 0.35 0.4 0.6],'Tag','imgax');
props.video.iax = iax;
iaxpos = iax.Position;
climv = [-0.02 0.02];
props.video.img = imagesc(props.video.imdata(:,:,slidepos),'AlphaData',props.video.imdata(:,:,slidepos)>climv(1));
caxis(iax, climv)
props.video.climv = climv;
iax.Tag = 'imgax';

iax.XTick = [];
iax.YTick = [];
iax.Color = 'none';


cb = colorbar('Units','normalized','Position',[0.7 0.35 0.01 0.6]);
cb.Label.String = '-\DeltaF/F';

corridx = find(contains(props.ch,'V-'),1) - 1;
for r=1:2
    strv = props.showlist(r);
    idx = props.showidx(r) - corridx;
    if contains(strv,'V-')
        props.video.roi(r) = text(iax,props.kern_center(idx,1),...
            props.kern_center(idx,2), num2str(idx),'Color','k',...
            'HorizontalAlignment','center', 'Clipping','on','Tag',['rois' num2str(r)]);
    else
        props.video.roi(r) = text(iax,1,1, ' ','Color','k',...
            'HorizontalAlignment','center', 'Clipping','on','Tag',['rois' num2str(r)]);
    end
end


idur = size(props.video.imdata,3);
uicontrol('Units','normalized','Position',[iaxpos(1) iaxpos(2)-0.03 iaxpos(3) 0.03],...
    'Style','slider','Value',slidepos,'Min',1,'Max',idur,...
    'SliderStep',[1 1]/idur,'Callback',@chframe,'Tag','imslider');

uicontrol('Units','normalized','Position',[iaxpos(1) sum(iaxpos([2 4])) 0.03 0.03],...
    'Style','togglebutton','Tag','Raw','String','Raw','Callback',@raw,'Enable','on');

uicontrol('Units','normalized','Position',[iaxpos(1)+0.03 sum(iaxpos([2 4])) 0.04 0.03],...
    'Style','togglebutton','Tag','roivpix','String','Pixels','Callback',@roivpix,'Enable','on');

uicontrol('Units','normalized','Position',[sum(iaxpos([1 3]))-0.13 sum(iaxpos([2 4])) 0.05 0.03],'Style','togglebutton',...
    'Tag','invert','String','inverted','Value',1,'Callback',@invertim,'Enable','on');

xsize = size(props.video.imdata,2);
props.video.txtframe = text(xsize-85,10,sprintf('Frame: %i',slidepos),'FontSize',15,...
    'Color','w');
txttm = text(xsize-85, 25, sprintf('Time: %0.2f s',length(props.video.tm)*slidepos/idur*sf),...
    'FontSize',15,'Color','w');

props.video.txttm = txttm;


ax(1) = axes('Units','normalized','Position',[0.3 0.18 0.4 0.12]);
plt(1) = plot(props.tm,props.data(props.showidx(1),:),'Tag','plt1');
ax(1).YLabel.String = '\DeltaF/F';
ax(2) = axes('Units','normalized','Position',[0.3 0.06 0.4 0.12]);
plt(2) = plot(props.tm,props.data(props.showidx(2),:),'Tag','plt2');
set(ax,'XLim',[min(props.tm) max(props.tm)]);
ax(2).XLabel.String = 'Time (s)';
ax(2).YLabel.String = '\DeltaF/F';
ax(3) = axes('Units','normalized','Position',[0.3 0.06 0.4 0.24],'Color','none','Visible','off');
ref = rectangle('Position',[props.video.reference 0 sf 1],'FaceColor','k','Tag','ref');
rectangle('Position',[0 0 sf 1],'FaceColor',[0.5 1 0.5],'EdgeColor',[0.5 1 0.5],...
    'Tag','startframe1');
rectangle('Position',[max(props.video.tm) 0 sf 1],'FaceColor',[1 0.5 0.5],...
    'EdgeColor',[1 0.5 0.5],'Tag','stopframe1');
rectangle('Position',[0 0 sf 1],'FaceColor',[0.5 0.5 0.5],'Tag','cframe');
set(ax,'XLim',[min(props.tm) max(props.video.tm)]);
linkaxes(ax,'x')

ch = props.ch;
hideidx = props.hideidx;
showidx = props.showidx;
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');



uicontrol('Units','normalized','Position',[0.2 0.20 0.07 0.05],'Style','popupmenu',...
    'Max',length(ch),'Min',1,'String',str','Tag','channels1','Value',showidx(1),'Callback',@chimch);

uicontrol('Units','normalized','Position',[0.2 0.08 0.07 0.05],'Style','popupmenu',...
    'Max',length(ch),'Min',1,'String',str','Tag','channels2','Value',showidx(2),'Callback',@chimch);

uicontrol('Units','normalized','Position',[0.4 0.30 0.06 0.02],'Style','pushbutton',...
    'Tag','Raw','String','Set reference frame','Callback',@setreference,'Enable','on');


% ------------------------------
% colormap
% ------------------------------
uicontrol('Units','normalized','Position',[0.75 0.86 0.11 0.03],'Style','text',...
    'String','Colormap axis','HorizontalAlignment','center','Enable','on');

uicontrol('Units','normalized','Position',[0.8 0.76 0.06 0.03],'Style','edit',...
    'Tag','alphathr','String',num2str(climv(1)),'HorizontalAlignment','center',...
    'Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.74 0.745 0.05 0.05],'Style','text',...
    'String','Alpha threshold','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.8 0.80 0.06 0.03],'Style','edit',...
    'Tag','cmap1','String',num2str(climv(1)),'HorizontalAlignment','center',...
    'Callback',@setcmap,'Enable','on');

uicontrol('Units','normalized','Position',[0.75 0.795 0.04 0.03],'Style','text',...
    'String','lower','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.8 0.84 0.06 0.03],'Style','edit',...
    'Tag','cmap2','String',num2str(climv(2)),'HorizontalAlignment','center',...
    'Callback',@setcmap,'Enable','on');

uicontrol('Units','normalized','Position',[0.75 0.835 0.04 0.03],'Style','text',...
    'String','upper','HorizontalAlignment','right','Enable','on');


% ------------------------------
% ROI params
% ------------------------------
uicontrol('Units','normalized','Position',[0.75 0.70 0.04 0.03],'Style','text',...
    'String','text color','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.8 0.7 0.06 0.03],'Style','popupmenu',...
    'Max',5,'Min',1,'String',["black","white","red","green","blue"],'Tag','textcolor','Value',1,'Callback',@txtcolor);


% ------------------------------
% video params
% ------------------------------
uicontrol('Units','normalized','Position',[0.11 0.79 0.08 0.03],'Style','text',...
    'String','Frame interval (ms)','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.2 0.80 0.06 0.03],'Style','edit',...
    'Tag','framerate','String',num2str(fr),'HorizontalAlignment','center',...
    'Callback',@framerate,'Enable','on');



% ------------------------------
% movie parameters
% ------------------------------
uicontrol('Units','normalized','Position',[0.05 0.16 0.11 0.03],'Style','text',...
    'String','Video time window','HorizontalAlignment','center','Enable','on');

uicontrol('Units','normalized','Position',[0.1 0.33 0.06 0.03],'Style','edit',...
    'Tag','notegap','String','5','HorizontalAlignment',...
    'center','Enable','on');

uicontrol('Units','normalized','Position',[0.03 0.325 0.06 0.04],'Style','text',...
    'String','Minimum note gap (fr)','HorizontalAlignment','right','Enable','on',...
    'TooltipString','The minimum gap between notes');

uicontrol('Units','normalized','Position',[0.1 0.29 0.06 0.03],'Style','edit',...
    'Tag','harmonics','String','5','HorizontalAlignment',...
    'center','Enable','on');

uicontrol('Units','normalized','Position',[0.04 0.285 0.05 0.03],'Style','text',...
    'String','# harmonics','HorizontalAlignment','right','Enable','on',...
    'TooltipString','Number of harmonics for each note.  The greater the number the more like a piano');

uicontrol('Units','normalized','Position',[0.1 0.25 0.06 0.03],'Style','edit',...
    'Tag','noteduration','String','0.7','HorizontalAlignment',...
    'center','Enable','on');

uicontrol('Units','normalized','Position',[0.04 0.245 0.05 0.03],'Style','text',...
    'String','duration (s)','HorizontalAlignment','right','Enable','on',...
    'TooltipString','Duration of each note.');


uicontrol('Units','normalized','Position',[0.1 0.14 0.06 0.03],'Style','edit',...
    'Tag','startframe','String',num2str(min(props.video.tm)),'HorizontalAlignment',...
    'center','Callback',@startstop,'Enable','on');

uicontrol('Units','normalized','Position',[0.05 0.135 0.04 0.03],'Style','text',...
    'String','start (s)','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.1 0.10 0.06 0.03],'Style','edit',...
    'Tag','stopframe','String',num2str(max(props.video.tm)),'Callback',@startstop,...
    'HorizontalAlignment','center','Enable','on');

uicontrol('Units','normalized','Position',[0.05 0.09 0.04 0.03],'Style','text',...
    'String','stop (s)','HorizontalAlignment','right','Enable','on');


uicontrol('Units','normalized','Position',[0.1 0.19 0.06 0.03],'Style','edit',...
    'Tag','movfr','String','30','HorizontalAlignment',...
    'center','Callback',@startstop,'Enable','on');

uicontrol('Units','normalized','Position',[0.03 0.185 0.06 0.03],'Style','text',...
    'String','Frame rate (f/s)','HorizontalAlignment','right','Enable','on');





uicontrol('Units','normalized','Position',[0.05 0.05 0.1 0.04],'Style','pushbutton',...
    'String','Make Video','Callback',@makevideo,'Enable','on');


guidata(hObject,props)
chframe(findobj(vfig,'Tag','imslider'))


function roivpix(hObject,eventdata)
if hObject.Value
    hObject.String = 'ROI';
else
    hObject.String = 'Pixels';
end
chframe(findobj(hObject.Parent,'Tag','imslider'))

function startstop(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
disp([hObject.Tag '1'])
marker = findobj(hObject.Parent,'Tag',[hObject.Tag '1']);
newpos = str2double(hObject.String);
pos = marker.Position;
pos(1) = props.video.tm(find(props.video.tm>newpos,1));
set(marker,'Position',pos)

function txtcolor(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
color = hObject.String{hObject.Value};
for r=1:length(props.video.roi)
    if ~isa(props.video.roi(r), 'matlab.graphics.GraphicsPlaceholder')
        props.video.roi(r).Color = color;
    end
end

function makevideo(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
vsd = props.files(contains(props.files(:,2),'tsm'),2);

[file,path,indx] = uiputfile('*.mp4','Save Video',replace(vsd,'.tsm','_video.mp4'));
file = replace(file,'.mp4','');

vid = VideoWriter(fullfile(path,file),'MPEG-4');
vfr = str2double(get(findobj(hObject.Parent,'Tag','movfr'),'String'));
vid.FrameRate = vfr;
imslide = findobj(hObject.Parent,'Tag','imslider');

pos = get(findobj(hObject.Parent,'Tag','cframe'),'Position');
sr = diff(props.video.tm(1:2));

start = get(findobj(hObject.Parent,'Tag','startframe'),'String');
stop = get(findobj(hObject.Parent,'Tag','stopframe'),'String');
start = str2double(start);
stop = str2double(stop);
start = find(props.video.tm>start,1);
stop = find(props.video.tm>stop,1);
disp([start,stop])
alphathr = str2double(get(findobj(hObject.Parent,'Tag','alphathr'),'String'));
idur = length(props.video.tm);

det = props.det;
kernpos = props.kernpos;
nroi = length(kernpos);

sf = diff(props.video.tm(1:2));
fs = 44100;
audio = zeros(1,(stop-start)*fs/vfr);

ra = str2double(get(findobj(hObject.Parent,'Tag','notegap'),'String'));
dur = str2double(get(findobj(hObject.Parent,'Tag','noteduration'),'String'));
nharm = str2double(get(findobj(hObject.Parent,'Tag','harmonics'),'String'));

spike = false(stop-start,nroi);
for r=1:ra
    spike(ra,randi(nroi,[round(nroi/ra),1])) = true;
end

equalize = ones(1,nroi);
% equalize([8 63 35 29 74]) = 0.2;

roi = get(findobj(hObject.Parent,'Tag','roivpix'),'Value');
inv = get(findobj(hObject.Parent,'Tag','invert'),'Value')+1;
imult = [1,-1];

open(vid)
for f=start:stop
    framed = props.video.imdataroi(:,:,f)';
    fidx = f-start+1;
    aidx = (f-start+1) + (f-start)*fs/vfr;
    for k=1:length(kernpos)
        if fidx<size(spike,1) && fidx>ra && framed(det(kernpos(k)+5))>alphathr &&  ~any(spike(fidx-ra:fidx,k))
            spike(fidx,k) = true;
            freq = k*430/nroi+70;
            note = makesound(freq,dur,fs,nharm);
            jitter = randi(200);
            nidx = aidx:aidx+length(note)-1;
            nidx = nidx + jitter;
            nidx(nidx>length(audio)) = [];
            audio(nidx) = audio(nidx) + note(1:length(nidx))*equalize(k);
        end
    end

    if roi
        iframe = props.video.imdataroi(:,:,f)*imult(inv);
        set(props.video.img,'CData',iframe)
        set(props.video.img,'AlphaData',(iframe>alphathr)*0.7)
    else
        iframe = props.video.imdata(:,:,f)*imult(inv);
        set(props.video.img,'CData',iframe)
        set(props.video.img,'AlphaData',(iframe>alphathr))
    end

    pos(1) = props.video.tm(f);
    set(findobj(hObject.Parent,'Tag','cframe'),'Position',pos)
    set(imslide,'Value',f);
    props.video.txtframe.String = sprintf('Frame: %i',f);
    props.video.txttm.String = sprintf('Time: %0.2f s',(length(props.video.tm)*f/idur)*sf);
    
    pause(0.01)
    frame = getframe(gcf);
    writeVideo(vid,frame)
end
close(vid)
assignin('base','spike',spike)
audiowrite( fullfile(path,[file '.wav']), audio/max(audio), fs,'BitsPerSample',32)

function note = makesound(freq,dur,fs,nharm)
% distinguishable and pleasurable range 70 - 500 Hz
% recommended fs = 44100
tm = linspace(0,dur,round(dur*fs));
% freq = 2^(k/12)*262;
harmf = (1:nharm)*freq;
hamp = [1, 0.55, 0.23, 0.25, 0.1, 0.4];
fun = @(p,x) sin(x*pi*2*p);
note = zeros(size(tm));
for h=1:length(harmf)
    note = note + fun(harmf(h),tm)*hamp(h);
end
note = note.*(1-exp(-tm/(max(tm)/20))).*exp(-tm/(max(tm)/6));

function invertim(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
set(findobj(hObject.Parent,'Tag','progtxt'),'String','Processing...');
pause(0.1)
adjustdata(intan,hObject.Parent)
chframe(findobj(hObject.Parent,'Tag','imslider'))
set(findobj(hObject.Parent,'Tag','progtxt'),'String',' ');


function setcmap(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
imgax = findobj(hObject.Parent,'Tag','imgax');
idx = str2double(hObject.Tag(end));
axes(imgax)
vals = caxis;
vals(idx) = str2double(hObject.String);
caxis(imgax,vals)
props.video.climv = vals;
guidata(intan,props)

function raw(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
if hObject.Value
    set(props.video.img,'CData',props.im) 
    caxis(props.video.iax,'auto')
else
    frame = round(get(findobj(hObject.Parent,'Tag','imslider'),'Value'));
    set(props.video.img,'CData',props.video.imdata(:,:,frame))
    imgax = findobj(hObject.Parent,'Tag','imgax');
    caxis(imgax,props.video.climv)
%     caxis(props.video.iax,props.video.climv)
end

function framerate(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
vsd = props.files(contains(props.files(:,2),'tsm'),2);
ref = find(props.video.tm>props.video.reference,1);
[imdatas,fparam,fun,imdata,tm,imdataroi] = getimdata(vsd,ref,hObject.Parent);
props.video.imdata = permute(-imdatas,[2,1,3]);
props.video.imdataroi = permute(-imdataroi,[2,1,3]);
props.video.tm = tm + diff(tm(1:2))*5;% don't know why this 5* needs to be done but it does
props.video.fun = fun;
props.video.fparam = fparam;
props.video.reference = 0;

slider = findobj(hObject.Parent,'Tag','imslider');
set(slider,'Max',size(props.video.imdata,3))
set(slider,'SliderStep',[1 1]/size(props.video.imdata,3))

frame = round(get(findobj(hObject.Parent,'Tag','imslider'),'Value'));
roi = get(findobj(hObject.Parent,'roivpix'),'Value');
if roi
    set(props.video.img,'CData',props.video.imdataroi(:,:,frame))
    set(props.video.img,'AlphaData',props.video.imdataroi(:,:,frame)>alphathr)
else
    set(props.video.img,'CData',props.video.imdata(:,:,frame))
    set(props.video.img,'AlphaData',props.video.imdata(:,:,frame)>alphathr)
end
imgax = findobj(hObject.Parent,'Tag','imgax');
caxis(imgax,props.video.climv)


guidata(intan,props)

function [imdatas,fparam,fun,imdata,tm,imdatarois] = getimdata(vsd,ref,vfig,ifi)
warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(vsd);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

intan = findobj('Tag',guidata(vfig));
props = guidata(intan);

xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};

if nargin<4
    ifi = str2double(get(findobj(vfig,'Tag','framerate'),'String'));
end

interval = round(ifi/sr/1000);disp(interval)

frameLength = xsize*ysize*interval; % Frame length is the product of X and Y axis lengths;
hoffset = info.PrimaryData.Offset;

sidx = 6:interval:zsize;

imdata = zeros(length(sidx),ysize*xsize,'single');
imdataroi = imdata;

outp = round(size(imdata,1)/52);

progress = findobj(vfig,'Tag','progress');
set(findobj(vfig,'Tag','progtxt'),'String',['reading image file ' vsd{1}]);
set(findobj(vfig,'Tag','progax'),'Position',[0.72 0.05 0.25 0.05]);
pause(0.01)

fid = fopen(info.Filename,'r');
tic
kernpos = props.kernpos;
kerndata = zeros(length(sidx),length(kernpos));
det = props.det;
kernel_size = diff([kernpos ; length(det)])-1;
nprog = round(length(sidx)/200);
for s=1:length(sidx)
    offset = hoffset + ... Header information takes 2880 bytes.
                (sidx(s)-1)*xsize*ysize*2; % Because each integer takes two bytes.
    
    fseek(fid,offset,'bof');% Find target position on file.
    
    % Read data.
    fdata = fread(fid,frameLength,'int16=>single');%'int16=>double');% single saves about 25% processing time and requires half of memory 
   
    if length(fdata)<frameLength
        s = s - 1;
        break
    end

    fdata = reshape(fdata,[xsize*ysize interval]);

    imdata(s,:) = mean(fdata,2)';% Format data.
    
    for k=1:length(kernpos)
        kIdx = det(kernpos(k)+1:kernpos(k)+kernel_size(k));
        imdataroi(s,kIdx) = mean(imdata(s,kIdx));
        kerndata(s,k) = mean(imdata(s,kIdx));
    end

    if mod(s,nprog)==0
        set(progress,'Position',[0 0 s/(length(sidx)-1) 1]);pause(0.05)
    end
end
toc
fprintf('\n')
fclose(fid);

sidx = sidx(1:s);
imdata = imdata(1:s,:);
imdataroi = imdataroi(1:s,:);

if ref>size(imdata,3); ref = 1;end

f0 = repmat(imdata(ref,:),size(imdata,1),1);
imdata = (imdata - f0)./f0;

f0 = repmat(imdataroi(ref,:),size(imdataroi,1),1);
imdataroi = (imdataroi - f0)./f0;

fun = @(p,x) p(1).*(1 - exp(x./-p(2))) + p(3).*(1 - exp(x./-p(4))) + p(5).*(1 - exp(x./-p(6)));
% [fun] = makefun(3);
p0 = ones(1,6);
flimits = inf([1,6]);
opts = optimset('Display','off','Algorithm','levenberg-marquardt');

tm = ((sidx+5)*sr)';% for some reason I need to add five frames of time

set(findobj(vfig,'Tag','progtxt'),'String',['calculate pixel bleaching ' vsd{1}]);

imdatas = imdata;
fparam = nan(xsize*ysize,length(p0));

ds = round(800/interval);

tic
for p=1:size(imdata,2)
    pixd = double(imdata(1:ds:end,p));
    fparam(p,:) = lsqcurvefit(fun,p0,tm(1:ds:end),pixd,-flimits,flimits,opts);
    imdatas(:,p) = imdata(:,p) - fun(fparam(p,:),tm);
    if mod(p,500)==0%round(size(imdata,2)/52))==0
         set(progress,'Position',[0 0 p/size(imdata,2) 1]);pause(0.01)
    end
end
toc


set(findobj(vfig,'Tag','progtxt'),'String',['calculate ROI bleaching ' vsd{1}]);

imdatarois = imdataroi;
fparamr = nan(length(kernpos),length(p0));

tic
figure('Name','new');
for p=1:length(kernpos)
    kIdx = det(kernpos(p)+1:kernpos(p)+kernel_size(p));
    fparamr(p,:) = lsqcurvefit(fun,p0,tm(1:ds:end),kerndata(1:ds:end,k),-flimits,flimits,opts);
    imdatarois(:,kIdx) = repmat( kerndata(:,k) - fun(fparamr(p,:),tm), 1, length(kIdx));
    set(progress,'Position',[0 0 p/length(kernpos) 1]);pause(0.01)
end
toc

imdatas = reshape(imdatas',[256, 256, length(sidx)]);
imdatarois = reshape(imdatarois',[256, 256, length(sidx)]);

set(findobj(vfig,'Tag','progtxt'),'String',' ');
set(findobj(vfig,'Tag','progax'),'Position',[10 0.05 0.25 0.05]);
pause(0.01)

function chframe(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
frame = round(get(findobj(hObject.Parent,'Tag','imslider'),'Value'));
pos = get(findobj(hObject.Parent,'Tag','cframe'),'Position');
pos(1) = props.video.tm(frame);
set(findobj(hObject.Parent,'Tag','cframe'),'Position',pos)

alphathr = str2double(get(findobj(hObject.Parent,'Tag','alphathr'),'String'));

set(hObject,'Value',frame)
roi = get(findobj(hObject.Parent,'Tag','roivpix'),'Value');

inv = get(findobj(hObject.Parent,'Tag','invert'),'Value')+1;
imult = [1,-1];
if roi
    iframe = props.video.imdataroi(:,:,frame)*imult(inv);
    set(props.video.img,'CData',iframe)
    set(props.video.img,'AlphaData',(iframe>alphathr)*0.7)
else
    iframe = props.video.imdata(:,:,frame)*imult(inv);
    set(props.video.img,'CData',iframe)
    set(props.video.img,'AlphaData',(iframe>alphathr))
end
idur = size(props.video.imdataroi,3);
sf = diff(props.video.tm(1:2));
props.video.txtframe.String = sprintf('Frame: %i',frame);
props.video.txttm.String = sprintf('Time: %0.2f s',(length(props.video.tm)*frame/idur)*sf);
guidata(intan,props)

function chimch(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
idx = hObject.Value;
ax = findobj(hObject.Parent,'Tag',['plt' num2str(hObject.Tag(end))]);
set(ax,'YData',props.data(idx,:))
txt = findobj(hObject.Parent,'Tag',['rois' hObject.Tag(end)]);
corridx = find(contains(props.ch,'V-'),1) - 1;
if contains(props.ch(idx),'V-')
    set(txt,'String',num2str(idx-corridx),'Position',[props.kern_center(idx-corridx,1:2) 0])
else
    set(txt,'String',' ')
end

function setreference(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
[x,~] = ginput(1);

set(findobj(hObject.Parent,'Tag','progtxt'),'String','Processing...');

refr = find(props.video.tm>x,1);
ref = findobj(hObject.Parent,'Tag','ref');
ref.Position(1) = x;
pause(0.1)
adjustdata(intan,hObject.Parent)
chframe(findobj(hObject.Parent,'Tag','imslider'))
set(findobj(hObject.Parent,'Tag','progtxt'),'String',' ');


function adjustdata(intan,vfig)
props = guidata(intan);

pos = get(findobj(vfig,'Tag','ref'),'Position');
refr = find(props.video.tm>pos(1),1);
props.video.reference = pos(1);

f0 = props.video.imdata(:,:,refr);
props.video.imdata = props.video.imdata - repmat(f0,1,1,size(props.video.imdata,3));
f0 = props.video.imdataroi(:,:,refr);
props.video.imdataroi = props.video.imdataroi - repmat(f0,1,1,size(props.video.imdataroi,3));

guidata(intan,props)



%% vsd frame image and ROI methods

function updateroi(hObject,eventdata)

props = guidata(hObject);
a = 0.7;
b = 0.85;
c = 0.95;
props.color = [1    a   a;...
               a    1   a;...
               a    a   1;...
               1    b   b;...
               b    1   b;...
               b    b   1;...
               1    c   b;...
               c	1   b;...
               c    b   1;...
               1    b   c;...
               b    1   c;...
               b    c   1];


if ~isfield(props,'roi')
    if isfield(props,'kernpos')
        props.roi = gobjects(length(props.kernpos),1);% this seems unneccessary because of the delete statement below.
    else
        props.kernpos = [];
    end
end

if isfield(props,'roi')
    delete(props.roi)
end

roidx = props.showlist(contains(props.showlist,'V-'));
roidx = str2double(replace(roidx,'V-',''));

if get(findobj(props.ropanel,'Tag','fillroi'),'Value')
    im = props.im;
    R = im(:,:,1)';
    G = im(:,:,2)';
    B = im(:,:,3)';
    cnt = 1;
    for r = roidx'
        if r<length(props.kernpos)
            pix = props.det(props.kernpos(r):props.kernpos(r+1)-1);
        else
            pix = props.det(props.kernpos(r):length(props.det));
        end
        pix(pix==0) = [];


        cnt(cnt>size(props.color,1)) = 1; %#ok<AGROW>
        R(pix) = R(pix).*props.color(cnt,1); 
        G(pix) = G(pix).*props.color(cnt,2); 
        B(pix) = B(pix).*props.color(cnt,3); 
        cnt = cnt+1;

    end
    props.imsh.CData = cat(3,R',G',B');
else
    props.imsh.CData = props.im;
end
% props.imsh.Parent.XLim = [0 size(props.im,2)];
for r=1:length(props.kernpos)
    if any(roidx==r)
       props.roi(r) = text(props.imsh.Parent,props.kern_center(r,1),props.kern_center(r,2), ...
                num2str(r),'Color','k','HorizontalAlignment','center','Clipping','on');
    else
        delete(props.roi(r))
        props.roi(r) = gobjects(1);
    end
end

guidata(hObject,props)

function imhistogram(hObject,eventdata)
props = guidata(hObject);
vsd = props.finfo.files(contains(props.finfo.files(:,2),'tsm'),2);

warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(vsd);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};

frameLength = xsize*ysize;
sidx = round(linspace(1,zsize,10)');
% sidx = 0:10000:100000;
imdata = zeros(ysize,xsize,length(sidx));

fid = fopen(info.Filename,'r');
for s=1:length(sidx)
    offset = info.PrimaryData.Offset + ... Header information takes 2880 bytes.
                (sidx(s)-1)*frameLength*2; % Because each integer takes two bytes.    
    fseek(fid,offset,'bof');% Find target position on file.    
    fdata = fread(fid,frameLength,'int16=>double');%'int16=>double');% single saves about 25% processing time and requires half of memory 
    if length(fdata)<xsize*ysize
        break
    end
    fdata = reshape(fdata,[xsize ysize]);
    imdata(:,:,s) = flipud(rot90(fdata));
end
fclose(fid);

figure;
subplot(2,1,1)
colors = parula(length(sidx));
for h=1:length(sidx)
    histogram(imdata(:,:,h),'FaceColor',colors(h,:));hold on
end
legend(string((round(sidx*sr,2))'))

subplot(2,1,2)
ims = imtile(imdata);
imagesc(ims)

%% misc methods
function note(hObject,eventdata)
props = guidata(hObject);
props.notes.(hObject.Tag) = hObject.String;
guidata(hObject,props)

function saveit(hObject,eventdata)
props = guidata(hObject);
fidx = find(props.files(:,2)~="",1,'first');
nn = regexprep(props.files{fidx,2},'.(tif|mat|det|rhs|tsm|xlsx)','.mat');

[file,path,indx] = uiputfile(nn);

if ~file
    return
end

allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
buf = uicontrol('Position',[500,800,200, 40],'Style','text','String','Saving...','FontSize',15);
pause(0.01)

if ~isfield(props,'showlist')
    props.showlist = get(findobj('Tag','showgraph'),'String');
end

if ~isfield(props,'hidelist')
    props.hidelist = get(findobj('Tag','hidegraph'),'String');
end

fields = ["plt","txt","chk","ax"];
for f=1:length(fields)
    if isfield(props,fields{f})
        props = rmfield(props,fields{f});
    end
end

props.min = min(props.data,[],2);
props.d2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
props.data = convert_uint(props.data, props.d2uint, props.min, 'uint16');

if isfield(props,'video')
    min1 = min(props.video.imdata(:));
    d2uint1 = 2^16/range(props.video.imdata(:));
    imdata = uint16((props.video.imdata - min1)*d2uint1);
    tm = props.video.tm;
    fun = props.video.fun;
    fparam = props.video.fparam;
    reference = props.video.reference;
    climv = props.video.climv;

%     save(fullfile(path,replace(file,'.','_imdata.')),'minp','d2uint','imdata',...
%         'tm','fun','fparam','reference','climv')

    min2 = min(props.video.imdataroi(:));
    d2uint2 = 2^16/range(props.video.imdataroi(:));
    imdataroi = uint16((props.video.imdataroi - min2)*d2uint2);
%     save(fullfile(path,replace(file,'.','_imdata.')),'video')
    if numel(imdata)>1e9
        halfit = round(size(imdata,3)/2);
        imdata1 = imdata(:,:,1:halfit);
        imdata2 = imdata(:,:,halfit+1:end);
        save(fullfile(path,replace(file,'.','_imdata11.')),'min1','d2uint1',...
            'imdata1','tm','fun','fparam','reference','climv','halfit')
        save(fullfile(path,replace(file,'.','_imdata12.')),'min1','d2uint1',...
            'imdata2','tm','fun','fparam','reference','climv','halfit')
        imdataroi1 = imdataroi(:,:,1:halfit);
        imdataroi2 = imdataroi(:,:,halfit+1:end);
        save(fullfile(path,replace(file,'.','_imdata21.')),'min2','d2uint2',...
            'imdataroi1','tm','fun','fparam','reference','climv','halfit')
        save(fullfile(path,replace(file,'.','_imdata22.')),'min2','d2uint2',...
            'imdataroi2','tm','fun','fparam','reference','climv','halfit')
    else
        save(fullfile(path,replace(file,'.','_imdata.')),'min1','d2uint1','min2',...
            'd2uint2','imdata','imdataroi','tm','fun','fparam','reference','climv')
    end
end
props = rmfield(props,'video');

if isfield(props,'databackup')
    props.databackup = convert_uint(props.databackup, props.bd2uint, props.bmin, 'uint16');
end

names = fieldnames(props);
for n=1:length(names)
    if isa(props.(names{n}),'handle')
        props = rmfield(props,names{n});
    elseif strcmp(names(n),'video')
        vnames = fieldnames(props.video);
        for v=1:length(vnames)
            if isa(props.video.(vnames{v}),'handle')
                props.video = rmfield(props.video,vnames{v});
            end
        end
    end
end


save(fullfile(path,file),'props')
disp(['Saved ' fullfile(path,file)])

set(allbut,'Enable','on')
delete(buf)

function help(hObject,eventdata)
if exist('help_readme.txt','file')
    helptxt  = fileread('help_readme.txt');%keyboard% not the right text reading funcitons
    msgbox(helptxt)
else
    msgbox('help_readme.txt file not found')
end

function toworkspace(hObject,eventdata)
props = guidata(hObject);
assignin('base', 'out', props);
disp('sent to workplace as ''out''')