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
    %   VSD graphs.  Turning off the Y-axes in the stackedplot function
    %   requires some additional maneuvering outside of what is
    %   normally used in the plot function.  Also sets X-axis tick
    %   marks as being split into six (so usually every 10 s)
    nexttile(1,[9 12]);
    VSDplot = stackedplot(tabData,'color','k');
    ax = gca;
    ax.XLabel = 'Time (ms)';
    ticks = findobj(VSDplot.NodeChildren, 'Type','Axes');
    set(ticks, 'YTick', [])
    [xpoints,~] = size(plotData);
    set(ticks, 'XTick', 0:(xpoints/6):xpoints);
    
    % NOTES: need to add disabling feature (so if it's blank, don't
    %   execute or whatever
    
    % loads in frames for plotting
    frameFolder = 'Z:\_Lab Personnell_Summer Students\Rodrigo\VSD_Data\21-07-12\Turbo_data\Sheathed\Strong_stain\Plotting_frames';
    clearFrame = imread(fullfile(frameFolder,'\21-07-12_RodrigoVSD009_frame_clear.tif'));
    ROIFrame = imread(fullfile(frameFolder,'\21-07-12_RodrigoVSD009_frame_ROIs.png'));
    
    nexttile(13,[4 4]);
    image(clearFrame);
    
    nexttile(77,[4 4]);
    image(ROIFrame);
    
    % checks if 25 plots have been generated, which is the maxiumum
    %   that can fit on a stacked plot.  If so, makes new tiled
    %   plot
    if mod(neurons,25)==0
        figure;
        tiledlayout(r,c,'TileSpacing','tight','Padding',...
            'compact');
    end

end