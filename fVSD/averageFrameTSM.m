function [data,tm,info] = averageFrameTSM(fpath)

if nargin==0
    [file, path, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select tsm file');
    fpath = fullfile(path,file);
end



%% Parameters
chunkLength = 485;
shutterThr = 2; % Threshold for detection of initial shutter opening. (In times the mean dark frame intensity.)
baselineFrames = 10; % Number of frames to average to get the baseline light intesity.
shutterOpenDur = 40; % Number of frames during the duration it takes to open the shutter.

darkFrameMode = 'builtin'; % 'builtin' uses the built-in dark frame at the end of .tsm files.
                            % 'firstframes' averages the first n frames to obtain the dark frame. 
                            % 'none' uses a null dark frame.                            
nDarkFrames = 50; % Number of dark frames in the beginning of the recording to use for 'firstframes' option.

%% Data extraction
% Obtain header information
warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(fpath);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

% Obtain image size and recording length
xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};
tm = 0:sr:zsize*sr-sr;
% Compute the number of chunks to extract
numChunks = ceil(zsize/chunkLength);

switch darkFrameMode
    case 'builtin'
        % Obtains a dark frame by indexing one frame after the end of tsm
        %   recording of length zsize, with special 4th input "getDarkFrame" to
        %   extract just the dark frame
        [darkFrame] = readTSM(info,1,(zsize+1),true);
    case 'firstframes'
        % Obtain dark frame by averaging initial frames.
        darkFrame = readTSM(info,nDarkFrames);
        darkFrame = mean(darkFrame,3);
    case 'none'
        darkFrame = zeros(xsize,ysize); % Null dark frame.        
    otherwise
        warning('Using no dark frame.')
        darkFrame = zeros(xsize,ysize); % Null dark frame.
end

data = zeros(ysize,xsize,numChunks);

disp(['reading ' fpath])
disp(['          ' repelem('_',round(numChunks))])
fprintf('Progress: ')
for a = 1:numChunks
    fprintf('|')
    dataChunk = readTSM(info,chunkLength,a,false);
    alength = size(dataChunk,3);
    dataChunk = dataChunk - darkFrame;
    
    data(:,:,a) = mean(dataChunk,3);        
end
fprintf('\n')

if nargout==0
    assignin('base','out',data);
end
