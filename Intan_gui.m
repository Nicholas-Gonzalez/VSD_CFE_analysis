function Intan_gui % main app

intan_tag = ['intan_tag' num2str(randi(1e4,1))];
f = figure('Position',[100 50 1700 900],'Name','Intan_Gui','NumberTitle','off','Tag',intan_tag);

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
mi(3) = uimenu(m,'Text','Save','Callback',@saveit,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@help,'Enable','on','Tag','help');

guidata(f,struct('show',[],'hide',[],'info',[],'recent',recent,'appfile',appfile,'mi',mi,'mn',m,...
                 'intan_tag',intan_tag))

% text(1000,860,'Show','Parent',it)
uicontrol('Position',[1000 845 40 20],'Style','text','String','Show')
uicontrol('Position',[1000 380 100 470],'Style','listbox','Max',1,'Min',1,...
              'Callback',@selection,'String',"",'Tag','showgraph');
uicontrol('Position',[1060 850 40 20],'Style','pushbutton','Tag','showsort',...
              'Callback',@sortlist,'String',[char(8595) 'sort'],'Enable','off');

% text(1150,860,'Hide','Parent',it)
uicontrol('Position',[1150 845 40 20],'Style','text','String','Hide')
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
              'Callback',@remove_artifact,'String','Remove Artifact','Enable','off',...
              'TooltipString','Attempts to remove artifact by stimulation.  Sometimes it is not effective');
uicontrol('Position',[1110 330 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@edit_undo,'String','Edit undo','Enable','off');
uicontrol('Position',[1110 310 100 20],'Style','pushbutton','Tag','adjust_not_finished',...
              'Callback',@decimateit,'String','Reduce sampling','Enable','off',...
              'TooltipString','Reduces the number or samples by half using the decimate function');
uicontrol('Position',[1110 290 100 20],'Style','pushbutton','Tag','filter',...
              'Callback',@filterit,'String','Filter','Enable','off',...
              'Tag','filter','TooltipString','Filters the data');
uicontrol('Position',[1220 350 100 20],'Style','pushbutton','Tag','adjust',...
              'Callback',@xcorrelation,'String','XCorr','Enable','off',...
              'Tag','filter','TooltipString','Calculates the cross correlation');
     
uicontrol('Position',[1110 50 100 40],'Style','pushbutton','Tag','plotagain',...
              'Callback',@loadplotwidgets,'String','Plot again','Enable','off',...
              'Tag','filter','TooltipString','Plots the data again');

uicontrol('Position',[2 860 40 40],'Style','text','String','show y-axis','Tag','yaxis_label')        
% text(2, 860,["show","y-axis"],'Visible','off','Tag','yaxis_label')

% VSD widgets
uicontrol('Position', [1270 430 40 20],'Style','togglebutton','Value',1,'Tag','fillroi',...
            'Callback',@updateroi,'String','fill roi','Enable','off','Visible','off','ForegroundColor','w')

%% loading methods
% This is the app that loads that data into the guidata
function loadapp(hObject,eventdata)
f2 = figure('MenuBar','None','Name','Open File','NumberTitle','off');
f2.Position(3:4) = [540 300];


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
vsdprops.matprops.Max = matprops.props.Max;
vsdprops.matprops.tm = matprops.props.tm;
vsdprops.matprops.ch = matprops.props.ch;
vsdprops.matprops.finfo = matprops.props.finfo;
vsdprops.matprops.im = matprops.props.im;
vsdprops.matprops.det = matprops.props.det;
vsdprops.matprops.kern_center = matprops.props.kern_center;
vsdprops.matprops.kernpos = matprops.props.kernpos;
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

fex = arrayfun(@exist,vsdprops.files(:,2));
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
            [data,tm,info] = extractTSM(tsm,det);
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
        [data, vsdprops.intan.tm, stim, ~, notes, amplifier_channels] = read_Intan_RHS2000_file(rfn);

        vsdprops.intan.data = [data;stim];
        
        sz = size(vsdprops.intan.data);
        vsdprops.intan.min = min(vsdprops.intan.data,[],2);
        vsdprops.intan.d2uint = repelem(2^16,sz(1),1)./range(vsdprops.intan.data,2);
        vsdprops.intan.data = convert_uint(vsdprops.intan.data, vsdprops.intan.d2uint, vsdprops.intan.min,'uint16');

        vsdprops.intan.ch = [string({amplifier_channels.native_channel_name})';...
                    join([string((1:size(data,1))'), repelem(" stim(uA)",size(data,1),1)])];
        [path,file] = fileparts(rfn);

        vsdprops.intan.finfo.file = file;
        vsdprops.intan.finfo.path = path;
        vsdprops.intan.finfo.duration = max(vsdprops.intan.tm);
        finfo = dir(rfn);
        vsdprops.intan.finfo.date = finfo.date;
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
if ~isempty(str)
    msgbox(["The following files are not loaded because not found.  Please change file name or unselect the file."; str])
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
            props.im = vsdprops.matprops.im;
            props.det = vsdprops.matprops.det;
            props.kern_center = vsdprops.matprops.kern_center;
            props.kernpos = vsdprops.matprops.kernpos;
            vsdprops.intan = vsdprops.matprops.intan;
            vsdprops.vsd = vsdprops.matprops.vsd;
        end
    end
    props.files = vsdprops.files;
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
    props.data = vsdprops.intan.data;
    props.finfo = vsdprops.intan.finfo;
    props.finfo.files = vsdprops.files;
    props.notes = struct('note1',"",'note2',"",'note3',"");
    props.im = ones(512,512,3);
end
try vsdprops = rmfield(vsdprops,'matprops'); end %#ok<TRYNC>

props.vsdprops = vsdprops;
props.newim = true;
if isfield(vsdprops,'im')
    props.im = vsdprops.im;
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

if exist(fstr,'file') 
    set(fph,'String', 'found', 'ForegroundColor','k')
else
    set(fph, 'String','not found', 'ForegroundColor','r')
end

function getvsdfile(hObject,eventdata)
vsdprops = guidata(hObject);
[file, path, id] = uigetfile(['C:\Users\cneveu\Desktop\Data\*.' hObject.Tag(1:end-2)],'Select file');
if ~file;return;end
vsdprops.files(vsdprops.files(:,1)==string([hObject.Tag 's']),2) = fullfile(path,file);
guidata(hObject,vsdprops);
guessfiles(hObject,fullfile(path,file))

function guessfiles(hObject,fname)
vsdprops = guidata(hObject);
[fpath,fn,~] = fileparts(fname);
fn = replace(fn,'_frame','');

strs = ["tiffns"   ,"detfns","tsmfns","rhsfns","xlsxfns";...
        "_frame.tif",".det" ,".tsm"  ,".rhs",".xlsx"];

    
dfolder = dir(fullfile(fpath));
fnames = string({dfolder.name});
for s=1:size(strs,2)
    chk = isempty(get(findobj(hObject.Parent,'Tag',strs{1,s}),'String'));
    fns = fullfile(fpath,[fn strs{2,s}]);
    if chk && exist(fns,'file')
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns);
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

slistobj = findobj(hObject.Parent,'Tag','showgraph');
slistobj.String = props.showlist;
slistobj.Max = length(props.showlist);
hlistobj = findobj(hObject.Parent,'Tag','hidegraph');
hlistobj.String = props.hidelist;
hlistobj.Max = length(props.hidelist);


if isfield(props,'info')
    if any(isgraphics(props.info),'all')
        delete(props.info)
    end
    props = rmfield(props, 'info');
end


% it = findobj('Tag','grid');
delete(findobj(hObject.Parent,'Tag','info'))
[~,name,ext] = fileparts(props.finfo.files{4,2});
props.info(1,1) = uicontrol('Style','text','Position',[990,240, 50,20],'String','RHS File:','Horizontal','right','Tag','info');
props.info(1,2) = uicontrol('Style','text','Position',[1050,240,220,20],'String',[name,ext],'Horizontal','left','Tag','info');

[folder,name,ext] = fileparts(props.finfo.files{3,2});
props.info(2,1) = uicontrol('Style','text','Position',[990,225, 50,20],'String','TSM File:','Horizontal','right','Tag','info');
props.info(2,2) = uicontrol('Style','text','Position',[1050,225,220,20],'String',[name,ext],'Horizontal','left','Tag','info');

props.info(3,1) = uicontrol('Style','text','Position',[990,210, 50,20],'String','Folder:','Horizontal','right','Tag','info');
props.info(3,2) = uicontrol('Style','text','Position',[1050,210, 220,20],'String',folder,'Horizontal','left','Tag','info');

props.info(4,1) = uicontrol('Style','text','Position',[990,195, 50,20],'String','Duration:','Horizontal','right','Tag','info');
props.info(4,2) = uicontrol('Style','text','Position',[1050,195, 220,20],'String',[num2str(props.finfo.duration) ' seconds'],'Horizontal','left','Tag','info');

% props.info(4,1) = text(1020,205,'# of Files:','Parent',it,'Horizontal','right','Tag','info');
% props.info(4,2) = text(1030,205,num2str(props.finfo.numfiles),'Parent',it,'Tag','info');

props.info(5,1) = uicontrol('Style','text','Position',[990,180, 50,20],'String','Date:','Horizontal','right','Tag','info');
props.info(5,2) = uicontrol('Style','text','Position',[1050,180, 220,20],'String',props.finfo.date,'Horizontal','left','Tag','info');

props.info(6,1) = uicontrol('Style','text','Position',[990,160, 50,20],'String','Note 1:','Horizontal','right','Tag','info');
props.info(6,2) = uicontrol('Position',[1050 160 220 20],'Style','edit','Tag','note1',...
              'Callback',@note,'String',props.notes.note1,'Horizontal','left');
          
props.info(7,1) = uicontrol('Style','text','Position',[990,140, 50,20],'String','Note 2:','Horizontal','right','Tag','info');
props.info(7,2) = uicontrol('Position',[1050 140 220 20],'Style','edit','Tag','note2',...
              'Callback',@note,'String',props.notes.note2,'Horizontal','left');
          
props.info(8,1) = uicontrol('Style','text','Position',[990,120, 50,20],'String','Note 3:','Horizontal','right','Tag','info');
props.info(8,2) = uicontrol('Position',[1050 120 220 20],'Style','edit','Tag','note3',...
              'Callback',@note,'String',props.notes.note3,'Horizontal','left');
props.info(9,2) = uicontrol('Style','text','Position',[1020,95,120,20],'String','Press enter to apply','Horizontal','left','Tag','info');

if props.newim
    delete(findobj(hObject.Parent,'Tag','roiax'))
    axes('Units','pixels','Position', [1270 450 400 400],'YTick',[],'XTick',[],'Box','on','Tag','roiax');
    if length(size(props.im))==3
        props.imsh = image(props.im);
    else
        props.im = repmat(props.im,1,1,3);
        props.imsh = image(props.im);
    end
    sz = size(props.im);
    set(props.imsh.Parent,'Units','pixels','Position', [1270 450 400 400*sz(1)/sz(2)],...
        'YTick',[],'XTick',[],'Box','on','Tag','roiax')
    props.newim = false;
end



if isfield(props,'im')
    set(findobj(hObject.Parent,'Tag','fillroi'),'Enable','on','Visible','on')
end
set(findobj(hObject.Parent,'Tag','savem'),'Enable','on');
set(findobj(hObject.Parent,'Tag','showgraph'),'Enable','on');
set(findobj(hObject.Parent,'Tag','hidegraph'),'Enable','on');
if isfield(props,'yaxis')
    set(props.yaxis,'Parent',hObject.Parent,'Enable','on')
end
set(findobj(hObject.Parent,'Tag','adjust'),'Enable','on')
set(findobj(hObject.Parent,'Tag','showsort'),'Enable','on')
set(findobj(hObject.Parent,'Tag','filter'),'Enable','on')

guidata(hObject,props)
updateroi(hObject)
set(allbut(isvalid(allbut)),'Enable','on')
plotdata(hObject)
% set(findobj(hObject.Parent,'Tag','fillroi'),'BackgroundColor',[0.2 0.2 0.2],'ForegroundColor',[1 1 1]);

function plotdata(hObject)
props = guidata(hObject);
% if isfield(props,'ax')
% %     delete(props.ax)
%     delete(props.txt)
%     delete(props.yaxis)
% end

set(findobj('Tag','yaxis_label'),'Visible','on')
allbut = findobj('Type','Uicontrol','Enable','on');
set(allbut,'Enable','off')
buf = uicontrol('Position',[500,800,200, 40],'Style','text','String','Plotting...','FontSize',15);
pause(0.1)


f = gcf;
data = props.data;

showstr = get(findobj(hObject.Parent,'Tag','showgraph'),'String');
idx = cellfun(@(x) find(strcmp(props.ch,x)),showstr);
nch = length(idx);

tm = props.tm;
gsize = f.Position(4) - 100;
posy = linspace(gsize - gsize/nch,0,nch) + 50;


if ~isfield(props,'plt')
    props.plt = gobjects(nch,1);
    props.ax = gobjects(nch,1);
    props.chk = gobjects(nch,1);
    props.txt = gobjects(nch,1);
    props.ylim.scplus = gobjects(nch,1);
    props.ylim.scminus = gobjects(nch,1);
    props.ylim.up = gobjects(nch,1);
    props.ylim.dwn = gobjects(nch,1);
end

if length(props.plt)>nch
    delete(props.plt(nch+1:end))
    delete(props.ax(nch+1:end))
    delete(props.ylim.scplus(nch+1:end))
    delete(props.ylim.scminus(nch+1:end))
    delete(props.ylim.up(nch+1:end))
    delete(props.ylim.dwn(nch+1:end))

    props.plt(~isvalid(props.plt)) = [];
    props.ax(~isvalid(props.ax)) = [];
    props.ylim.scplus(~isvalid(props.ylim.scplus)) = [];
    props.ylim.scminus(~isvalid(props.ylim.scminus)) = [];
    props.ylim.up(~isvalid(props.ylim.up)) = [];
    props.ylim.dwn(~isvalid(props.ylim.dwn)) = [];
    
    delete(props.chk(nch+1:end))
    delete(props.txt(nch+1:end))
    props.chk(~isvalid(props.chk)) = [];
    props.txt(~isvalid(props.txt)) = [];
elseif length(props.plt)<nch
    props.plt = [props.plt ; gobjects(nch-length(props.plt),1)];
    props.ax =  [props.ax ; gobjects(nch-length(props.plt),1)];
    props.chk = [props.chk; gobjects(nch-length(props.plt),1)];
    props.txt = [props.txt; gobjects(nch-length(props.plt),1)];

    props.ylim.scplus = [props.ylim.scplus; gobjects(nch-length(props.plt),1)];
    props.ylim.scminus = [props.ylim.scminus; gobjects(nch-length(props.plt),1)];
    props.ylim.up = [props.ylim.up; gobjects(nch-length(props.plt),1)];
    props.ylim.dwn = [props.ylim.dwn; gobjects(nch-length(props.plt),1)];
end
disp('plotting')

for d=1:nch
    chpos = posy(d) + gsize/nch/2 - 8;
    if ~isgraphics(props.plt(d))
        props.ax(d) = axes('Units','pixels','Position',[85   posy(d)   880   gsize/nch]);
        props.plt(d) = plot(tm,data(idx(d),:));
        props.chk(d) = uicontrol('Style','checkbox','Callback',@yaxis,'Value',false,'Position',[3 chpos  15 15],...
            'Value',false,'Visible','off','Tag',['c' num2str(d)]);
        props.txt(d) = uicontrol('Style','text','Position',[18 chpos  40 15],'String',props.showlist{d},'Visible','off','Tag',['t' num2str(d)]);
        props.ylim.scplus(d) = uicontrol('Style','pushbutton','Position',[965 chpos+8  15 15],'String','+','Callback',@adjylim,'Visible','off','Tag',['p' num2str(d)],'TooltipString','increase yscale');
        props.ylim.scminus(d) = uicontrol('Style','pushbutton','Position',[965 chpos-8  15 15],'String','-','Callback',@adjylim,'Visible','off','Tag',['m' num2str(d)],'TooltipString','decrease yscale');
        props.ylim.up(d) = uicontrol('Style','pushbutton','Position',[980 chpos+8  15 15],'String',char(708),'Callback',@adjylim,'Visible','off','Tag',['u' num2str(d)],'TooltipString','shift y-range up');
        props.ylim.dwn(d) = uicontrol('Style','pushbutton','Position',[980 chpos-8  15 15],'String',char(709),'Callback',@adjylim,'Visible','off','Tag',['d' num2str(d)],'TooltipString','shift y-range down');
    else
        props.ax(d) = props.plt(d).Parent;
        set(props.plt(d).Parent,'Units','pixels','Position',[85   posy(d)   880   gsize/nch])
        set(props.plt(d),'XData',tm,'YData',data(idx(d),:))
        
        set(props.chk(d),'Position',[3 chpos  15 15],'Value',false,'Visible','off');
        set(props.txt(d),'Position',[18 chpos  40 15],'String',props.showlist{d},'Visible','off');
        set(props.ylim.scplus(d),'Position',[965 chpos+8  15 15],'Visible','off');% I don't think i need to set string here.  I am removing.
        set(props.ylim.scminus(d),'Position',[965 chpos-8  15 15],'Visible','off');
        set(props.ylim.up(d),'Position',[980 chpos+8  15 15],'Visible','off');
        set(props.ylim.dwn(d),'Position',[980 chpos-8  15 15],'Visible','off');
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
    else
        set(props.plt(d).Parent,'XTickMode','auto','XTickLabelMode', 'auto');
    end
end 

set(props.ax,'YTick',[],'XLim',[0 max(tm)])% somehow is also modifying im, but only when loading new files, 05-23-22: not sure if this comment is still applicable
linkaxes(props.ax,'x')
set(findobj('Tag','adjust'),'Enable','on')
set(findobj('Tag','showsort'),'Enable','on')
set(findobj(hObject.Parent,'Visible','off'),'Visible','on')


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

function modtxt(hObject,eventdata)% should sort list but doesn't
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
filterp.fr = 2;
filterp.fatt = [60,60];
filterp.fpass = [15,50];
filterp.fstop = [0.1,100];


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
        h = fdesign.lowpass('Fp,Fst,Ap,Ast', fpass(2), fstop(2), fr, fatt(2), diff(props.tm(1:2))^-1);
    case 'bandpass'      
        h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', fstop(1), fpass(1), ...
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

win = 100;% window for calculating the cross correlation
nch = length(props.showidx);
showidx = props.showidx;
idx = nchoosek(1:nch,2);
props.xcorr = nan(nch);
props.xcorr_lag = nan(nch);
props.xcorr_fulltrace = nan(length(idx),win*2+1);

disp('running xcorr')
disp(['          ' repelem('_',round(length(idx)/10))])
fprintf('Progress: ')

for i=1:length(idx)
%     disp([num2str(i) ' of ' num2str(length(idx)) '    ' num2str(idx(i,1)) 'x' num2str(idx(i,2))])
    if mod(i,10)==0
        fprintf('|')
    end
    x = props.data(showidx(idx(i,1)),:);
    y = props.data(showidx(idx(i,2)),:);
    x(isnan(x)) = 0;
    y(isnan(y)) = 0;
    r = xcorr(x,y,win,'normalized');
    [val,id] = max(r);
    props.xcorr(idx(i,2),idx(i,1)) = val;
    props.xcorr_lag(idx(i,2),idx(i,1)) = id-win/2;
    props.xcorr_fulltrace(i,:) = r;
end

figure('Position',[400 500 1300 400])
ax(1) = subplot(1,2,1);
imagesc(props.xcorr,'AlphaData', 1-isnan(props.xcorr))

tcmap = [(0:0.02:2)', (0:0.01:1)' , (1:-0.01:0)'];
tcmap(tcmap>1) = 1;
lower = min(props.xcorr(:))/max(props.xcorr(:))*50;
if lower>0
    cmap = tcmap(50:end,:);
else
    cmap = tcmap(round(50-lower):end,:);
end
colormap(cmap)
colorbar
ax(1).Title.String = 'Correlation';
ax(2) = subplot(1,2,2);
imagesc(props.xcorr_lag,'AlphaData', 1-isnan(props.xcorr_lag))
colorbar
set(ax,'YTick',1:length(props.showlist),'YTickLabel',props.showlist,'XTick',1:length(props.showlist),'XTickLabel',props.showlist,'XTickLabelRotation',90)
ax(2).Title.String = 'Time lag';

guidata(hObject,props)

%% vsd frame image and ROI methods

function updateroi(hObject,eventdata)
% fillr = get(findobj(hObject.Parent,'Tag','fillroi'),'Value');
% if fillr
%     set(findobj(hObject.Parent,'Tag','fillroi'),'BackgroundColor',[0.2 0.2 0.2],'ForegroundColor',[1 1 1]);
% else
%    set(findobj(hObject.Parent,'Tag','fillroi'),'BackgroundColor',[0.8 0.8 0.8],'ForegroundColor','k');
% end

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

if get(findobj(hObject.Parent,'Tag','fillroi'),'Value')
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

if isfield(props,'databackup')
    props.databackup = convert_uint(props.databackup, props.bd2uint, props.bmin, 'uint16');
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