function vsd_stacked_plotter_tsm(allVSD,ROIs,RHSname,frameim, IntanSignals,IntanLabels,roixy)

% USAGE: vsd_stacked_plotter_tsm
% DESCRIPTION: utlizes "tiledlayout" and "stackedplot" functions to
%   generate a figure of time-matched VSD and nerve signal data for a
%   particular flourescent VSD trial.  It's very critical to note that
%   this function can only utlize manually-specified .rhs Intan files.
%   As of last modified date, the .tbn files generated by Turbo-SM64 
%   could not be successfully read and de-coded (see function 
%   "extractTBN").  Therefore, backup .rhs files generated by the Intan
%   program must be manually identified and copied into the folder with 
%   the other experimental files for this feature to work.  Otherwise,
%   this function can ignore nerve signal data and simply not plot it.
%   This program by default divides the tiledlayout figure into a grid 
%   of 9 rows and 16 columns, to match the size of a typical wide-
%   screen aspect ratio.  These dimensions can be manually modified.
%   The total rows "r" anc total columns "c" are parametrized in this
%   function.  Additionally, the maximum height of the nerve signals
%   to be plotted under the VSD signals, as in the number vertical
%   tiles it will occupy, is parametrized as "nervePlotHeight".  If
%   there are no nerve signals inputed into this function, 
%   "nervePlotHeight" is defaulted to 0.  Furthermore, this function
%   adds images of the frame without ROIs (located in path specified by 
%   "folder") and with ROIs (located in path manually parametrized in
%   this function).  Lastly, the "stackedplot" function is relatively 
%   new to MATLAB, and modifying graph aesthetic features is different
%   from most MATLAB plotting functions.  The best strategy to get 
%   around this is to use "findobj" then "set" to modify axis features.
% INPUTS: 
%   allVSD       =      (matrix of VSD data with ROIs in columns and frames in 
%                       rows), 
%   ROIs         =      (array of ROIs to be selected from VSD data), 
%   RHSname      =      name of Intan data file
%   IntanSignals =      double or char.  if double then its the index of 
%                       signals in .rhs file to plot, class double, if string
%                       then it will plot signals corresponding to that
%                       name.
%   IntanLabels =       (manually-written nerve labels for plotting purposes).  
%                       NOTE: IntanSignals and IntanLabels can be ignored when 
%                       calling function from driver, and "vsd_stacked_plotter_tsm" 
%                       will ignore plotting nerve signals.
%  roixy         =       ROI positions
% OUTPUTS: none (generates figure)
% CONTACT: Rodrigo Gonzales-Rojas (rag13@rice.edu or 
%   rodrigogonzrojas@gmail.com)
% LAST MODIFIED: July 23, 2021

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

% parametrizes final ticks to be plotted in graphs (usually 6, so
%   over 60 s, tick every 10 s)
finalTicks = 6;

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

% calculates the total number of VSD frames.  Then calls the 
%   function read_Intan_RHS2000_file to acquire manually-
%   specified RHS data.  Finishes trimming by removing  
%   specified frames at the beginning and end (trimStart and 
%   strimEnd).  Also selects pre-determined nerve signals to be 
%   plotted.
totalFrames = length(allVSD);
[untrimNerves,t,~,~,~,channels] = read_Intan_RHS2000_file(RHSname);
allNerves = trimRHS(untrimNerves,t,totalFrames,IntanRate);
if nargin < 5
    IntanSignals = 1:size(untrimNerves,1);
end

if isstring(IntanSignals)
    chnm = string({channels.native_channel_name})';
    IntanSignals = arrayfun(@(x) find(chnm==x),IntanSignals);
end
nerves = length(IntanSignals);


dataNerves = allNerves(IntanSignals,:);
dataNerves(:,1:trimStart*20) = [];
dataNerves(:,end-(trimEnd*20-1):end) = [];  

% conditionally applies manual labels of the nerve signals,
%   stored in cell array IntanLabels, assuming there is one
%   label for every desired nerve signal
if nargin >=6  && length(IntanLabels) == length(IntanSignals)
    tabNamesNerves = IntanLabels;

% Otherwise, generates cell array of table column names to be 
%   used as nerve identifiers simply based on the input
%   IntanSignals
else
    tabNamesNerves = cell(1,nerves);
    for k = 1:nerves
        tabNamesNerves{k} = ['Nerve ',num2str(IntanSignals(k))];
    end

end    

% generates table of VSD data to be read by the stacked plot 
%   function with column headers specified by tabNamesVSD
tabDataNerves = array2table(dataNerves','VariableNames',tabNamesNerves);

% parametrizes size of nerve signal plot as 2
nervePlotHeight = 4;

if nargin<3

    % parametrizes size of nerve signal plot as 0, which
    %   deactivates it from being plotted.
    nervePlotHeight = 0;

end



% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% PLOTTING SECTION
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% parametrizes the general grid layout of the tiled plot, with r 
%   rows and c columns.  9 rows and 16 columns will fit perfectly
%   onto a standard PPT slide
r = 9;
c = 16;  

column1 = 1:c:r*c;

% initializes first tiled plot with r rows and c columns
figure('color','w','Position',[100 100 1800 900]);
tiledlayout(r,c,'TileSpacing','compact','Padding','compact');

% selects tiles for VSD graphs, plots tabDataVSD, and turns off  
%   Y-axis on VSD graphs.  Turning off the Y-axes in the
%   stackedplot function requires some additional maneuvering
%   outside of what is normally used in the plot functions. 
%   Furthermore, size of the VSD graphs in the tiled layout depends
%   on if additional nerve signals will be added.
nexttile(1,[(r-nervePlotHeight) 12]);
VSDplot = stackedplot(tabDataVSD,'color','k');
tickVSD = findobj(VSDplot.NodeChildren, 'Type','Axes');
set(tickVSD, 'YTick', []);

% conditionally plots nerve data, assuming IntanSignals input had
%   contents.
if nervePlotHeight ~= 0

    % turns off X-axis on VSD plot, since it will be created on the
    %   nerve plot
    set(tickVSD, 'XColor', 'none');

    % selects tiles for nerve signal graphs, plots tabDataNerves,
    %   and turns off Y-axis on nerve signals graphs.  Determines
    %   size of nerve signal plots based on parametrized
    %   "nervePlotHeight" at the end of NERVE DATA SECTION
    nexttile(column1(end - nervePlotHeight+1) ,[nervePlotHeight 12]);
    nervePlot = stackedplot(tabDataNerves,'color','r');
    tickNerves = findobj(nervePlot.NodeChildren, 'Type','Axes');
    set(tickNerves, 'YTick', []);
    [~,xpoints] = size(dataNerves);
    set(tickNerves, 'XTick', 0:(xpoints/finalTicks):xpoints);
    s = xpoints/(VSDRate*IntanRate);
    set(tickNerves, 'XTickLabel', 0:s/finalTicks:s);
    xlabel(tickNerves(end), 'Time (s)');

% otherwise, adds remaining X-axis features to VSD plot.
else

    [xpoints,~] = size(dataVSD);
    set(tickVSD, 'XTick', 0:(xpoints/finalTicks):xpoints);
    s = xpoints/VSDRate;
    set(tickVSD, 'XTickLabel', 0:s/finalTicks:s);
    xlabel(tickVSD(end), 'Time (s)');

end    

% loads in frames for plotting.  Please note that the location of
%   the frame with selected ROIs needs to be manually specified
%   here (will resolve this issue later).  This figure must also
%   be manually created (I did this by taking a screenshot and
%   cropping it to 256x256 in mspaint).
%     frameFolder = 'Z:\_Lab Personnell_Summer Students\Rodrigo\VSD_Data\21-07-12\Turbo_data\Sheathed\Strong_stain\Plotting_frames';
%     clearFrame = imread(fullfile(folder,'\21-07-12_RodrigoVSD009_frame.tif'));
%     ROIFrame = imread(fullfile(frameFolder,'\21-07-12_RodrigoVSD009_frame_ROIs.png'));

% plots frames with and without ROIs.
nexttile(13,[4 4]);
imshow(frameim);
text(roixy(ROIs,1),roixy(ROIs,2),string(ROIs))
%     nexttile(77,[4 4]);
%     imshow(ROIFrame);

% checks if 25 plots have been generated, which is the maxiumum
%   that can fit on a stacked plot.  If so, makes new tiled
%   plot
%     if mod(neurons,25)==0
%         figure;
%         tiledlayout(r,c,'TileSpacing','tight','Padding',...
%             'compact');
%     end

end