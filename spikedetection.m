function spikedetection(inputdata,tm)
% data can either be a 2D array or the structure properties from the intan
% GUI. Each row is each channel.  If array, then time can optionally be
% included as a second input.

if isstruct(inputdata)
    data = inputdata.data;
    ch = inputdata.ch;
    hideidx = inputdata.hideidx;
    showidx = inputdata.showidx;
    tm = inputdata.tm;
    files = inputdata.files;

    vsd = files(contains(files(:,2),'tsm'),2);

    warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
    info = fitsinfo(vsd);
    warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')
    
    xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
    ysize = info.PrimaryData.Size(1);
    sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};
    origim = inputdata.im;
else
    data = inputdata;
    ch = 1:size(data,1);
    hideidx = [];
    showidx = 1:size(data,1);
    if nargin<2
        tm = 1:size(data,2);
    end
    files = [];
end

sf = diff(tm(1:2));

% default parameters
inc = 0.25;% increment increas for threshold

default.ckup = true;% default whether upper threshold is used as criteria
default.updur = 5;% default number of datapoints above threshold to detect spike.
default.upthr = 5;
default.ckuprej = false;% default whether to reject spikes above a value
default.uprej = 10;% default value for rejection.  If data is above this then it rejects the spike.
default.ckdwn = false;% default whether lower threshold is used as criteria.
default.dwndur = 5;
default.dwnthr = -1.75;
default.ckdwnrej = false;
default.dwnrej = -4;
default.gapdur = 15;
default.ra = 20;% re-arm, the minimal amount of time to detect a subsequent spike (should be just longer than the concievable duration of a spike)

default.updur = sf*default.updur*1000;
default.dwndur = sf*default.dwndur*1000;
default.gapdur = sf*default.gapdur*1000;
default.ra = sf*default.ra*1000;
params = repmat(default,length(ch),1);%<-----just changed these values

apptag = ['apptag' num2str(randi(1e4,1))];
fig = figure('Position',[10 80 1900 600],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Spike Tools');
mi(1) = uimenu(m,'Text','Open','Callback',@threshold,'Enable','off');
mi(3) = uimenu(m,'Text','Save','Callback',@threshold,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','on','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


oppos = [120 327 40 20];
panel = uipanel('Title','Controls','Units','pixels','FontSize',12,'Position',[2 2 420 132],'Tag','panel');%[0.005 0.78 0.20 0.22]

uicontrol(panel,'Position',[55  88 80 25],'Style','text','String','Threshold','Enable','on');
uicontrol(panel,'Position',[135 88 80 25],'Style','text','String','Min Duration','Enable','on');
uicontrol(panel,'Position',[215 88 80 25],'Style','text','String','Gap','Enable','on');
uicontrol(panel,'Position',[295 88 80 25],'Style','text','String','Reject','Enable','on');


%threshold 1
uicontrol(panel,'Position',[1 73 20 20],'Style','checkbox','Tag','ckup','Callback',@activatethr,'Enable','on','Value',default.ckup);
uicontrol(panel,'Position',[20  70  40 20],'Style','text','String','Upper','Tag','upstr','Enable','on');
uicontrol(panel,'Position',[65  82  20 14],'Style','pushbutton','Tag','uppUPthr','String',char(708),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[65  69  20 14],'Style','pushbutton','Tag','uppDWNthr','String',char(709),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[85 73  30 20],'Style','edit','String',default.upthr,'Tag','upthr','Callback',@chparam,'Enable','on');
uicontrol(panel,'Position',[115 70  20 20],'Style','text','String','std','Tag','upunits','Enable','on');

uicontrol(panel,'Position',[145 82  20 14],'Style','pushbutton','Tag','uppUPdur','String',char(708),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[145 69  20 14],'Style','pushbutton','Tag','uppDWNdur','String',char(709),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[165 73  30 20],'Style','edit','String',num2str(default.updur,2),'Tag','updur','Callback',@duration,'Enable','on');
uicontrol(panel,'Position',[195 70  20 20],'Style','text','String','ms','Tag','upunits','Enable','on');

uicontrol(panel,'Position',[300 73 20 20],'Style','checkbox','Tag','ckuprej','Callback',@activatethr,'Enable','on','Value',default.ckuprej);
uicontrol(panel,'Position',[320 82  20 14],'Style','pushbutton','Tag','uppUPrej','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[320 69  20 14],'Style','pushbutton','Tag','uppDWNrej','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[340 73  30 20],'Style','edit','String',num2str(default.uprej,2),'Tag','uprej','Callback',@chparam,'Enable','off');
uicontrol(panel,'Position',[370 70  20 20],'Style','text','String','std','Tag','upunitsrej','Enable','off');

uicontrol(panel,'Position',[395 73  20 20],'Style','pushbutton','String','?','Tag','helps1','Callback',@helpf,'Enable','on');


%threshold 2
uicontrol(panel,'Position',[1  43 20 20],'Style','checkbox','Tag','ckdwn','Callback',@activatethr,'Enable','on','value',default.ckdwn,'Tooltip','have not coded this yet');
uicontrol(panel,'Position',[20  40 40 20],'Style','text','Tag','dwnstr','String','Lower','Enable','off');
uicontrol(panel,'Position',[65  52 20 14],'Style','pushbutton','Tag','dwnpUPthr','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[65  39 20 14],'Style','pushbutton','Tag','dwnpDWNthr','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[85  43 30 20],'Style','edit','String',default.dwnthr,'Tag','dwnthr','Callback',@chparam,'Enable','off');
uicontrol(panel,'Position',[115  40 20 20],'Style','text','String','std','Tag','dwnunits','Enable','off');

uicontrol(panel,'Position',[145 52 20 14],'Style','pushbutton','Tag','dwnpUPdur','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[145 39 20 14],'Style','pushbutton','Tag','dwnpDWNdur','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[165 43 30 20],'Style','edit','String',num2str(default.dwndur,2),'Tag','dwndur','Callback',@duration,'Enable','off');
uicontrol(panel,'Position',[195 40 20 20],'Style','text','String','ms','Tag','dwnunits','Enable','off');

uicontrol(panel,'Position',[300 43 20 20],'Style','checkbox','Tag','ckdwnrej','Callback',@activatethr,'Enable','on','Value',default.ckdwnrej);
uicontrol(panel,'Position',[320 52  20 14],'Style','pushbutton','Tag','dwnpUPrej','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[320 39  20 14],'Style','pushbutton','Tag','dwnpDWNrej','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[340 43  30 20],'Style','edit','String',num2str(default.dwnrej,2),'Tag','dwnrej','Callback',@chparam,'Enable','off');
uicontrol(panel,'Position',[370 40  20 20],'Style','text','String','std','Tag','dwnunitsrej','Enable','off');

uicontrol(panel,'Position',[395 43 20 20],'Style','pushbutton','String','?','Tag','helps2','Callback',@helpf,'Enable','on');

%gap
uicontrol(panel,'Position',[225 52 20 14],'Style','pushbutton','Tag','gappUPdur','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[225 39 20 14],'Style','pushbutton','Tag','gappDWNdur','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[245 43 30 20],'Style','edit','String',num2str(default.gapdur,2),'Tag','gapdur','Callback',@duration,'Enable','off');
uicontrol(panel,'Position',[275 40 20 20],'Style','text','String','ms','Tag','gapunits','Enable','off');

%rearming
uicontrol(panel,'Position',[1  1 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol(panel,'Position',[40 4 30 20],'Style','edit','String',num2str(default.ra,2),'Tag','rearm','Callback',@duration,'Enable','on');
uicontrol(panel,'Position',[70 1 20 20],'Style','text','String','ms','Enable','on');
uicontrol(panel,'Position',[90 4 20 20],'Style','pushbutton','String','?','Tag','helps3','Callback',@helpf,'Enable','on');

uicontrol(panel,'Position',[295 1 120 30],'Style','pushbutton','String','Get Image Average','Tag','avgim','Callback',@avgim,'Enable','on');
uicontrol(panel,'Position',[170 1 120 30],'Style','pushbutton','String','Copy Parameters','Callback',@copyparam,'Enable','on');


uicontrol('Position',[220 125 60 20],'Style','text','String','# spikes:','Enable','on');
uicontrol('Position',[280 125 20 20],'Style','text','String',' ','Tag','nspikes','Enable','on');



uicontrol('Units','normalized','Position',[0.78 0.9 0.2 0.05],'Style','text','String',' ','Tag','processing',...
    'HorizontalAlignment','center','FontSize',15,'Enable','on');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Units','normalized','Position',[0.002 0.96 0.05 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.002 0.23 0.05 0.73],'Style','listbox','Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@chchannel);
%[5 440 100 20] [5 40 100 400]

% initialize axes

mdata = mean(data(showidx(1),:));
stddata = std(data(showidx(1),:));

ax = axes('Position',[0.23 0.1 0.5 0.75]);
plt = plot(tm,data(showidx(1),:));hold on

tplt(1) = plot([min(tm) max(tm)],[mdata, mdata]+stddata*default.upthr);hold on
tplt(2) = plot([min(tm) max(tm)],nan(2,1));hold on
tplt(3) = plot([min(tm) max(tm)],nan(2,1),':');hold on
tplt(4) = plot([min(tm) max(tm)],nan(2,1),':');hold on
splt = scatter(nan,nan,'x');hold on

ax.XLabel.String = 'Time (s)';

ax2 = axes('Position',[0.23 0.9 0.5 0.07]);
Lplt = plot(tm,zeros(length(tm),1));

linkaxes([ax, ax2],'x')

ax2.XTick = [];
ax2.YTick = -2:2;
ax2.YTickLabels = ["Lower Rej","Thr","null","Thr","Upper Rej"];
ax2.YLim = [-2 2];
ax2.Toolbar.Visible = 'off';
ax2.XLim = [min(tm),max(tm)];



W = -300:500;
W0 = round(min(W)*sf/sr); 
idur = round(length(W)*sf/sr);
slidepos = 30;

sax = axes('Position',[0.08 0.65 0.12 0.25]);
aplt = plot(W*sf*1000,nan(size(W)));
sax.XTick = [];
sax.Title.String = 'Average detected spike';

vax = axes('Position',sax.Position + [0 -0.3 0 0]);
tempx = -20:34;
vax.XLabel.String = 'Time (ms)';
vax.Title.String = 'ROI average';

saxover = axes('Position',vax.Position);% so that the rectangle always exceed ylimits
pos = [(W(1) + length(W)*slidepos/idur)*sf*1000,  -1,   length(W)/idur*sf*1000,  2];
frame = rectangle('Position',pos,'EdgeColor','none','FaceColor',[0 0 0 0.2]);
set(saxover,'ytick',[],'xtick',[],'color','none','Ylim',[-0.5 0.5])

linkaxes([sax, saxover,vax],'x')
sax.XLim = [min(W) max(W)]*sf*1000;

aspike = repelem({zeros(2,length(W))},size(data,1));
spikes = repelem({zeros(1,0)},size(data,1));

iax = axes('Position', [0.75 0.1 0.2 0.2*ysize/xsize*fig.Position(3)/fig.Position(4)],'YTick',[],'XTick',[],'Box','on','Tag','roiax');
img = imagesc(zeros(ysize,xsize));
set(iax,'XTick',[],'YTick',[])

colorbar('Location','manual','Position',[sum(iax.Position([1 3])) 0.1 0.01 iax.Position(4)])

uicontrol('Units','normalized','Position',[iax.Position(1) iax.Position(2)-0.05 iax.Position(3) 0.05],'Style','slider','Value',slidepos,'Min',1,'Max',idur-1,'SliderStep',[1 1]/idur,'Callback',@chframe,'Tag','imslider');
uicontrol('Units','normalized','Position',[0.75 0.9 0.03 0.05],'Style','pushbutton','String','+ ROI','Tag','droi','Callback',@drawroi,'Enable','on','TooltipString','Add an ROI to the image');
uicontrol('Units','normalized','Position',[0.78 0.9 0.03 0.05],'Style','pushbutton','String','- ROI','Callback',@removelastroi,'Enable','on','TooltipString','Remove previously drawn ROI');
uicontrol('Units','normalized','Position',[0.81 0.9 0.03 0.05],'Style','pushbutton','String','clear','Callback',@clearroi,'Enable','on','TooltipString','Remove all ROIs');


uicontrol('Units','normalized','Position',[iax.Position(1) sum(iax.Position([2 4])) 0.04 0.05],'Style','pushbutton','String','Raw Image','Tag','raw','Callback',@rawimage)

helps = ["To detect spikes the data value has to be above this threshold consecutively for as long as the minimum duration.  If active, the reject will remove spikes whose data goes above the reject threshold during the duration.",...
         "To detect spikes the data value has to be below this threshold consecutively for as long as the minimum duration.  If active, the reject will remove spikes whose data goes above the reject threshold during the duration.",...
         "The re-arm prevents the same spike from being detected twice.  The re-arm value is the minimal amount of time to detect a subsequent spike.  Should be a little longer than the concievable duration of a spike and shorter than the minimum concievable spike interval.  A neuron that fires at most 100Hz should have a re-arm duration less than 10 ms."];

color = makecolor(-0.2);
color(2,:) = color(2,:)*0.7;

guidata(fig,struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                   'tplt',tplt,         'splt',splt,        'sax',sax,...
                   'aplt',aplt,         'iax',iax,          'img',img,...
                   'W',W,               'data',data,        'ch',ch,...
                   'hideidx',hideidx,   'showidx',showidx,  'tm',tm,...
                   'str',str,           'ckup',true,        'ckdwn',false,...
                   'gidx',showidx(1),   'aspike',{aspike},  'spikes',{spikes},...
                   'inc',inc,           'files',files,      'frame',frame,...
                   'helps',helps,       'vax',vax,        'panel',panel,...
                   'rawim',false,       'origim',origim,    'imdata',zeros(ysize,xsize,slidepos+10),...
                   'roiln',gobjects(0,1),'roi',gobjects(0,1), 'colors',color,...
                   'params',params,     'Lplt',Lplt))

detsp(fig)

function copyparam(hObject,eventdata)
props = guidata(hObject);
allbut = findobj(hObject,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')

[indx,tf] = listdlg('PromptString',{'Choose channel','Press apply to overwrite', 'selected channels with the ', 'parameters of the current',  'channel'},'ListString',props.str);

idx = get(findobj('Tag','channels','Parent',props.panel.Parent),'Value');
if tf
    props.params(indx) = props.params(idx);
end
guidata(hObject,props)
set(allbut,'Enable','on')

function clearroi(hObject,eventdata)
props = guidata(hObject);
delete(props.roi)
delete(props.roiln)
props.roi = gobjects(0,1);
props.roiln = gobjects(0,1);
guidata(hObject,props)

function removelastroi(hObject,eventdata)
props = guidata(hObject);
delete(props.roi(end))
delete(props.roiln(end))
props.roi(end) = [];
props.roiln(end) = [];
guidata(hObject,props)

function rawimage(hObject,eventdata)
props = guidata(hObject);
rbutton = findobj(hObject,'Tag','raw');
if props.rawim
    props.rawim = false;
    set(rbutton,'BackgroundColor',[0.94 0.94 0.94])
    frame = get(findobj('Tag','imslider','Parent',hObject.Parent) ,'Value')+1;
    set(props.img,'CData',props.imdata(:,:,frame))
else
    props.rawim = true;
    set(rbutton,'BackgroundColor',[0.7 0.7 0.7])
    set(props.img,'CData',props.origim(:,:,1))
end
guidata(hObject,props)

function [pixels, vdata] = roidata(pos,imdata)
pixels = zeros(0,2,'uint16');
for r = min(pos(:,2)):max(pos(:,2))
    pix = pos(pos(:,2)==r,1);
    cols = min(pix):max(pix);
    tpix = [cols', repelem(r,length(cols))'];
    pixels = [pixels; tpix];  
end

vdata = zeros(size(imdata,3),1);
for f = 1:size(imdata,3)
    imf = imdata(:,:,f);
    pidx = sub2ind(size(imf),pixels(:,2),pixels(:,1));
    vdata(f) = mean(imf(pidx),'all');
end

function moveroi(hObject,eventdata)
props = guidata(hObject.Parent.Parent);
idx = regexp(hObject.Tag,'\d+','match');
idx = str2double(idx{1});
[pixels,vdata] = roidata(unique(round(hObject.Position),'rows'), props.imdata);
set(props.roiln(idx),'YData',vdata)
guidata(hObject,props)

function drawroi(hObject,eventdata)
props = guidata(hObject);

set(findobj('Tag','processing','Parent',hObject.Parent),'String','Draw ROI')
pause(0.1)
allbut = findobj(findobj('Tag',props.apptag),'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')
pause(0.1)

color = props.colors(size(props.roi,1)+1,:);
roi = drawfreehand(props.iax,'MarkerSize',1,'Color',color,'Tag', ['roi', num2str(size(props.roi,1)+1)]);%drawpolygon
assignin("base",'roi',roi)
addlistener(roi,'ROIMoved',@moveroi);
props.roi = [props.roi; roi];

pos = unique(round(roi.Position),'rows');
pos(pos==0) = 1;
[pixels,vdata] = roidata(pos, props.imdata);

props.pixels = pixels;
props.vdata = vdata;


sf = diff(props.tm(1:2));% get exact timing of vsd frames 
W0 = round(min(props.W)*sf/props.sr)/1.25; 
dur = round(length(props.W)*sf/props.sr)/1.25;
vx = linspace(W0,W0+dur,length(vdata));

ln = line(vx,vdata,'Parent',props.vax,'Color',color);
props.roiln = [props.roiln; ln];


set(findobj('Tag','processing','Parent',hObject.Parent),'String',' ')

set(allbut,'Enable','on')

guidata(hObject,props)
assignin('base', 'roi', roi);
assignin('base', 'pixels', pixels);
assignin('base', 'props', props);

function chframe(hObject,eventdata)
props = guidata(hObject);
frame = round(hObject.Value);
set(hObject,'Value',frame)
set(props.img,'CData',props.imdata(:,:,frame))
idur = get(hObject,'Max');
sf = diff(props.tm(1:2));
pos = [(props.W(1) + length(props.W)*frame/idur)*sf*1000,  -1,   length(props.W)/idur*sf*1000,  2];
set(props.frame,'Position',pos)

function chval(hObject,eventdata)
props = guidata(hObject);
tag = get(hObject,'Tag');
change = regexp(tag,'(up|dwn|UP|DWN|thr|dur|gap|rej)','match');
dir = contains(tag,'UP')*2 - 1;
obj = findobj('Tag',[change{1},change{3}],'Parent',hObject.Parent);
val = str2double(obj.String);
if contains(tag,'thr') || contains(tag,'rej')
    val = val + dir*props.inc;% increment of change 
    vals = num2str(val);
else
    val = val/1000;
    sr = diff(props.tm(1:2));
    val = val + dir*sr;
    val(val<sr) = sr;
    vals = num2str(sr*round(val/sr)*1000,2);% ensure that duration is incriments of the sampling frequency
    updur = str2double(get(findobj('Tag','updur','Parent',props.panel),'String'));
    if contains(hObject.Tag,'gap') && str2double(vals)<updur+2*sr*1000
        vals = num2str(updur + sr*2*1000,2);
    end
end
set(obj,'String',vals)
chparam(hObject.Parent)

function chchannel(hObject,eventdata)
props = guidata(hObject);
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
enable = ["off","on"];
set(findobj('Tag','ckup','Parent',props.panel),'Value',props.params(idx).ckup)
set(findobj('Tag','ckdwn','Parent',props.panel),'Value',props.params(idx).ckdwn)
set(findobj('Tag','ckuprej','Parent',props.panel),'Value',props.params(idx).ckuprej)
set(findobj('Tag','ckdwnrej','Parent',props.panel),'Value',props.params(idx).ckdwnrej)
set(findobj('Tag','updur','Parent',props.panel),'String',num2str(props.params(idx).updur,2));
set(findobj('Tag','upthr','Parent',props.panel),'String',props.params(idx).upthr);

set(findobj('Tag','uprej','Parent',props.panel),'String',props.params(idx).uprej);
set(findobj('Tag','dwnrej','Parent',props.panel),'String',props.params(idx).dwnrej);

set(findobj('Tag','dwndur','Parent',props.panel),'String',num2str(props.params(idx).dwndur,2));
set(findobj('Tag','dwnthr','Parent',props.panel),'String',props.params(idx).dwnthr);
set(findobj('Tag','gapdur','Parent',props.panel),'String',num2str(props.params(idx).gapdur,2));
set(findobj('Tag','rearm','Parent',props.panel),'String',num2str(props.params(idx).ra,2));

set(findobj('-regexp','Tag','^up(pUP|pDWN|units|dur|thr)(?!rej)','Parent',props.panel) ,'Enable',enable(props.params(idx).ckup+1))
set(findobj('-regexp','Tag','^up\w*rej$','Parent',props.panel)     ,'Enable',enable((props.params(idx).ckup & props.params(idx).ckuprej)+1))
set(findobj('-regexp','Tag','^dwn(pUP|pDWN|units|dur|thr)(?!rej)','Parent',props.panel),'Enable',enable(props.params(idx).ckdwn+1))
set(findobj('-regexp','Tag','^dwn\w*rej$','Parent',props.panel)    ,'Enable',enable((props.params(idx).ckdwn & props.params(idx).ckdwnrej)+1))

% set(findobj('-regexp','Tag','^up','Parent',props.panel),'Enable',enable(props.params(idx).ckup+1))
% set(findobj('-regexp','Tag','^dwn','Parent',props.panel),'Enable',enable(props.params(idx).ckdwn+1))
if props.params(idx).ckup && props.params(idx).ckdwn
    set(findobj('-regexp','Tag','^gap','Parent',props.panel),'Enable','on')
else
    set(findobj('-regexp','Tag','^gap','Parent',props.panel),'Enable','off')
end
detsp(hObject)

function helpf(hObject,eventdata)
props = guidata(hObject);
idx = double(string(regexp(hObject.Tag,'\d+','match')));
helpdlg(props.helps(idx),'Tip!')

function toworkspace(hObject,eventdata)
props = guidata(hObject);
assignin('base', 'sout', props);
disp('sent to workplace as ''sout''')

function threshold(hObject,eventdata)% dummy function
props = guidata(hObject);

function plotdata(hObject)
props = guidata(hObject);
idx = get(findobj('Tag','channels','Parent',findobj('Tag',props.apptag)),'Value');
set(props.plt,'YData', props.data(idx,:));

stdata = std(props.data(idx,:));
if props.params(idx).ckup
    thr = str2double(get(findobj('Tag','upthr','Parent',props.panel),'String'));
else
    thr = str2double(get(findobj('Tag','dwnthr','Parent',props.panel),'String'));
end
spikes = props.spikes{idx};
set(props.splt,'XData',props.tm(spikes),'YData',ones(size(spikes))*thr*stdata)

set(props.aplt,'YData',mean(props.aspike{idx},1))
guidata(hObject,props)

function activatethr(hObject,eventdata)
props = guidata(hObject);
vals = [get(findobj('Tag','ckup','Parent',props.panel),'Value') , get(findobj('Tag','ckdwn','Parent',props.panel),'Value')];
if ~hObject.Value && ~any(vals)
    hObject.Value = true;
    return
end
enable = ["off","on"];
ckup = findobj('Tag','ckup','Parent',props.panel);
ckdwn = findobj('Tag','ckdwn','Parent',props.panel);
ckuprej = findobj('Tag','ckuprej','Parent',props.panel);
ckdwnrej = findobj('Tag','ckdwnrej','Parent',props.panel);

disp(enable((get(ckdwn,'Value') & get(ckdwnrej,'Value'))+1))
set(findobj('-regexp','Tag','^up(pUP|pDWN|units|dur|thr)(?!rej)','Parent',props.panel) ,'Enable',enable(get(ckup,'Value')+1))
set(findobj('-regexp','Tag','^up\w*rej$','Parent',props.panel)     ,'Enable',enable((get(ckup,'Value') & get(ckuprej,'Value'))+1))
set(findobj('-regexp','Tag','^dwn(pUP|pDWN|units|dur|thr)(?!rej)','Parent',props.panel),'Enable',enable(get(ckdwn,'Value')+1))
set(findobj('-regexp','Tag','^dwn\w*rej$','Parent',props.panel)    ,'Enable',enable((get(ckdwn,'Value') & get(ckdwnrej,'Value'))+1))

ischecked = string(get(findobj('-regexp','Tag','ck(up|dwn)$'),'Value'))=="1";
if all(ischecked)
    set(findobj('-regexp','Tag','^gap','Parent',props.panel),'Enable','on')
else
    set(findobj('-regexp','Tag','^gap','Parent',props.panel),'Enable','off')
end
    
chparam(hObject)

function duration(hObject,eventdata)
props = guidata(hObject);
dur = str2double(hObject.String)/1000;
sr = diff(props.tm(1:2));
nval = num2str(sr*round(dur/sr)*1000,2);
set(hObject,'String',nval)
updur = str2double(get(findobj('Tag','updur','Parent',props.panel),'String'));
if contains(hObject.Tag,'gap') && st2double(nval)<=updur+sr
    replval = updur + sr*2;
    set(hObject,'String',num2str(replval,2))
end
chparam(hObject.Parent)

function chparam(hObject,eventdata)
props = guidata(hObject);
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
props.params(idx).ckup = get(findobj('Tag','ckup','Parent',props.panel),'Value');
props.params(idx).ckdwn = get(findobj('Tag','ckdwn','Parent',props.panel),'Value');
props.params(idx).ckuprej = get(findobj('Tag','ckuprej','Parent',props.panel),'Value');
props.params(idx).ckdwnrej = get(findobj('Tag','ckdwnrej','Parent',props.panel),'Value');
props.params(idx).updur = str2double(get(findobj('Tag','updur','Parent',props.panel),'String'));
props.params(idx).upthr = str2double(get(findobj('Tag','upthr','Parent',props.panel),'String'));

props.params(idx).uprej = str2double(get(findobj('Tag','uprej','Parent',props.panel),'String'));
props.params(idx).dwnrej = str2double(get(findobj('Tag','dwnrej','Parent',props.panel),'String'));

props.params(idx).dwndur = str2double(get(findobj('Tag','dwndur','Parent',props.panel),'String'));
props.params(idx).dwnthr = str2double(get(findobj('Tag','dwnthr','Parent',props.panel),'String'));
props.params(idx).gapdur = str2double(get(findobj('Tag','gapdur','Parent',props.panel),'String'));
props.params(idx).ra = str2double(get(findobj('Tag','rearm','Parent',props.panel),'String'));
guidata(hObject.Parent,props)
detsp(hObject)

function detsp(hObject,eventdata)
if nargin==2
    hObject = hObject.Parent;
end
props = guidata(hObject);

allbut = findobj(hObject,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')

fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');

data = props.data(idx,:);
tm = props.tm;
stdata = std(data);
sf = diff(tm(1:2));

updur = round(props.params(idx).updur/1000/sf);% convert from time to # indices
dwndur = round(props.params(idx).dwndur/1000/sf);% convert from time to # indices
gapdur = round(props.params(idx).gapdur/1000/sf);% convert from time to # indices
ra = round(props.params(idx).ra/1000/sf);% convert from time to # indices

sdata = repelem('n',length(data));
logic = zeros(length(data),1);
if props.params(idx).ckup
    sidx = data>props.params(idx).upthr*stdata;% find all values > threshold
    sdata(sidx) = 'u';
    logic(sidx) = 1;
    set(props.tplt(1),'YData',[1 1]*props.params(idx).upthr*stdata)
    pattern = repelem('u',updur);
else
    set(props.tplt(1),'YData',nan(2,1))
end

if props.params(idx).ckup && props.params(idx).ckuprej
    sidx = data>props.params(idx).uprej*stdata;% find all values > threshold
    sdata(sidx) = 'r';
    logic(sidx) = 2;
    set(props.tplt(3),'YData',[1 1]*props.params(idx).uprej*stdata)
else
    set(props.tplt(3),'YData',nan(2,1))
end

if props.params(idx).ckdwn
    sidx = data<props.params(idx).dwnthr*stdata;% find all values > threshold
    sdata(sidx) = 'd';
    logic(sidx) = -1;
    set(props.tplt(2),'YData',[1 1]*props.params(idx).dwnthr*stdata)
    pattern = repelem('d',dwndur);
else
    set(props.tplt(2),'YData',nan(2,1))
end

if props.params(idx).ckdwn && props.params(idx).ckdwnrej
    sidx = data<props.params(idx).dwnrej*stdata;% find all values > threshold
    sdata(sidx) = 'r';
    logic(sidx) = -2;
    set(props.tplt(4),'YData',[1 1]*props.params(idx).dwnrej*stdata)
else
    set(props.tplt(4),'YData',nan(2,1))
end

set(props.Lplt,'YData',logic)


if props.params(idx).ckup && props.params(idx).ckdwn
    eval(['pattern = "' repelem('u',updur) '"' repmat(' + ("u"|"d"|"n")',1,gapdur-updur) ' + "' repelem('d',dwndur) '";'])
end
spikes = strfind(sdata,pattern);
if ~isempty(spikes)
    spikes = spikes([true, diff(spikes)>ra]);% remove values that are separated by < re-arm (prevents dection of same spike).  The value is idices;

    W = props.W;
    aspike = zeros(length(spikes),length(W));
    for i = 1:length(spikes)
        aspike(i,:) = data(W+spikes(i));
    end
    props.aspike{idx} = aspike;
end

props.spikes{idx} = spikes;
guidata(hObject,props)

set(findobj('Tag','nspikes','Parent',findobj('Tag',props.apptag)),'String',num2str(length(spikes)));
plotdata(hObject)
set(allbut,'Enable','on')

function avgim(hObject,eventdata)
props = guidata(hObject);

set(findobj('Tag','processing','Parent',hObject.Parent.Parent),'String','Processing...')
allbut = findobj(hObject.Parent.Parent,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')
pause(0.1)

tic
if isempty(props.files)
    return
end
idx = get(findobj('Tag','channels','Parent',hObject.Parent.Parent),'Value');

vsd = props.files(contains(props.files(:,2),'tsm'),2);

warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(vsd);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};
props.sr = sr;

spikes = props.spikes{idx};
itm = props.tm;

sidx = round(itm(spikes)/sr);


sf = diff(props.tm(1:2));
W0 = round(min(props.W)*sf/sr); 
dur = round(length(props.W)*sf/sr);
sidx = sidx + W0;
sidx(sidx>zsize | sidx<1) = [];

imdata = zeros(ysize,xsize,dur);
frameLength = xsize*ysize; % Frame length is the product of X and Y axis lengths;

fid = fopen(info.Filename,'r');
for s=1:length(sidx)
    offset = info.PrimaryData.Offset + ... Header information takes 2880 bytes.
                (sidx(s)-1)*frameLength*2; % Because each integer takes two bytes.
    
    fseek(fid,offset,'bof');% Find target position on file.
    
    % Read data.
    fdata = fread(fid,frameLength*dur,'int16=>double');% single saves about 25% processing time and requires half of memory 
    if length(fdata)<xsize*ysize*dur
        break
    end
    fdata = reshape(fdata,[xsize ysize dur]);
    f0 = repmat(fdata(:,:,1),1,1,size(fdata,3));
    fdata = (fdata - f0)./f0;
    
    imdata = imdata + fdata;% Format data.
end
fclose(fid);

imdata = imdata/length(sidx);
imdata = permute(imdata,[2 1 3]);
% f0 = repmat(imdata(:,:,1),1,1,size(imdata,3));
% imdata = (imdata - f0)./f0;
% imdata(1:6,:,:) = 0;
props.imdata = imdata;

frame = get(findobj('Tag','imslider','Parent',hObject.Parent.Parent) ,'Value')+1;
set(props.img,'CData',imdata(:,:,frame))

set(findobj('Tag','processing','Parent',hObject.Parent.Parent),'String',' ')
toc
set(allbut,'Enable','on')
guidata(hObject,props)

    



