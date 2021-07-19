function data = extractTSM(folder,trial)

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
info = fitsinfo(fullfile(folder,[trial '.tsm']));

% Obtain image size and recording length
xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording

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

% Load kernels from .det file
[det,~,~,kernel_size,kernpos]=readdet(folder,trial);
numKern = length(kernpos);

% Iterate data extraction through chunks
kernelData = nan(zsize,numKern);
for A = 1:numChunks
    dataChunk = readTSM(info,chunkLength,A,false);
    dataChunk = dataChunk - darkFrame;
    
    dataChunk = reshape(dataChunk,xsize*ysize,chunkLength); % Reshape in two dimensions to facilitate indexing.
    
    chunkWin = 1+chunkLength*(A-1):chunkLength*A; % Index of the temporal window of the chunk.
    for B = 1:numKern
        kIdx = det(kernpos(B)+1:kernpos(B)+kernel_size(B)); % Index of current kernel.
        
        kernelData(chunkWin,B) = mean(double(dataChunk(kIdx,:)),1)';        
    end
end

data = kernelData;

%% Data pre-processsing and normalization

% Find first fully illuminated frame.
mData = mean(data,2);
darkThr = mean(darkFrame,'all')*shutterThr;
light = mData > darkThr;
firstLightFrame = find(light); 
firstLightFrame = firstLightFrame(shutterOpenDur); % Note that this is not the true first fully illuminated frame, but a fully illuminated frame that follows the onset of shutter opening by a margin of safety specified by 'shutterOpenDur'.

% Smooth shutter off
baseline = mean(data(firstLightFrame:firstLightFrame+baselineFrames,:));
data(1:firstLightFrame,:) = repmat(baseline,[firstLightFrame 1]);

% Smooth off instances of the bulb turning off/flickering
if any(diff(light)==-1)
    lightOn = find(diff(light)==1);
    lightOff = find(diff(light)==-1);
    
    for A = 1:length(lightOff)
        
        offRange = lightOff(A)-2:lightOn(find(lightOn>lightOff(A),1))+2;
        if ~isempty(offRange)
            localBaseline = mean(data(lightOff(A)-3*baselineFrames : lightOff(A)-3,:));
            data(offRange,:) = repmat(localBaseline,[length(offRange) 1]);
        else
            localBaseline = mean(data(lightOff(A)-10*baselineFrames : lightOff(A)-5*baselineFrames,:));
            data(lightOff(A)-5*baselineFrames:end,:) = repmat(localBaseline,[length(lightOff(A)-5*baselineFrames:zsize) 1]);
        end
    end
end

% Normalize data
baseline = repmat(baseline,[zsize 1]);
data = (data - baseline)./baseline;

