function spikedetection(inputdata,tm)
% data can either be a 2D array or the structure properties from the intan
% GUI. Each row is each channel.  If array, then time can optionally be
% included as a second input.

apptag = ['apptag' num2str(randi(1e4,1))];
fig = figure('Position',[80 80 1700 500],'Name','Intan_Gui','NumberTitle','off','Tag',apptag);

ax = axes('Position',[0.25 0.05 0.75 0.8]);

uicontrol('Position',[235 415 20 25],'Style','text','String','Thr','Enable','on');
uicontrol('Position',[290 425 20 25],'Style','text','String','Min Dur','Enable','on');

ckup = uicontrol('Position',[120  400 20 20],'Style','checkbox','Tag','ckup','Callback',@activatethr,'Enable','on','Value',true);
uicontrol('Position',[140  397 40 20],'Style','text','String','Upper','Tag','upstr','Callback',@threshold,'Enable','on');
uicontrol('Position',[185  400 20 20],'Style','pushbutton','Tag','uppUP','String',char(708),'Callback',@threshold,'Enable','on');
uicontrol('Position',[205 400 20 20],'Style','pushbutton','Tag','uppDWN','String',char(709),'Callback',@threshold,'Enable','on');
uicontrol('Position',[230 400 30 20],'Style','edit','String','1.5','Tag','upthr','Callback',@threshold,'Enable','on');
uicontrol('Position',[260 397 20 20],'Style','text','String','std','Tag','upunits','Enable','on');
uicontrol('Position',[285 400 30 20],'Style','edit','String','2.5','Tag','updur','Callback',@duration,'Enable','on');
uicontrol('Position',[315 397 20 20],'Style','text','String','ms','Tag','updurunits','Enable','on');

ckdwn = uicontrol('Position',[120  370 20 20],'Style','checkbox','Tag','ckdwn','Callback',@activatethr,'Enable','on');
uicontrol('Position',[140  367 40 20],'Style','text','Tag','dwnstr','String','Lower','Enable','off');
uicontrol('Position',[185  370 20 20],'Style','pushbutton','Tag','dwnpUP','String',char(708),'Callback',@threshold,'Enable','off');
uicontrol('Position',[205 370 20 20],'Style','pushbutton','Tag','dwnpDWN','String',char(709),'Callback',@threshold,'Enable','off');
uicontrol('Position',[230 370 30 20],'Style','edit','String','1.5','Tag','dwnthr','Callback',@threshold,'Enable','off');
uicontrol('Position',[260 367 20 20],'Style','text','String','std','Tag','dwnunits','Enable','off');
uicontrol('Position',[285 370 30 20],'Style','edit','String','2.5','Tag','dwndur','Callback',@duration,'Enable','off');
uicontrol('Position',[315 367 20 20],'Style','text','String','ms','Tag','dwndurunits','Enable','off');

uicontrol('Position',[120 327 40 20],'Style','text','String','re-arm','Enable','on');
uicontrol('Position',[160 330 30 20],'Style','edit','String','10','Tag','rearm','Callback',@duration,'Enable','on');
uicontrol('Position',[190 327 20 20],'Style','text','String','ms','Enable','on');

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


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Position',[5 440 100 20],'Style','text','String','Select channel');
uicontrol('Position',[5 40 100 400],'Style','listbox','Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@plotdata);

mdata = mean(data(showidx(1),:));
stddata = std(data(showidx(1),:));

plt = plot(tm,data(showidx(1),:));hold on
tplt(1) = plot([min(tm) max(tm)],[mdata, mdata]+stddata*2.5);
ax.XLim = [min(tm),max(tm)];

guidata(fig,struct('apptag',apptag,'ax',ax,'plt',plt,'data',data,'ch',ch,'hideidx',hideidx,'showidx',showidx,'tm',tm,'str',str,'ckup',true,'ckdwn',false,'gidx',showidx(1)))

detsp(fig)



function threshold(hObject,eventdata)
props = guidata(hObject);

function plotdata(hObject,eventdata)
props = guidata(hObject);
set(props.plt,'YData', props.data(hObject.Value,:));
props.gidx = hObject.Value;
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

function detsp(hObject,eventdata)
props = guidata(hObject);
dur = str2double(get(findobj('Tag','updur','Parent',hObject),'String'));
thr = str2double(get(findobj('Tag','upthr','Parent',hObject),'String'));disp(thr)


