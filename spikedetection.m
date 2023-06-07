function spikedetection(inputinfo,tm)
% data can either be a 2D array or intan tag. Each row is each channel.  If array, then time can optionally be
% included as a second input.

if ischar(inputinfo)
    inputdata = guidata(findobj('Tag',inputinfo));
    data = inputdata.data;
    data(isnan(data)) = 0;
    ch = inputdata.ch;
    hideidx = inputdata.hideidx;
    showidx = inputdata.showidx;
    tm = inputdata.tm;
    files = inputdata.files;
    ofigsize = inputdata.figsize;

    vsd = files(contains(files(:,2),'tsm'),2);
    [folder, filenm, ext] = fileparts(vsd);
    fvsd = [filenm{1},ext{1}];

    hasvsd = true;
    if exist(fullfile(inputdata.curdir,fvsd),'file')
        nvsd = fullfile(inputdata.curdir,fvsd);
    else
        if exist(vsd,'file')
            nvsd = vsd;
        else
            answer = questdlg('Could not find file?  Would you like to search another folder?', 'Oops!','Yes','No','Cancel','Yes');
            if strcmp(answer,'Yes')
                [file, path, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select file','MultiSelect','off');
                nvsd = fullfile(path,file);
            elseif strcmp(answer,'No')
                nvsd = vsd;
            else
                warning(['Could not find ' char(vsd)])
                hasvsd = false;
            end
        end
    end

    if hasvsd
        warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
        info = fitsinfo(nvsd);
        warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')
    
        vsd = nvsd;
        
        xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
        ysize = info.PrimaryData.Size(1);
        sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};
        origim = inputdata.im;
    end
else
    data = inputdata;
    data(isnan(data)) = 0;
    ch = 1:size(data,1);
    hideidx = [];
    showidx = 1:size(data,1);
    if nargin<2
        tm = 1:size(data,2);
    end
    files = [];
    mpos = get(0,'MonitorPositions');
    if nargin==0
        [~,monitor] = max(prod(mpos(:,3:end),2));% gets the larger monitor
    end
    ofigsize = mpos(monitor,:);
end

sf = diff(tm(1:2));

% default parameters
slidepos = 27;% default frame for image
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

if isfield(inputdata,'spikedetection')
    params = inputdata.spikedetection.params;
    spikes = inputdata.spikedetection.spikes;
else
    params = repmat(default,length(ch),1);
    spikes = repelem({zeros(1,0)},size(data,1));
end

apptag = ['apptag' num2str(randi(1e4,1))];
% fig = figure('Position',[10 80 1900 600],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);
fig = figure('Position',[ofigsize(1) ofigsize(4)*0.1+ofigsize(2) ofigsize(3) ofigsize(4)*0.7],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Spike Tools');
mi(1) = uimenu(m,'Text','Open Parameters','Callback',@opensaveparams,'Enable','on','Tag','open');
mi(3) = uimenu(m,'Text','Save Parameters','Callback',@opensaveparams,'Enable','on','Tag','save');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','on','Tag','savem');
mi(5) = uimenu(m,'Text','Send to Intan_Gui','Callback',@tointan,'Enable','on','Tag','savem');
mi(6) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


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
uicontrol(panel,'Position',[220 52 20 14],'Style','pushbutton','Tag','gappUPdur','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[220 39 20 14],'Style','pushbutton','Tag','gappDWNdur','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[240 43 35 20],'Style','edit','String',num2str(default.gapdur,2),'Tag','gapdur','Callback',@duration,'Enable','off');
uicontrol(panel,'Position',[275 40 20 20],'Style','text','String','ms','Tag','gapunits','Enable','off');

%rearming
uicontrol(panel,'Position',[1  1 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol(panel,'Position',[40 4 30 20],'Style','edit','String',num2str(default.ra,2),'Tag','rearm','Callback',@duration,'Enable','on');
uicontrol(panel,'Position',[70 1 20 20],'Style','text','String','ms','Enable','on');
uicontrol(panel,'Position',[90 4 20 20],'Style','pushbutton','String','?','Tag','helps3','Callback',@helpf,'Enable','on');

uicontrol(panel,'Position',[295 1 120 30],'Style','pushbutton','String','Get Image Average','Tag','avgim','Callback',@avgim,'Enable','on');
uicontrol(panel,'Position',[170 1 120 30],'Style','pushbutton','String','Copy Parameters','Callback',@copyparam,'Enable','on');


uicontrol('Position',[220 125 60 20],'Style','text','String','# spikes:','Enable','on');
uicontrol('Position',[280 125 40 20],'Style','text','String',' ','Tag','nspikes','Enable','on');
uicontrol('Position',[340 125 40 20],'Style','text','String',' ','Tag','sprogress','Enable','on');



uicontrol('Units','normalized','Position',[0.78 0.9 0.2 0.05],'Style','text','String',' ','Tag','processing',...
    'HorizontalAlignment','center','FontSize',15,'Enable','on');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Units','normalized','Position',[0.002 0.96 0.05 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.002 0.23 0.05 0.73],'Style','listbox',...
    'Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@chchannel);
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
Lplt = plot(tm,int8(zeros(length(tm),1)));

linkaxes([ax, ax2],'x')

ax2.XTick = [];
ax2.YTick = -2:2;
ax2.YTickLabels = ["Lower Rej","Thr","null","Thr","Upper Rej"];
ax2.YLim = [-2 2];
ax2.Toolbar.Visible = 'off';
ax2.XLim = [min(tm),max(tm)];

uicontrol('Units','normalized','Position',[0.23 0.04 0.05 0.03],'Style','text','String','Add channel');
uicontrol('Units','normalized','Position',[0.28 0.04 0.05 0.03],'Style','popupmenu',...
    'Max',length(ch),'Min',1,'String',str','Tag','addchannels','Value',showidx(1),'Callback',@addchannel);


W = -1000:1000;
W0 = round(min(W)*sf/sr); 
idur = round(length(W)*sf/sr);

% ------------ Average spike graph --------------------

ht = 0.2; % height of axes
sp = 0.02; % space between graphs

sax = axes('Position',[0.08 0.72 0.12 ht]);
aplt = plot(W*sf*1000,nan(size(W)));
sax.XTick = [];
sax.Title.String = 'Average detected spike';

vax = axes('Position',sax.Position + [0 -(ht+sp) 0 0]);
vax.XTick = [];
vax.Title.String = 'ROI average';

nax = axes('Position',sax.Position + [0 -2*(ht+sp) 0 0]);
aplt2 = plot(W*sf*1000,nan(size(W)));
nax.XLabel.String = 'Time (ms)';
nax.Title.String = 'Channel average';

uicontrol('Units','normalized','Position',[0.08 0.2 0.05 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.13 0.2 0.05 0.03],'Style','popupmenu',...
    'Max',length(ch),'Min',1,'String',str','Tag','avgchannels','Value',showidx(1),'Callback',@chchannel);

saxover = axes('Position',vax.Position);% so that the rectangle always exceed ylimits
pos = [(W(1) + length(W)*slidepos/idur)*sf*1000,  -1,   length(W)/idur*sf*1000,  2];
frame = rectangle('Position',pos,'EdgeColor','none','FaceColor',[0 0 0 0.2]);
set(saxover,'ytick',[],'xtick',[],'color','none','Ylim',[-0.5 0.5])

linkaxes([sax, saxover,vax,nax],'x')
sax.XLim = [min(-300) max(500)]*sf*1000;

aspike = repelem({zeros(2,length(W))},size(data,1));

iax = axes('Position', [0.75 0.1 0.2 0.2*ysize/xsize*fig.Position(3)/fig.Position(4)],'YTick',[],'XTick',[],'Box','on','Tag','roiax');
img = imagesc(zeros(ysize,xsize));
set(iax,'XTick',[],'YTick',[])

txtframe = text(xsize-85,10,sprintf('Frame: %i',slidepos),'FontSize',15);
txttm = text(xsize-85,25,sprintf('Time: %0.1f ms',(W(1) + length(W)*slidepos/idur)*sf*1000),'FontSize',15);

colorbar('Location','manual','Position',[sum(iax.Position([1 3])) 0.1 0.01 iax.Position(4)])

uicontrol('Units','normalized','Position',[iax.Position(1) iax.Position(2)-0.05 iax.Position(3) 0.05],'Style','slider','Value',slidepos,'Min',1,'Max',idur-1,'SliderStep',[1 1]/idur,'Callback',@chframe,'Tag','imslider');
uicontrol('Units','normalized','Position',[0.75 0.9 0.03 0.05],'Style','pushbutton','String','+ ROI','Tag','droi','Callback',@drawroi,'Enable','on','TooltipString','Add an ROI to the image');
uicontrol('Units','normalized','Position',[0.78 0.9 0.03 0.05],'Style','pushbutton','String','- ROI','Callback',@removelastroi,'Enable','on','TooltipString','Remove previously drawn ROI');
uicontrol('Units','normalized','Position',[0.81 0.9 0.03 0.05],'Style','pushbutton','String','clear','Callback',@clearroi,'Enable','on','TooltipString','Remove all ROIs');

cpanel = uipanel('Title','Compare Images','Units','normalized','FontSize',12,'Position',[0.85 0.8 0.09 0.2],'Tag','cpanel');
uicontrol(cpanel,'Units','pixels','Position',[5 75 40 20],'Style','pushbutton','String','add','Callback',@addframe,'Enable','on','TooltipString','Add displayed frame to comparison figure');
uicontrol(cpanel,'Units','pixels','Position',[5 55 40 20],'Style','pushbutton','String','show','Callback',@showcompare,'Enable','on','TooltipString','Show comparison figure');
uicontrol(cpanel,'Units','pixels','Position',[45 0 100 20],'Style','pushbutton','String','Remove','Callback',@removeframe,'Enable','on','TooltipString','Remove selected image');
uicontrol(cpanel,'Units','pixels','Position',[45 20 100 75],'Style','listbox','Tag','compare','Max',inf)

bw = 0.03;
uicontrol('Units','normalized','Position',[iax.Position(1) sum(iax.Position([2 4])) bw 0.05],'Style','pushbutton','String','Raw','Tag','raw1','Callback',@rawimage)
uicontrol('Units','normalized','Position',[iax.Position(1)+bw sum(iax.Position([2 4])) bw 0.05],'Style','pushbutton','String','Unfiltered','Tag','raw2','Callback',@rawimage)
uicontrol('Units','normalized','Position',[iax.Position(1)+bw*2 sum(iax.Position([2 4])) bw 0.05],'Style','pushbutton','String','Filtered','Tag','raw3','Callback',@rawimage)
uicontrol('Units','normalized','Position',[iax.Position(1)+bw*3 sum(iax.Position([2 4])) bw 0.05],'Style','pushbutton','String','Filt - BL','Tag','raw4','Callback',@rawimage)
uicontrol('Units','normalized','Position',[iax.Position(1) sum(iax.Position([2 4]))+0.05 bw 0.05],'Style','pushbutton','String','montage','Tag','montage','Callback',@montagef)

helps = ["To detect spikes the data value has to be above this threshold consecutively for as long as the minimum duration.  If active, the reject will remove spikes whose data goes above the reject threshold during the duration.",...
         "To detect spikes the data value has to be below this threshold consecutively for as long as the minimum duration.  If active, the reject will remove spikes whose data goes above the reject threshold during the duration.",...
         "The re-arm prevents the same spike from being detected twice.  The re-arm value is the minimal amount of time to detect a subsequent spike.  Should be a little longer than the concievable duration of a spike and shorter than the minimum concievable spike interval.  A neuron that fires at most 100Hz should have a re-arm duration less than 10 ms."];

color = makecolor(-0.2);
color(2,:) = color(2,:)*0.7;

if ~ischar(inputinfo)
    inputinfo = [];
end

guidata(fig,struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                   'tplt',tplt,         'splt',splt,        'sax',sax,...
                   'aplt',aplt,         'iax',iax,          'img',img,...
                   'W',W,               'data',data,        'ch',ch,...
                   'hideidx',hideidx,   'showidx',showidx,  'tm',tm,...
                   'str',str,           'ckup',true,        'ckdwn',false,...
                   'gidx',showidx(1),   'aspike',{aspike},  'aspike2',{aspike},...
                   'aplt2',aplt2,       'spikes',{spikes},  'vsd',vsd,...
                   'inc',inc,           'files',files,      'frame',frame,...
                   'helps',helps,       'vax',vax,          'panel',panel,...
                   'rawim',2,           'origim',origim,    'imdata',zeros(ysize,xsize,slidepos+40),...
                   'roiln',gobjects(0,1),'roi',gobjects(0,1), 'colors',color,...
                   'params',params,     'Lplt',Lplt,        'txtframe',txtframe,...
                   'txttm',txttm,       'cpanel',cpanel,    'cdata',{cell(0,3)},...
                   'intan_tag',inputinfo))

detsp(fig)

function tointan(hObject,eventdata)
aprops = guidata(hObject);
intan = findobj('Tag',aprops.intan_tag);
props = guidata(intan);
props.spikedetection.params = aprops.params;
sf = diff(props.tm(1:2));

pos = get(findobj('Tag',props.intan_tag),'Position');
fig = figure('Name','Progress...','NumberTitle','off','MenuBar','none',...
    'Position',[pos(1)+pos(3)/2, pos(2)+pos(4)/2 300 75]);
pax = axes('Position',[0.1 0.2 0.8 0.7],'XLim',[0 1],'YLim',[0 1],'YTick',[]);
rec = rectangle('Position',[0 0 0 1],'FaceColor','b');

for d=1:length(props.ch)
    set(rec,'Position',[0 0 d/length(props.ch) 1])
    pause(0.01)
    [aprops.spikes{d}] = detection_algorithm(aprops.params(d), aprops.W, props.data(d,:), [], sf);
end
close(fig)

props.spikedetection.spikes = aprops.spikes;
disp('sent to intan_gui')
guidata(hObject,aprops)
guidata(intan,props)

function addchannel(hObject,eventdata)
props = guidata(hObject);
nch = length(props.ax) + 1;
lowerY = props.ax(end).Position(2);
totalh = sum(props.ax(1).Position([2 4]));
gap = 0.02;
height = (totalh-lowerY)/nch - gap*(nch-1)/nch;
Ys = fliplr(lowerY:height+gap:totalh-lowerY);
for p=1:length(props.ax)
    props.ax(p).Position([2 4]) = [Ys(p) height];
    obj = findobj(hObject.Parent,'Tag',['addchannels' num2str(p)]);
    if ~isempty(obj)
        obj.Position(2) = Ys(p)+height-0.03;
    end
    obj = findobj(hObject.Parent,'Tag',['rmchannels' num2str(p)]);
    if ~isempty(obj)
        obj.Position(2) = Ys(p)+height-0.025;
    end
end
% plot new axis
props.ax(nch) = axes('Position',[props.ax(1).Position(1) , Ys(end) , props.ax(1).Position(3) , height]);
props.addplt(nch) = plot(props.tm,props.data(hObject.Value,:));
set(props.ax,'XLim',props.ax(1).XLim)
set(props.ax,'XLabel',[])
set(props.ax(1:end-1),'XTick',[])
props.ax(end).XLabel.String = 'Time (s)';
linkaxes(props.ax,'x')

uicontrol('Units','normalized','Position',[props.ax(1).Position(1)+0.01 , Ys(end)+height-0.03 , 0.05 , 0.03],...
    'Style','popupmenu','Max',length(props.ch),'Min',1,'String',props.str','Tag',['addchannels' num2str(p+1)],...
    'Value',hObject.Value,'Callback',@chaddchannel,'TooltipString','Change this channel');
uicontrol('Units','normalized','Position',[props.ax(1).Position(1)+0.06 , Ys(end)+height-0.025 , 0.01 , 0.025],...
    'Style','pushbutton','String','X','Callback',@rmaddchannel,'Tag',['rmchannels' num2str(p+1)],'TooltipString','Remove this channel')

guidata(hObject,props)

function chaddchannel(hObject,eventdata)
props = guidata(hObject);
idx = double(string(regexp(hObject.Tag,'\d+','match')));
set(props.addplt(idx),'YData',props.data(hObject.Value,:))
guidata(hObject,props)

function rmaddchannel(hObject,eventdata)
props = guidata(hObject);
fig = hObject.Parent;
lowerY = props.ax(end).Position(2);
totalh = sum(props.ax(1).Position([2 4]));

idx = double(string(regexp(hObject.Tag,'\d+','match')));
delete(props.ax(idx));
props.ax(idx) = [];
props.addplt(idx) = [];
delete(findobj(hObject.Parent,'Tag',replace(hObject.Tag,'rm','add')));

% update numbering of the tags
nidx = idx + 1;
addch = findobj(fig,'Tag',['addchannels' num2str(nidx)]);
while ~isempty(addch)
    addch.Tag = ['addchannels' num2str(nidx-1)];
    nidx = nidx + 1;
    addch = findobj(fig,'Tag',['addchannels' num2str(nidx)]);
end
delete(findobj(fig,'Tag',['rmchannels' num2str(nidx-1)]))

nch = length(props.ax);
gap = 0.02;
height = (totalh-lowerY)/nch - gap*(nch-1)/nch;
Ys = fliplr(lowerY:height+gap:totalh-lowerY);
if isempty(Ys)
    Ys = lowerY;
end
for p=1:length(props.ax)
    props.ax(p).Position([2 4]) = [Ys(p) height];
    obj = findobj(fig,'Tag',['addchannels' num2str(p)]);
    if ~isempty(obj)
        obj.Position(2) = Ys(p)+height-0.03;
    end
    obj = findobj(fig,'Tag',['rmchannels' num2str(p)]);
    if ~isempty(obj)
        obj.Position(2) = Ys(p)+height-0.025;
    end
end
guidata(fig,props)

function showcompare(hObject,eventdata)
props = guidata(hObject);
compareim(props.cdata(:,1),props.cdata(:,3));
% nim = size(props.cdata,1);
% figure;
% for f=1:nim
%     ax = subplot(1,nim,f);
%     imagesc(props.cdata{f,1});
%     ax.Title.String = props.cdata{f,3};
%     ax.XGrid = 'on';
%     ax.YGrid = 'on';
%     pbaspect([1 1 1])
% end

function removeframe(hObject,eventdata)
props = guidata(hObject);
list = findobj('Parent',props.cpanel,'Tag','compare');
if length(list.Value)==length(list.String)
    list.String = '';
end
list.String(list.Value) = [];
props.cdata(list.Value,:) = [];
set(list,'Value',1)
guidata(hObject,props)

function addframe(hObject,eventdata)
props = guidata(hObject);
list = findobj('Parent',props.cpanel,'Tag','compare');
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
frame = get(findobj('Tag','imslider','Parent',fig),'Value');
props.cdata = [props.cdata; {props.img.CData, [idx frame], [props.ch{idx} '  (' num2str(frame) ')']}];
if isempty(list.String)
    list.String = {[props.ch{idx} '  (' num2str(frame) ')']};
else
    list.String = [list.String; [props.ch{idx} '  (' num2str(frame) ')']];
end
guidata(hObject,props)

function opensaveparams(hObject,eventdata)
props = guidata(hObject);
params = props.params;
cdata = props.cdata;
if ~isempty(props.files)
    folder = [];
    t=1;
    while t>0
        if ~isempty(props.files{t,2})
            folder = fileparts(props.files{t,2});
            t = -1;
        else
            t = t+1;
        end
        if t>size(props.files,1)
            t = -1;
        end
    end
end
fname = fullfile(folder,'spike_parameters.mat');
if strcmp(hObject.Tag,'open')
    [file,path] = uigetfile(fname,'Select spike_parameter file');
    if ~isempty(file)
        return
    end
    filedata = load(fullfile(path,file));
    assignin('base','filedata',filedata)
    props.params = filedata.params;
    props.cdata = filedata.cdata;
    if ~isempty(props.cdata)
        set(findobj('Parent',props.cpanel,'Tag','compare'),'String',string(filedata.cdata(:,3)));
    end
    str = 'loaded';
else
    [file,path] = uiputfile(fname);
    save(fullfile(path,file),'params','cdata')
    str = 'saved';
end
disp(['File ' str ' :'])
disp(fname)
guidata(hObject,props)
chchannel(hObject)

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
set(findobj(hObject.Parent,'-regexp','Tag','raw(1|2|3|4)'),'BackgroundColor',[0.94 0.94 0.94]);
set(hObject,'BackgroundColor',[0.7 0.7 0.7])
idx = double(string(regexp(hObject.Tag,'\d','match')));
props.rawim = idx;
frame = get(findobj('Tag','imslider','Parent',hObject.Parent) ,'Value')+1;
if idx==1
    set(props.img,'CData',props.origim(:,:,1))
else
    set(props.img,'CData',props.imdata(:,:,frame,idx-1))
end
guidata(hObject,props)

function montagef(hObject,eventdata)
props = guidata(hObject);
figure
im = props.imdata(:,:,:,props.rawim);
im = im - min(im(:));
im = im/max(im(:));
montage(im)
colormap(parula)

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

function chframe(hObject,eventdata)
props = guidata(hObject);
frame = round(hObject.Value);
set(hObject,'Value',frame)
if props.rawim>1
    set(props.img,'CData',props.imdata(:,:,frame,props.rawim-1))
end
idur = get(hObject,'Max');
sf = diff(props.tm(1:2));
pos = [(props.W(1) + length(props.W)*frame/idur)*sf*1000,  -1,   length(props.W)/idur*sf*1000,  2];
props.txtframe.String = sprintf('Frame: %i',frame);
props.txttm.String = sprintf('Time: %0.1f ms',(props.W(1) + length(props.W)*frame/idur)*sf*1000);
set(props.frame,'Position',pos)
guidata(hObject,props)

function chval(hObject,eventdata)
props = guidata(hObject);
tag = get(hObject,'Tag');
change = regexp(tag,'(up|dwn|UP|DWN|thr|dur|gap|rej)','match');
dir = contains(tag,'UP')*2 - 1;
obj = findobj(hObject.Parent,'Tag',[change{1},change{3}]);
val = str2double(obj.String);
if contains(tag,'thr') || contains(tag,'rej')
    val = val + dir*props.inc;% increment of change 
    vals = num2str(val);
else
    sr = diff(props.tm(1:2));
    val = val/1000/sr;
    val = val + dir;
    if contains(tag,'gap')
        val = correctgap(props,val);
    end
    val = sr*val*1000;
    vals = num2str(val,2);% ensure that duration is incriments of the sampling frequency
end
set(obj,'String',vals)
chparam(hObject.Parent)

function val = correctgap(props,val)
% must be in units of samples (idx) 
sr = diff(props.tm(1:2));
if val>=0
    updur = str2double(get(findobj('Tag','updur','Parent',props.panel),'String'))/1000/sr;
    updur = updur+2;
    val(val<updur) = updur;
else
    dwndur = str2double(get(findobj('Tag','dwndur','Parent',props.panel),'String'))/1000/sr;
    dwndur = -(dwndur+2);
    val(val>dwndur) = dwndur;
end

function chchannel(hObject,eventdata)
props = guidata(hObject);
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
enable = ["off","on"];
set(findobj(props.panel,'Tag','ckup'),'Value',props.params(idx).ckup)
set(findobj(props.panel,'Tag','ckdwn'),'Value',props.params(idx).ckdwn)
set(findobj(props.panel,'Tag','ckuprej'),'Value',props.params(idx).ckuprej)
set(findobj(props.panel,'Tag','ckdwnrej'),'Value',props.params(idx).ckdwnrej)
set(findobj(props.panel,'Tag','updur'),'String',num2str(props.params(idx).updur,2));
set(findobj(props.panel,'Tag','upthr'),'String',props.params(idx).upthr);

set(findobj(props.panel,'Tag','uprej'),'String',props.params(idx).uprej);
set(findobj(props.panel,'Tag','dwnrej'),'String',props.params(idx).dwnrej);

set(findobj(props.panel,'Tag','dwndur'),'String',num2str(props.params(idx).dwndur,2));
set(findobj(props.panel,'Tag','dwnthr'),'String',props.params(idx).dwnthr);
set(findobj(props.panel,'Tag','gapdur'),'String',num2str(props.params(idx).gapdur,2));
set(findobj(props.panel,'Tag','rearm'),'String',num2str(props.params(idx).ra,2));

set(findobj(props.panel,'-regexp','Tag','^up(pUP|pDWN|units|dur|thr)(?!rej)') ,'Enable',enable(props.params(idx).ckup+1))
set(findobj(props.panel,'-regexp','Tag','^up\w*rej$')     ,'Enable',enable((props.params(idx).ckup & props.params(idx).ckuprej)+1))
set(findobj(props.panel,'-regexp','Tag','^dwn(pUP|pDWN|units|dur|thr)(?!rej)'),'Enable',enable(props.params(idx).ckdwn+1))
set(findobj(props.panel,'-regexp','Tag','^dwn\w*rej$')    ,'Enable',enable((props.params(idx).ckdwn & props.params(idx).ckdwnrej)+1))

if props.params(idx).ckup && props.params(idx).ckdwn
    set(findobj(props.panel,'-regexp','Tag','^gap'),'Enable','on')
else
    set(findobj(props.panel,'-regexp','Tag','^gap'),'Enable','off')
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
set(props.plt(1),'YData', props.data(idx,:));

stdata = std(props.data(idx,:));
if props.params(idx).ckup
    tag = 'upthr';
    if props.params(idx).ckdwn && str2double(get(findobj('Tag','gapdur','Parent',props.panel),'String'))<0
        tag = 'dwnthr';
    end
else
    tag = 'dwnthr';
end
thr = str2double(get(findobj(props.panel,'Tag',tag),'String'));
spikes = props.spikes{idx};
set(props.splt,'XData',props.tm(spikes),'YData',ones(size(spikes))*thr*stdata)

set(props.aplt,'YData',mean(props.aspike{idx},1))
set(props.aplt2,'YData',mean(props.aspike2{idx},1))
guidata(hObject,props)

function activatethr(hObject,eventdata)
props = guidata(hObject);
vals = [get(findobj(props.panel,'Tag','ckup'),'Value') , get(findobj(props.panel,'Tag','ckdwn'),'Value')];
if ~hObject.Value && ~any(vals)
    hObject.Value = true;
    return
end
enable = ["off","on"];
ckup = findobj(props.panel,'Tag','ckup');
ckdwn = findobj(props.panel,'Tag','ckdwn');
ckuprej = findobj(props.panel,'Tag','ckuprej');
ckdwnrej = findobj(props.panel,'Tag','ckdwnrej');

disp(enable((get(ckdwn,'Value') & get(ckdwnrej,'Value'))+1))
set(findobj(props.panel,'-regexp','Tag','^up(pUP|pDWN|units|dur|thr)(?!rej)') ,'Enable',enable(get(ckup,'Value')+1))
set(findobj(props.panel,'-regexp','Tag','^up\w*rej$')     ,'Enable',enable((get(ckup,'Value') & get(ckuprej,'Value'))+1))
set(findobj(props.panel,'-regexp','Tag','^dwn(pUP|pDWN|units|dur|thr)(?!rej)'),'Enable',enable(get(ckdwn,'Value')+1))
set(findobj(props.panel,'-regexp','Tag','^dwn\w*rej$')    ,'Enable',enable((get(ckdwn,'Value') & get(ckdwnrej,'Value'))+1))

ischecked = string(get(findobj('-regexp','Tag','ck(up|dwn)$'),'Value'))=="1";
if all(ischecked)
    set(findobj(props.panel,'-regexp','Tag','^gap'),'Enable','on')
else
    set(findobj(props.panel,'-regexp','Tag','^gap'),'Enable','off')
end
    
chparam(hObject)

function duration(hObject,eventdata)
props = guidata(hObject);
dur = str2double(hObject.String)/1000;
sr = diff(props.tm(1:2));
nval = num2str(sr*round(dur/sr)*1000,2);
set(hObject,'String',nval)
gapobj = findobj('Tag','gapdur','Parent',props.panel);
gapdur = str2double(get(gapobj,'String'))/1000/sr;
set(gapobj,'String',num2str(correctgap(props,gapdur)*1000*sr,2));
chparam(hObject.Parent)

function chparam(hObject,eventdata)
props = guidata(hObject);
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
props.params(idx).ckup = get(findobj(props.panel,'Tag','ckup'),'Value');
props.params(idx).ckdwn = get(findobj(props.panel,'Tag','ckdwn'),'Value');
props.params(idx).ckuprej = get(findobj(props.panel,'Tag','ckuprej'),'Value');
props.params(idx).ckdwnrej = get(findobj(props.panel,'Tag','ckdwnrej'),'Value');
props.params(idx).updur = str2double(get(findobj(props.panel,'Tag','updur'),'String'));
props.params(idx).upthr = str2double(get(findobj(props.panel,'Tag','upthr'),'String'));

props.params(idx).uprej = str2double(get(findobj(props.panel,'Tag','uprej'),'String'));
props.params(idx).dwnrej = str2double(get(findobj(props.panel,'Tag','dwnrej'),'String'));

props.params(idx).dwndur = str2double(get(findobj(props.panel,'Tag','dwndur'),'String'));
props.params(idx).dwnthr = str2double(get(findobj(props.panel,'Tag','dwnthr'),'String'));
props.params(idx).gapdur = str2double(get(findobj(props.panel,'Tag','gapdur'),'String'));
props.params(idx).ra = str2double(get(findobj(props.panel,'Tag','rearm'),'String'));
guidata(hObject.Parent,props)
detsp(hObject)

function detsp(hObject,eventdata)
if nargin==2
    hObject = hObject.Parent;
end
props = guidata(hObject);

set(findobj(hObject.Parent.Parent,'Tag','sprogress'),'String','   ')

allbut = findobj(hObject,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')

fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');

data = props.data(idx,:);
tm = props.tm;
sf = diff(tm(1:2));

idx2 = get(findobj('Tag','avgchannels','Parent',fig),'Value');
data2 = props.data(idx2,:);

[spikes,aspike,aspike2,logic] = detection_algorithm(props.params(idx),props.W,data,data2,sf,props.tplt);

props.aspike{idx} = aspike;
props.aspike2{idx} = aspike2;
props.spikes{idx} = spikes;

set(props.Lplt,'YData',logic)

guidata(hObject,props)

set(findobj('Tag','nspikes','Parent',findobj('Tag',props.apptag)),'String',num2str(length(spikes)));
plotdata(hObject)
set(allbut,'Enable','on')

function [spikes, aspike, aspike2,logic] = detection_algorithm(params,W,data,data2,sf,tplt)
updur = round(params.updur/1000/sf);% convert from time to # indices
dwndur = round(params.dwndur/1000/sf);% convert from time to # indices
gapdur = round(params.gapdur/1000/sf);% convert from time to # indices
ra = round(params.ra/1000/sf);% convert from time to # indices

sdata = repelem('n',length(data));
stdata = std(data,"omitnan");
logic = int8(zeros(length(data),1));
if params.ckup
    sidx = data>params.upthr*stdata;% find all values > threshold
    sdata(sidx) = 'u';
    logic(sidx) = 1;
    if nargin>5; set(tplt(1),'YData',[1 1]*params.upthr*stdata);end
    pattern = ['u{' num2str(updur) ',}' ];
%     pattern = repelem('u',updur);
elseif nargin>5
    set(tplt(1),'YData',nan(2,1))
end

if params.ckup && params.ckuprej
    sidx = data>params.uprej*stdata;% find all values > threshold
    sdata(sidx) = 'r';
    logic(sidx) = 2;
    if nargin>5; set(tplt(3),'YData',[1 1]*params.uprej*stdata);end
    pattern = ['u{' num2str(updur) ',}'];
    rpattern1 = ['r' pattern];
    rpattern2 = [pattern 'r'];
elseif nargin>5
    set(tplt(3),'YData',nan(2,1))
end

if params.ckdwn
    sidx = data<params.dwnthr*stdata;% find all values > threshold
    sdata(sidx) = 'd';
    logic(sidx) = -1;
    if nargin>5; set(tplt(2),'YData',[1 1]*params.dwnthr*stdata);end
    pattern = ['d{' num2str(dwndur) ',}' ];
%     pattern = repelem('d',dwndur);
elseif nargin>5
    set(tplt(2),'YData',nan(2,1))
end

if params.ckdwn && params.ckdwnrej
    sidx = data<params.dwnrej*stdata;% find all values > threshold
    sdata(sidx) = 'r';
    logic(sidx) = -2;
    if nargin>5; set(tplt(4),'YData',[1 1]*params.dwnrej*stdata);end
    pattern = ['d{' num2str(dwndur) ',}' ];
    rpattern1 = ['r' pattern];
    rpattern2 = [pattern 'r'];
elseif nargin>5
    set(tplt(4),'YData',nan(2,1))
end

if params.ckup && params.ckdwn
    warning('haven''t fixed this condition for rejection')
    if gapdur>=0
        pattern = ['u{' num2str(updur) ',}' '[udn]{' num2str(gapdur-updur) '}' 'd{' num2str(dwndur) ',}'];
%         eval(['pattern = "' repelem('u',updur) '"' repmat(' + ("u"|"d"|"n")',1,gapdur-updur) ' + "' repelem('d',dwndur) '";'])
    else
        pattern = ['d{' num2str(dwndur) ',}' '[udn]{' num2str(abs(gapdur)-dwndur) '}' 'u{' num2str(updur) ',}'];
%         eval(['pattern = "' repelem('d',dwndur) '"' repmat(' + ("u"|"d"|"n")',1,abs(gapdur)-dwndur) ' + "' repelem('u',updur) '";'])
    end
end

spikes = regexp(sdata,pattern);
if params.ckdwnrej || params.ckuprej
    rej = regexp(sdata,rpattern1);
    rejlog = arrayfun(@(x) any(rej==x-1),spikes);
    spikes(rejlog) = [];
    rej = regexp(sdata,rpattern2);
    rejlog = arrayfun(@(x) any(rej==x),spikes);
    spikes(rejlog) = [];
end
% spikes = strfind(sdata,pattern);
aspike = [];
aspike2 = [];
if ~isempty(spikes)
    spikes = spikes([true, diff(spikes)>ra]);% remove values that are separated by < re-arm (prevents dection of same spike).  The value is idices;
    spikes(spikes+W(1)<0 | spikes+W(end)>length(data)) = [];
    aspike = zeros(length(spikes),length(W));
    aspike2 = zeros(length(spikes),length(W));% for averaging of channel2
    for i = 1:length(spikes)
        aspike(i,:) = data(W+spikes(i));
        if ~isempty(data2)
            aspike2(i,:) = data2(W+spikes(i));
        end
    end
end

function avgim(hObject,eventdata)
props = guidata(hObject);

set(findobj('Tag','processing','Parent',hObject.Parent.Parent),'String','Processing...')
allbut = findobj(hObject.Parent.Parent,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')
set(findobj(hObject.Parent.Parent,'Tag','sprogress'),'Enable','on')
pause(0.1)

tic
if isempty(props.files)
    return
end
idx = get(findobj('Tag','channels','Parent',hObject.Parent.Parent),'Value');

warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(props.vsd);
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

imdata = int16(zeros(ysize,xsize,dur));
frameLength = xsize*ysize; % Frame length is the product of X and Y axis lengths;
f0 = int16(zeros(ysize,xsize,length(sidx)));

fid = fopen(info.Filename,'r');
for s=1:length(sidx)
    offset = info.PrimaryData.Offset + ... Header information takes 2880 bytes.
                (sidx(s)-1)*frameLength*2; % Because each integer takes two bytes.
    
    fseek(fid,offset,'bof');% Find target position on file.
    
    % Read data.
    fdata = fread(fid,frameLength*dur,'int16=>int16');%'int16=>double');% single saves about 25% processing time and requires half of memory 
    if length(fdata)<xsize*ysize*dur
        break
    end
    fdata = reshape(fdata,[xsize ysize dur]);
    f0(:,:,s) = fdata(:,:,1);
    f0p = repmat(fdata(:,:,1),1,1,size(fdata,3));
%     fdata = (fdata - f0)./f0;
    fdata = fdata - f0p;
    

    imdata = imdata + fdata;% Format data.
    if mod(s,10)==0
        set(findobj(hObject.Parent.Parent,'Tag','sprogress'),'String',num2str(s))
        pause(0.1)
    end
end
fclose(fid);

imdata = double(imdata);
imdata = imdata/length(sidx);
f0a = repmat(mean(f0,3),1,1,size(imdata,3));
imdata = imdata./f0a;
imdata = permute(imdata,[2 1 3]);

% f0 = repmat(imdata(:,:,1),1,1,size(imdata,3));
% imdata = (imdata - f0)./f0;
% imdata(1:6,:,:) = 0;
imdataf = imgaussfilt3(imdata);
props.imdata = cat(4,imdata,imdataf,imdataf - repmat(median(imdataf,2),1,size(imdataf,2),1));


frame = get(findobj('Tag','imslider','Parent',hObject.Parent.Parent) ,'Value')+1;
set(props.img,'CData',imdata(:,:,frame))

set(findobj('Tag','processing','Parent',hObject.Parent.Parent),'String',' ')
toc
set(allbut,'Enable','on')
guidata(hObject,props)




