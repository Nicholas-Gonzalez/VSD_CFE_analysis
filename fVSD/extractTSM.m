function [data,tm,info,imdata,imtm] = extractTSM(fpath, detpath, pixelparam,pixelfun)

if nargin==0
    [file, path, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select tsm file');
    fpath = fullfile(path,file);
end

if nargin<2
    [dfile, dpath, ~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.det','Select det file');
    detpath = fullfile(dpath,dfile);
end


%% Parameters
chunkLength = 485;
shutterThr = 2; % Threshold for detection of initial shutter opening. (In times the mean dark frame intensity.)
baselineFrames = 10; % Number of frames to average to get the baseline light intesity.
shutterOpenDur = 400; % Number of frames during the duration it takes to open the shutter.

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
numChunks = floor(zsize/chunkLength);

imtm = 0:chunkLength*sr:zsize*sr;

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

if nargin>2
    pixelparam = permute(pixelparam,[1 3 2]);
    pixelparam = repmat(pixelparam,1,chunkLength,1);
    chunktm = repmat((0:chunkLength-1)*sr,xsize*ysize,1);
end

% Iterate data extraction through chunks
kernelData = nan(zsize,numKern);
% disp(['reading ' fpath])
% disp(['          ' repmat('|______________',1,4) '|']);
% fprintf('Progress: ')

fig = figure('Name','Progress...','NumberTitle','off','MenuBar','none',...
    'Position',[500, 500 300 75]);
pax = axes('Position',[0.1 0.2 0.8 0.7],'XLim',[0 1],'YLim',[0 1],'YTick',[]);
rec = rectangle('Position',[0 0 0 1],'FaceColor','b');
pause(0.01)

imdata = nan(ysize,xsize,numChunks);
shutter = nan(zsize,1);
tic
for a = 1:numChunks
%     if mod(a,round(numChunks/60))==0
%         fprintf('|')
%     end
    if mod(a,round(numChunks/60))==0
        if ~isvalid(rec)
            disp('operation terminated')
            return
        end
        set(rec,'Position',[0 0 a/numChunks 1])
        pause(0.01)
    end
    dataChunk = readTSM(info,chunkLength,a,false);
    alength = size(dataChunk,3);
    dataChunk = dataChunk - darkFrame;
    
    dataChunk = reshape(dataChunk,xsize*ysize,alength); % Reshape in two dimensions to facilitate indexing.
    idx = 1:alength;

    if a==1
        f0 = dataChunk(:,end);
        f0 = repmat(f0,1,size(dataChunk,2));
    end
    chunkWin = idx + chunkLength*(a-1);% Index of the temporal window of the chunk.
    shutter(chunkWin) = mean(dataChunk);
    dataChunk = (dataChunk - f0(:,idx))./f0(:,idx);

    if nargin>2
        imdata(:,:,a) = reshape(dataChunk(:,1),ysize,xsize);   
        imdatafp = pixelfun(pixelparam(:,idx,1), pixelparam(:,idx,2), pixelparam(:,idx,3),...
            pixelparam(:,idx,4), chunktm(:,idx)+a*chunkLength*sr);
        dataChunk = dataChunk - imdatafp;
    end
    
%     chunkWin = 1+chunkLength*(a-1):chunkLength*a; % Index of the temporal window of the chunk.

%     chunktm = chunkWin*sr;
    
    for b = 1:numKern
        kIdx = det(kernpos(b)+1:kernpos(b)+kernel_size(b)); % Index of current kernel.
        
        kernelData(chunkWin,b) = mean(dataChunk(kIdx,:),1)';        
    end
    
end
close(fig)
toc
% fprintf('\n')
data = kernelData;

%% Data pre-processsing and normalization

%Find first fully illuminated frame.
light = shutter>500;
firstLightFrame = find(light,1)+ shutterOpenDur; 

% Smooth shutter off
p0 = [0 0];
flimits = inf([1,2]);
opts = optimset('Display','off','Algorithm','levenberg-marquardt');

btm = firstLightFrame:firstLightFrame+100;
x = 1:max(btm);
fun = @(p,x) p(1).*exp(x./200) - p(2); 
for i=1:size(data,2)
    fp = lsqcurvefit(fun,p0,btm',data(btm,i),-flimits,flimits,opts);
    data(x,i) = fun(fp,x);
end

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
% baseline = repmat(baseline,[zsize 1]);
% data = (data - baseline)./baseline;

