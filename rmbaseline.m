function rmbaseline(inputdata,tm)
% data can either be a 2D array or the structure properties from the intan
% GUI. Each row is each channel.  If array, then time can optionally be
% included as a second input.

if isstruct(inputdata)
    data = inputdata.data;
    data(isnan(data)) = 0;
    ch = inputdata.ch;
    hideidx = inputdata.hideidx;
    showidx = inputdata.showidx;
    tm = inputdata.tm;
    files = inputdata.files;
    ofigsize = inputdata.figsize;
    intan_tag = inputdata.intan_tag;
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

tm(data(end,:)==data(end,1)) = [];
data(:,data(end,:)==data(end,1)) = [];


apptag = ['apptag' num2str(randi(1e4,1))];
fig = figure('Position',[ofigsize(1) ofigsize(4)*0.1+ofigsize(2) ofigsize(3) ofigsize(4)*0.7],...
    'Name','Remove Baseline','NumberTitle','off','Tag',apptag);


m = uimenu('Text','Baseline tools');
mi(1) = uimenu(m,'Text','Open Parameters','Callback',@opensaveparams,'Enable','off','Tag','open');
mi(3) = uimenu(m,'Text','Save Parameters','Callback',@opensaveparams,'Enable','off','Tag','save');
mi(4) = uimenu(m,'Text','Send to workspace','Callback',@toworkspace,'Enable','off','Tag','savem');
mi(4) = uimenu(m,'Text','Help','Callback',@threshold,'Enable','off','Tag','help');


str = repmat(["<HTML><FONT color=""", "black", """>", "", "</FONT></HTML>"],length(ch),1);
str(hideidx,2) = "gray";
str(:,4) = string(ch);
str = join(str,'');

uicontrol('Units','normalized','Position',[0.002 0.96 0.07 0.03],'Style','text','String','Select channel');
uicontrol('Units','normalized','Position',[0.002 0.23 0.07 0.73],'Style','listbox',...
    'Max',length(ch),'Min',1,'String',str','Tag','channels','Value',showidx(1),'Callback',@chchannel);

cpanel = uipanel('Title','Controls','Units','normalized','FontSize',12,'Position',[0.75 0 0.25 1],'Tag','cpanel');
uicontrol(cpanel,'Units','normalized','Position',[0.31 0.8 0.1 0.05],'Style','edit',...
    'String','3','Callback',@fitequation,'Enable','on','TooltipString','Number of coefficients','Tag','coeff');
uicontrol(cpanel,'Units','normalized','Position',[0 0.79 0.3 0.05],'Style','text','String','Coefficients','HorizontalAlignment','right');

uicontrol(cpanel,'Units','normalized','Position',[0.60 0.9 0.3 0.05],'Style','text','String','Select channel');
uicontrol(cpanel,'Units','normalized','Position',[0.60 0.1 0.3 0.8],'Style','listbox','Max',length(ch),...
    'Min',1,'String',str','Tag','channels');
uicontrol(cpanel,'Units','normalized','Position',[0.60 0.05 0.3 0.05],'Style','pushbutton','String','Apply','Callback',@applyrm); 


ax = axes('Position',[0.12 0.1 0.6 0.8]);
plt = plot(tm,data(showidx(1),:));hold on
splt = plot(tm,zeros(1,length(tm)));hold on

fun = makefun(3);

opts = optimset('Display','off','Algorithm','levenberg-marquardt');
p0 = ones(1,15);
flimits = inf([1,15]);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
fparam = lsqcurvefit(fun,p0,tm,data(idx,:),-flimits,flimits,opts);

fplt = plot(tm,fun(fparam,tm));

ax.YLim = [min(data(idx,:)) max(data(idx,:))];

guidata(fig,struct('apptag',apptag,     'ax',ax,            'plt',plt,...
                    'data',data,        'fplt',fplt,        'fun',fun,...
                    'p0',p0,            'flimits',flimits,   'tm',tm,...
                    'splt',splt,        'intan_tag',intan_tag))


function chchannel(hObject,eventdata)
props = guidata(hObject);
fig = findobj('Tag',props.apptag);
idx = get(findobj('Tag','channels','Parent',fig),'Value');
set(props.plt,'YData',props.data(idx,:))
fitequation(fig)

function [fun] = makefun(coef)
estr = 'fun = @(p,x) 0 ';
for c=1:2:coef*2
    str = sprintf('+ p(%i).*(1 - exp((x - p(1))./-p(%i)))',c+1,c+2);
    estr = [estr, str];
end
estr = [estr, ';'];
eval(estr);

function fitequation(hObject,eventdata)
props = guidata(hObject);
disp('fitting')
fig = findobj('Tag',props.apptag);
buf = uicontrol(fig,'Units','normalized','Position',[0.3 , 0.9, 0.4 0.1],...
    'Style','text','String','Fitting...','FontSize',15);
pause(0.1)

idx = get(findobj('Tag','channels','Parent',fig),'Value');
coef = str2double(get(findobj(fig,'Tag','coeff'),'String'));
props.fun = makefun(coef);
opts = optimset('Display','off','Algorithm','levenberg-marquardt');
ds = 64;%downsample
tic
fparam = lsqcurvefit(props.fun,props.p0,props.tm(1:ds:end),props.data(idx,1:ds:end),-props.flimits,props.flimits,opts);
toc
set(props.fplt,'YData',props.fun(fparam,props.tm))
sdata = props.data(idx,:) - props.fun(fparam,props.tm);
set(props.splt,'YData',sdata)
set(props.ax,'YLim',[min(props.data(idx,:)) max(sdata)])
disp('plotted')
guidata(hObject,props)
delete(buf)

function applyrm(hObject,eventdata)
props = guidata(hObject);
hObject.String = 'Applying...';
hObject.BackgroundColor = [0.6 1 0.6];
pause(0.1)
idx = get(findobj('Tag','channels','Parent',fig),'Value');
coef = str2double(get(findobj(fig,'Tag','coeff'),'String'));
fun = makefun(coef);

intan = findobj('Tag',props.intan_tag);
iprops = guidata(intan);
iprops.sdata = sdata;
guidata(intan,iprops)


