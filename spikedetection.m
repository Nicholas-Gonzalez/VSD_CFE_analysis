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
else
    data = inputdata;
    ch = 1:size(data,1);
    hideidx = [];
    showidx = 1:size(data,1);
    if nargin<2
        tm = 1:size(data,2);
    end
end

sf = diff(tm(1:2));

% default parameters
sdur = 10;% default number of datapoints above threshold to detect spike.
thr = 5;
ra = 10;% re-arm, the minimal amount of time to detect a subsequent spike (should be just longer than the concievable duration of a spike)

apptag = ['apptag' num2str(randi(1e4,1))];
fig = figure('Position',[80 80 1700 500],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Spike Tools');
mi(1) = uimenu(m,'Text','Open','Callback',@threshold,'Enable','off');
mi(3) = uimenu(m,'Text','Save','Callback',@threshold,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','on','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


uicontrol('Position',[235 415 20 25],'Style','text','String','Thr','Enable','on');
uicontrol('Position',[290 425 20 25],'Style','text','String','Min Dur','Enable','on');


ckup = uicontrol('Position',[120  400 20 20],'Style','checkbox','Tag','ckup','Callback',@activatethr,'Enable','on','Value',true);
uicontrol('Position',[140  397 40 20],'Style','text','String','Upper','Tag','upstr','Callback',@threshold,'Enable','on');
uicontrol('Position',[185  400 20 20],'Style','pushbutton','Tag','uppUP','String',char(708),'Callback',@threshold,'Enable','off');
uicontrol('Position',[205 400 20 20],'Style','pushbutton','Tag','uppDWN','String',char(709),'Callback',@threshold,'Enable','off');
uicontrol('Position',[230 400 30 20],'Style','edit','String',num2str(thr),'Tag','upthr','Callback',@detsp,'Enable','on');
uicontrol('Position',[260 397 20 20],'Style','text','String','std','Tag','upunits','Enable','on');
uicontrol('Position',[285 400 30 20],'Style','edit','String',num2str(sf*5*1000,2),'Tag','updur','Callback',@duration,'Enable','on');
uicontrol('Position',[315 397 20 20],'Style','text','String','ms','Tag','updurunits','Enable','on');
uicontrol('Position',[340 400 20 20],'Style','pushbutton','String','?','Tag','helps1','Callback',@helpf,'Enable','on');

ckdwn = uicontrol('Position',[120  370 20 20],'Style','checkbox','Tag','ckdwn','Callback',@activatethr,'Enable','off','Tooltip','have not coded this yet');
uicontrol('Position',[140  367 40 20],'Style','text','Tag','dwnstr','String','Lower','Enable','off');
uicontrol('Position',[185  370 20 20],'Style','pushbutton','Tag','dwnpUP','String',char(708),'Callback',@threshold,'Enable','off');
uicontrol('Position',[205 370 20 20],'Style','pushbutton','Tag','dwnpDWN','String',char(709),'Callback',@threshold,'Enable','off');
uicontrol('Position',[230 370 30 20],'Style','edit','String',num2str(thr),'Tag','dwnthr','Callback',@threshold,'Enable','off');
uicontrol('Position',[260 367 20 20],'Style','text','String','std','Tag','dwnunits','Enable','off');
uicontrol('Position',[285 370 30 20],'Style','edit','String',num2str(sf*5*1000,2),'Tag','dwndur','Callback',@duration,'Enable','off');
uicontrol('Position',[315 367 20 20],'Style','text','String','ms','Tag','dwndurunits','Enable','off');
uicontrol('Position',[340 370 20 20],'Style','pushbutton','String','?','Tag','helps2','Callback',@helpf,'Enable','on');

uicontrol('Position',[120 327 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol('Position',[160 330 30 20],'Style','edit','String',num2str(ra),'Tag','rearm','Callback',@duration,'Enable','on');
uicontrol('Position',[190 327 20 20],'Style','text','String','ms','Enable','on');
uicontrol('Position',[210 330 20 20],'Style','pushbutton','String','?','Tag','helps3','Callback',@helpf,'Enable','on');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Position',[5 440 100 20],'Style','text','String','Select channel');
uicontrol('Position',[5 40 100 400],'Style','listbox','Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@detsp);

mdata = mean(data(showidx(1),:));
stddata = std(data(showidx(1),:));

ax = axes('Position',[0.25 0.1 0.73 0.85]);
plt = plot(tm,data(showidx(1),:));hold on

tplt(1) = plot([min(tm) max(tm)],[mdata, mdata]+stddata*thr);
tplt(2) = plot([min(tm) max(tm)],nan(2,1));
splt = scatter(nan,nan,'x');

ax.XLim = [min(tm),max(tm)];

sax = axes('Position',[0.1 0.1 0.1 0.4]);
W = -30:70;
aplt = plot(W*sf*1000,nan(size(W)));
sax.XLabel.String = 'Time (ms)';

helps = ["To detect spikes the data value has to be above this threshold consecutively for as long as the minimum duration",...
         "To detect spikes the data value has to be below this threshold consecutively for as long as the minimum duration",...
         "The re-arm prevents the same spike from being detected twice.  The re-arm value is the minimal amount of time to detect a subsequent spike.  Should be a little longer than the concievable duration of a spike and shorter than the minimum concievable spike interval.  A neuron that fires at most 100Hz should have a re-arm duration less than 10 ms."];

aspike = repelem({zeros(2,length(W))},size(data,1));
spikes = repelem({zeros(1,0)},size(data,1));

guidata(fig,struct('apptag',apptag,'ax',ax,'plt',plt,'tplt',tplt,'splt',splt,...
    'sax',sax,'aplt',aplt,'W',W,'data',data,'ch',ch,'hideidx',hideidx,'showidx',showidx,...
    'tm',tm,'str',str,'ckup',true,'ckdwn',false,'gidx',showidx(1),'aspike',{aspike},...
    'spikes',{spikes},'helps',helps))


detsp(fig)

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

set(props.aplt,'YData',mean(props.aspike{idx}))
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
props = guidata(hObject);
if nargin==2
    idx = get(findobj('Tag','channels','Parent',hObject.Parent),'Value');
    dur = str2double(get(findobj('Tag','updur','Parent',hObject.Parent),'String'));
    thr = str2double(get(findobj('Tag','upthr','Parent',hObject.Parent),'String'));
    ra = str2double(get(findobj('Tag','rearm','Parent',hObject.Parent),'String'));
else
    idx = get(findobj('Tag','channels','Parent',hObject),'Value');
    dur = str2double(get(findobj('Tag','updur','Parent',hObject),'String'));
    thr = str2double(get(findobj('Tag','upthr','Parent',hObject),'String'));
    ra = str2double(get(findobj('Tag','rearm','Parent',hObject),'String'));
end

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

if nargin==2
    plotdata(hObject.Parent)
else
    plotdata(hObject)
end


