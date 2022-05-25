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
fig = figure('Position',[10 80 1900 500],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Spike Tools');
mi(1) = uimenu(m,'Text','Open','Callback',@threshold,'Enable','off');
mi(3) = uimenu(m,'Text','Save','Callback',@threshold,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','on','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


uicontrol('Position',[235 415 20 25],'Style','text','String','Thr','Enable','on');
uicontrol('Position',[290 425 20 25],'Style','text','String','Min Dur','Enable','on');


ckup = uicontrol('Position',[120  400 20 20],'Style','checkbox','Tag','ckup','Callback',@activatethr,'Enable','on','Value',true);
uicontrol('Position',[140  397 40 20],'Style','text','String','Upper','Tag','upstr','Callback',@threshold,'Enable','on');
uicontrol('Position',[185  400 20 20],'Style','pushbutton','Tag','uppUPthr','String',char(708),'Callback',@chval,'Enable','on');
uicontrol('Position',[205 400 20 20],'Style','pushbutton','Tag','uppDWNthr','String',char(709),'Callback',@chval,'Enable','on');
uicontrol('Position',[230 400 30 20],'Style','edit','String',num2str(thr),'Tag','upthr','Callback',@detsp,'Enable','on');
uicontrol('Position',[260 397 20 20],'Style','text','String','std','Tag','upunits','Enable','on');

%< ----- Need to activate duration buttons
uicontrol('Position',[285  400 20 20],'Style','pushbutton','Tag','uppUPdur','String',char(708),'Callback',@chval,'Enable','on');
uicontrol('Position',[305 400 20 20],'Style','pushbutton','Tag','uppDWNdur','String',char(709),'Callback',@chval,'Enable','on');
uicontrol('Position',[330 400 30 20],'Style','edit','String',num2str(sf*dur*1000,2),'Tag','updur','Callback',@duration,'Enable','on');
uicontrol('Position',[360 397 20 20],'Style','text','String','ms','Enable','on');
uicontrol('Position',[390 400 20 20],'Style','pushbutton','String','?','Tag','helps1','Callback',@helpf,'Enable','on');



ckdwn = uicontrol('Position',[120  370 20 20],'Style','checkbox','Tag','ckdwn','Callback',@activatethr,'Enable','off','Tooltip','have not coded this yet');
uicontrol('Position',[140  367 40 20],'Style','text','Tag','dwnstr','String','Lower','Enable','off');
uicontrol('Position',[185  370 20 20],'Style','pushbutton','Tag','dwnpUPthr','String',char(708),'Callback',@chval,'Enable','off');
uicontrol('Position',[205 370 20 20],'Style','pushbutton','Tag','dwnpDWNthr','String',char(709),'Callback',@chval,'Enable','off');
uicontrol('Position',[230 370 30 20],'Style','edit','String',num2str(thr),'Tag','dwnthr','Callback',@threshold,'Enable','off');
uicontrol('Position',[260 367 20 20],'Style','text','String','std','Tag','dwnunits','Enable','off');

uicontrol('Position',[285 370 20 20],'Style','pushbutton','Tag','dwnpUPdur','String',char(708),'Callback',@chval,'Enable','off');
uicontrol('Position',[305 370 20 20],'Style','pushbutton','Tag','dwnpDWNdur','String',char(709),'Callback',@chval,'Enable','off');
uicontrol('Position',[330 370 30 20],'Style','edit','String',num2str(sf*dur*1000,2),'Tag','dwndur','Callback',@duration,'Enable','off');
uicontrol('Position',[360 367 20 20],'Style','text','String','ms','Enable','off');
uicontrol('Position',[390 370 20 20],'Style','pushbutton','String','?','Tag','helps2','Callback',@helpf,'Enable','on');



uicontrol('Position',[120 327 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol('Position',[160 330 30 20],'Style','edit','String',num2str(ra),'Tag','rearm','Callback',@duration,'Enable','on');
uicontrol('Position',[190 327 20 20],'Style','text','String','ms','Enable','on');
uicontrol('Position',[210 330 20 20],'Style','pushbutton','String','?','Tag','helps3','Callback',@helpf,'Enable','on');

uicontrol('Position',[220 255 60 20],'Style','text','String','# spikes:','Enable','on');
uicontrol('Position',[280 255 20 20],'Style','text','String',' ','Tag','nspikes','Enable','on');

uicontrol('Position',[300 300 90 30],'Style','pushbutton','String','Get Average','Tag','avgim','Callback',@avgim,'Enable','on');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Position',[5 440 100 20],'Style','text','String','Select channel');
uicontrol('Position',[5 40 100 400],'Style','listbox','Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@detsp);

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

sax = axes('Position',[0.08 0.1 0.13 0.4]);
W = -200:400;
aplt = plot(W*sf*1000,nan(size(W)));
sax.XLabel.String = 'Time (ms)';
sax.XLim = [min(W) max(W)]*sf*1000;

aspike = repelem({zeros(2,length(W))},size(data,1));
spikes = repelem({zeros(1,0)},size(data,1));

iax = axes('Position', [0.78 0.1 0.2 0.2*ysize/xsize*fig.Position(3)/fig.Position(4)],'YTick',[],'XTick',[],'Box','on','Tag','roiax');
img = imagesc(zeros(ysize,xsize));
set(iax,'XTick',[],'YTick',[])

W0 = round(min(W)*sf/sr); 
idur = round(length(W0)*sr/sf);

uicontrol('Units','normalized','Position',[0.78 0.05 0.2 0.05],'Style','slider','Min',0,'Max',idur,'SliderStep',[1 1]/idur,'Callback',@chframe,'Tag','imslider');

helps = ["To detect spikes the data value has to be above this threshold consecutively for as long as the minimum duration",...
         "To detect spikes the data value has to be below this threshold consecutively for as long as the minimum duration",...
         "The re-arm prevents the same spike from being detected twice.  The re-arm value is the minimal amount of time to detect a subsequent spike.  Should be a little longer than the concievable duration of a spike and shorter than the minimum concievable spike interval.  A neuron that fires at most 100Hz should have a re-arm duration less than 10 ms."];

guidata(fig,struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                   'tplt',tplt,         'splt',splt,        'sax',sax,...
                   'aplt',aplt,         'iax',iax,          'img',img,...
                   'W',W,               'data',data,        'ch',ch,...
                   'hideidx',hideidx,   'showidx',showidx,  'tm',tm,...
                   'str',str,           'ckup',true,        'ckdwn',false,...
                   'gidx',showidx(1),   'aspike',{aspike},  'spikes',{spikes},...
                   'inc',inc,           'files',files,      'helps',helps))

detsp(fig)

function chframe(hObject,eventdata)
props = guidata(hObject);
frame = round(hObject.Value);
set(hObject,'Value',frame)
set(props.img,'CData',props.imdata(:,:,frame))

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
idx = get(findobj('Tag','channels','Parent',hObject),'Value');
set(props.plt,'YData', props.data(idx,:));

stdata = std(props.data(idx,:));
thr = str2double(get(findobj('Tag','upthr','Parent',hObject),'String'));
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

idx = get(findobj('Tag','channels','Parent',hObject),'Value');
dur = str2double(get(findobj('Tag','updur','Parent',hObject),'String'));
thr = str2double(get(findobj('Tag','upthr','Parent',hObject),'String'));
ra = str2double(get(findobj('Tag','rearm','Parent',hObject),'String'));

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

set(findobj('Tag','nspikes','Parent',hObject),'String',num2str(length(spikes)))
plotdata(hObject)

function avgim(hObject,eventdata)
props = guidata(hObject);
if isempty(props.files)
    return
end
idx = get(findobj('Tag','channels','Parent',hObject.Parent),'Value');

vsd = props.files(contains(props.files(:,2),'tsm'),2);

warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(vsd);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};

spikes = props.spikes{idx};
itm = props.tm;

sidx = round(itm(spikes)/sr);
sidx(sidx>zsize) = [];

sf = diff(props.tm(1:2));
W0 = round(min(props.W)*sf/sr); 
dur = round(length(W0)*sr/sf);

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
    
    imdata = imdata + fdata;% Format data.
end
fclose(fid);

imdata = imdata/length(sidx);
f0 = repmat(imdata(:,:,1),1,1,size(imdata,3));
imdata = (imdata - f0)./f0;
imdata(:,1:6,:) = 0;
props.imdata = imdata;

frame = get(findobj('Tag','imslider','Parent',hObject.Parent) ,'Value')+1;
set(props.img,'CData',imdata(:,:,frame))

guidata(hObject,props)

    



