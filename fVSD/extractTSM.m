function data = extractTSM(folder,trial)

%% Parameters
chunkLength = 500;

%% Data extraction
% Obtain header information
info = fitsinfo(fullfile(folder,[trial '.tsm']));

% Obtain image size and recording length
xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording

% Compute the number of chunks to extract
numChunks = ceil(zsize/chunkLength);

% Obtains a dark frame by indexing one frame after the end of tsm
%   recording of length zsize, with special 4th input "getDarkFrame" to
%   extract just the dark frame
[darkFrame] = readTSM(info,1,(zsize+1),true);

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

