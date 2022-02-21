function visVSD(data,neurPlot,spTimes,spTrace)
% Function for plotting individual VSD traces for each neuron. If spike
% times and spike waveforms are provided, those are plotted as well.


if nargin<4
    [spTimes,spTrace,~,~] = detect_spikes_vsd(data);
end
if nargin==1 || isempty(neurPlot)
    neurPlot = 1:size(data,2); % Specify which neurons to plot.
end

%%

% Compute average spike traces
orig_avgSp = cellfun(@(x) mean(x,1),spTrace,'uni',0);
orig_avgSp = cell2mat(orig_avgSp')'; % Double transpose necessary for cell2mat.

%% Plotting

% Parameters

% Acquisition rate of data in Hz;
acqRate = 1000;
%% Initiate figure
f1 = figure('Name','VSD Traces');
f1.Position = [340   50   1200   920];

%% Plot neuron traces

% Offset to add to spiketimes for plotting.
% (Spiketimes are at onset of each spike. This adds a few
% datapoints to approximate the peak.)
spTimeOffset = 0;

% Preallocate all graphic objects
[ax1, ax2, neurLabel,...
    hOrig, ...
    hScOrig, ...
    hAvgOrig] = ...
    deal(gobjects(length(neurPlot),1));

for A = 1:length(neurPlot)
    
    % Create axes for main traces
    ax1(A) = axes; hold on;
    ax1(A).Position = [0.025 0.95-0.9/length(neurPlot)*A 0.90 0.9/length(neurPlot)];
    
    % Label each neuron
    neurLabel(A) = annotation('textbox',...
        [0.0045 0.95-0.9/length(neurPlot)*A 0.019 0.9/length(neurPlot)],....
        'String',neurPlot(A),'EdgeColor','none','HorizontalAlignment','right',...
        'VerticalAlignment','middle','FontSize',12,'Margin',0);
    
    % Plot main traces
    hOrig(A) = plot(data(:,neurPlot(A)),'k');
    
    % Prepare spike times
    tempSTO = spTimes(:,neurPlot(A));
    tempSTO(tempSTO==0) = [];
    tempSTO = tempSTO + spTimeOffset;
    
    % Plot spike times
    try
        %hScOrig(A) = plot(tempSTO,5,'|r','LineWidth',1);
    catch
        hScOrig(A) = plot(NaN,NaN,'|r'); % If plotting fails (e.g., there are no spikes), still create a non-empty line object to be modified by nested functions.
    end
    
    % Create axes for average spike traces
    ax2(A) = axes; hold on;
    ax2(A).Position = [0.94 0.95-0.9/length(neurPlot)*A 0.05 0.9/length(neurPlot)];
    
    % Plot average traces
    hAvgOrig(A) = plot(orig_avgSp(:,neurPlot(A)),'k','LineWidth',1);
end
set([ax1; ax2],'Visible','off')
annotation('textbox',...
    [0.378333333333335,0.939130434782609,0.2,0.05],....
    'String','Neuron Traces','EdgeColor','none','HorizontalAlignment','center',...
    'FontSize',15);
annotation('textbox',...
    [0.929166666666668,0.955460869565217,0.066666666666667,0.0391],....
    'String','Average Spike','EdgeColor','none','HorizontalAlignment','center',...
    'VerticalAlignment','middle','FontSize',12);
tAx1 = axes('Position',[0.025 0.95-0.9/length(neurPlot)*A 0.90 0.9/length(neurPlot)],'TickDir','out','XMinorTick','on');
tAx1.YTick = [];
linkaxes([ax1; tAx1],'x')
xticklabels(xticks(tAx1)/acqRate)
xlabel(tAx1,'Time (s)')
%ylabel(tAx1,'Z-score')
tAx1.YAxisLocation = 'right';
tAx1.Color = [1 1 1 0];
%ax1(1).YLim = [-2.5e-4 1e-4]; % Use predetermined scale.
ax1(1).YLim = [-20 5]; % Use predetermined scale.

tAx2 = axes('Position',[0.94 0.95-0.9/length(neurPlot)*A 0.05 0],'TickDir','out','XMinorTick','on');
linkaxes([ax2; tAx2])
xticklabels(xticks(tAx2)/acqRate*1000)
xlabel(tAx2,'Time (ms)')
tAx2.TickLength = tAx2.TickLength*tAx1.Position(3)/tAx2.Position(3);
%ax2(1).YLim = [-2.5e-4 1e-4]; % Use predetermined scale.
ax2(1).YLim = [-20 5]; % Use predetermined scale.



%set(hScOrig,'Visible','off')

end

