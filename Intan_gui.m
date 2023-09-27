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
mi(4) = uimenu(m,'Text','Average Image','Callback',@avgtsm,'Enable','on');
mi(5) = uimenu(m,'Text','Save','Callback',@saveit,'Enable','off','Tag','savem');
mi(6) = uimenu(m,'Text','Save BMP','Callback',@saveBMP,'Enable','off','Tag','savem');
mi(7) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');
mi(8) = uimenu(m,'Text','Print file log','Callback',@printlog,'Enable','off','Tag','savem');
mi(9) = uimenu(m,'Text','Help','Callback',@help,'Enable','on','Tag','help');

% ---- formatting parameters --------
fontsz = 10;

csz = [nan 300 figsize(3)*0.25];% size of ROI and channels
menusz = 90;
insz = 250;
% ----------------------------------
axpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[0                       10     figsize(3)-sum(csz(2:3)) figsize(4)-menusz ],'Title','','Tag','axpanel');
chpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-sum(csz(2:3)) insz   csz(2)                 figsize(4)-insz-menusz],'Title','channels','Tag','chpanel');
cmpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-sum(csz(2:3)) 0     sum(csz(2:3))-300       insz],'Title','Controls','Tag','cmpanel');
inpanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-300           0     300                     insz],'Title','File information','Tag','inpanel');
ropanel = uipanel('Units','pixels','FontSize',fontsz,'OuterPosition',[figsize(3)-csz(3)        insz   csz(3)                  figsize(4)-insz-menusz],'Title','ROI','Tag','ropanel');


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

uicontrol(cmpanel,'Units','normalized','Position',[0 0.9 0.19 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','autoscale xy','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.19 0.9 0.07 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','x','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.26 0.9 0.07 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@autoscale,'String','y','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.8 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@centerbl,'String','center zeros','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.7 0.165 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String',[char(8593) ' y-scale'],'Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.165 0.7 0.165 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@zoom,'String',[char(8595) ' y-scale'],'Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0 0.6 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@setylim,'String','set y-limits','Enable','off');

          
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.9 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@zero_region,'String','Zero region','Enable','off',...
              'TooltipString','zeros a region of data.  Sometimes it is not effective');
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.8 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@edit_undo,'String','Edit undo','Enable','off');
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.7 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@restore_channel,'String','Restore Channel','Enable','off',...
              'Tooltip','Restores data from a channel to the original');
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.6 0.33 0.1],'Style','pushbutton','Tag','adjust_not_finished',...
              'Callback',@decimateit,'String','Reduce sampling','Enable','off',...
              'TooltipString','Reduces the number or samples by half using the decimate function');
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.5 0.33 0.1],'Style','pushbutton','Tag','filter',...
              'Callback',@filterit,'String','Filter','Enable','off',...
              'Tag','filter','TooltipString','Filters the data');
uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.4 0.33 0.1],'Style','pushbutton','Tag','filter',...
              'Callback',@remove_artifact,'String','Remove artifact','Enable','off',...
              'Tag','filter','Tooltip','Removes stimulation artifact of data');


uicontrol(cmpanel,'Units','normalized','Position',[0.66 0.9 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@xcorrelation,'String','XCorr','Enable','off',...
              'Tag','filter','TooltipString','Calculates the cross correlation');
uicontrol(cmpanel,'Units','normalized','Position',[0.66 0.8 0.19 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@spiked,'String','spike detection','Enable','off',...
              'Tag','filter','Tooltip','detect spike activity in the traces');
uicontrol(cmpanel,'Units','normalized','Position',[0.85 0.8 0.07 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@plotspikes,'String','show','Enable','off',...
              'Tag','filter','Tooltip','Add spikes to the graphs');
uicontrol(cmpanel,'Units','normalized','Position',[0.92 0.8 0.07 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@plotspikes,'String','hide','Enable','off',...
              'Tag','filter','Tooltip','Add spikes to the graphs');
uicontrol(cmpanel,'Units','normalized','Position',[0.66 0.7 0.19 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@scalebar,'String','scale bar Add','Enable','off',...
              'Tag','filter','TooltipString','add scale bar');
uicontrol(cmpanel,'Units','normalized','Position',[0.85 0.7 0.14 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@scalebar,'String','Remove','Enable','off',...
              'Tag','filter','TooltipString','remove scale bar');
uicontrol(cmpanel,'Units','normalized','Position',[0.66 0.6 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@baseline,'String','remove baseline','Enable','off',...
              'Tag','filter','TooltipString','detect');
uicontrol(cmpanel,'Units','normalized','Position',[0.66 0.5 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@videoprompt,'String','Video','Enable','off',...
              'Tag','filter','TooltipString','generate a video of recording');

uicontrol(cmpanel,'Units','normalized','Position',[0 0.4 0.33 0.1],'Style','pushbutton','Tag','adjust',...
              'Callback',@imhistogram,'String','Image histogram','Enable','off',...
              'Tag','filter','Tooltip','Generates a histogram of the pixel intensities');


uicontrol(cmpanel,'Units','normalized','Position',[0.33 0.2 0.33 0.1],'Style','pushbutton','Tag','plotagain',...
              'Callback',@loadplotwidgets,'String','Plot again','Enable','off',...
              'Tag','filter','TooltipString','Plots the data again');



% ======== ROI panel ==========
uicontrol(ropanel,'Units','pixels','Position',[0 0 50 20],'Style','togglebutton','Value',1,'Tag','fillroi',...
            'Callback',@updateroi,'String','fill ROI','Enable','off','Visible','off','ForegroundColor','w')
uicontrol(ropanel,'Units','pixels','Position',[50 0 40 20],'Style','togglebutton','Value',1,'Tag','red',...
            'Callback',@updateroi,'String','Red','Enable','off','Visible','off','ForegroundColor','w')
uicontrol(ropanel,'Units','pixels','Position',[90 0 40 20],'Style','togglebutton','Value',1,'Tag','green',...
            'Callback',@updateroi,'String','Green','Enable','off','Visible','off','ForegroundColor','w')
uicontrol(ropanel,'Units','pixels','Position',[130 0 40 20],'Style','togglebutton','Value',1,'Tag','blue',...
            'Callback',@updateroi,'String','Blue','Enable','off','Visible','off','ForegroundColor','w')
uicontrol(ropanel,'Units','pixels','Position',[170 0 60 20],'Style','pushbutton','Tag','newim',...
            'Callback',@loadim,'String','Load Image','Enable','off','Visible','off')
uicontrol(ropanel,'Units','pixels','Position',[230 0 80 20],'Style','pushbutton','Tag','adjcont',...
            'Callback',@adjcontrast,'String','Contrast','Enable','off','Visible','off')

guidata(f,struct('show',[],'hide',[],'info',[],'recent',recent,'appfile',appfile,'mi',mi,'mn',m,...
                 'intan_tag',intan_tag,'axpanel',axpanel,'chpanel',chpanel,'cmpanel',cmpanel,'inpanel',inpanel,'ropanel',ropanel,'figsize',figsize))


function all_kframe(hObject,eventdata)
[fnames, fpath] = uigetfile('*.tsm',"MultiSelect",'on');
if length(fnames)>1
    props = guidata(hObject);
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
end

function avgtsm(hObject,eventdata)
[fnames, fpath] = uigetfile('*.tsm',"MultiSelect",'off');
file = fullfile(fpath,fnames);

pause(0.1)
if ischar(file)
    fig = figure('Name','Progress','NumberTitle','off');
    fig.Position(4) = 100;


    disp(['avgs   ',file])
    warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
    info = fitsinfo(file);
    warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')
    
    xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
    ysize = info.PrimaryData.Size(1);
    zsize = info.PrimaryData.Size(3); % Length of recording
    
    interval = 500;

    frameLength = xsize*ysize*interval; % Frame length is the product of X and Y axis lengths;
    hoffset = info.PrimaryData.Offset;
    
    sidx = 6:interval:zsize;
    
    im = zeros(ysize,xsize,length(sidx));
    
    ax = axes('YTick',[],'XTick',[],'Box','on','XLim',[0 1]);
    progress = rectangle('Position',[0 0 0 1],'FaceColor','b','Tag','progress');
    pause(0.01)
    
    fid = fopen(info.Filename,'r');
    tic
    nprog = round(length(sidx)/200);
    nprog(nprog==0) = 1;
    for s=1%:4%length(sidx)  Not sure why last frame section is junk.  Why is it ending prematurely
        offset = hoffset +  (sidx(s)-1)*xsize*ysize*2; % Because each integer takes two bytes.
        
        fseek(fid,offset,'bof');% Find target position on file.
        
        % Read data.
        fdata = fread(fid,frameLength,'int16=>single');%'int16=>double');% single saves about 25% processing time and requires half of memory 
       
        if length(fdata)<frameLength
            s = s - 1;
            break
        end   
        fdata = reshape(fdata,[xsize*ysize interval]);
        fdata = mean(fdata,2);
    
        im(:,:,s) = reshape(fdata,ysize,xsize)';% Format data.    
        if mod(s,nprog)==0
            set(progress,'Position',[0 0 s/(length(sidx)-1) 1]);pause(0.05)
        end
    end
    toc
    fclose(fid);
    im = mean(im,3);
    im = im/max(im(:));
    imwrite(im,replace(file,'.tsm','_average.tif'))
    close(fig)
end

function scalebar(hObject,eventdata)
props = guidata(hObject);
delete(findobj('Tag','scaleb'));
if contains(hObject.String,'Add')
    xlim = props.ax(1).XLim;
    pos = xlim(1)+range(xlim)*0.05;
    ylim = cell2mat(get(props.ax,'YLim'));
    idx = find(ylim(:,2)<2)';
    ylim(~idx) = [];
    sz = min(range(ylim,2))/2;
    sz = round(sz,1,'significant');
    for a = idx
        lw = props.ax(a).YLim(1);
        line(props.ax(a),[pos pos],[lw lw+sz],'Color','k','Tag','scaleb')
    end
    disp(['scale bar added with size ' num2str(sz)])
end

%% loading methods
% This is the app that loads that data into the guidata
function loadapp(hObject,eventdata)
props = guidata(hObject);
f2 = figure('MenuBar','None','Name','Open File','NumberTitle','off','DeleteFcn',@reenable);
intan = findobj('Tag',props.intan_tag);
f2.Position = [intan.Position(1:2)+intan.Position(3:4)/2 540 300];


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

uicontrol('Position',[230 10 20 20],'Style','checkbox','Tag','loadvid','Value',0);
uicontrol('Position',[250 8 60 20],'Style','text','String','Load video');

uicontrol('Position',[230 30 20 20],'Style','checkbox','Tag','warproi','Value',0);
uicontrol('Position',[250 28 60 20],'Style','text','String','Warp ROI');

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

function reenable(hObject,eventdata)
vsdprops = guidata(hObject);
set(vsdprops.allbut,'Enable','on')

function loadmat(hObject,eventdata)
vsdprops = guidata(hObject);
[file, path, id] = uigetfile('C:\Users\cneveu\Desktop\Data\*.mat','Select frame file');
if ~file;return;end
matprog = findobj('Tag','matprog');
set(matprog,'String','loading...','ForeGroundColor','b')
pause(0.1)
matprops = load(fullfile(path,file));
set(matprog,'String','loaded','ForeGroundColor','k')
if isfield(matprops.props.vsdprops,'intan')
    vsdprops.matprops.intan = matprops.props.vsdprops.intan;
end
if isfield(matprops.props.vsdprops,'intan')% this tempfix for some improperly saved files
    vsdprops.matprops.intan = matprops.props.vsdprops.intan;
elseif isfield(matprops.props,'intan')
    vsdprops.matprops.intan = matprops.props.intan;
end
% vsdprops.matprops.intan.data = vsdprops.matprops.intan.data;
if isfield(matprops.props.vsdprops,'vsd')% this tempfix for some improperly saved files
    vsdprops.matprops.vsd = matprops.props.vsdprops.vsd;
    vsdprops.matprops.vsd.tm = matprops.props.vsdprops.vsd.tm;
else
    vsdprops.matprops.vsd.data = matprops.props.vsd.data;
    vsdprops.matprops.vsd.tm = matprops.props.vsd.tm;
end
vsdprops.matprops.data = matprops.props.data;
vsdprops.matprops.min = matprops.props.min;
vsdprops.matprops.d2uint = matprops.props.d2uint;
vsdprops.matprops.showlist = matprops.props.showlist;
vsdprops.matprops.hidelist = matprops.props.hidelist;
vsdprops.matprops.showidx = matprops.props.showidx;
vsdprops.matprops.hideidx = matprops.props.hideidx;
vsdprops.matprops.notes = matprops.props.notes;
vsdprops.matprops.finfo = matprops.props.finfo;

fields = ["BMP_analysis","BMP","btype","rn","video","spikedetection","log","filter","databackup","bmin","bd2uint","imadj","note"];
for f=1:length(fields)
    if isfield(matprops.props,fields{f})
        if strcmp(fields{f},"BMP") || strcmp(fields{f},"btype") || strcmp(fields{f},"rn")
            vsdprops.matprops.BMP_analysis.(fields{f}) = matprops.props.(fields{f});
        else
            vsdprops.matprops.(fields{f}) = matprops.props.(fields{f});
        end
    elseif strcmp(fields{f},'imadj')
        vsdprops.matprops.imadj.imback = matprops.props.im;
        vsdprops.matprops.imadj.params = [0 1;0 1;0 1];
        vsdprops.matprops.imadj.params_back = [0 1;0 1;0 1];
    elseif strcmp(fields{f},'note')
        try
            vsdprops.matprops.note = string(readcell(matprops.props.vsdprops.files{5,2}));
            disp('Note.xlsx was not found in file.  Successfully loaded')
        catch
            warning([matprops.props.vsdprops.files{5,2} , 'not found'])
        end 
    end
end


vsdprops.matprops.Max = matprops.props.Max;
vsdprops.matprops.tm = matprops.props.tm;
vsdprops.matprops.ch = matprops.props.ch;

vsdprops.matprops.im = matprops.props.im;
vsdprops.matprops.det = matprops.props.det;
vsdprops.matprops.kern_center = matprops.props.kern_center;
vsdprops.matprops.kernpos = matprops.props.kernpos;
vsdprops.matprops.curdir = path;
vsdprops.files = matprops.props.files;

vid = get(findobj(hObject.Parent,'Tag','loadvid'),'Value')==1;
if vid
    imfn = fullfile(path,replace(file,'.','_imdata.'));
    if exist(imfn,'file')
        vsdprops.matprops.video = load(imfn);
    else
        imfn = fullfile(path,replace(file,'.','_imdata11.'));
        fieldname = ["imdata","imdataroi","imdatar"];
        for n=1:3
            p = 1;
            while 1==1
                imfn1 = replace(imfn,'imdata11.',['imdata' num2str(n) num2str(p) '.']);
                if ~exist(imfn1,'file'); break; end
                video1 = load(imfn1);     
                fields = {'climv','xlim','alphathr','ch','frame','instrumento','inv',...
                    ['d2uint' num2str(n)],'fparam','fun',['min' num2str(n)],'reference','tm','chunks'};
                if p==1
                    video.(fieldname{n}) = video1.([fieldname{n} 'p']);
                    if n==1
                        fields = [fields , 'kerndata'];
                    end
            
                    for f=1:length(fields)
                        video.(fields{f}) = video1.(fields{f});
                    end
                else
                    video.(fieldname{n}) = cat(3,video.(fieldname{n}), video1.([fieldname{n} 'p']));
                end
                disp(['loaded:   ' imfn1])
                p = p + 1;
            end
        end
        if exist('video','var')
            vsdprops.matprops.video = video;
        else
            warning(['No associated video file called ' imfn])
        end
    end
end

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
        fstr = split(fn,'; ');
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
        for f=1:3
            try
                imp = double(imread(vsdprops.files(vsdprops.files(:,1)=="tiffns",2),'Index',f));
                if f==1
                    im = zeros([size(imp) 3]);
                end
                im(:,:,f) = imp/max(imp,[],'all');
            catch
                im(:,:,f) = im(:,:,1);
            end
        end
        vsdprops.im = im;
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
            warproi = get(findobj(hObject.Parent,'Tag','warproi'),'Value');
            
            if ~warproi
                [data,tm,info,imdata,imtm,im] = extractTSM(tsm{1}, det,[],[],warproi);
            else
                directory = dir(fileparts(tsm{1}));
                filenms = string({directory.name}');
                framefile = filenms{arrayfun(@(x) ~isempty(regexp(x,'001_\d{2}-')),filenms)};
                framefile = fullfile(fileparts(tsm{1}),framefile);
                frame = open(framefile);
                disp(['found ' framefile])
                
                [data,tm,info,imdata,imtm,im,Dwarp,Dwall] = extractTSM(tsm{1}, det,[],[],warproi,frame.frame);

                rwstr = replace(tsm{1},'.tsm',  '_ROIwarp.tif');
                imwrite(imdata(:,:,:,1),rwstr)
                for i=2:size(imdata,4)
                    imwrite(imdata(:,:,:,i),rwstr,'WriteMode','append')
                end  

                save(replace(tsm{1},'.tsm',  '_ROIwarp.mat'), 'im','Dwarp','Dwall')
            end

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
        rfn = split(rfn,'; ');
        for r=1:length(rfn)
            if r==1
                [data, tm, stim, ~, notes, amplifier_channels, adc_channels , analog] = read_Intan_RHS2000_file(rfn{r});
            else
                [datap, tmp, stimp, ~,  ~, amplifier_channels, adc_channels , analogp] = read_Intan_RHS2000_file(rfn{r});
                data = [data, datap];
                tm = [tm, tmp];
                stim = [stim, stimp];
                analog = [analog, analogp];
            end
        end
        vsdprops.intan.tm = tm;
        
        if isempty(data)
            data = zeros(0,length(tm));
        end

        if isempty(stim)
            stim = zeros(0,length(tm));
        end

        vsdprops.intan.data = [data;stim;analog];

        sz = size(vsdprops.intan.data);
        vsdprops.intan.min = min(vsdprops.intan.data,[],2);
        vsdprops.intan.d2uint = repelem(2^16,sz(1),1)./range(vsdprops.intan.data,2);
        vsdprops.intan.data = convert_uint(vsdprops.intan.data, vsdprops.intan.d2uint, vsdprops.intan.min,'uint16');

        vsdprops.intan.ch = [string({amplifier_channels.native_channel_name})';...
                            string({adc_channels.native_channel_name})';...
                    join([string((1:size(data,1))'), repelem(" stim(uA)",size(data,1),1)])];
        [path,file] = fileparts(rfn);

        vsdprops.intan.finfo.file = join(file,'; ');
        vsdprops.intan.finfo.path = join(path,'; ');
        if isa(rfn,'cell')
            finfo = dir(rfn{1});
        end
        vsdprops.intan.finfo.date = finfo.date;
        vsdprops.intan.finfo.duration = max(vsdprops.intan.tm);
        
        if isfield(vsdprops,'note') && exist('det','var')
            [~, basefn, ~] = fileparts(det); 
            note1 = vsdprops.note(vsdprops.note(:,1)==basefn,3);
            nfn = fieldnames(notes);
            for n=1:length(nfn)
                if isempty(notes.(nfn{n}))
                    notes.(nfn{n}) = note1;
                    break
                end
            end
        end
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
if isfield(props,'spikedetection')
    props = rmfield(props,'spikedetection');
end

if isfield(props, 'BMP_analysis')
    props.BMP_analysis.BMP = zeros(0,3);
    props.BMP_analysis.spikes = zeros(0,8,0);
    props.BMP_analysis.btype = zeros(1,0);
    props.BMP_analysis.Rn = zeros(0,8);
end

intch = isfield(vsdprops,'intan') || (isfield(vsdprops,'matprops') && isfield(vsdprops.matprops,'intan'));
vsdch = isfield(vsdprops,'vsd') || (isfield(vsdprops,'matprops') && isfield(vsdprops.matprops,'vsd'));
if intch && vsdch
    if isfield(vsdprops,'intan')
        intan = convert_uint(vsdprops.intan.data(:,1:2:end), vsdprops.intan.d2uint, vsdprops.intan.min,'double');
        itm = vsdprops.intan.tm(1:2:end);
        if isfield(vsdprops,'vsd')
            vsd = convert_uint(vsdprops.vsd.data, vsdprops.vsd.d2uint, vsdprops.vsd.min,'double');
            props.vsd.d2uint = vsdprops.vsd.d2uint;
            props.vsd.min = vsdprops.vsd.min;
            tm = vsdprops.vsd.tm;
            if isfield(vsdprops.vsd,'fparam')
                props.fparam = vsdprops.vsd.fparam;
            end
        else
            vsd = convert_uint(vsdprops.matprops.vsd.data, vsdprops.matprops.vsd.d2uint,...
                vsdprops.matprops.vsd.min,'double');
            props.vsd.d2uint = vsdprops.matprops.vsd.d2uint;
            props.vsd.min = vsdprops.matprops.vsd.min;
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
        props.vsd.data = convert_uint(vsd,props.vsd.d2uint,props.vsd.min,'uint16');
        props.vsd.tm = vtm;
        vsd = interp1(vtm, vsd', itm);
        vsd = vsd';
        
        props.data = [intan ; vsd];
        if isfield(vsdprops,'note')
            for c=1:length(vsdprops.intan.ch)
                nstr = replace(vsdprops.intan.ch(c),'A-','A');
                idx = contains(vsdprops.note(:,1),nstr);
                if any(idx) && ~ismissing(vsdprops.note(idx,2))  
                    nsp = replace(vsdprops.intan.ch(c),'-0','');
                    nsp = replace(nsp,'ALOG-IN','');
                    vsdprops.intan.ch(c) = join([nsp vsdprops.note(idx,2)],'-');
                end
            end
        end
        props.intan = vsdprops.intan;
        props.BMP = zeros(0,3); 
        props.ch = [vsdprops.intan.ch ;  string([repelem('V-',size(vsd,1),1) num2str((1:size(vsd,1))','%03u')])];
        props.tm = itm;
        showidx = find(cellfun(@(x) ~contains(x,'stim'),props.ch));
        props.showlist = props.ch(showidx);
        props.showidx = showidx;
        hideidx = find(cellfun(@(x) contains(x,'stim'),props.ch));
        props.hidelist = props.ch(hideidx);
        props.hideidx = hideidx;
        props.Max = size(props.data,1);
        props.finfo = vsdprops.intan.finfo;
        props.finfo.files = vsdprops.files;
        props.notes = vsdprops.intan.notes;
        props.note = vsdprops.note;
        props.log = string(['loaded data on ',char(datetime)]);
        props.curdir = fileparts(vsdprops.files{1,2});
    else
        if isfield(vsdprops,'vsd')
            intan = convert_uint(vsdprops.matprops.intan.data, vsdprops.matprops.intan.d2uint,...
                vsdprops.matprops.intan.min, 'double');
            itm = vsdprops.matprops.intan.tm;  
            vsd = vsdprops.vsd.data;
            tm = vsdprops.vsd.tm;
            props.vsd.tm = vsdprops.vsd.tm;
            props.vsd.d2uint = vsdprops.vsd.d2uint;
            props.vsd.min = vsdprops.vsd.min;
            sr = diff(vsdprops.vsd.tm(1:2));
            vtm = min(itm):sr:max(itm);
            prsz = length(min(itm):sr:min(tm)-sr);
            posz = length(max(tm)+sr:sr:max(itm));
            vsd = [repmat(vsd(:,1),1,prsz),  vsd, repmat(vsd(:,end),1,posz)];

            props.vsd.data = vsd;
            props.vsd.tm = vtm;
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
            if isfield(vsdprops.matprops,'log')
                props.log = [vsdprops.matprops.log; string(['loaded data on ' char(datetime)])];
            else
                props.log = string(['loaded data on ',char(datetime)]);
            end
            if isfield(vsdprops.matprops,'note')
                props.note = vsdprops.matprops.note;
            end

            if isfield(vsdprops.matprops,'BMP_analysis')
                props.BMP_analysis.BMP = vsdprops.matprops.BMP_analysis.BMP;
            end

            if isfield(vsdprops.matprops,'video')
                props.video = vsdprops.matprops.video;disp('added video')
                fieldn = ["imdata","imdataroi","imdatar"];
                for f=1:length(fieldn)
                    if isfield(props.video,fieldn{f})
                        d2uint = vsdprops.matprops.video.(['d2uint' num2str(f)]);
                        minv = vsdprops.matprops.video.(['min' num2str(f)]);
                        props.video.(fieldn{f}) = double(props.video.(fieldn{f}))/d2uint + minv;
                    end
                end
            end
        else
            fields = fieldnames(vsdprops.matprops);

            fields(ismember(fields,{'video','data'})) = [];% set all fields
            for f=1:length(fields)
                props.(fields{f}) = vsdprops.matprops.(fields{f});
            end
%             if ~isfield(props,'imback')
%                 props.imback = props.im;
%             end

            if isfield(vsdprops.matprops,'BMP_analysis')
                props.BMP_analysis.BMP = vsdprops.matprops.BMP_analysis.BMP;
            else
                props.BMP_analysis.BMP = zeros(0,3);
            end

            props.finfo.files = vsdprops.files;
            props.data = convert_uint(vsdprops.matprops.data, props.d2uint, props.min,'double');

            if isfield(vsdprops.matprops,'log')
                props.log = [vsdprops.matprops.log; string(['loaded data on ' char(datetime)])];
            else
                props.log = string(['loaded data  ',char(datetime)]);
            end

            if isfield(vsdprops.matprops,'video')
                props.video = vsdprops.matprops.video;disp('added video')
                fieldn = ["imdata","imdataroi","imdatar"];
                for f=1:length(fieldn)
                    if isfield(props.video,fieldn{f})
                        d2uint = vsdprops.matprops.video.(['d2uint' num2str(f)]);
                        minv = vsdprops.matprops.video.(['min' num2str(f)]);
                        props.video.(fieldn{f}) = double(props.video.(fieldn{f}))/d2uint + minv;
                    end
                end
            end
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
    props.BMP_analysis.BMP = zeros(0,3);
    props.finfo.date = vsdprops.vsd.info.FileModDate;
    props.notes = struct('note1',"",'note2',"",'note3',"");
    props.log = string(['loaded data on ',char(datetime)]);
    props.curdir = fileparts(filename);
else
    if isfield(vsdprops,'note')
        for c=1:length(vsdprops.intan.ch)
            nstr = replace(vsdprops.intan.ch(c),'A-','A');
            idx = contains(vsdprops.note(:,1),nstr);
            if any(idx) && ~ismissing(vsdprops.note(idx,2))           
                nsp = replace(vsdprops.intan.ch(c),'-0','');
                nsp = replace(nsp,'ALOG-IN','');
                vsdprops.intan.ch(c) = join([nsp vsdprops.note(idx,2)],'-');
            end
        end
    end
    nch = length(vsdprops.intan.ch);
    props.ch = vsdprops.intan.ch;
    props.tm = vsdprops.intan.tm;
    props.showlist = vsdprops.intan.ch;
    props.showidx = 1:nch;
    props.hidelist = [];
    props.hideidx = [];
    props.BMP_analysis.BMP = zeros(0,3);
    props.data = convert_uint(vsdprops.intan.data, vsdprops.intan.d2uint, vsdprops.intan.min,'double');
    props.finfo = vsdprops.intan.finfo;
    props.finfo.files = vsdprops.files;
    props.notes = struct('note1',"",'note2',"",'note3',"");
    props.im = ones(512,512,3);
    props.log = string(['loaded data on ',char(datetime)]);
    props.curdir = fileparts(vsdprops.files{1,2});
end
props.files = vsdprops.files;
try vsdprops = rmfield(vsdprops,'matprops'); end %#ok<TRYNC>

props.vsdprops = vsdprops;
props.newim = true;

if isfield(vsdprops,'im')
    props.im = vsdprops.im;
    props.imadj.imback = vsdprops.im;
    props.imadj.params = [0 1;0 1;0 1];
end

if isfield(props,'sc')
    props = rmfield(props,'sc');
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

fstr = split(fstr,'; ');
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

for s=1:size(strs,2)
    chk = isempty(get(findobj(hObject.Parent,'Tag',strs{1,s}),'String'));
    fns = fullfile(fpath,[fn strs{2,s}]);
    if chk && exist(fns,'file')
        set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',fns);
    elseif chk && strs(1,s)=="rhsfns"
        noten = fullfile(fpath,'notes.xlsx');
        cfexist = false;
        if exist(noten,"file")
            notes = readcell(fullfile(fpath,'notes.xlsx'));
            cfename = notes{ismember(string(notes(:,1)),fn),2};
            if ~isempty(cfename)
                rfn = split(cfename,'; ');
                for r=1:length(rfn)
                    if any(contains(fnames,rfn{r}))
                       rfn{r} = fullfile(fpath,rfn{r},[rfn{r} '.rhs']);
                    else
                       for f=3:length(dfolder)
                           if dfolder(f).isdir
                                sf = dir(fullfile(dfolder(f).folder,dfolder(f).name));
                                idx = contains(string({sf.name}),rfn{r});
                                if any(idx)
                                    rfn{r} = fullfile(sf(idx).folder,sf(idx).name);break
                                end
                           end
                       end
                    end
                end
            end
            cfename = join(rfn,'; ');
            cfexist = true;
        end
        if cfexist
            set(findobj(hObject.Parent,'Tag',strs{1,s}),'String',cfename)
        end
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
    set(findobj(props.ropanel,'Tag','red'),'Enable','on','Visible','on')
    set(findobj(props.ropanel,'Tag','green'),'Enable','on','Visible','on')
    set(findobj(props.ropanel,'Tag','blue'),'Enable','on','Visible','on')
    set(findobj(props.ropanel,'Tag','newim'),'Enable','on','Visible','on')
    set(findobj(props.ropanel,'Tag','adjcont'),'Enable','on','Visible','on')
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

if isfield(props,'plt') && isgraphics(props.plt(1))
    props.ax(1).XLim = [min(props.plt(1).XData) max(props.plt(1).XData)];
end
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
buf = uicontrol(props.axpanel,'Units','pixels',...
    'Position',[props.axpanel.Position(3)/2, props.axpanel.Position(4)-60,200, 40],...
    'Style','text','String','Plotting...','FontSize',15);
pause(0.1)

data = props.data;

showstr = get(findobj(props.chpanel,'Tag','showgraph'),'String');
idx = cellfun(@(x) find(strcmp(props.ch,x)),showstr);
nch = length(idx);

tm = props.tm;
top = 60;
bottom = 50;
left = 85;
right = 30;
gsize = props.axpanel.Position(4) - (top + bottom);
posy = linspace(gsize - gsize/nch,0,nch) + bottom;

if isfield(props,'plt') && isgraphics(props.plt(1))
    xlim = props.ax(1).XLim;
else
    xlim = [min(tm), max(tm)];
end

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

% if isfield(props,'BMP_analysis') && isfield(props.BMP_analysis,'axbmp')
%     delete(props.BMP_analysis.axbmp)
%     delete(findobj(props.axpanel,'Tag','makeprot'))
%     delete(findobj(props.axpanel,'Tag','makeret'))
% end

delete(findobj(props.axpanel,'Tag','axbmp'))
delete(findobj(props.axpanel,'Tag','makeprot'))
delete(findobj(props.axpanel,'Tag','makern'))
keyboard
uicontrol(props.axpanel,'Units','pixels','Position',[5 max(posy)+gsize/nch+5 20 20],'Style','pushbutton',...
    'Callback',@makeBMP,'String','+','Tag','makeprot')
uicontrol(props.axpanel,'Units','pixels','Position',[5 max(posy)+gsize/nch+25 20 20],'Style','pushbutton',...
    'Callback',@selectRn,'String','Rn','Tag','makern')
props.BMP_analysis.axbmp = axes(props.axpanel,'Units','pixels','Position',[left   max(posy)+gsize/nch  props.axpanel.Position(3)-(right+left)  top-top/6],'Tag','axbmp');
props.BMP_analysis.axbmp.XTick = [];
props.BMP_analysis.axbmp.YTick = [1 2 3];
props.BMP_analysis.axbmp.YLim = [0 4.8];
props.BMP_analysis.axbmp.YTickLabel = ["Protraction","Retraction","Closure"];
props.BMP_analysis.axbmp.TickLength = [0 0];
if isfield(props,'BMP_analysis') && isfield(props.BMP_analysis,'BMP') && ~isempty(props.BMP_analysis.BMP)
    color = 'bg';
    phase = ["Prot","Retr"];
    for b=1:size(props.BMP_analysis.BMP,1)
        for p=1:2
            line(props.BMP_analysis.BMP(b,p:p+1) , [p p],'Color',color(p),'Tag',[phase{p} num2str(b)],'LineWidth',2);hold on
            sc(1) = scatter(props.BMP_analysis.BMP(b,p),  p,100,['|' color(p)],'LineWidth',2,'ButtonDownFcn',@adjustline,...
                'Tag',[phase{p} num2str(b) 's']);hold on
            sc(2) = scatter(props.BMP_analysis.BMP(b,p+1),p,100,['|' color(p)],'LineWidth',2,'ButtonDownFcn',@adjustline,...
                'Tag',[phase{p} num2str(b) 'e']);hold on
            pb.enterFcn = @(fig,currentPoint) set(fig,'Pointer','hand');
            pb.exitFcn = @(fig,currentPoint) set(fig,'Pointer','arrow');
            pb.traverseFcn = [];
            iptSetPointerBehavior(sc,pb);
            iptPointerManager(gcf)
        end
    end
    props = countspikes(props);
end
delete(findobj(props.axpanel,'Tag','move'))
uicontrol(props.axpanel,'Units','pixels','Position',[left-30 bottom 30 30],'Style','pushbutton',...
    'Callback',@moveleft,'String',char(8882),'Tag','move')
uicontrol(props.axpanel,'Units','pixels','Position',[props.axpanel.Position(3)-right bottom 30 30],'Style','pushbutton',...
    'Callback',@moveright,'String',char(8883),'Tag','move')

for d=1:nch
    chpos = posy(d) + gsize/nch/2 - 8;
    if ~isgraphics(props.plt(d))
        props.ax(d) = axes(props.axpanel,'Units','pixels','Position',[left   posy(d)   props.axpanel.Position(3)-(right+left)   gsize/nch]);
        props.plt(d) = plot(tm,data(idx(d),:));hold on
        props.chk(d) = uicontrol(props.axpanel,'Units','pixels','Style','checkbox','Callback',@yaxis,'Value',false,'Position',[3 chpos  15 15],...
            'Value',false,'Visible','off','Tag',['c' num2str(d)]);
        props.txt(d) = uicontrol(props.axpanel,'Units','pixels','Style','text','Position',[18 chpos  60 15],'String',props.showlist{d},'HorizontalAlignment','left','Visible','off','Tag',['t' num2str(d)]);
        props.ylim.scplus(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[ props.axpanel.Position(3)-right chpos+8  15 15],'String','+','Callback',@adjylim,'Visible','off','Tag',['p' num2str(d)],'TooltipString','increase yscale');
        props.ylim.scminus(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-right chpos-8  15 15],'String','-','Callback',@adjylim,'Visible','off','Tag',['m' num2str(d)],'TooltipString','decrease yscale');
        props.ylim.up(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-right/2 chpos+8  15 15],'String',char(708),'Callback',@adjylim,'Visible','off','Tag',['u' num2str(d)],'TooltipString','shift y-range up');
        props.ylim.dwn(d) = uicontrol(props.axpanel,'Units','pixels','Style','pushbutton','Position',[props.axpanel.Position(3)-right/2 chpos-8  15 15],'String',char(709),'Callback',@adjylim,'Visible','off','Tag',['d' num2str(d)],'TooltipString','shift y-range down');
    else
        props.ax(d) = props.plt(d).Parent;
        set(props.plt(d).Parent,'Units','pixels','Position',[left   posy(d)   props.axpanel.Position(3)-(right+left)   gsize/nch])
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

set(props.ax,'YTick',[],'XLim',xlim)% somehow is also modifying im, but only when loading new files, 05-23-22: not sure if this comment is still applicable
linkaxes([props.ax; props.BMP_analysis.axbmp],'x')
set(findobj(props.chpanel,'Tag','adjust'),'Enable','on')
set(findobj(props.chpanel,'Tag','showsort'),'Enable','on')
set(findobj(props.axpanel,'Visible','off'),'Visible','on')


delete(buf)
guidata(gcf,props)
set(allbut(isvalid(allbut)),'Enable','on');

function moveleft(hObject,eventdata)
props = guidata(hObject);
set(props.ax(1),'XLim',props.ax(1).XLim - range(props.ax(1).XLim)*0.7)

function moveright(hObject,eventdata)
props = guidata(hObject);
set(props.ax(1),'XLim',props.ax(1).XLim + range(props.ax(1).XLim)*0.7)

%% YLimit app
function setylim(hObject,eventdata)
validatech(hObject)
props = guidata(hObject);
aprops.intan_tag = props.intan_tag;

str = string(props.showlist);
YLim = get(props.ax,'YLim');
lw = zeros(size(YLim));
up = zeros(size(YLim));
for p=1:length(str)
    str{p} = [str{p} ' ' '[' num2str(YLim{p}) ']'];
    lw(p) = YLim{p}(1);
    up(p) = YLim{p}(2);
end
aprops.lw = lw;
aprops.up = up;

fig = figure('Name','Set Y-axis Limits','NumberTitle','off');
fig.Position(3:4) = [420 420];

uicontrol('Units','normalized','Position',[0.002 0.95 0.5 0.05],'Style','text','String','Select channel [cur lower, cur upper]');
uicontrol('Units','normalized','Position',[0.002 0.05 0.45 0.9],'Style','listbox',...
    'Max',length(str),'Min',1,'String',str,'Tag','channelslim','Value',1)


mlw = min(lw(lw>-1));
uicontrol('Units','normalized','Position',[0.5 0.95 0.15 0.05],'Style','text','String','Lower');
uicontrol('Units','normalized','Position',[0.5 0.9 0.15 0.05],'Style','edit',...
    'String',num2str(mlw),'Tag','lowerlim');
mup = max(up(up<1));
aprops.mlw = mlw;
aprops.mup = mup;
uicontrol('Units','normalized','Position',[0.65 0.95 0.15 0.05],'Style','text','String','Upper');
uicontrol('Units','normalized','Position',[0.65 0.90 0.15 0.05],'Style','edit',...
    'String',num2str(mup),'Tag','upperlim');
uicontrol('Units','normalized','Position',[0.8 0.90 0.15 0.05],'Style','pushbutton','String','Apply','Callback',@setlim);


uicontrol('Units','normalized','Position',[0.5 0.7  0.2 0.06],'Style','pushbutton','String','Auto (ind)','Callback',@autolimind);
uicontrol('Units','normalized','Position',[0.5 0.64 0.2 0.06],'Style','pushbutton','String','Auto (comb)','Callback',@autolimcomb);

uicontrol('Units','normalized','Position',[0.50 0.05 0.15 0.07],'Style','pushbutton','String','Reset','Callback',@resetval,'Tooltip','Reset values back to original');
uicontrol('Units','normalized','Position',[0.65 0.05 0.15 0.07],'Style','pushbutton','String','Keep','Callback',@closeit);
uicontrol('Units','normalized','Position',[0.80 0.05 0.15 0.07],'Style','pushbutton','String','Cancel','Callback',@cancelout,'Tooltip','Reset values back to original and close window.');

guidata(fig,aprops)

function closeit(hObject,eventdata)
close(hObject.Parent)

function autolimcomb(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
tm = props.tm;
idx = props.showidx;
cidx = get(findobj(hObject.Parent,'Tag','channelslim'),'Value');
channelslim = findobj(hObject.Parent,'Tag','channelslim');
str = get(channelslim,'String');

xlim = get(props.ax(1),'XLim');
xlim(xlim>max(tm)) = max(tm);
xlim(xlim<min(tm)) = min(tm);
xidx = [find(tm>xlim(1),1), find(tm>=xlim(2),1)];
data = props.data(idx(cidx),xidx(1):xidx(2));

rng = max(range(data,2));
lw = min(data,[],2) - rng*0.1;
rng = rng*1.2;


for a=1:length(cidx)
    ylim = [lw(a) lw(a)+rng];
    set(props.ax(cidx(a)),'YLim',ylim)
    str{a} = regexprep(str{a},'\[.+\]',[ '[' num2str(ylim) ']']);
end
set(channelslim,'String',str)
guidata(intan,props)

function autolimind(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
tm = props.tm;
idx = props.showidx;
cidx = get(findobj(hObject.Parent,'Tag','channelslim'),'Value');
channelslim = findobj(hObject.Parent,'Tag','channelslim');
str = get(channelslim,'String');
for a=cidx
    xlim = get(props.ax(a),'XLim');
    xidx = [find(tm>xlim(1),1), find(tm>xlim(2),1)];
    data = props.data(idx(a),xidx(1):xidx(2));
    rng = range(data);
    lw = round(min(data) - rng*0.1,5);
    up = round(max(data) + rng*0.1,5);
    set(props.ax(a),'YLim',[lw up])
    str{a} = regexprep(str{a},'\[.+\]',[ '[' num2str([lw up]) ']']);
end
set(channelslim,'String',str)
guidata(intan,props)

function setlim(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);

lw = str2double(get(findobj(hObject.Parent,'Tag','lowerlim'),'String'));
up = str2double(get(findobj(hObject.Parent,'Tag','upperlim'),'String'));
idx = get(findobj(hObject.Parent,'Tag','channelslim'),'Value');

channelslim = findobj(hObject.Parent,'Tag','channelslim');
str = get(channelslim,'String');
for i=idx
    set(props.ax(i),'YLim',[lw , up])
    str{i} = regexprep(str{i},'\[.+\]',[ '[' num2str([lw up]) ']']);
end
set(channelslim,'String',str)
guidata(intan,props)

function resetval(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);

channelslim = findobj(hObject.Parent,'Tag','channelslim');
str = get(channelslim,'String');
for a=1:length(props.ax)
    set(props.ax(a),'YLim',[aprops.lw(a) aprops.up(a)])
    str{a} = regexprep(str{a},'\[.+\]',[ '[' num2str([aprops.lw(a) aprops.up(a)]) ']']);
end
set(channelslim,'String',str)
set(findobj(hObject.Parent,'Tag','lowerlim'),'String',aprops.mlw)
set(findobj(hObject.Parent,'Tag','upperlim'),'String',aprops.mup)
guidata(intan,props)

function cancelout(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
for a=1:length(props.ax)
    set(props.ax(a),'YLim',[aprops.lw(a) aprops.up(a)])
end
guidata(intan,props)
close(hObject.Parent)

%% cosmetic stuff
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
if isfield(props,'databackup')
    props.data = convert_uint(props.databackup, props.bd2uint, props.bmin, 'double');
    for c=1:length(props.showidx)
        props.ax(c).Children.YData = props.data(props.showidx(c),:);pause(0.01)
    end
    props.log = [props.log; 'replaced data with backup'];
    guidata(hObject,props)
else
    buf = uicontrol(props.axpanel,'Units','pixels',...
    'Position',[props.axpanel.Position(3)/2, props.axpanel.Position(4)-60,200, 40],...
    'Style','text','String','No backup found','FontSize',15);
    pause(1)
    delete(buf)
    disp(' ')
    disp('No backup data is stored.')
    disp('Usually because the original file was too large to store a backup of the data.')
end

function restore_channel(hObject,eventdata)
props = guidata(hObject);
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(props.ch),1);
str(props.hideidx,2) = "gray";
str(:,4) = string(props.ch);
str = join(str,'');
[idx,tf] = listdlg('liststring',str,'OKString','Restore');
vst = find(contains(props.ch,'V-'),1,'first');
if tf
    idxd = zeros(0,1);
    for i=1:length(idx)
        cidx = contains(props.intan.ch,props.ch{idx(i)});  
        if any(cidx)
            d2uint = props.intan.d2uint(cidx);
            dmin = props.intan.min(cidx);
            data = convert_uint(props.intan.data(cidx,:), d2uint, dmin, 'double');
            props.data(idx(i),:) = interp1(props.intan.tm,data,props.tm);
            idxd = [idxd,idx(i)];
        else
            vidx = idx(i) - vst + 1;
            d2uint = props.vsd.d2uint(vidx);
            dmin = props.vsd.min(vidx);
            data = convert_uint(props.vsd.data(vidx,:),d2uint,dmin,'double');
            props.data(idx(i),:) = interp1(props.vsd.tm, data, props.tm);
            idxd = [idxd,idx(i)];
        end
    end

    props.bmin = min(props.data,[],2);
    props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
    props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16'); 
    props.log = [props.log; 'updated backup of data'];

    props.log = [props.log; ['Restored channels ' num2str(idxd) ' back to original.']];
    guidata(hObject,props)
    plotdata(hObject)
end

function zero_region(hObject,eventdata)
props = guidata(hObject);
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(props.ch),1);
str(props.hideidx,2) = "gray";
str(:,4) = string(props.ch);
str = join(str,'');
[idx,tf] = listdlg('liststring',str);
if tf
    [x,~] = ginput(2);
    tidx = find(props.tm>min(x),1):find(props.tm<max(x),1,'last');
    
    props.bmin = min(props.data,[],2);
    props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
    props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16'); 
    props.log = [props.log; 'updated backup of data'];
    
    props.data(idx,tidx) = repmat(props.data(idx,tidx(1)),1,length(tidx));
    guidata(hObject,props)
    plotdata(hObject)
end

function remove_artifact(hObject,eventdata)
props = guidata(hObject);
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(props.ch),1);
str(props.hideidx,2) = "gray";
str(:,4) = string(props.ch);
str = join(str,'');
[idx,tf] = listdlg('liststring',str,'SelectionMode','single');
if tf
    [~,y] = ginput(1);
    if y>mean(props.data(idx,:))
        yidx = find(props.data(idx,:)>y);
    else
        yidx = find(props.data(idx,:)<y);
    end
    ra = 5;
    yidx = yidx([true diff(yidx)>ra]);
    deltax = floor(mean(diff(yidx)));
    prew = 5;
    trim = 100;
    avg = zeros(1,deltax - trim);
    yidx(yidx<=prew) = [];
    yidx(yidx>length(props.data)-length(avg)-1) = [];
    
    for x=1:length(yidx)
        avg = avg + props.data(idx,yidx(x) - prew:yidx(x) + length(avg) - prew - 1);
    end
    avg = avg/length(yidx);
    
%     start = find(abs(diff(avg))>0.04,1,'first');
%     last = find(abs(diff(avg))>0.04,1,'last');
%     val = avg(start);   
%     awin = win(start:last);
% 
%     startd = diff(avg(start-1:start));
%     lastd = diff(avg(last-1:last));
        
    props.bmin = min(props.data,[],2);
    props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
    props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16'); 
    props.log = [props.log; 'updated backup of data'];

%     for w=1:length(awin)
%         props.data(idx,yidx+awin(w)) = val;
%     end
    tic
    for x=1:length(yidx)
        widx = yidx(x) - prew:yidx(x) + length(avg) - prew - 1;
        ridx = find(abs(props.data(idx,widx))>abs(y),1,'last');
        props.data(idx,widx) = props.data(idx,widx) - avg;
        props.data(idx,widx(1:ridx + 5)) = 0;
    end
    toc
    props.log = [props.log; ['Removed artifact from channel ' num2str(idx) ' (' props.ch{idx} ').']];

%     props.log = [props.log; ['Removed artifact from channel ' num2str(idx) ' (' props.ch{idx} ').  Replaced with value of ' num2str(val)]];
    guidata(hObject,props)
    plotdata(hObject)
end

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
props.hideidx = reshape(props.hideidx,1,[]);
props.showidx = reshape(props.showidx,1,[]);
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
f2.Position = [mfpos(1:2)+100 500 600];
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

bg = uibuttongroup('Visible','off','Units','Pixels','Position',[30 510 260 40],'SelectionChangedFcn',@bpass,'Tag','fband');

uicontrol(bg,'Style','text',       'Position',[10  13 60 20],'String','Lowpass','HandleVisibility','off');
uicontrol(bg,'Style','text',       'Position',[70  13 60 20],'String','Bandpass','HandleVisibility','off');
uicontrol(bg,'Style','text',       'Position',[130 13 60 20],'String','Highpass','HandleVisibility','off');
uicontrol(bg,'Style','text',       'Position',[190 13 60 20],'String','Notch','HandleVisibility','off');
uicontrol(bg,'Style','radiobutton','Position',[30  0 60 20],'HandleVisibility','off','Tag','lowpass');     
uicontrol(bg,'Style','radiobutton','Position',[90  0 60 20],'HandleVisibility','off','Tag','bandpass','Value',1);
uicontrol(bg,'Style','radiobutton','Position',[150 0 60 20],'HandleVisibility','off','Tag','highpass');
uicontrol(bg,'Style','radiobutton','Position',[210 0 60 20],'HandleVisibility','off','Tag','notch');
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
meth =   get(findobj(hObject.Parent,'Tag','fmeth'),'String');
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
    case 'notch'
        set(uil,'Visible','on')
        set(uih,'Visible','on')
        objs = findobj(hObject.Parent,'Tag','fatthigher','-or','Tag','fslower','-or','Tag','fshigher');
        set(objs,'Visible','off')
        if strcmp(meth,'butter')
            set(findobj(hObject.Parent,'Tag','fripple'),'Enable','off')
        end
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
set(plt, 'XData', [0 fstop(1) fpass fstop(2) ax.XLim(2)],...
         'YData', [0  0   0  0  0 0]);
%plt.XData = [0 fstop(1) fpass fstop(2) ax.XLim(2)];
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
    case 'notch'
        set(plt,'XData', [0 fpass(1) mean(fpass) fpass(2) ax.XLim(2)],...
                'YData', [0   0      -fatt(1) 0 0 ]);
        rec.Position = [1e6   0   1   1];
end

ax.YLim(2) = round(fr+10);

function applyfilter(hObject,eventdata)%<--- print out ignores lowpass highpass,   apply filter to data and close filter app
props = guidata(hObject);
hObject.String = 'Applying...';
hObject.BackgroundColor = [0.6 1 0.6];
pause(0.1)
idx = get(findobj(hObject.Parent,'Tag','channels'),'Value');

[h, Hd, fprop] = makefilter(hObject, diff(props.tm(1:2))^-1);

fprintf(['\nfilter parameters\n',...
         'method\t'       fprop.meth           '\t' 'type\t' fprop.ftype '\n',...
         'ripple\t'      num2str(fprop.fr)   '\t' num2str(fprop.fr) '\n',...
         'attenuation\t' 'low\t' num2str(fprop.fatt(1)) '\thigh\t' num2str(fprop.fatt(2)) '\n',...
         'passband\t'    'low\t' num2str(fprop.fpass(1)) '\thigh\t' num2str(fprop.fpass(2)) '\n',...
         'stopband\t'    'low\t' num2str(fprop.fstop(1)) '\thigh\t' num2str(fprop.fstop(2)) '\n\n'])

filterp.fr = fprop.fr;
filterp.fatt = fprop.fatt;
filterp.fpass = fprop.fpass;
filterp.fstop = fprop.fstop;
filterp.meth = fprop.meth;
filterp.idx = idx;
filterp.type = fprop.ftype;

props.bmin = min(props.data,[],2);
props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16'); 
props.log = [props.log; 'updated backup of data'];

for d=idx
    disp(num2str(d))
    props.data(d,:) = filter(Hd,props.data(d,:));
    idx = find(props.tm>1,1);
    props.data(d,1:idx) = 0;
end

if ~isfield(props,'filter')
    props.filter = filterp;
else
    if isfield(props.filter,'type')
        props.filter(end+1) = filterp;
    else
        props.filter(end+1).type = 5;
        props.filter(end) = filterp;
    end
end

str = ['filtered: idx = '  char(join(string(filterp.idx),',')),...
    ' fr = ' num2str(fprop.fr) ' fatt = ' char(join(string(fprop.fatt),','))  ' fpass = ' char(join(string(fprop.fpass),',')),...
    ' fstop = ' char(join(string(fprop.fstop),',')), ' meth = ', fprop.meth,' type = ', fprop.ftype];
props.log = [props.log; str];

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
 
[h, Hd] = makefilter(hObject, diff(props.tm(1:2))^-1);

plt2 = findobj(hObject.Parent,'Tag','fdata_filt');
fdata = filter(Hd,props.data(val,:));
idx = find(props.tm>1,1);
fdata(1:idx) = 0;
plt2.YData = fdata;

set(allbut,'Enable','on')

function [h, Hd,fprop] = makefilter(hObject,sr)
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

fprop = struct('fr',fr,'fatt',fatt,'fpass',fpass,'fstop',fstop,'meth',meth{midx},'midx',midx,'ftype',hband.Tag);

switch hband.Tag
    case 'lowpass'
        h = fdesign.lowpass('Fp,Fst,Ap,Ast', fpass(2), fstop(2), fr, fatt(2), sr);
    case 'bandpass'      
        h = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', fstop(1), fpass(1), ...
            fpass(2), fstop(2), fatt(1), fr, fatt(2), sr);
    case 'highpass'
        h = fdesign.highpass('Fst,Fp,Ast,Ap', fstop(1), fpass(1), fatt(1), fr, sr);
    case 'notch'
        switch meth{midx}
            case 'butter'
                h = fdesign.notch('N,F0,BW', 2, mean(fpass), diff(fpass), sr);
            case 'cheby1'
                h = fdesign.notch('N,F0,BW,Ap', 2, mean(fpass), diff(fpass), fr, sr);
            case 'cheby2'
                h = fdesign.notch('N,F0,BW,Ast', 2, mean(fpass), diff(fpass), fatt(1), sr);
            case 'ellip'
                h = fdesign.notch('N,F0,BW,Ap,Ast', 2, mean(fpass), diff(fpass), fr, fatt(1), sr);
        end
end

try
    if strcmp(hband.Tag,'notch')
        Hd = design(h, meth{midx}, 'SOSScaleNorm', 'Linf');
    else
        Hd = design(h, meth{midx}, 'MatchExactly', 'passband', 'SOSScaleNorm', 'Linf');
    end
    set(findobj(hObject.Parent,'Tag','errorcode'),'String','')
catch ME
    set(findobj(hObject.Parent,'Tag','errorcode'),'String',ME.message)
end

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

%% correlation
function xcorrelation(hObject,eventdata)% calculates the cross correlation of the channels shown
props = guidata(hObject);

if isfield(props,'spikedetection')
    answer = questdlg('How do you want to process data?','Question?','Binary','Continuous','Binary');
else
    answer = 'Continuous';
end

if isempty(answer)
    return
end

win = 1500;%700 379 window for calculating the cross correlation
nch = length(props.showidx);
showidx = props.showidx;

ch = props.ch;
idx = nchoosek(1:nch,2);
props.xcorr = nan(nch);
props.xcorr_lag = nan(nch);
props.xcorr_fulltrace = nan(nch,nch,win*2+1);
signit = [1,-1];
sr = diff(props.tm([1 100]))/100*1000;

pos = get(findobj('Tag',props.intan_tag),'Position');
fig = figure('Name','Progress...','NumberTitle','off','MenuBar','none',...
    'Position',[pos(1)+pos(3)/2, pos(2)+pos(4)/2 300 75]);
pax = axes('Position',[0.1 0.2 0.8 0.7],'XLim',[0 1],'YLim',[0 1],'YTick',[]);
rec = rectangle('Position',[0 0 0 1],'FaceColor','b');
pause(0.01)

for i=1:length(idx)
%     disp([num2str(i) ' of ' num2str(length(idx)) '    ' num2str(idx(i,1)) 'x' num2str(idx(i,2))])
    if mod(i,5)==0
        if ~isvalid(rec)
            disp('operation terminated')
            return
        end
        set(rec,'Position',[0 0 i/length(idx) 1])
        pause(0.01)
    end
    
    sidx = showidx(idx(i,:));
    if strcmp(answer,'Binary')
        x = zeros(size(props.tm));
        x(props.spikedetection.spikes{sidx(1)}) = 1;
        y = zeros(size(props.tm));
        y(props.spikedetection.spikes{sidx(2)}) = 1;

        wf = gausswin(1e5,1000);
        
        xf = conv(x,wf);
        dl = round((length(xf)-length(x))/2); 
        xf = xf(dl+1:end-dl);
    
        yf = conv(y,wf);
        dl = round((length(yf)-length(y))/2); 
        yf = yf(dl+1:end-dl);
    else
        xf = props.data(sidx(1),:)*signit(contains(props.ch(sidx(1)),'V')+1);
        yf = props.data(sidx(2),:)*signit(contains(props.ch(sidx(2)),'V')+1);
    end
    xf(isnan(xf)) = 0;
    yf(isnan(yf)) = 0;
    
    r = xcorr(xf,yf,win,'normalized');

%     x = abs(x);
%     y = abs(y);
%     x = decimate(x,20);
%     y = decimate(y,20);
    

    [val,id] = max(r);
    props.xcorr(idx(i,2),idx(i,1)) = val;
    props.xcorr(idx(i,1),idx(i,2)) = val;
    props.xcorr_lag(idx(i,2),idx(i,1)) = -(id-win)*sr;
    props.xcorr_lag(idx(i,1),idx(i,2)) = (id-win)*sr;
    props.xcorr_fulltrace(idx(i,2),idx(i,1),:) = fliplr(r);
    props.xcorr_fulltrace(idx(i,1),idx(i,2),:) = r;
end
close(fig)

props.xcorr(find(eye(size(props.xcorr,1)))) = 1;

Z = linkage(props.xcorr);
fig = figure('Position',[100 100 1108 782]);

ax(2) = subplot(2,2,3);

ax(1) = axes('Position',[ax(2).Position(1) 0.45 0.28 0.2]);
[~,~,didx] = dendrogram(Z);
ax(1).Title.String = 'Correlation';
ax(1).XLim = [0.5 size(props.xcorr,1)+0.5];
ax(1).Color = 'none';

props.didx = didx;
props.corr_list = props.showlist(didx);
props.corr_idx = props.showidx(didx);

props.xcorr_fulltrace = props.xcorr_fulltrace(didx,didx,:);

axes(ax(2))
imagesc(props.xcorr(didx,didx),'AlphaData', 1-isnan(props.xcorr(didx,didx)))
ax(2).Tag = 'corrplot';

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
imagesc(props.xcorr_lag(didx,didx),'AlphaData', 1-isnan(props.xcorr_lag(didx,didx)))
colorbar
set(ax,'YTick',1:length(didx),'YTickLabel',props.showlist(didx),'XTick',1:length(props.showlist),'XTickLabel',props.showlist(didx),'XTickLabelRotation',90)
ax(1).XTick = [];
ax(1).YTick = [];
ax(3).Title.String = 'Time lag';

uicontrol('Units','normalized','Position',[0.05 0.8 0.15 0.05],'Style','pushbutton',...
    'String','plot correlation','Callback',@plotcorrelation,'Tooltip','Plots the correlation of the selected region');


guidata(hObject,props)
guidata(fig,props.intan_tag)

function plotcorrelation(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops);
props = guidata(intan);
if isfield(props,'xcorr_rect')
    delete(props.xcorr_rect)
end

axes(findobj(hObject.Parent,'Tag','corrplot'))

rect = getrect();
rect = floor(rect);
rect(1:2) = rect(1:2)+1;

props.xcorr_rect = rectangle('Position',[rect(1:2)-0.5 rect(3:4)],'EdgeColor','r');

figure('Name','Correlation traces for region','NumberTitle','off')
cnt = 1;

xidx = rect(1):rect(1)+rect(3)-1;
yidx = rect(2):rect(2)+rect(4)-1;
minv = min(props.xcorr_fulltrace(yidx,xidx,:),[],'all');
maxv = max(props.xcorr_fulltrace(yidx,xidx,:),[],'all');
ax = gobjects(length(yidx)*length(xidx),1);
for j=yidx
    for i=xidx
        ax(cnt) = subplot(length(yidx),length(xidx),cnt);
        y = squeeze(props.xcorr_fulltrace(j,i,:));
        x  = ((1:length(y))-length(y)/2)*diff(props.tm(1:2)); 

        yp = y(y>=0);
        xp = x(y>=0);

        yn = y(y<0);
        xn = x(y<0);

        yp = [yp ; zeros(size(yp))];
        xp = [xp'; flipud(xp')];

        yn = [yn ; zeros(size(yn))];
        xn = [xn'; flipud(xn')];

        fill(xp,yp,[1 0.5 0]);hold on
        fill(xn,yn,'blue');hold on
        plot([0 0],[-1 1],'k');hold on
        if i==j
            rectangle('Position',[-1 -1 2 2],'FaceColor',[0.6 0.6 0.6])
        end

        if i~=xidx(1)
            ax(cnt).YTick = [];
        else
            ax(cnt).YLabel.String = props.corr_list(j);
        end

        if j~=yidx(end)
            ax(cnt).XTick = [];
        else
            ax(cnt).XLabel.String = props.corr_list(i);
        end

        if ~isempty(xp)
            xlim = [min([xn;xp]) max([xn;xp])];
        end
        cnt = cnt + 1;
    end
end
linkaxes(ax,'y')
set(ax,'YLim',[minv-0.05 maxv+0.05],'XLim',xlim)

guidata(intan,props)

%% spike detection
function spiked(hObject,eventdata)% spike detection 
validatech(hObject);
props = guidata(hObject);
spikedetection(props.intan_tag)

function validatech(hObject)
props = guidata(hObject);
for p=1:length(props.showlist)
    truth = props.showlist{p};
    if p<=length(props.showidx)
        checkit = props.ch(props.showidx(p));
        if ~strcmp(truth,checkit)
            warning(['Showidx ' num2str(p) ' does not match showlist, replacing idx value with showlist'])
        end
    end
end

for p=1:length(props.hidelist)
    truth = props.hidelist{p};
    if p<=length(props.hideidx)
        checkit = props.ch(props.hideidx(p));
        if ~strcmp(truth,checkit)
            warning(['Hideidx ' num2str(p) ' does not match hidelist, replacing idx value with hidelist'])
        end
    end
end

props.showidx = arrayfun(@(x) find(ismember(props.ch,x)),props.showlist);
props.showidx = reshape(props.showidx,1,[]);
props.hideidx = arrayfun(@(x) find(ismember(props.ch,x)),props.hidelist);
props.hideidx = reshape(props.hideidx,1,[]);

guidata(hObject, props)

function plotspikes(hObject,eventdata)% adds the spike times to the graphs
props = guidata(hObject);
showidx = props.showidx;
data = props.data(showidx,:);
if isfield(props,'spikedetection')
    spikes = props.spikedetection.spikes(showidx);
    ax = props.ax;
    if strcmp(hObject.String,'show')
        for p=1:length(ax)
            if ~isempty(spikes{p})
                axes(ax(p))
                hold on
                scatter(props.tm(spikes{p}), data(p,spikes{p}),'rd','filled')
            end
        end
    else
        scobj = findobj(ax,'Type','scatter');
        if ~isempty(scobj)
            delete(findobj(ax,'Type','scatter'))
        end
    end
else
    msgbox('You have not run spike detection for this data yet')
end
guidata(hObject,props)

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
    'Max',1,'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@chchannel);

cpanel = uipanel('Title','Controls','Units','normalized','FontSize',12,'Position',[0.75 0 0.25 1],'Tag','cpanel');


uicontrol(cpanel,'Units','normalized','Position',[0.05 0.80 0.05 0.05],'Style','radiobutton',...
    'Callback',@radio, 'Tag','Fit_','Value',1);
uicontrol(cpanel,'Units','normalized','Position',[0.1 0.78 0.1 0.05],'Style','text',...
    'String','Fit equation','HorizontalAlignment','left','Enable','on','Tag','Fit');
uicontrol(cpanel,'Units','normalized','Position',[0.25 0.78 0.1 0.05],'Style','text',...
    'String','Coefficients','HorizontalAlignment','right','Enable','on','Tag','Fit');
uicontrol(cpanel,'Units','normalized','Position',[0.41 0.8 0.1 0.05],'Style','edit',...
    'String','2','Callback',@fitequation,'Enable','on','TooltipString','Number of coefficients','Tag','Fit');
uicontrol(cpanel,'Units','normalized','Position',[0.52 0.825  0.05 0.025],'Style','pushbutton','Tag','UP','String',char(708),'Callback',@chval,'Enable','on');
uicontrol(cpanel,'Units','normalized','Position',[0.52 0.8 0.05 0.025],'Style','pushbutton','Tag','DN','String',char(709),'Callback',@chval,'Enable','on');

uicontrol(cpanel,'Units','normalized','Position',[0.05 0.70 0.05 0.05],'Style','radiobutton',...
    'Callback',@radio,'Tag','Spline_','Value',0);
uicontrol(cpanel,'Units','normalized','Position',[0.1 0.68 0.1 0.05],'Style','text',...
    'String','Spline','HorizontalAlignment','left','Enable','off','Tag','Spline');
uicontrol(cpanel,'Units','normalized','Position',[0.31 0.7 0.1 0.05],'Style','pushbutton',...
    'String','Add points','Callback',@addpoints,'Enable','off','TooltipString','Add points for spline','Tag','Spline');
uicontrol(cpanel,'Units','normalized','Position',[0.41 0.7 0.1 0.05],'Style','pushbutton',...
    'String','redo','Callback',@addpoints,'Enable','off','TooltipString','start over adding points for spline','Tag','Spline');

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
p0 = ones(1,50);
flimits = inf(size(p0));

fparam = lsqcurvefit(fun,p0,tm(1:ds:end),data(1:ds:end),-flimits,flimits,opts);

fplt = plot(props.tm,fun(fparam,props.tm));

scplt = scatter([],[]);

ax.YLim = [min(data) max(data)];

props.blapp = struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                    'fplt',fplt,        'fun',fun,...
                    'p0',p0,            'flimits',flimits,   'tm',tm,...
                    'splt',splt,        'scplt',scplt,          'intan_tag',intan_tag);
guidata(hObject,props)

function chval(hObject,eventdata)
obj = findobj(hObject.Parent,'Tag','Fit','Style','edit');
coef = str2double(get(obj,'String'));
if strcmp(hObject.Tag,'UP')
    set(obj,'String',num2str(coef+1))
else
    set(obj,'String',num2str(coef-1))
end
fitequation(obj)

function addpoints(hObject,eventdata)
intan_tag = guidata(hObject);
intan_fig = findobj('Tag',intan_tag);
fig = hObject.Parent.Parent;
idx = get(findobj(fig,'Tag','channels'),'Value');
props = guidata(intan_fig);
if strcmp(hObject.String,'redo')
    set(props.blapp.scplt,'XData',[],'YData',[])
end

while 1==1
    [x,y,button] = ginput(1);
    if button~=1
        break
    end
    x = [props.blapp.scplt.XData x];
    y = [props.blapp.scplt.YData y];
    set(props.blapp.scplt,'XData',x,'YData',y)
    if length(x)>1
        yy = spline(x,y,props.blapp.fplt.XData);
        set(props.blapp.fplt,'YData',yy)
        sdata = props.data(idx,:) - yy;
        sdata(props.tm<1) = sdata(find(props.tm>=1,1)); 
        set(props.blapp.splt,'YData',sdata)
    end
end
guidata(intan_fig,props)

function radio(hObject,eventdata)
panel = hObject.Parent;
tags = ["Fit","Spline"];
tagidx = contains(tags,hObject.Tag(1:end-1));
set(findobj(panel,'Tag',tags{tagidx}),'Enable','on')
set(findobj(panel,'Tag',tags{~tagidx}),'Enable','off')
set(findobj(panel,'Tag',[tags{~tagidx} '_']),'Value',0)
if find(tagidx)==1
    fitequation(hObject.Parent)
end

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

fig = hObject.Parent;
while ~strcmp(get(fig,'type'),'figure')
    fig = fig.Parent;
end

props = guidata(findobj('Tag',intan_tag));
disp('fitting')
buf = uicontrol(fig,'Units','normalized','Position',[0.3 , 0.9, 0.4 0.1],...
    'Style','text','String','Fitting...','FontSize',15);
pause(0.1)

idx = get(findobj(fig,'Tag','channels'),'Value');
coef = str2double(get(findobj(fig,'Tag','Fit','Style','edit'),'String'));
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
sdata = data(1:ds:end);
stm = tm(1:ds:end);
stm(sdata==sdata(1)) = [];
sdata(sdata==sdata(1)) = [];

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
coef = str2double(get(findobj(panel,'Tag','Fit','Style','edit'),'String'));
fun = makefun(coef);

flimits = props.blapp.flimits;
p0 = props.blapp.p0;

props.blapp.applyparam = nan(length(idx),50);
props.blapp.applyidx = idx;
props.blapp.fun = fun;
props.blapp.coef = coef;
opts = optimset('Display','off','Algorithm','levenberg-marquardt');
ds = 20000;%downsample

props.bmin = min(props.data,[],2);
props.bd2uint = repelem(2^16,size(props.data,1),1)./range(props.data,2);
props.databackup = convert_uint(props.data, props.bd2uint, props.bmin, 'uint16');
props.log = [props.log; 'updated backup of data'];

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

props.log = [props.log; 'Removed baseline using ' num2str(props.blapp.coef),...
    ' coefficients, downsample = ' num2str(ds) ',  idx = ' char(join(string(idx),','))];

guidata(findobj('Tag',intan_tag),props)
close(panel.Parent)
plotdata(findobj('Tag',intan_tag))

%% BMP
function makeBMP(hObject,eventdata)
fig = ancestor(hObject,'figure','toplevel');
props = guidata(fig);
[x, ~] = ginput(3);

if  ~isfield(props.BMP_analysis,'BMP') || isempty(props.BMP_analysis.BMP)
    b = 1;
    props.BMP_analysis.BMP = x';
else
    b = size(props.BMP_analysis.BMP,1)+1;
    props.BMP_analysis.BMP = [props.BMP_analysis.BMP; x'];
end



color = 'bg';
phase = ["Prot","Retr"];
axes(props.BMP_analysis.axbmp)
for p=1:2
    line(x(p:p+1) , [p p],'Color',color(p),'Tag',[phase{p} num2str(b)],'LineWidth',2);hold on
    sc(1) = scatter(x(p),  p,100,['|' color(p)],'LineWidth',2,'ButtonDownFcn',@adjustline,'Tag',[phase{p} num2str(b) 's']);hold on
    sc(2) = scatter(x(p+1),p,100,['|' color(p)],'LineWidth',2,'ButtonDownFcn',@adjustline,'Tag',[phase{p} num2str(b) 'e']);hold on
    pb.enterFcn = @(fig,currentPoint) set(fig,'Pointer','hand');
    pb.exitFcn = @(fig,currentPoint) set(fig,'Pointer','arrow');
    pb.traverseFcn = [];
    iptSetPointerBehavior(sc,pb);
    iptPointerManager(gcf)
end
props.axbmp.YLim = [0 4.5];
props = countspikes(props);
props = reorderBMP(props);
disp(props.BMP_analysis.BMP)
guidata(fig,props)

function props = reorderBMP(props)
fig = findobj('Tag',props.intan_tag);
[~,idx] = sort(props.BMP_analysis.BMP(:,1));
props.BMP_analysis.BMP = props.BMP_analysis.BMP(idx,:);
if isfield(props.BMP_analysis,'btype')
    props.BMP_analysis.btype = props.BMP_analysis.btype(idx);
    props.BMP_analysis.Rn = props.BMP_analysis.Rn(idx,:);
end
for i=1:length(idx)
    set(findobj(fig,'Tag',['Prot' num2str(i)]),'Tag', ['Prot' num2str(idx(i)) 'reordered'])
    set(findobj(fig,'Tag',['Prot' num2str(i) 's']),'Tag', ['Prot' num2str(idx(i)) 's' 'reordered'])
    set(findobj(fig,'Tag',['Prot' num2str(i) 'e']),'Tag', ['Prot' num2str(idx(i)) 'e' 'reordered'])

    set(findobj(fig,'Tag',['Retr' num2str(i)]),'Tag', ['Retr' num2str(idx(i)) 'reordered'])
    set(findobj(fig,'Tag',['Retr' num2str(i) 's']),'Tag', ['Retr' num2str(idx(i)) 's' 'reordered'])
    set(findobj(fig,'Tag',['Retr' num2str(i) 'e']),'Tag', ['Retr' num2str(idx(i)) 'e' 'reordered']) 
end
allthem = findobj(fig,'-regexp','Tag','reordered');
for a=1:length(allthem)
    tag = get(allthem(a),'Tag');
    set(allthem(a),'Tag',replace(tag,'reordered',''))
end
props = countspikes(props);

function selectRn(hObject,eventdata)
props = guidata(hObject);
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(props.ch),1);
str(props.hideidx,2) = "gray";
str(:,4) = string(props.ch);
str = join(str,'');
props.rn = listdlg('liststring',str);
props = countspikes(props);
guidata(hObject,props)

function props = countspikes(props)
if isfield(props,'spikedetection')
    nbmp = size(props.BMP_analysis.BMP,1);
    btypes = ["R","I"];
    phase = ["Prot","Retr"];
    props.BMP_analysis.spikes = zeros(nbmp, 8, length(props.ch) );
    for c=1:length(props.ch)
        spike = props.spikedetection.spikes{c};
        spike = props.tm(spike);
        if ~isempty(spike)
            for b=1:nbmp
                x = props.BMP_analysis.BMP(b,:);
                pdur = [0 0];
                for p=1:2
                    sp = spike(spike>x(p) & spike<x(p+1));
                    props.BMP_analysis.spikes(b,p+3,c) = length(sp);
                    rdursp = diff(sp);
                    if length(sp)>1
                        bursts = [0 find(rdursp>=4)];
                        for r=1:length(bursts)
                            if r==length(bursts)
                                bx = [sp(bursts(r)+1)  sp(end)];
                            else
                                bx = [sp(bursts(r)+1)  sp(bursts(r+1))];
                            end
                            line(bx , [3 3],'Color','r','Tag',[num2str(b) phase{p} 'r' num2str(r)],'LineWidth',2);hold on
                        end
                        pdur(p) = sum(rdursp(rdursp<4));
                    end
                end
                props.BMP_analysis.spikes(b,6:7,c) = props.BMP_analysis.spikes(b,4:5)./diff(props.BMP_analysis.BMP(b,1:3));
                analysis = [pdur(1)  pdur(2)  pdur(2)/sum(pdur)  props.BMP_analysis.spikes(b,7,c)/sum(props.BMP_analysis.spikes(b,6:7,c))];
                props.BMP_analysis.spikes(b,[1:3 8],c) = analysis;                
            end
        end
    end       

    % count rn spikes
    if isfield(props.BMP_analysis,'rn')
        ridx = props.BMP_analysis.rn;
    else
        ridx = contains(props.ch,'-Rn');
    end
    if any(ridx)
        rspike = props.spikedetection.spikes{ridx};
        rspike = props.tm(rspike);
        if isfield(props.BMP_analysis,'btxt')
            delete(props.BMP_analysis.btxt)
        end
        rnln = findobj(findobj('Tag',props.intan_tag),'-regexp','Tag','(Prot|Retr)r');
        if ~isempty(rnln)
            delete(rnln)
        end
        props.btxt = gobjects(size(props.BMP_analysis.BMP,1),1);
        props.btype = zeros(size(props.BMP_analysis.BMP,1),1);
        props.BMP_analysis.Rn = zeros(size(props.BMP_analysis.BMP,1),8);
        axes(props.BMP_analysis.axbmp)
        if ~isempty(rspike)
            props.BMP_analysis.rnratio_head = ["rn duration protr","rn duration retr","rn dur ratio","rn sp protr","rn sp retr","rn Hz protr","rn Hz retr","rn Hz ratio"];
            for b=1:size(props.BMP_analysis.BMP,1)
                x = props.BMP_analysis.BMP(b,:);
                pdur = [0 0];
                for p=1:2
                    rsp = rspike(rspike>x(p) & rspike<x(p+1));
                    props.BMP_analysis.Rn(b,p+3) = length(rsp);
                    rdursp = diff(rsp);
                    if length(rsp)>1
                        bursts = [0 find(rdursp>=4)];
                        for r=1:length(bursts)
                            if r==length(bursts)
                                bx = [rsp(bursts(r)+1)  rsp(end)];
                            else
                                bx = [rsp(bursts(r)+1)  rsp(bursts(r+1))];
                            end
                            line(bx , [3 3],'Color','r','Tag',[num2str(b) phase{p} 'r' num2str(r)],'LineWidth',2);hold on
                        end
                        pdur(p) = sum(rdursp(rdursp<4));
                    end
                end
                props.BMP_analysis.btype(b) = (pdur(2)>pdur(1))+1;
                props.BMP_analysis.Rn(b,6:7) = props.BMP_analysis.Rn(b,4:5)./diff(props.BMP_analysis.BMP(b,1:3));
                props.BMP_analysis.Rn(b,[1:3 8]) = [pdur(1)  pdur(2)  pdur(2)/sum(pdur)  props.BMP_analysis.Rn(b,7)/sum(props.BMP_analysis.Rn(b,6:7))];
                props.BMP_analysis.btxt(b) = text(x(2),4,btypes(props.BMP_analysis.btype(b)),'HorizontalAlignment','center','FontName','times');hold on
            end
        end
    end
end

function adjustline(hObject,eventdata)
fig = ancestor(hObject,'figure','toplevel');
props = guidata(fig);
if eventdata.Button==1
    if contains(hObject.Tag,'endtag')% i don't think this is necessary
        mouseclick(fig)
    else
        for a=1:length(props.ax)
            scatter(props.ax(a),nan,nan,'or','filled','Tag',['snap_marker' num2str(length(props.ax) - a+1)]);hold on
        end
        set(hObject,'Tag',[hObject.Tag 'endtag'])
        set(fig,'WindowButtonMotionFcn',@mousemove)
        set(fig,'WindowButtonDownFcn',@mouseclick)
        set(fig,'WindowKeyPressFcn',@snaptospike)
        set(gcf,'WindowKeyReleaseFcn',@snaprelease)
    end
else
    choice = questdlg('Delete motor pattern?','Question','Yes','No','Yes');
    if strcmp(choice,'Yes')
        idxs = char(regexp(hObject.Tag,'\d+','match'));
        idx = str2double(idxs);disp(idx)
        delete(findobj(fig,'Tag',['Prot' idxs]))
        delete(findobj(fig,'Tag',['Prot' idxs 's']))
        delete(findobj(fig,'Tag',['Prot' idxs 'e']))

        delete(findobj(fig,'Tag',['Retr' idxs]))
        delete(findobj(fig,'Tag',['Retr' idxs 's']))
        delete(findobj(fig,'Tag',['Retr' idxs 'e']))

        cnt = idx+1;
        obj = findobj(fig,'Tag',['Retr' num2str(cnt)]);
        while isvalid(obj)
            set(findobj(fig,'Tag',['Prot' num2str(cnt)]),'Tag', ['Prot' num2str(cnt-1)])
            set(findobj(fig,'Tag',['Prot' num2str(cnt) 's']),'Tag', ['Prot' num2str(cnt-1) 's'])
            set(findobj(fig,'Tag',['Prot' num2str(cnt) 'e']),'Tag', ['Prot' num2str(cnt-1) 'e'])

            set(findobj(fig,'Tag',['Retr' num2str(cnt)]),'Tag', ['Retr' num2str(cnt-1)])
            set(findobj(fig,'Tag',['Retr' num2str(cnt) 's']),'Tag', ['Retr' num2str(cnt-1) 's'])
            set(findobj(fig,'Tag',['Retr' num2str(cnt) 'e']),'Tag', ['Retr' num2str(cnt-1) 'e'])

            cnt = idx+1;
            obj = findobj(fig,'Tag',['Retr' num2str(cnt)]);
        end

        props.BMP_analysis.BMP(idx,:) = [];

        delete(props.BMP_analysis.btxt(idx))
        props.BMP_analysis.btxt(idx) = [];
        props.BMP_analysis.btype(idx) = [];
        props.BMP_analysis.Rn(idx,:) = [];

        rnln = findobj(fig,'-regexp','Tag',[num2str(idx) '(Prot|Retr)r']);
        delete(rnln)
        
        delete(hObject)
        disp('BMP removed')
    end
end
props.snapit = false;
guidata(fig,props)

function snaptospike(hObject,eventdata)
props = guidata(hObject);
props.snapit = true;
guidata(hObject,props)

function snaprelease(hObject,eventdata)
props = guidata(hObject);
props.snapit = false;
guidata(hObject,props)

function mousemove(hObject,eventdata)
props = guidata(hObject);
C = get(gca,'CurrentPoint');
sc = findobj(hObject,'-regexp','Tag','\w+endtag');
ln = findobj(hObject,'Tag',char(regexp(sc.Tag,'(Prot|Retr)\d+','match')));
mind = 1;
if contains(sc.Tag,'ee')
    C(C<ln.XData(1)+mind) = ln.XData(1)+mind;
else
    C(C>ln.XData(2)-mind) = ln.XData(2)-mind;
end
set(findobj(hObject,'-regexp','Tag','snap_marker'),'XData',nan,'YData',nan)
if props.snapit && isfield(props,'spikedetection')
    Cf = get(gcf,'CurrentPoint');
    ch = findobj(props.axpanel,'Type','uicontrol','Style','text');
    pos = cell2mat({ch.Position}');
    pos = pos(:,2);
    ht = diff(pos(1:2));
    curax = abs(pos-Cf(2))<ht/2;
    if any(curax)
        idx = ismember(props.ch,ch(curax).String);
        spikes = props.tm(props.spikedetection.spikes{idx});
        if ~isempty(spikes)
            [~,sidx] = min(abs(spikes-C(1)));
            C(1) = spikes(sidx);
        
            snap_sc = findobj('Tag',['snap_marker' num2str(find(curax))]);
            params = props.spikedetection.params(idx);
            md = mean(props.data(idx,:));
            stdev = std(props.data(idx,:));

            if params.ckup
                y = md + params.upthr*stdev;
            else
                y = md - params.dwnthr*stdev;
            end
            set(snap_sc,'XData',C(1),'YData',y);
        end
    end
end

idxs = char(regexp(sc.Tag,'\d+','match'));
if contains(sc.Tag,'Prot') && contains(sc.Tag,'ee')
    sc2 = findobj(hObject,'Tag',['Retr' idxs 's']); 
    sc3 = findobj(hObject,'Tag',['Retr' idxs 'e']); 
    C(C>sc3.XData-mind) = sc3.XData-mind;
    set(sc2,'XData',C(1));
    ln2 = findobj(hObject,'Tag',['Retr' idxs]); 
    ln2.XData(1) = C(1);
    props.BMP(str2double(idxs),2) = C(1);
elseif contains(sc.Tag,'Retr') && contains(sc.Tag,'s')
    sc2 = findobj(hObject,'Tag',['Prot' idxs 'e']); 
    sc3 = findobj(hObject,'Tag',['Prot' idxs 's']);
    C(C<sc3.XData+mind) = sc3.XData+mind;
    set(sc2,'XData',C(2));
    ln2 = findobj(hObject,'Tag',['Prot' idxs]); 
    ln2.XData(2) = C(2);
    props.BMP(str2double(idxs),2) = C(1);
elseif contains(sc.Tag,'Prot') 
    props.BMP(str2double(idxs),1) = C(1);
else
    props.BMP(str2double(idxs),3) = C(1);
end
set(sc,'XData',C(1));
ln.XData(contains(sc.Tag,'ee')+1) = C(1);
guidata(hObject,props)

function mouseclick(hObject,eventdata)
sc = findobj(hObject,'-regexp','Tag','\w+endtag');
set(sc,'Tag',replace(sc.Tag,'endtag',''))
set(gcf,'WindowButtonMotionFcn',[])
set(gcf,'WindowButtonDownFcn',[])
delete(findobj(hObject,'-regexp','Tag','snap_marker'))
props = guidata(hObject);
props = countspikes(props);
guidata(hObject,props)


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
vfig = figure('Position',[ofigsize(1) ofigsize(4)*0.06+ofigsize(2) ofigsize(3)*0.95 ofigsize(4)-ofigsize(4)*0.16],...
    'Name','Make Video','NumberTitle','off','Tag',apptag);

m = uimenu('Text','Video');
mi(1) = uimenu(m,'Text','Save Image Frame','Callback',@saveframe);

guidata(vfig,props.intan_tag)

pax = axes('Units','normalized','Position',[10 0.05 0.25 0.05],'XTick',[],'YTick',[],'Box','on','Tag','progax');
prog = rectangle('Position',[0 0 0 1],'FaceColor','b','Tag','progress');
pax.XLim = [0 1];

uicontrol('Units','normalized','Position',[5.72 0.12 0.25 0.04],...
    'Style','text','Tag','progtxt','String',' ','Enable','on');

pause(0.1)

vsd = props.files(contains(props.files(:,2),'tsm'),2);



if redo
    [imdatas,fparam,fun,imdata,tm,imdataroi,kerndata] = getimdata(vsd,1,vfig,fr);
    props.video.imdata = permute(imdatas,[2,1,3]);
    props.video.imdatar = permute(imdata,[2,1,3]);
    props.video.imdataroi = permute(imdataroi,[2,1,3]);
    props.video.kerndata = kerndata;
    props.video.tm = tm;% + diff(tm(1:2))*5;% don't know why this 5* needs to be done but it does
    props.video.fun = fun;
    props.video.fparam = fparam;
    props.video.reference = 1;
    slidepos = 10;
    inv = 1;
    climv = [0 0.02];
    props.video.climv = climv;
    alphathr = -0.02;
    props.video.alphathr = alphathr;
    props.video.xlim = [min(tm) max(tm)];
    % [~,idx] = sort(props.kernsize,'descend');
    makenewinstr = true;
    props.video.ch = props.showidx(1:4);
    ninstr = 13;
else
    if isfield(props.video,'frame')
        slidepos = props.video.frame;
    else
        slidepos = 10;
    end

    if isfield(props.video,'inv')
        inv = props.video.inv;
    else
        inv = true;
    end

    if isfield(props.video,'climv')
        climv = props.video.climv;
    else
        climv = [0 0.01];
    end

    if isfield(props.video,'alphathr')
        alphathr = props.video.alphathr;
    else
        alphathr = -0.02;
    end

    if isfield(props.video,'instrumento')
        instrumento = props.video.instrumento;
        makenewinstr = false;
    else
        makenewinstr = true;
    end

    if ~isfield(props.video,'xlim')
        props.video.xlim = [min(props.video.tm) max(props.video.tm)];
    end  

    if ~isfield(props.video,'ch')
        props.video.ch = props.showidx(1:4);
    end

    ninstr = 13;
end


% setting notes and intruments --------------
for a=1
instrumentfile = fullfile(fileparts(which('Intan_gui')),'all_instruments.xml');
all_instruments = readstruct(instrumentfile);
instruments = {all_instruments.part_list.score_part.part_name}';
vch = props.ch(contains(props.ch,'V-'));

pitch = [repmat(["A" "B" "C" "D" "E" "F" "G"],1,7) "A" "B" "C"];
octave = ["0","0", repelem(["1","2","3","4","5","6","7"],1,7), "8"];
notes = join([pitch',octave'],'');
props.video.notes = notes;
props.video.pitch = pitch;
props.video.octave = octave;

instr_range = ["D5","C8"; "C4","A6"; "B3","E6"; "D3","B6"; "B1","B5";...
         "A3","E6"; "D3","A5"; "A2","E5"; "C2","A4"; "B1","G5";...
         "F3","A6"; "E2","E4"; "E2","E4"; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "A0","C8"; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""; "","";"","";...
         "",""; "",""; "",""];
end

if makenewinstr
    idx = (1:length(props.kernpos))';
    vsdidx = string(idx);
    ninstr = 13;
    instrumento = struct();
    % instruments panel ---------------
    for i=1:ninstr
        if i==1
            instr = 51;
        else
            instr = i;
        end
        rng = instr_range(instr,:);
        inotes = find(contains(notes,rng{1})):find(contains(notes,rng{2}));
        if ~isempty(vsdidx)
            lastone = length(inotes);
            lastone(lastone>length(vsdidx)) = length(vsdidx);
            vstr = join([vsdidx(1), vsdidx(lastone)],'-');
    %         vstr = join(vsdidx(1:lastone),',');
            nstr = [notes{inotes(1)} '-' notes{inotes(lastone)}];
            vsdidx(1:lastone) = [];
            chkv = 1;
            enable = 'on';
        else
            vstr = '-';
            chkv = 0;
            enable = 'off';
            nstr = join(instr_range(instr,:),'-');
        end
        instrumento(i).chkv = chkv;
        instrumento(i).enable = enable;
        instrumento(i).vstr = vstr;
        instrumento(i).nstr = nstr;
        instrumento(i).instr = instr;
    end
    props.video.instrumento = instrumento;
end



figure(vfig)
% props.video.tm = props.video.tm + diff(props.video.tm(1:2))*5;
sf = diff(props.video.tm(1:2));

% initializing video image ----------------------
for a=1
iaxr = axes('Units','normalized','Position',[0.3 0.39 0.32 0.58],'Tag','imgax');
props.video.img = image(props.im);
iaxr.XTick = [];
iaxr.YTick = [];

imult = [1,-1];
iax = axes('Units','normalized','Position',iaxr.Position,'Tag','imgax');
props.video.iax = iax;
iaxpos = iax.Position;
props.video.img = imagesc(props.video.imdata(:,:,slidepos)*imult(inv+1),'AlphaData',props.video.imdata(:,:,slidepos)>alphathr);
caxis(iax, climv)
iax.Tag = 'imgax';

iax.XTick = [];
iax.YTick = [];
iax.Color = 'none';


% cb = colorbar('Units','normalized','Position',[sum(iax.Position([1 3])) iax.Position(2) 0.01 iax.Position(4)]);
cb = colorbar('Units','normalized','Position',[iax.Position(1) iax.Position(2)-0.01 iax.Position(3) 0.01],'Location','south');
cb.Label.String = '-\DeltaF/F';

corridx = find(contains(props.ch,'V-'),1) - 1;
for r=1:length(props.kern_center)
    props.video.roi(r) = text(iax,props.kern_center(r,1),...
        props.kern_center(r,2), num2str(r),'Color','k',...
        'HorizontalAlignment','center','FontSize',13, 'Clipping','on','Tag',['rois' num2str(r)]);
end
% for r=1:4
%     strv = props.showlist(r);
%     idx = props.showidx(r) - corridx;
%     if contains(strv,'V-')
%         props.video.roi(r) = text(iax,props.kern_center(idx,1),...
%             props.kern_center(idx,2), num2str(idx),'Color','k',...
%             'HorizontalAlignment','center','FontSize',20, 'Clipping','on','Tag',['rois' num2str(r)]);
%     else
%         props.video.roi(r) = text(iax,1,1, ' ','Color','k',...
%             'HorizontalAlignment','center','FontSize',20, 'Clipping','on','Tag',['rois' num2str(r)]);
%     end
% end
end

idur = size(props.video.imdata,3);

% ---row, pix, invert, timestamp----------------
for a=1
uicontrol('Units','normalized','Position',[iaxpos(1) sum(iaxpos([2 4])) 0.03 0.03],...
    'Style','togglebutton','Tag','Raw','String','Raw','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[iaxpos(1)+0.03 sum(iaxpos([2 4])) 0.04 0.03],...
    'Style','togglebutton','Tag','roivpix','String','Pixels','Callback',@roivpix,'Enable','on');

uicontrol('Units','normalized','Position',[sum(iaxpos([1 3]))-0.16 sum(iaxpos([2 4])) 0.05 0.03],'Style','togglebutton',...
    'Tag','invert','String','inverted','Value',inv,'Callback',@invertim,'Enable','on');

xsize = size(props.video.imdata,2);
props.video.txtframe = text(xsize-85,10,sprintf('Frame: %i',slidepos),'FontSize',15,...
    'Color','w');
txttm = text(xsize-85, 25, sprintf('Time: %0.2f s',length(props.video.tm)*slidepos/idur*sf),...
    'FontSize',15,'Color','w');

props.video.txttm = txttm;
end

% time series data ------------------
for a=1
ch = props.ch;
hideidx = props.hideidx;
showidx = props.showidx;
str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

ax = gobjects(4,1);
axheight = 0.085;
topax = 0.91;
for a=1:length(ax)
    ax(a) = axes('Units','normalized','Position',[0.71 topax-axheight*(a-1) 0.285 0.085]);
    plt(a) = plot(props.tm,props.data(props.video.ch(a),:),'Tag',['plt' num2str(a)]);
    ax(a).YLabel.String = '\DeltaF/F';
    ax(a).XTick = [];

    uicontrol('Units','normalized','Position',[0.63 topax-axheight*(a-1) 0.05 0.05],'Style','popupmenu',...
        'Max',length(ch),'Min',1,'String',str','Tag',['channels' num2str(a)],'Value',props.video.ch(a),'Callback',@chimch);
end
ax(5) = axes('Units','normalized','Position',[ax(end).Position(1) 0.05 ax(end).Position(3) 0.605]);
props.video.kimg = imagesc(props.video.tm, 1:size(props.video.kerndata,2), props.video.kerndata'*imult(inv+1));
ax(5).YTick = 1:2:size(props.video.kerndata,2);
ax(5).YLabel.String = 'Neuron';
ax(5).XLabel.String = 'Time (s)';
ax(5).Tag = 'kimgax';
caxis(ax(5), climv)
axsize = sum(cellfun(@(x) x(4),{ax.Position}'));
ax(6) = axes('Units','normalized','Position',[ax(end).Position(1:3) axsize],'Color','none','Visible','off');
ref = rectangle('Position',[props.video.reference 0 sf 1],'FaceColor','k','Tag','ref');
rectangle('Position',[0 0 sf 1],'FaceColor',[0.5 1 0.5],'EdgeColor',[0.5 1 0.5],...
    'Tag','startframe1');
rectangle('Position',[max(props.video.tm) 0 sf 1],'FaceColor',[1 0.5 0.5],...
    'EdgeColor',[1 0.5 0.5],'Tag','stopframe1');
rectangle('Position',[0 0 sf 1],'FaceColor',[0.5 0.5 0.5],'Tag','cframe');
set(ax,'XLim',props.video.xlim);
ax(end).YLim = [0 1];
ax(end).Toolbar.Visible = 'off';
linkaxes(ax,'x')
end

%changing frames -------------------------------
for a=1
uicontrol('Units','normalized','Position',[0.46 0.27 0.1 0.03],'Style','slider',...
    'Value',slidepos,'Min',1,'Max',idur,'SliderStep',[1 1]/idur,'Callback',@chframe,...
    'Tag','imslider');

uicontrol('Units','normalized','Position',[0.46 0.24 0.02 0.03],'Style','pushbutton',...
    'Tag','fastback','String','<<','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.48 0.24 0.02 0.03],'Style','pushbutton',...
    'Tag','back','String','<','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.50 0.24 0.02 0.03],'Style','pushbutton',...
    'Tag','selectframe','String','+','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.52 0.24 0.02 0.03],'Style','pushbutton',...
    'Tag','forward','String','>','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.54 0.24 0.02 0.03],'Style','pushbutton',...
    'Tag','fastforward','String','>>','Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.46 0.21 0.1 0.03],'Style','pushbutton',...
    'Tag','reference','String','Set reference frame','Callback',@setreference,'Enable','on');
end

% ----colormap--alphathr------------------------
for a=1
uicontrol('Units','normalized','Position',[0.45 0.16 0.11 0.03],'Style','text',...
    'String','Colormap axis','HorizontalAlignment','center','Enable','on');

uicontrol('Units','normalized','Position',[0.5 0.06 0.06 0.03],'Style','edit',...
    'Tag','alphathr','String',num2str(alphathr),'HorizontalAlignment','center',...
    'Callback',@chframe,'Enable','on');

uicontrol('Units','normalized','Position',[0.44 0.045 0.05 0.05],'Style','text',...
    'String','Alpha threshold','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.5 0.10 0.06 0.03],'Style','edit',...
    'Tag','cmap1','String',num2str(climv(1)),'HorizontalAlignment','center',...
    'Callback',@setcmap,'Enable','on');

uicontrol('Units','normalized','Position',[0.45 0.095 0.04 0.03],'Style','text',...
    'String','lower','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.5 0.14 0.06 0.03],'Style','edit',...
    'Tag','cmap2','String',num2str(climv(2)),'HorizontalAlignment','center',...
    'Callback',@setcmap,'Enable','on');

uicontrol('Units','normalized','Position',[0.45 0.135 0.04 0.03],'Style','text',...
    'String','upper','HorizontalAlignment','right','Enable','on');
end

% ----ROI params--------------------------
for a=1
uicontrol('Units','normalized','Position',[0.45 0.00 0.04 0.03],'Style','text',...
    'String','text color','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.5 0.0 0.06 0.03],'Style','popupmenu',...
    'Max',5,'Min',1,'String',["black","white","red","green","blue"],'Tag','textcolor','Value',1,'Callback',@txtcolor);
end

% -----video params-------------------------
for a=1
uicontrol('Units','normalized','Position',[0.29 0.31 0.07 0.03],'Style','text',...
    'String','Frame interval (ms)','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.37 0.32 0.06 0.03],'Style','edit',...
    'Tag','framerate','String',num2str(fr),'HorizontalAlignment','center',...
    'Callback',@framerate,'Enable','on');
end


% -----movie params-------------------

% % props.kernsize = diff([props.kernpos ; length(props.det)]);
% % [~,idx] = sort(props.kernsize,'descend');
% idx = (1:length(props.kernpos))';
% vsdidx = string(idx);
% height = 0.027;
% ninstr = 13;
% 
% % instruments panel ---------------
height = 0.027;
for i=1:ninstr
    y = 0.96-height*(i-1);
    uicontrol('Units','normalized','Position',[0.01 y 0.02 height],'Style','checkbox',...
        'Tag',['instrument' num2str(i)],'HorizontalAlignment','center','Value',instrumento(i).chkv,...
        'Enable','on','callback',@use_instrument);
    uicontrol('Units','normalized','Position',[0.03 y 0.09 height],'Style','edit',...
        'Tag',['instrument' num2str(i)],'String',instrumento(i).nstr,'HorizontalAlignment','center',...
        'Enable',instrumento(i).enable,'callback',@update_notes);
    uicontrol('Units','normalized','Position',[0.12 y 0.09 height],'Style','edit',...
        'Tag',['instrument' num2str(i)],'String',instrumento(i).vstr,'HorizontalAlignment','center',...
        'Enable',instrumento(i).enable,'callback',@update_notes);
    uicontrol('Units','normalized','Position',[0.21 y 0.09 height],'Style','popupmenu',...
        'Tag',['instrument' num2str(i)],'String',instruments,'Value',instrumento(i).instr,'HorizontalAlignment','center',...
        'Enable',instrumento(i).enable,'callback',@update_notes);
end

% notes axis-----------
for a=1
nax = axes('units','normalized','Position',[0.02 0.03 0.18 0.58]);
for i=1:ninstr
    props.video.notesgraph(i) = scatter(-10, -10,'filled');hold on
end
nax.XLim = [1 length(pitch)];
nax.XTick = 1:2:length(pitch);
nax.XTickLabel = pitch(1:2:end);
nax.XTickLabelRotation = 0;
nax.YLim = [1 length(vch)];
nax.YTick = 1:2:length(vch);
nax.YLabel.String = 'Neuron';
nax.YDir = 'reverse';
nax.FontSize = 8;
nax.YGrid = 'on';
nax.XGrid = 'on';

obj = findobj(vfig,'Tag','instrument1');
props.video.knotes = getnotes(obj(2),props);
setnotes(props.video.notesgraph, props.video.knotes)
end

% uicontrol('Units','normalized','Position',[0.20 0.60 0.05 0.03],'Style','text',...
%     'String','Select Audio Channels','HorizontalAlignment','center');
% 
% uicontrol('Units','normalized','Position',[0.20 0.03 0.05 0.58],'Style','listbox',...
%     'String',vch,'Max',length(ch),'Min',1,'HorizontalAlignment','center',...
%     'Tag','selectvsd','FontSize',4.1,'Enable','on');

uicontrol('Units','normalized','Position',[0.21 0.28 0.07 0.03],'Style','edit',...
    'Tag','exportonly','String','all','HorizontalAlignment',...
    'center','Enable','on');

uicontrol('Units','normalized','Position',[0.21 0.31 0.07 0.03],'Style','text',...
    'String','Channels to write music','HorizontalAlignment','center',...
    'TooltipString','Type which channels to write music for.');

% audio video settings-------------------------
for a=1
uicontrol('Units','normalized','Position',[0.31 0.11 0.11 0.03],'Style','text',...
    'String','Video time window','HorizontalAlignment','center');

% uicontrol('Units','normalized','Position',[0.37 0.28 0.06 0.03],'Style','edit',...
%     'Tag','notegap','String','5','HorizontalAlignment',...
%     'center','Enable','on');
% 
% uicontrol('Units','normalized','Position',[0.30 0.275 0.06 0.03],'Style','text',...
%     'String','Minimum note gap (fr)','HorizontalAlignment','right','Enable','on',...
%     'TooltipString','The minimum gap between notes');
% 
% uicontrol('Units','normalized','Position',[0.37 0.24 0.06 0.03],'Style','edit',...
%     'Tag','harmonics','String','5','HorizontalAlignment',...
%     'center','Enable','on');
% 
% uicontrol('Units','normalized','Position',[0.31 0.235 0.05 0.03],'Style','text',...
%     'String','# harmonics','HorizontalAlignment','right','Enable','on',...
%     'TooltipString','Number of harmonics for each note.  The greater the number the more like a piano');
%
% uicontrol('Units','normalized','Position',[0.37 0.20 0.06 0.03],'Style','edit',...
%     'Tag','noteduration','String','0.7','HorizontalAlignment',...
%     'center','Enable','on');

uicontrol('Units','normalized','Position',[0.225 0.18 0.04 0.03],'Style','edit',...
    'Tag','timesig','String','1/1','HorizontalAlignment',...
    'center','Enable','off');

uicontrol('Units','normalized','Position',[0.21 0.21 0.07 0.03],'Style','text',...
    'String','Time signature','HorizontalAlignment','center',...
    'TooltipString','Type which channels to write music for.');

uicontrol('Units','normalized','Position',[0.37 0.28 0.06 0.03],'Style','edit',...
    'Tag','beatsperm','String','112.5','HorizontalAlignment',...
    'center','Enable','off');

uicontrol('Units','normalized','Position',[0.28 0.275 0.08 0.03],'Style','text',...
    'String','Beats per minute','HorizontalAlignment','right',...
    'TooltipString','The minimum gap between notes');

props.video.durationsfrac = ["1/16","1/8"   ,"3/16"  ,"1/4"    ,"3/8"    ,"1/2" ,"3/4" ,"1"];
props.video.durationsnum  = [1/16 , 1/8     , 3/16   , 1/4     , 3/8     , 1/2  , 3/4  , 1 ];
props.video.durationsstr  = ["16th","eighth","eighth","quarter","quarter","half","half","whole"];
props.video.dots  = logical([0     ,0       ,   1    ,0        ,1        ,0     ,1     ,0 ]);

uicontrol('Units','normalized','Position',[0.37 0.24 0.06 0.03],'Style','popupmenu',...
    'Tag','restduration','String',props.video.durationsfrac,'Value',1,'HorizontalAlignment',...
    'center','Enable','off');

uicontrol('Units','normalized','Position',[0.29 0.235 0.07 0.03],'Style','text',...
    'String','Shortest rest','HorizontalAlignment','right','Enable','on',...
    'TooltipString','Number of harmonics for each note.  The greater the number the more like a piano');

uicontrol('Units','normalized','Position',[0.37 0.20 0.06 0.03],'Style','popupmenu',...
    'Tag','noteduration','String',props.video.durationsfrac,'Value',1,'HorizontalAlignment',...
    'center','Enable','off');

uicontrol('Units','normalized','Position',[0.29 0.195 0.07 0.03],'Style','text',...
    'String','Minumu duration','HorizontalAlignment','right','Enable','on',...
    'TooltipString','Duration of each note.');



uicontrol('Units','normalized','Position',[0.37 0.09 0.06 0.03],'Style','edit',...
    'Tag','startframe','String',num2str(min(props.video.tm)),'HorizontalAlignment',...
    'center','Callback',@startstop,'Enable','on');

uicontrol('Units','normalized','Position',[0.32 0.085 0.04 0.03],'Style','text',...
    'String','start (s)','HorizontalAlignment','right','Enable','on');

uicontrol('Units','normalized','Position',[0.37 0.05 0.06 0.03],'Style','edit',...
    'Tag','stopframe','String',num2str(max(props.video.tm)),'Callback',@startstop,...
    'HorizontalAlignment','center','Enable','on');

uicontrol('Units','normalized','Position',[0.32 0.04 0.04 0.03],'Style','text',...
    'String','stop (s)','HorizontalAlignment','right','Enable','on');


uicontrol('Units','normalized','Position',[0.37 0.16 0.06 0.03],'Style','edit',...
    'Tag','movfr','String','30','HorizontalAlignment',...
    'center','Enable','on');

uicontrol('Units','normalized','Position',[0.30 0.155 0.06 0.03],'Style','text',...
    'String','Frame rate (f/s)','HorizontalAlignment','right','Enable','on');


uicontrol('Units','normalized','Position',[0.36 0.00 0.09 0.04],'Style','pushbutton',...
    'String','Make Audio/Video','Callback',@exportav,'Enable','on','Tag','audiovideo');

uicontrol('Units','normalized','Position',[0.28 0.00 0.08 0.04],'Style','pushbutton',...
    'String','Make Audio','Callback',@exportav,'Enable','on','Tag','audioonly');
end

guidata(hObject,props)
chframe(findobj(vfig,'Tag','imslider'))

function update_notes(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
props.video.knotes = getnotes(hObject,props);
setnotes(props.video.notesgraph, props.video.knotes)
props = update_instrumento(props);
guidata(intan,props)

function setnotes(notesgraph,knotes)
showg = false(1,0);
for i=1:length(knotes)
    set(notesgraph(i),'XData',knotes(i).noteidx,'YData',knotes(i).vsdidx)
    instrumentog = findobj(notesgraph(1).Parent.Parent,'Tag',['instrument' num2str(i)]);
    showg(i) = instrumentog(4).Value;
end
legend(notesgraph(showg), {knotes(showg).instrument})

function knotes = getnotes(hObject,props)
vfig = hObject.Parent;
notes = props.video.notes;
instr = 1;
allvsd = zeros(1,0);
instrumentog = findobj(vfig,'Tag',['instrument' num2str(instr)]);
while ~isempty(instrumentog)
    rstr = get(instrumentog(3),'String');
    vstr = get(instrumentog(2),'String');
    rgrp = strsplit(rstr,',');
    vgrp = strsplit(vstr,',');
    set(instrumentog(2:3),'ForegroundColor','black')  
    
    knotes(instr).noteidx = zeros(1,0);
    knotes(instr).vsdidx = zeros(1,0);
    if get(instrumentog(4),'Value')
        for g=1:length(rgrp)
            notest = regexp(rgrp{g},'[ABCDEFG][0-8]','match');
            noteidx = cellfun(@(x) find(contains(notes,x)),notest);
            if contains(rgrp{g},'-') && length(noteidx)>1
                subnotes = noteidx(1):noteidx(2);
            else
                subnotes = noteidx;
            end
            knotes(instr).noteidx = [knotes(instr).noteidx subnotes];
        end

        for g=1:length(vgrp)
            vsdest = regexp(vgrp{g},'[0-9]+','match');
            if contains(vgrp{g},'-') && length(vsdest)>1
                subvsd = str2double(vsdest{1}):str2double(vsdest{2});
            else
                subvsd = str2double(vsdest{1});
            end
            knotes(instr).vsdidx = [knotes(instr).vsdidx subvsd];
        end
        
        if length(knotes(instr).noteidx) ~= length(knotes(instr).vsdidx)
            set(instrumentog(3),'ForegroundColor','red')
            error(['not all specified notes have corresponding roi for instrument ' num2str(instr)])
        end

        if length(knotes(instr).vsdidx)~=length(unique(knotes(instr).vsdidx))
             set(instrumentog(2),'ForegroundColor','red')
            error(['roi is used more than once within instrument ' num2str(instr)])
        end

        if any(ismember(allvsd,knotes(instr).vsdidx))
            set(instrumentog(2),'ForegroundColor','red')
            error(['roi in instrument ' num2str(instr) ' is used in another instrument'])
        end

        allvsd = [allvsd, subvsd];
    end
    knotes(instr).instrument = instrumentog(1).String{instrumentog(1).Value};
    instr = instr + 1;
    instrumentog = findobj(vfig,'Tag',['instrument' num2str(instr)]);
end

function use_instrument(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
idx = regexp(hObject.Tag,'\d+','match');
seten = ["off","on"];
obj = findobj(hObject.Parent,'Tag',['instrument' idx{1}]);
set(obj(1:3),'Enable',seten(hObject.Value+1))
props.video.instrumento(idx).chkv = hObject.Value;

function saveframe(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
vfig = hObject.Parent.Parent;

vsd = props.files(contains(props.files(:,2),'tsm'),2);
[file,path,indx] = uiputfile('*.tiff','Save Video',replace(vsd,'.tsm','_videoframe.tiff'));

pos = get(findobj(vfig,'Tag','cframe'),'Position');
frame = find(props.video.tm>=pos(1),1);
alphathr = str2double(get(findobj(vfig,'Tag','alphathr'),'String'));
roi = get(findobj(vfig,'Tag','roivpix'),'Value');
raw = get(findobj(vfig,'Tag','Raw'),'Value');
inv = get(findobj(vfig,'Tag','invert'),'Value')+1;
imult = [1,-1];

imgax = findobj(vfig,'Tag','imgax');
axes(imgax)
clim = caxis;
alpha = 0.7;

iframe_raw = repmat(props.video.imdatar(:,:,frame),[1,1,3]);
iframe_pix = props.video.imdata(:,:,frame)*imult(inv);
iframe_roi = props.video.imdataroi(:,:,frame)*imult(inv);

map = colormap;
ncol = size(map,1);
s = round(1+(ncol-1)*(iframe_pix - clim(1))/(clim(2) - clim(1)));
rgb_pix = ind2rgb(s,map);

sroi = round(1+(ncol-1)*(iframe_roi - clim(1))/(clim(2) - clim(1)));
rgb_roi = ind2rgb(sroi,map);

iframe_raw = iframe_raw/(max(iframe_raw(:)));

t=Tiff(fullfile(path,file),'w');
tagstruct.ImageLength = size(rgb_pix,1); % image height
tagstruct.ImageWidth = size(rgb_pix,2); % image width
tagstruct.Photometric = Tiff.Photometric.RGB; % https://de.mathworks.com/help/matlab/ref/tiff.html
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = 3;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; % groups rgb values into a single pixel instead of saving each channel separately for a tiff image
tagstruct.Software = 'MATLAB';
setTag(t,tagstruct)
write(t,squeeze(im2uint8(iframe_raw)));

writeDirectory(t);
setTag(t,tagstruct)
write(t,squeeze(im2uint8(rgb_pix))) %%%appends the next layer to the same file t

writeDirectory(t);
setTag(t,tagstruct)
write(t,squeeze(im2uint8(rgb_roi))) %%%appends the next layer to the same file t

% do this for as many as you need, or put it in a loop if you can
close(t) 

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

function exportav(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
vsd = props.files(contains(props.files(:,2),'tsm'),2);

[file,path,indx] = uiputfile('*.mp4','Save Video',replace(vsd,'.tsm','_video.mp4'));
file = replace(file,'.mp4','');

imslide = findobj(hObject.Parent,'Tag','imslider');

pos = get(findobj(hObject.Parent,'Tag','cframe'),'Position');

start = get(findobj(hObject.Parent,'Tag','startframe'),'String');
stop = get(findobj(hObject.Parent,'Tag','stopframe'),'String');
start = str2double(start);
stop = str2double(stop);
start = find(props.video.tm>start,1);
stop = find(props.video.tm>stop,1);
tmidx = start:stop;

alphathr = str2double(get(findobj(hObject.Parent,'Tag','alphathr'),'String'));
idur = length(props.video.tm);

det = props.det;
kernpos = props.kernpos;
nroi = length(kernpos);

vfr = str2double(get(findobj(hObject.Parent,'Tag','movfr'),'String'));% frame rate
sf = diff(props.video.tm(1:2));
fs = 44100;
audio = zeros(1,(stop-start)*fs/vfr);

% dur = str2double(get(findobj(hObject.Parent,'Tag','noteduration'),'String'));
% nharm = str2double(get(findobj(hObject.Parent,'Tag','harmonics'),'String'));

% spike = false(stop-start,nroi);
% for r=1:ra
%     spike(ra,randi(nroi,[round(nroi/ra),1])) = true;
% end

equalize = ones(1,nroi);
% equalize([8 63 35 29 74]) = 0.2;

roi = get(findobj(hObject.Parent,'Tag','roivpix'),'Value');
inv = get(findobj(hObject.Parent,'Tag','invert'),'Value')+1;
imult = [1,-1];

kerndata = props.video.kerndata*imult(inv)>alphathr;
props.video.kerndatav = kerndata(start:stop,:);

writemusic(hObject.Parent,props,fullfile(path,file))

if strcmp(hObject.Tag,'audiovideo')
    vid = VideoWriter(fullfile(path,file),'MPEG-4');
    vid.FrameRate = vfr;
    open(vid)
    for f=start:stop
%         aidx = (f-start+1) + (f-start)*fs/vfr;
%         for k=1:length(kernpos)
%             if kerndata(f,k) 
%                 freq = k*430/nroi+70;
%                 ndur = kerndata(f,k)*sr*2+dur;
%                 note = makesound(freq,ndur,fs,nharm);
%                 nidx = round(aidx:aidx+length(note)-1);
%                 nidx(nidx>length(audio)) = [];
%                 audio(nidx) = audio(nidx) + note(1:length(nidx))*equalize(k);
%             end
%         end
    
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
end

% audiowrite( fullfile(path,[file '.wav']), audio/max(audio), fs,'BitsPerSample',32)

function writemusic(vfig,props,file)
% all_instruments = readstruct('all_instruments.xml');

 % delete line after close video gui 2/2/23 ---->
props.video.durationsfrac = ["1/16","1/8"   ,"3/16"  ,"1/4"    ,"3/8"    ,"1/2" ,"3/4" ,"1"];
props.video.durationsnum  = [1/16 , 1/8     , 3/16   , 1/4     , 3/8     , 1/2  , 3/4  , 1 ];
props.video.durationsstr  = ["16th","eighth","eighth","quarter","quarter","half","half","whole"];
props.video.dots  = logical([0     ,0       ,   1    ,0        ,1        ,0     ,1     ,0 ]);
% <---- delete line after close video gui 2/2/23

music.versionAttribute = '4.0';


dur = get(findobj(vfig,'Tag','noteduration'),'Value');
durtype = props.video.durationsstr(dur);
dots = props.video.dots(dur);
rest = get(findobj(vfig,'Tag','restduration'),'Value');
rest = props.video.durationsnum(rest);

% tmsigobj = get(findobj(vfig,'Tag','timesig'),'String');
% tmsig = str2double(strsplit(tmsigobj,'/'));
tmsig = [1 1];
bpm = str2double(get(findobj(vfig,'Tag','beatspers'),'String'));


notedur = props.video.durationsnum(dur)*tmsig(2)/(bpm/60);
ra = rest*tmsig(2)/(bpm/60);
fr = get(findobj(vfig,'Tag','movfr'),'Value');
rai = round(ra*fr); 

frmpn = round(tmsig(1)/tmsig(2)/props.video.durationsnum(dur));

estr = get(findobj(vfig,'Tag','exportonly'),'String');
egrp = strsplit(estr,',');
eidx = zeros(1,0);
if contains(estr,'all')
    eidx = 1:size(props.video.kerndata,2);
else
    for g=1:length(egrp)
        est = regexp(egrp{g},'[0-9]+','match');
        if contains(egrp{g},'-') && length(est)>1
            subvsd = str2double(est{1}):str2double(est{2});
        else
            subvsd = str2double(est{1});
        end
        eidx = [eidx subvsd];
    end
end

% kernstr = char(props.video.kerndatav(:,eidx)+48);
% spikes = zeros(size(kernstr));
% key = [repelem('0',rai) '[1]+'];
% for k=1:size(kernstr,2)
%     [startsp,stopsp] = regexp(kernstr(:,k)',key);
%     spikes(startsp,k) = stopsp-startsp;
% end

knotes = props.video.knotes;
for k=1:length(knotes)
    if ~isempty(knotes(k).vsdidx) && any(ismember(knotes(k).vsdidx, eidx))
        idx = ismember(knotes(k).vsdidx, eidx);
        parts(k).noteidx = knotes(k).noteidx(idx);
        parts(k).pitch = props.video.pitch(parts(k).noteidx);
        parts(k).octave = double(props.video.octave(parts(k).noteidx));
        parts(k).vsdidx = knotes(k).vsdidx(idx);
        parts(k).instrument = knotes(k).instrument;
    end
end

for p=1:length(parts)
    pname = ['P' num2str(p)];
    music.part_list.score_part(p).idAttribute = pname;
    music.part_list.score_part(p).part_name = parts(p).instrument;
    music.part_list.score_part(p).score_instrument.idAttribute = [pname '-I1'];
    music.part_list.score_part(p).score_instrument.instrument_name = parts(p).instrument;
    music.part(p).idAttribute = ['P' num2str(p)];
end

kerndatav = props.video.kerndatav;
assignin('base',['kerndatam' num2str(1)],kerndatav(:, parts(1).vsdidx))
assignin('base',['kerndatam' num2str(2)],kerndatav(:, parts(2).vsdidx))
for m=1:floor(size(kerndatav,1)/frmpn)
    kerndatam = kerndatav((1:frmpn) + (m-1)*frmpn, :);
    for p=1:length(parts)
        kerndatamp = kerndatam(:, parts(p).vsdidx);
        pitch = parts(p).pitch;
        octave = parts(p).octave;
        music.part(p).measure(m).numberAttribute = num2str(m);
        if m==1
            music.part(p).measure(m).attributes.key.fifths = 0;
            music.part(p).measure(m).attributes.time.beats = tmsig(1);
            music.part(p).measure(m).attributes.time.beat_type = tmsig(2);
            music.part(p).measure(m).attributes.staves = 1;
            if any(parts(p).noteidx>24) || all(parts(p).noteidx>=21) 
                music.part(p).measure(m).attributes.clef.sign = 'G';
                music.part(p).measure(m).attributes.clef.line = 2;
            else
                music.part(p).measure(m).attributes.clef.sign = 'F';
                music.part(p).measure(m).attributes.clef.line = 4;
            end
            music.part(p).measure(m).direction.placementAttribute = 'above';
            music.part(p).measure(m).direction.direction_type.words = 'Moderato';
            music.part(p).measure(m).direction.sound.tempoAttribute = '450';
        end
        
        n = 1;
        for t=1:frmpn
            if n==1
                music.part(p).measure(m).note(n) = struct('chord',[],'rest',[],...
                    'pitch',[],'duration',[],'voice',[],'type',[],'dot',[],'staff',[]);
            end

            if any(kerndatamp(t,:))
                for s=1:size(kerndatamp,2)
                    if kerndatamp(t,s)
                        music.part(p).measure(m).note(n).chord = double(sum(kerndatamp(t,:))>1 & s>find(kerndatamp(t,:),1));
                        music.part(p).measure(m).note(n).pitch.step = pitch(s);
                        music.part(p).measure(m).note(n).pitch.octave = octave(s);
                        music.part(p).measure(m).note(n).duration = 1;
                        music.part(p).measure(m).note(n).type = durtype;
                        music.part(p).measure(m).note(n).dot = double(dots);
                        n = n + 1;
                    end
                end
            else
                music.part(p).measure(m).note(n).rest = 1;
                music.part(p).measure(m).note(n).duration = 1;
                music.part(p).measure(m).note(n).type = durtype;
                music.part(p).measure(m).note(n).dot = double(dots);
                n = n + 1;
            end
        end
    end
end


writestruct(music,[file '.xml'],'StructNodeName','score_partwise')

fid = fopen([file '.xml'],'r');
fstr = fread(fid,'*char')';
fclose(fid);

fstr = replace(fstr,'_','-');
fstr = replace(fstr,'<chord>0</chord>','');
fstr = replace(fstr,'<chord>1</chord>','<chord/>');
fstr = replace(fstr,'<rest>1</rest>','<rest/>');
fstr = replace(fstr,'<dot>0</dot>','');
fstr = replace(fstr,'<dot>1</dot>','<dot/>');
fstr = replace(fstr,'<?xml version="1.0" encoding="UTF-8"?>',...
    ['<?xml version="1.0" encoding="UTF-8" standalone="no"?>',newline,...
    '<!DOCTYPE score-partwise PUBLIC',...
    ' "-//Recordare//DTD MusicXML 4.0 Partwise//EN"',... 
    ' "http://www.musicxml.org/dtds/partwise.dtd">']);

fid = fopen([file '.musicxml'],'w');
fprintf(fid,'%s',fstr);
fclose(fid);
disp(['wrote:   ' file '.musicxml'])

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
note = note.*(1-exp(-tm/(max(tm)/40))).*exp(-tm/(max(tm)/5));
note = note*(4*exp(-freq/100)+1);% generate equal perceptable noise

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
kimgax = findobj(hObject.Parent,'Tag','kimgax');
idx = str2double(hObject.Tag(end));
axes(imgax)
vals = caxis;
vals(idx) = str2double(hObject.String);
caxis(imgax,vals)
caxis(kimgax,vals)
props.video.climv = vals;
plt = findobj(hObject.Parent,'Tag','plt1');
props.video.xlim = get(plt.Parent,'XLim');
guidata(intan,props)

function raw(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
frame = round(get(findobj(hObject.Parent,'Tag','imslider'),'Value'));
if hObject.Value
    imframe = repmat(props.video.imdatar(:,:,frame),1,1,3);
    set(props.video.img,'CData',imframe/max(imframe(:))) 
%     set(props.video.img,'CData',props.video.imdatar(:,:,frame))
    caxis(props.video.iax,'auto')
else
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
[imdatas,fparam,fun,imdata,tm,imdataroi,kerndata] = getimdata(vsd,ref,hObject.Parent);
props.video.imdata = permute(imdatas,[2,1,3]);
props.video.imdatar = permute(imdata,[2,1,3]);
props.video.imdataroi = permute(imdataroi,[2,1,3]);
props.video.kerndata = kerndata;
props.video.tm = tm + diff(tm(1:2))*5;% don't know why this 5* needs to be done but it does
props.video.fun = fun;
props.video.fparam = fparam;
props.video.reference = 0;

slider = findobj(hObject.Parent,'Tag','imslider');
set(slider,'Max',size(props.video.imdata,3))
set(slider,'SliderStep',[1 1]/size(props.video.imdata,3))

frame = round(get(findobj(hObject.Parent,'Tag','imslider'),'Value'));
roi = get(findobj(hObject.Parent,'Tag','roivpix'),'Value');
alphathr = str2double(get(findobj(hObject.Parent,'Tag','alphathr'),'String'));
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

function [imdatas,fparam,fun,imdata,tm,imdatarois,kerndata] = getimdata(vsd,ref,vfig,ifi)
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
set(findobj(vfig,'Tag','progtxt'),'String',['reading image file ' vsd{1}],'Position',[0.72 0.12 0.25 0.04]);
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
kerndata = kerndata(1:s,:);

if ref>size(imdata,3); ref = 1;end

f0 = repmat(imdata(ref,:),size(imdata,1),1);
imdatas = (imdata - f0)./f0;

f0 = repmat(imdataroi(ref,:),size(imdataroi,1),1);
imdataroi = (imdataroi - f0)./f0;

f0 = repmat(kerndata(ref,:),size(kerndata,1),1);
kerndata = (kerndata - f0)./f0;

fun = @(p,x) p(1).*(1 - exp(x./-p(2))) + p(3).*(1 - exp(x./-p(4))) + p(5).*(1 - exp(x./-p(6)));
% [fun] = makefun(3);
p0 = ones(1,6);
flimits = inf([1,6]);
opts = optimset('Display','off','Algorithm','levenberg-marquardt');

tm = ((sidx+5)*sr)';% for some reason I need to add five frames of time

set(findobj(vfig,'Tag','progtxt'),'String',['calculate pixel bleaching ' vsd{1}]);

fparam = nan(xsize*ysize,length(p0));

ds = round(800/interval);

% pixel bleaching
tic
for p=1:size(imdatas,2)
    pixd = double(imdatas(1:ds:end,p));
    fparam(p,:) = lsqcurvefit(fun,p0,tm(1:ds:end),pixd,-flimits,flimits,opts);
    imdatas(:,p) = imdatas(:,p) - fun(fparam(p,:),tm);
    if mod(p,500)==0%round(size(imdata,2)/52))==0
         set(progress,'Position',[0 0 p/size(imdatas,2) 1]);pause(0.01)
    end
end
toc


set(findobj(vfig,'Tag','progtxt'),'String',['calculate ROI bleaching ' vsd{1}]);

imdatarois = imdataroi;
fparamr = nan(length(kernpos),length(p0));

%ROI bleaching
tic
for k=1:length(kernpos)
    kIdx = det(kernpos(k)+1:kernpos(k)+kernel_size(k));
    fparamr(k,:) = lsqcurvefit(fun,p0,tm(1:ds:end),kerndata(1:ds:end,k),-flimits,flimits,opts);
    kerndata(:,k) =  kerndata(:,k)  - fun(fparamr(k,:),tm);
    imdatarois(:,kIdx) = repmat( kerndata(:,k), 1, length(kIdx));
    set(progress,'Position',[0 0 k/length(kernpos) 1]);pause(0.01)
end
toc

imdatas = reshape(imdatas',[256, 256, length(sidx)]);
imdatarois = reshape(imdatarois',[256, 256, length(sidx)]);
imdata = reshape(imdata',[256, 256, length(sidx)]);

set(findobj(vfig,'Tag','progtxt'),'String',' ','Position',[5.72 0.12 0.25 0.04]);
set(findobj(vfig,'Tag','progax'),'Position',[10 0.05 0.25 0.05]);
pause(0.01)

function chframe(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
slider = findobj(hObject.Parent,'Tag','imslider');
pos = get(findobj(hObject.Parent,'Tag','cframe'),'Position');
if strcmp(hObject.Tag,'imslider')
    frame = round(get(slider,'Value'));
elseif strcmp(hObject.Tag,'selectframe')
    tm = ginput(1);disp(tm)
    frame = find(props.video.tm>=tm(1),1);
elseif any(["<<","<","+",">",">>"]==hObject.String)
    chidx = strcmp(["<<","<","+",">",">>"],hObject.String);
    fast = 10;
    chval = [-fast,-1,0,1,fast];
    frame = find(props.video.tm>=pos(1),1) + chval(chidx);
    frame(frame<1) = 1;
else
    frame = round(get(slider,'Value'));
end
pos(1) = props.video.tm(frame);
set(findobj(hObject.Parent,'Tag','cframe'),'Position',pos)

alphathr = str2double(get(findobj(hObject.Parent,'Tag','alphathr'),'String'));

set(slider,'Value',frame)
roi = get(findobj(hObject.Parent,'Tag','roivpix'),'Value');
raw = get(findobj(hObject.Parent,'Tag','Raw'),'Value');

inv = get(findobj(hObject.Parent,'Tag','invert'),'Value')+1;

imult = [1,-1];
if roi
    iframe = props.video.imdataroi(:,:,frame)*imult(inv);
    set(props.video.img,'CData',iframe)
    set(props.video.img,'AlphaData',(iframe>alphathr)*0.7)
    caxis(props.video.iax,props.video.climv)
else
    if raw
        iframe = repmat(props.video.imdatar(:,:,frame),[1,1,3]);
        set(props.video.img,'CData',iframe/max(iframe(:)));
        set(props.video.img,'AlphaData',iframe(:,:,1)>-inf);
        caxis(props.video.iax,'auto')
    else
        iframe = props.video.imdata(:,:,frame)*imult(inv);
        set(props.video.img,'CData',iframe)
        set(props.video.img,'AlphaData',(iframe>alphathr))
        caxis(props.video.iax,props.video.climv)
    end
end
idur = size(props.video.imdataroi,3);
sfr = diff(props.video.tm(1:2));
props.video.txtframe.String = sprintf('Frame: %i',frame);
props.video.txttm.String = sprintf('Time: %0.2f s',(length(props.video.tm)*frame/idur)*sfr);

props.video.frame = frame;
props.video.alphathr = alphathr;
props.video.inv = logical(inv-1);

plt = findobj(hObject.Parent,'Tag','plt1');
props.video.xlim = get(plt.Parent,'XLim');

guidata(intan,props)

function chimch(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
idx = hObject.Value;
objidx = num2str(hObject.Tag(end));
ax = findobj(hObject.Parent,'Tag',['plt' objidx]);
set(ax,'YData',props.data(idx,:))
txt = findobj(hObject.Parent,'Tag',['rois' hObject.Tag(end)]);
corridx = find(contains(props.ch,'V-'),1) - 1;


plt = findobj(hObject.Parent,'Tag','plt1');
props.video.xlim = get(plt.Parent,'XLim');
props.video.ch(str2double(objidx)) = idx;
guidata(intan,props)

function setreference(hObject,eventdata)
intan = findobj('Tag',guidata(hObject));
props = guidata(intan);
[x,~] = ginput(1);

set(findobj(hObject.Parent,'Tag','progtxt'),'String','Processing...','Position',[0.72 0.12 0.25 0.04]);

refr = find(props.video.tm>x,1);
ref = findobj(hObject.Parent,'Tag','ref');
ref.Position(1) = x;
pause(0.1)
adjustdata(intan,hObject.Parent)
chframe(findobj(hObject.Parent,'Tag','imslider'))
set(findobj(hObject.Parent,'Tag','progtxt'),'String',' ','Position',[5.72 0.12 0.25 0.04]);

function adjustdata(intan,vfig)
props = guidata(intan);

pos = get(findobj(vfig,'Tag','ref'),'Position');
refr = find(props.video.tm>pos(1),1);
props.video.reference = pos(1);

f0 = props.video.imdata(:,:,refr);
props.video.imdata = props.video.imdata - repmat(f0,1,1,size(props.video.imdata,3));
f0 = props.video.imdataroi(:,:,refr);
props.video.imdataroi = props.video.imdataroi - repmat(f0,1,1,size(props.video.imdataroi,3));
f0 = props.video.kerndata(refr,:);
props.video.kerndata = props.video.kerndata - repmat(f0,size(props.video.kerndata,1),1);

inv = get(findobj(vfig,'Tag','invert'),'Value')+1;
imult = [1,-1];
set(props.video.kimg,'CData',props.video.kerndata'*imult(inv))

plt = findobj(vfig,'Tag','plt1');
props.video.xlim = get(plt.Parent,'XLim');

guidata(intan,props)

%% vsd frame image and ROI methods
function loadim(hObject,eventdata)
props = guidata(hObject);
[file, path, ~] = uigetfile({'*.tif';'.png';'.jpeg'},'Select file','MultiSelect','off');
if ~any(file); return;end

im = loadit(path,file);
while ~all(size(im,1:2)==size(props.im,1:2)) && ~isempty(file)
    if size(im,1)/size(props.im,1)==size(im,2)/size(props.im,2)
        im = imresize(im,size(props.im,1)/size(im,1));
        disp('Changed the image size to size of VSD frames')
    else
        msgbox('Image not the same aspect ratio as the VSD file')
        [file, path, ~] = uigetfile({'*.tif';'.png';'.jpeg'},'Select file','MultiSelect','off');
        if isempty(file);return;end
        im = loadit(path,file);
    end
end


fig = figure('MenuBar','none');
fig.Position([3 4]) = [700 200];

axes('Position',[0.6 0 0.4 1])
imex = imshow(im);

[path0,file0,ext0] = fileparts(props.files{1,2});
uicontrol(fig,"Units","normalized","Position",[0.1 0.8 0.17 0.1], "Style","text","String",[file0,ext0],"FontSize",8)
uicontrol(fig,"Units","normalized","Position",[0.27 0.8 0.17 0.1], "Style","text","String",file,"FontSize",8)
uicontrol(fig,"Units","normalized","Position",[0.44 0.8 0.16 0.1], "Style","text","String",'none',"FontSize",8)

uicontrol(fig,"Units","normalized","Position",[0 0.55 0.1 0.2], "Style","text","String","Red","FontSize",10)
Rg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.6 0.5 0.2],'BorderType','none','Tag','redchannel');
uicontrol(Rg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Rg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Rg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0 0.35 0.1 0.2], "Style","text","String","Green","FontSize",10)
Gg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.4 0.5 0.2],'BorderType','none','Tag','greenchannel');
uicontrol(Gg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Gg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Gg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0 0.15 0.1 0.2], "Style","text","String","Blue","FontSize",10)
Bg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.2 0.5 0.2],'BorderType','none','Tag','bluechannel');
uicontrol(Bg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Bg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Bg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0.4 0 0.2 0.1], "Style","pushbutton","String","Update",...
    "Callback",@replaceim,"FontSize",8)

guidata(fig,struct('intan_tag',props.intan_tag,'im',im,'im0',props.im,'imex',imex,...
    'file',fullfile(path,file),'imsel',[2 2 2]));

function im = loadit(path,file)
imp = double(imread(fullfile(path,file)));
if size(imp,3)==3
    im = imp/max(imp,[],'all');
else
    for f=1:3
        try
            imp = double(imread(fullfile(path,file),'Index',f));
            if f==1
                im = zeros([size(imp,[1 2]) 3]);
            end
            im(:,:,f) = imp/max(imp,[],'all');
        catch
            im(:,:,f) = im(:,:,1);
        end
    end
end

function update_example(hObject,eventdata)
aprops = guidata(hObject);

cim = cat(4,aprops.im0, aprops.im, zeros(size(aprops.im)));
im = zeros(size(aprops.im));

bg = get(get(findobj(hObject.Parent.Parent,'Tag','redchannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,1) = cim(:,:,1,bg);
aprops.imsel(1) = bg;

bg = get(get(findobj(hObject.Parent.Parent,'Tag','greenchannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,2) = cim(:,:,2,bg);
aprops.imsel(2) = bg;

bg = get(get(findobj(hObject.Parent.Parent,'Tag','bluechannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,3) = cim(:,:,3,bg);
aprops.imsel(3) = bg;

guidata(hObject,aprops)
set(aprops.imex,'CData',im)

function replaceim(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
props.im = get(aprops.imex,'CData');
props.imadj.imback = get(aprops.imex,'CData');
props.imadj.params = [0 1;0 1; 0 1];
props.imadj.params_back = [0 1;0 1; 0 1];
imsel = find(aprops.imsel==2);
if ~isempty(imsel)
    selstr = ["red","green","blue"];
    substr = char(join(selstr(imsel),' and '));
    str = [substr ' channels replaced with ' substr ' channel of ' aprops.file];
end
imsel = find(aprops.imsel==3);
if ~isempty(imsel)
    selstr = ["red","green","blue"];
    substr = char(join(selstr(imsel),' and '));
    str = [substr ' channels replaced with zeros'];
end
props.log = [props.log; str];
guidata(intan,props)
close(hObject.Parent)
updateroi(intan)

function updateroi(hObject,eventdata)
props = guidata(hObject);

fig = ancestor(hObject,'figure','toplevel');
redch = get(findobj(fig,'Tag','red'),'Value');
greench = get(findobj(fig,'Tag','green'),'Value');
bluech = get(findobj(fig,'Tag','blue'),'Value');

imch = any(props.im,[1 2]);

if ~all([redch, greench, bluech, squeeze(imch)'])
    a = 0.10;
    b = 0.10;
    c = 0.10;
    d = 0.3;
else
    a = 0.7;
    b = 0.85;
    c = 0.95;
    d = 1;
end

props.color = [d    a   a;...
               a    d   a;...
               a    a   d;...
               d    b   b;...
               b    d   b;...
               b    b   d;...
               d    c   b;...
               c	d   b;...
               c    b   d;...
               d    b   c;...
               b    d   c;...
               b    c   d];


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

im = props.im;

if redch
    R = im(:,:,1)';
else
    R = zeros(size(im,[1 2]));
end

if greench
    G = im(:,:,2)';
else
    G = zeros(size(im,[1 2]));
end

if bluech
    B = im(:,:,3)';
else
    B = zeros(size(im,[1 2]));
end


if get(findobj(props.ropanel,'Tag','fillroi'),'Value')
    cnt = 1;
    for r = roidx'
        if r<length(props.kernpos)
            pix = props.det(props.kernpos(r):props.kernpos(r+1)-1);
        else
            pix = props.det(props.kernpos(r):length(props.det));
        end
        pix(pix==0) = [];


        cnt(cnt>size(props.color,1)) = 1; %#ok<AGROW>
        if ~all([redch, greench, bluech, squeeze(imch)'])
            R(pix) = R(pix) + props.color(cnt,1); 
            G(pix) = G(pix) + props.color(cnt,2); 
            B(pix) = B(pix) + props.color(cnt,3); 
        else
            R(pix) = R(pix).*props.color(cnt,1); 
            G(pix) = G(pix).*props.color(cnt,2); 
            B(pix) = B(pix).*props.color(cnt,3); 
        end
        cnt = cnt+1;

    end
end

props.imsh.CData = cat(3,R',G',B');

% props.imsh.Parent.XLim = [0 size(props.im,2)];
for r=1:length(props.kernpos)
    if any(roidx==r) || r>length(props.roi)
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
    histogram(imdata(:,:,h),'BinEdges',0:100:max(imdata(:)) ,'FaceColor',colors(h,:));hold on
end
legend(string((round(sidx*sr,2))'))

subplot(2,1,2)
ims = imtile(imdata);
imagesc(ims)
colorbar

function adjcontrast(hObject,eventdata)
props = guidata(hObject);
fig = figure('MenuBar','none');
fig.Position([3 4]) = [500 400];

uicontrol('Units','normalized','Position',[0.3 0.92 0.2 0.07],'Style','pushbutton','String','Reset',...
    'Callback',@resetim,'Tag','resetim','Tooltip','Reset to the way it was when file was opened')
uicontrol('Units','normalized','Position',[0.5 0.92 0.2 0.07],'Style','pushbutton','String','Undo',...
    'Callback',@resetim,'Tag','undoim','Tooltip','Reset to the way it was before you opened this adjustment window')
color = 'rgb';
for c=1:3
    ax(c) = axes('Units','normalized','Position',[0.05 (c-1)/3.2+0.06  0.9  0.23]);
    [N,edges] = histcounts(props.imadj.imback(:,:,4-c),linspace(0,1,129));
    bar(edges(1:end-1),N,'FaceColor',color(4-c),'EdgeColor','none');hold on
    pos = [props.imadj.params(4-c,1),  1,  diff(props.imadj.params(4-c,:)),   max(N)];
    rec(c) = rectangle("Position",pos,"FaceColor",[0.7 0.7 0.7 0.5]);hold on
    uicontrol('Units','normalized','Position',[0.02 (c-1)/3.2+0.03  0.96  0.03],'Style','slider',...
        'Min',0,'Max',1,'Value',props.imadj.params(4-c,1),'SliderStep',[0.004 0.016],'BackgroundColor',[0.7 0.7 0.7],...
        "Callback",@adjrec,'Tag',[num2str(c) 'v1'])
    uicontrol('Units','normalized','Position',[0.02 (c-1)/3.2  0.96  0.03],'Style','slider',...
        'Min',0,'Max',1,'Value',props.imadj.params(4-c,2),'SliderStep',[0.004 0.016],'BackgroundColor',[0.7 0.7 0.7],...
         "Callback",@adjrec,'Tag',[num2str(c) 'v2'])
end
set(ax,'XTick',[],'YTick',[])
guidata(fig,struct('rec',rec,'intan_tag',props.intan_tag,'im0',props.im))

props.imadj.imtemp = props.im;
props.imadj.params_temp = props.imadj.params;
guidata(hObject,props)

function resetim(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);

if strcmp(hObject.Tag,'resetim')
    props.imadj.params = props.imadj.params_back;
    props.im = props.imadj.imback;
else
    props.imadj.params = props.imadj.params_temp;
    props.im = props.imadj.imtemp;
end

for c=1:3
    for v=1:2
        set(findobj(hObject.Parent,'Tag',[num2str(c) 'v' num2str(v)]),'Value',props.imadj.params(4-c,v) )
        aprops.rec(c).Position([1 3]) = [props.imadj.params(4-c,1),  diff(props.imadj.params(4-c,:))];
    end
end
guidata(intan,props)
updateroi(intan)

function adjrec(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
ch = str2double(hObject.Tag(1));
lw = get(findobj(hObject.Parent,'Tag',[num2str(ch) 'v1']),'Value');
up = get(findobj(hObject.Parent,'Tag',[num2str(ch) 'v2']),'Value');
imch = 4-ch;
im = props.imadj.imback(:,:,imch);
im = (im - lw)/up;
im(im>1) = 1;
im(im<0) = 0;
props.im(:,:,imch) = im;
props.imadj.params(imch,:) = [lw up];
aprops.rec(ch).Position([1 3]) = [lw,  diff([lw up])];
guidata(intan,props)
updateroi(intan)

%% misc methods
function saveBMP(hObject,eventdata)
props = guidata(hObject);
if ~isfield(props,'BMP_analysis')
    msgbox('You have no BMPs to save')
    return
end
[file,path] = uiputfile('BMP_analysis.mat','Select BMP file');
if isequal(file,0) || isequal(path,0)
    disp('Canceled')
else
    fn = fullfile(path,file);
    bmp = [props.BMP_analysis.BMP props.BMP_analysis.Rn];
    group = [string(props.intan.finfo.date), props.notes.note1];
    group = repmat(group,size(bmp,1),1);
    bmp(:,12:13) = diff(bmp(:,1:3),1,2);
    bmp(:,14) = (bmp(:,6)>0.5)+1;
    spikes = props.BMP_analysis.spikes;
    spikes = [repmat(props.BMP_analysis.BMP,1,1,size(spikes,3)) , spikes   ];
    spikes(:,12:13) = diff(spikes(:,1:3),1,2);
    spikes(:,14) = (spikes(:,6)>0.5)+1;
    spikes = {spikes};
    groups = group(1,:);
    head = ["protraction",...   1
    "transition",...            2
    "retraction",...            3
    "Sp protr dur",...          4
    "Sp retr dur",...           5
    "Sp activity dur (retr / (prot + ret))",... 6
    "Sp protr",...                           7
    "Sp retr",...                            8
    "Protraction spike rate (Hz)",...        9
    "Retraction spike rate (Hz)",...         10
    "Activity Hz (retr / (prot + ret))",...  11
    "Prot dur",...  12
    "Retr dur",...  13
    "Type"];%       14
    if exist(fn,'file')
        answer = questdlg('Would you like to append to this file or overwrite?','Action','Append','Overwrite','Cancel','Append');
        if strcmp(answer,'Append')
            vars = load(fn);
            bmp = [vars.bmp ; bmp];
            group = [vars.group; group];
            if isfield(vars,'spikes')
                spikes = [vars.spikes; spikes];
                groups = [vars.groups; groups];
            end
            disp(['BMPs were appended to ' fn])
            props.log = [props.log; 'Appended BMPs to ' fn];
        elseif strcmp(answer,'Cancel')
            disp('BMP save canceled')
            return
        end
    else
        disp(['BMPs were saved to ' fn])
        props.log = [props.log; 'Saved BMPs to ' fn];
    end
    save(fn,'group','bmp','head','spikes','groups')
end

function printlog(hObject,eventdata)
props = guidata(hObject);
disp('============= File Log =============')
disp(props.log)
disp('====================================')

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

props.log = [props.log; string(['saved data on ',char(datetime)])];
guidata(hObject,props)

fields = ["plt","txt","chk","ax","ylim"];
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
    xlim = props.video.xlim;
    alphathr = props.video.alphathr;
    instrumento = props.video.instrumento;
    frame = props.video.frame;
    inv = props.video.inv;
    ch = props.video.ch;

    kerndata = props.video.kerndata;
%     save(fullfile(path,replace(file,'.','_imdata.')),'minp','d2uint','imdata',...
%         'tm','fun','fparam','reference','climv')

    min2 = min(props.video.imdataroi(:));
    d2uint2 = 2^16/range(props.video.imdataroi(:));
    imdataroi = uint16((props.video.imdataroi - min2)*d2uint2);

    if isfield(props.video,'imdatar')
        min3 = min(props.video.imdatar(:));
        d2uint3 = 2^16/range(props.video.imdatar(:));
        imdatar = uint16((props.video.imdatar - min3)*d2uint3);
    end
%     save(fullfile(path,replace(file,'.','_imdata.')),'video')

    numchunk = ceil((numel(imdata)/9e8));
    chunks = round(linspace(0,size(imdata,3),numchunk+1));
    mfields = {'xlim','alphathr','instrumento','frame','inv','ch'};
    for n=1:numchunk
        imdatap = imdata(:,:,chunks(n)+1:chunks(n+1));
        save(fullfile(path,replace(file,'.',['_imdata1' num2str(n) '.'])),'min1','d2uint1',...
            'imdatap','tm','fun','fparam','reference','climv','chunks','kerndata',mfields{:})
        disp(fullfile(path,replace(file,'.',['_imdata1' num2str(n) '.'])))

        imdataroip = imdataroi(:,:,chunks(n)+1:chunks(n+1));
        save(fullfile(path,replace(file,'.',['_imdata2' num2str(n) '.'])),'min2','d2uint2',...
            'imdataroip','tm','fun','fparam','reference','climv','chunks',mfields{:})
        disp(fullfile(path,replace(file,'.',['_imdata2' num2str(n) '.'])))
        
        if exist('d2uint3','var')
            imdatarp = imdatar(:,:,chunks(n)+1:chunks(n+1));
            save(fullfile(path,replace(file,'.',['_imdata3' num2str(n) '.'])),'min3','d2uint3',...
                'imdatarp','tm','fun','fparam','reference','climv','chunks',mfields{:})
            disp(fullfile(path,replace(file,'.',['_imdata3' num2str(n) '.'])))
        end
    end
    props = rmfield(props,'video');
end

if isfield(props,'databackup')
    try
        props.databackup = convert_uint(props.databackup, props.bd2uint, props.bmin, 'uint16');
    catch
        warning('couldn''t save backup')
    end
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


if isfield(props,'BMP_analysis')
    bmp_fn = fieldnames(props.BMP_analysis);
    for f=1:length(bmp_fn)
        if isa(props.BMP_analysis.(bmp_fn{f}),'handle')
            props.BMP_analysis = rmfield(props.BMP_analysis,bmp_fn{f});
        end
    end
end


try
    save(fullfile(path,file),'props')
    disp(['Saved ' fullfile(path,file)])
catch exception
    disp('>>>>>> Error >>>>>')
    disp(getReport(exception))
end

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