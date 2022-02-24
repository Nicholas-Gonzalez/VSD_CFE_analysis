function [data,tm,info] = extractTSM(fpath, detpath)

if nargin==0
    [file, path, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select tsm file');
    fpath = fullfile(path,file);
    [dfile, dpath, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.det','Select det file');
    detpath = fullfile(dpath,dfile);
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

% Load kernels from .det file
[det,~,~,kernel_size,kernpos]=readdet(detpath);
numKern = length(kernpos);

% Iterate data extraction through chunks
kernelData = nan(zsize,numKern);
disp(['reading ' fpath])
disp(['          ' repelem('_',round(numChunks/10))])
fprintf('Progress: ')
for a = 1:numChunks
    if mod(a,10)==0
        fprintf('|')
    end
    dataChunk = readTSM(info,chunkLength,a,false);
    alength = size(dataChunk,3);
    dataChunk = dataChunk - darkFrame;
    
    dataChunk = reshape(dataChunk,xsize*ysize,alength); % Reshape in two dimensions to facilitate indexing.

    chunkWin = 1+alength*(a-1):alength*a; % Index of the temporal window of the chunk.
    
    for b = 1:numKern
        kIdx = det(kernpos(b)+1:kernpos(b)+kernel_size(b)); % Index of current kernel.
        
        kernelData(chunkWin,b) = mean(dataChunk(kIdx,:),1)';        
    end
end
fprintf('\n')
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
    
    for a = 1:length(lightOff)
        
        offRange = lightOff(a)-2:lightOn(find(lightOn>lightOff(a),1))+2;
        if ~isempty(offRange)
            localBaseline = mean(data(lightOff(a)-3*baselineFrames : lightOff(a)-3,:));
            data(offRange,:) = repmat(localBaseline,[length(offRange) 1]);
        else
            localBaseline = mean(data(lightOff(a)-10*baselineFrames : lightOff(a)-5*baselineFrames,:));
            data(lightOff(a)-5*baselineFrames:end,:) = repmat(localBaseline,[length(lightOff(a)-5*baselineFrames:zsize) 1]);
        end
    end
end

% Normalize data
baseline = repmat(baseline,[zsize 1]);
data = (data - baseline)./baseline;

