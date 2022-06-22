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
dur = 5;% default number of datapoints above threshold to detect spike.
thr = 5;
ra = 10;% re-arm, the minimal amount of time to detect a subsequent spike (should be just longer than the concievable duration of a spike)
inc = 0.25;

apptag = ['apptag' num2str(randi(1e4,1))];
fig = figure('Position',[10 80 1900 600],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Spike Tools');
mi(1) = uimenu(m,'Text','Open','Callback',@threshold,'Enable','off');
mi(3) = uimenu(m,'Text','Save','Callback',@threshold,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','on','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


oppos = [120 327 40 20];
panel = uipanel('Title','Controls','Units','pixels','FontSize',12,'Position',[2 2 380 132],'Tag','panel');%[0.005 0.78 0.20 0.22]

uicontrol(panel,'Position',[55  88 80 25],'Style','text','String','Threshold','Enable','on');
uicontrol(panel,'Position',[165 88 80 25],'Style','text','String','Min Duration','Enable','on');

%threshold 1
ckup = uicontrol(panel,'Position',[1 73 20 20],'Style','checkbox','Tag','ckup','Callback',@activatethr,'Enable','on','Value',true);
uicontrol(panel,'Position',[20  70  40 20],'Style','text','String','Upper','Tag','upstr','Callback',@threshold,'Enable','on');
uicontrol(panel,'Position',[65  73  20 20],'Style','pushbutton','Tag','uppUPthr','String',char(708),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[85  73  20 20],'Style','pushbutton','Tag','uppDWNthr','String',char(709),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[110 73  30 20],'Style','edit','String',num2str(thr),'Tag','upthr','Callback',@detsp,'Enable','on');
uicontrol(panel,'Position',[140 70  20 20],'Style','text','String','std','Tag','upunits','Enable','on');

uicontrol(panel,'Position',[165 73  20 20],'Style','pushbutton','Tag','uppUPdur','String',char(708),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[185 73  20 20],'Style','pushbutton','Tag','uppDWNdur','String',char(709),'Callback',@chval,'Enable','on');
uicontrol(panel,'Position',[210 73  30 20],'Style','edit','String',num2str(sf*dur*1000,2),'Tag','updur','Callback',@duration,'Enable','on');
uicontrol(panel,'Position',[240 70  20 20],'Style','text','String','ms','Enable','on');
uicontrol(panel,'Position',[270 73  20 20],'Style','pushbutton','String','?','Tag','helps1','Callback',@helpf,'Enable','on');


%threshold 2
ckdwn = uicontrol(panel,'Position',[1  43 20 20],'Style','checkbox','Tag','ckdwn','Callback',@activatethr,'Enable','off','Tooltip','have not coded this yet');
uicontrol(panel,'Position',[20  40 40 20],'Style','text','Tag','dwnstr','String','Lower','Enable','off');
uicontrol(panel,'Position',[65  43 20 20],'Style','pushbutton','Tag','dwnpUPthr','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[85  43 20 20],'Style','pushbutton','Tag','dwnpDWNthr','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[110  43 30 20],'Style','edit','String',num2str(thr),'Tag','dwnthr','Callback',@threshold,'Enable','off');
uicontrol(panel,'Position',[140  40 20 20],'Style','text','String','std','Tag','dwnunits','Enable','off');

uicontrol(panel,'Position',[165 43 20 20],'Style','pushbutton','Tag','dwnpUPdur','String',char(708),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[185 43 20 20],'Style','pushbutton','Tag','dwnpDWNdur','String',char(709),'Callback',@chval,'Enable','off');
uicontrol(panel,'Position',[210 43 30 20],'Style','edit','String',num2str(sf*dur*1000,2),'Tag','dwndur','Callback',@duration,'Enable','off');
uicontrol(panel,'Position',[240 40 20 20],'Style','text','String','ms','Enable','off');
uicontrol(panel,'Position',[270 43 20 20],'Style','pushbutton','String','?','Tag','helps2','Callback',@helpf,'Enable','on');

%rearming
uicontrol(panel,'Position',[1  1 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol(panel,'Position',[40 4 30 20],'Style','edit','String',num2str(ra),'Tag','rearm','Callback',@duration,'Enable','on');
uicontrol(panel,'Position',[70 1 20 20],'Style','text','String','ms','Enable','on');
uicontrol(panel,'Position',[90 4 20 20],'Style','pushbutton','String','?','Tag','helps3','Callback',@helpf,'Enable','on');

uicontrol(panel,'Position',[255 1 120 30],'Style','pushbutton','String','Get Image Average','Tag','avgim','Callback',@avgim,'Enable','on');


uicontrol('Position',[220 125 60 20],'Style','text','String','# spikes:','Enable','on');
uicontrol('Position',[280 125 20 20],'Style','text','String',' ','Tag','nspikes','Enable','on');



uicontrol('Units','normalized','Position',[0.78 0.9 0.2 0.05],'Style','text','String',' ','Tag','processing',...
    'HorizontalAlignment','center','FontSize',15,'Enable','on');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Units','normalized','Position',[0.002 0.96 0.05 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.002 0.23 0.05 0.73],'Style','listbox','Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@detsp);
%[5 440 100 20] [5 40 100 400]

% initialize axes
mdata = mean(data(showidx(1),:));
stddata = std(data(showidx(1),:));

ax = axes('Position',[0.23 0.1 0.5 0.85]);
plt = plot(tm,data(showidx(1),:));hold on

tplt(1) = plot([min(tm) max(tm)],[mdata, mdata]+stddata*thr);
tplt(2) = plot([min(tm) max(tm)],nan(2,1));
splt = scatter(nan,nan,'x');

ax.XLim = [min(tm),max(tm)];
ax.XLabel.String = 'Time (s)';


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

helps = ["To detect spikes the data value has to be above this threshold consecutively for as long as the minimum duration",...
         "To detect spikes the data value has to be below this threshold consecutively for as long as the minimum duration",...
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
                   'roiln',gobjects(0,1),'roi',gobjects(0,1), 'colors',color))

detsp(fig)

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
addlistener(roi,'ROIMoved',@moveroi);
props.roi = [props.roi; roi];

[pixels,vdata] = roidata(unique(round(roi.Position),'rows'), props.imdata);

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
change = regexp(tag,'(up|dwn|UP|DWN|thr|dur)','match');
dir = contains(tag,'UP')*2 - 1;
obj = findobj('Tag',[change{1},change{3}],'Parent',hObject.Parent);
val = str2double(obj.String);
if contains(tag,'thr')
    val = val + dir*props.inc;% increment of change 
    vals = num2str(val);
else
    val = val/1000;
    sr = diff(props.tm(1:2));
    val = val + dir*sr;
    vals = num2str(sr*round(val/sr)*1000,2);% ensure that duration is incriments of the sampling frequency
end
set(obj,'String',vals)
detsp(hObject.Parent)

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
thr = str2double(get(findobj('Tag','upthr','Parent',props.panel),'String'));
spikes = props.spikes{idx};
set(props.splt,'XData',props.tm(spikes),'YData',ones(size(spikes))*thr*stdata)

set(props.aplt,'YData',mean(props.aspike{idx},1))
guidata(hObject,props)

function activatethr(hObject,eventdata)
props = guidata(hObject);
props.(hObject.Tag) = hObject.Value;
vstr = ["off","on"];
substr = ["dwn","up"];
substr = char(substr(contains(hObject.Tag,'up')+1));
set(findobj('-regexp','Tag',['^' substr]),'Enable',vstr(hObject.Value+1))
guidata(hObject,props)

function duration(hObject,eventdata)
props = guidata(hObject);
dur = str2double(hObject.String)/1000;
sr = diff(props.tm(1:2));
set(hObject,'String',num2str(sr*round(dur/sr)*1000,2))
detsp(hObject.Parent)

function detsp(hObject,eventdata)
if nargin==2
    hObject = hObject.Parent;
end
props = guidata(hObject);

allbut = findobj(hObject,'Type','Uicontrol','Enable','on');
allbut = [allbut; findobj(props.panel,'Type','Uicontrol','Enable','on')];
set(allbut,'Enable','off')

idx = get(findobj('Tag','channels','Parent',findobj('Tag',props.apptag)),'Value');
dur = str2double(get(findobj('Tag','updur','Parent',props.panel),'String'));
thr = str2double(get(findobj('Tag','upthr','Parent',props.panel),'String'));
ra = str2double(get(findobj('Tag','rearm','Parent',props.panel),'String'));


data = props.data(idx,:);
tm = props.tm;
stdata = std(data);
sf = diff(tm(1:2));

set(props.tplt(1),'YData',[thr thr]*stdata)

dur = round(dur/1000/sf);% convert from time to # indices
ra = round(ra/1000/sf);% convert from time to # indices

Ldata = data>thr*stdata;% find all values > threshold
spikes = strfind(Ldata,repelem(true,dur));% find consecutive values >= duration
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

    



