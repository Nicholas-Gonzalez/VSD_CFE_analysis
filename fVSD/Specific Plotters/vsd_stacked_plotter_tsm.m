function vsd_stacked_plotter_tsm(allData,ROIs)

    % selects subset of allData to be plotted based on ROIs
    plotData = allData(:,ROIs);
    
    % calculates the total number of ROIsto pre-allocate for speed, 
    %   stored as "neurons"
    neurons = length(ROIs);
    
    % parametrizes the number of frames to be trimmed off the beginning
    %   and end of the recordings.  Then trims off the row values from 
    %   plotData.
    trimStart = 1000;
    trimEnd = 110;
    plotData(1:trimStart,:) = [];
    plotData(end-(trimEnd-1):end,:) = [];
    
    % parametrizes the general grid layout of the tiled plot, with r 
    %   rows and c columns.  9 rows and 16 columns will fit perfectly
    %   onto a standard PPT slide
    r = 9;
    c = 16;
    
    % generates cell matrix of table column names to be used as ROI
    %   identifiers
    tabNames = cell(1,neurons);
    for j = 1:neurons
        tabNames{j} = ['ROI ',num2str(ROIs(j))];
    end
    
    % generates table to be read by the stacked plot function with
    %   column headers specified by tabNames
    tabData = array2table(plotData,'VariableNames',tabNames);
    
    % initializes first tiled plot with r rows and c columns
    figure('color','w');
    tiledlayout(r,c,'TileSpacing','tight','Padding','compact');
    
    % selects tiles for VSD graphs, plots tabData, turns off Y-axis on
    %   VSD graphs
    nexttile(1,[9 12]);
    stackedplot(tabData,'color','k');
    ax = gca;
    ax.XLabel = 'Time (ms)';
    
    
    % checks if 25 plots have been generated, which is the maxiumum
    %   that can fit on a stacked plot.  If so, makes new tiled
    %   plot
    if mod(neurons,25)==0
        figure;
        tiledlayout(r,c,'TileSpacing','tight','Padding',...
            'compact');
    end

end