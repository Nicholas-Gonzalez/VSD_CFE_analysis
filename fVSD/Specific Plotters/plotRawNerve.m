function plotRawNerve(rawdata,channels,figName)

%% Parameters

acqRate = 1000; % Hz
tUniDisp = 's'; % Time unit to display ('hrs','min','s','ms','us')
tPerTick = 10; % Time per tick in above units.

%nervNames = {'iRn', 'cBn1','iBn3','cBn3','iBn2','cBn2','iEn2','Shutter'};
nervNames = {'nothing', '2','3','4','5','6','7','8'};

figure_size=[0.01 0.01 .97 .90];
monitor=1;

%%

if nargin<3
    figName = 'Raw Data';
end

if strcmp(tUniDisp,'hrs')
    tUniC = 60*60;
elseif strcmp(tUniDisp,'min')
    tUniC = 60;
elseif strcmp(tUniDisp,'s')
    tUniC = 1;
elseif strcmp(tUniDisp,'ms')
    tUniC = 1e-3;
elseif strcmp(tUniDisp,'us')
    tUniC = 1e-6;
end
    

close(findobj(0, 'Name', figName))
figure('Name' , figName,'NumberTitle' , 'off','Visible','off'); 

if nargin<2
    channels=1:size(rawdata,2);
end
%kernels=[5 6 12 27] ;

ax=gobjects([1 length(channels)]);
count=1;
for kern=channels
    ax(count)=axes;
       plot(rawdata(:,kern),'LineWidth',1,'Color','k')
       ax(count).Position=[0.05 1-count*(0.9/length(channels))  0.9  0.9/length(channels)];
       ax(count).XTick=[];
       ax(count).YTick=[];       
       ax(count).XColor = 'none';
       ax(count).YColor = 'none';
       ax(count).Box = 'off';
    text(0,0,nervNames(count),'FontSize',18,'HorizontalAlignment','right');
    count=count+1;
    axis tight
end

ax(count+1) = axes;
ax(count+1).Position = [0.05 0.075 0.9 0.01];
ax(count+1).XTick = 0:acqRate*tUniC*tPerTick:size(rawdata,1);
ax(count+1).XTickLabel = ax(count+1).XTick/(acqRate*tUniC);
ax(count+1).FontSize = 18;
ax(count+1).XLabel.String = ['Time (' tUniDisp ')'];
ax(count+1).YColor = 'none';

linkaxes(ax,'x') % Keep same scale for all axes.
ax(1).XLim = [0 size(rawdata,1)];
%ax(1).YLim = [-5e-4 5e-4]; % Use predetermined scale.
%ax(1).YLim = [-30 30]; % Use predetermined scale (nerves).

MP = get(0,'MonitorPositions');
set(gcf,'Position',[figure_size(1:2).*MP(monitor,3:4)+MP(monitor,1:2)  figure_size(3:4).*MP(monitor,3:4)],'Visible','on');

end


