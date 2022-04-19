fpath = "E:\Renan\Cerebral AT Priming\22-04-07\106.tsm";

%% Parameters
chunkLength = 500;
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

% Iterate data extraction through chunks
data = zeros(xsize,ysize,chunkLength);
disp(['reading ' fpath])
disp(['          ' repelem('_',round(numChunks/10))])
fprintf('Progress: ')
for a = 1:numChunks
    if mod(a,10)==0
        fprintf('|')
    end
    dataChunk = readTSM(info,chunkLength,a,false,400);
    alength = size(dataChunk,3); % Note that only for the last chunk should it be possible for alength to be different from chunkLength.
    if alength~=chunkLength
        numChunks = numChunks-1;
        continue
    end
    %dataChunk = dataChunk - darkFrame;
    
    %chunkDiff = diff(dataChunk,1,3);
    %chunkDiff = cat(3,zeros(xsize,ysize),chunkDiff);
    
    data = data+dataChunk;
end
fprintf('\n')
data = data./numChunks;
baseline = data(:,:,1:50);
baseline = mean(baseline,3);
data = data-repmat(baseline,1,1,size(data,3));
data = data./repmat(baseline,1,1,size(data,3));
%data = diff(data,1,3);
%data = cat(3,zeros(xsize,ysize),data);
data = reshape(data,xsize,ysize,1,chunkLength);
data = data-min(data(:));
data = data./max(data(:));
data = permute(data,[2 1 3 4]);
%data = rot90(data); data=fliplr(data);
data = -data +1;
%%
imData = uint8(data(:,:,:,100:250)*256);
imData = cat(4,zeros(xsize,ysize,1,5),imData);
v = VideoWriter("E:\Renan\Cerebral AT Priming\22-04-07\106.avi",'Indexed AVI');
v.Colormap = parula(256);
open(v);
writeVideo(v,imData)
close(v);