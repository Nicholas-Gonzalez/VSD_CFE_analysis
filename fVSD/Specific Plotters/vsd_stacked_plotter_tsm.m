function vsd_stacked_plotter_tsm(allVSD,ROIs,folder,trial,IntanSignals)

    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % NEURON DATA SECTION
    %
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    % selects subset of allVSD to be plotted based on ROIs.  Each
    %   column in allVSD is an ROI, and each row is a VSD frame.
    dataVSD = allVSD(:,ROIs);
    
    % calculates the total number of ROIs to pre-allocate for speed, 
    %   stored as "neurons".
    neurons = length(ROIs);
    
    % parametrizes VSD recording rate in frames/s and Intan recording 
    %   rate in kHz
    VSDRate = 1000;
    IntanRate = 20;
    
    % parametrizes the number of frames to be trimmed off the beginning
    %   and off the end of the VSD recordings.  Then trims off the row 
    %   values from dataVSD.
    trimStart = 1000;
    trimEnd = 110;
    dataVSD(1:trimStart,:) = [];
    dataVSD(end-(trimEnd-1):end,:) = [];
    
    % generates cell array of table column names to be used as ROI
    %   identifiers.
    tabNamesVSD = cell(1,neurons);
    for j = 1:neurons
        tabNamesVSD{j} = ['ROI ',num2str(ROIs(j))];
    end
        
    % generates table of VSD data to be read by the stacked plot 
    %   function with column headers specified by tabNamesVSD
    tabDataVSD = array2table(dataVSD,'VariableNames',tabNamesVSD);
    
    
    
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % NERVE DATA SECTION
    %
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    % conditionally plots nerve data, assuming an input is recieved in
    %   the form of IntanSignals
    if nargin >= 5
    
        % calculates the total number of nerve signals to pre-allocate 
        %   for speed, stored as "nerves".
        nerves = length(IntanSignals);

        % calculates the total number of VSD frames.  Then calls the 
        %   function read_Intan_RHS2000_file to acquire manually-
        %   specified RHS data.  Finishes trimming by removing  
        %   specified frames at the beginning and end (trimStart and 
        %   strimEnd).  Also elects pre-determined nerve signals to be 
        %   plotted.
        totalFrames = length(allVSD);
        
        RHSname = fullfile(folder,[trial '.rhs']);
        [untrimNerves,t,~,~,~,~,~,~] = read_Intan_RHS2000_file(RHSname);
        allNerves = trimRHS(untrimNerves,t,totalFrames,IntanRate);
        dataNerves = allNerves(IntanSignals,:);
        dataNerves(:,1:trimStart*20) = [];
        dataNerves(:,end-(trimEnd*20-1):end) = [];  

        % generates cell matrix of table column names to be used as 
        %   nerve identifiers
        tabNamesNerves= cell(1,nerves);
        for k = 1:nerves
            tabNamesNerves{k} = ['Nerve ',num2str(IntanSignals(k))];
        end

        % generates table of VSD data to be read by the stacked plot 
        %   function with column headers specified by tabNamesVSD
        tabDataNerves = array2table(dataNerves','VariableNames',tabNamesNerves);
    
        % parametrizes size of nerve signal plot as 2
        nervePlotHeight = 2;
        
    else
        
        % parametrizes size of nerve signal plot as 0, which
        %   deactivates it from being plotted.
        nervePlotHeight = 0;
        
    end
    
    
    
    % parametrizes the general grid layout of the tiled plot, with r 
    %   rows and c columns.  9 rows and 16 columns will fit perfectly
    %   onto a standard PPT slide
    r = 9;
    c = 16;  
    
    % initializes first tiled plot with r rows and c columns
    figure('color','w');
    tiledlayout(r,c,'TileSpacing','tight','Padding','compact');
    
    % selects tiles for VSD graphs, plots tabDataVSD, and turns off  
    %   Y-axis on VSD graphs.  Turning off the Y-axes in the
    %   stackedplot function requires some additional maneuvering
    %   outside of what is normally used in the plot function.  Also 
    %   sets X-axis tick marks as being split into six (so usually 
    %   every 10 s). Furthermore, size of the VSD graphs in the tiled 
    %  layout depends  on if additional nerve signals will be added.
    nexttile(1,[(r-nervePlotHeight) 12]);
    VSDplot = stackedplot(tabDataVSD,'color','k');
    tickVSD = findobj(VSDplot.NodeChildren, 'Type','Axes');
    set(tickVSD, 'YTick', []);
    
    
    % conditionally plots nerve data, assuming IntanSignals input had
    %   contents. Otherwise, adds remaining X-axis features to VSD
    %   plot.
    if nervePlotHeight ~= 0
    
        % turns off X-axis on VSD plot, since it will be created on the
        %   nerve plot
        set(tickVSD, 'XColor', 'none');
        %axis 'auto x' off


        % selects tiles for nerve signal graphs, plots tabDataNerves,
        %   and turns off Y-axis on nerve signals graphs.  Determines
        %   size of nerve signal plots based on parametrized
        %   "nervePlotHeight" at the end of NERVE DATA SECTION
        nexttile(113,[nervePlotHeight 12]);
        nervePlot = stackedplot(tabDataNerves,'color','r');
        tickNerves = findobj(nervePlot.NodeChildren, 'Type','Axes');
        set(tickNerves, 'YTick', []);
        [~,xpoints] = size(dataNerves);
        set(tickNerves, 'XTick', 0:(xpoints/6):xpoints);
        s = xpoints/(VSDRate*IntanRate);
        set(tickNerves, 'XTickLabel', 0:s/6:s);
        xlabel(tickNerves, 'Time (s)')
    
    else
        
        [xpoints,~] = size(dataVSD);
        set(tickVSD, 'XTick', 0:(xpoints/6):xpoints);
        s = xpoints/VSDRate;
        set(tickVSD, 'XTickLabel', 0:s/6:s);
        xlabel(tickVSD, 'Time (s)')
        
    end    
    
    % loads in frames for plotting
    frameFolder = 'Z:\_Lab Personnell_Summer Students\Rodrigo\VSD_Data\21-07-12\Turbo_data\Sheathed\Strong_stain\Plotting_frames';
    clearFrame = imread(fullfile(folder,'\21-07-12_RodrigoVSD009_frame.tif'));
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