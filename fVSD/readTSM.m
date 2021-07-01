function [data] = readTSM(info,chunkLength,chunkNumber)
% Reads .tsm files, which are stored in FITS standard, but use
% little-endian byte order instead of big-endian. .tsm also has an
% additional dark frame at the end, which is currently ignored here.

% INPUT         DESCRIPTION
% "info"        Header information, extracted using the built-in "fitsinfo" function.
% "chunkLength" Length of chunk to be read.
% "chunkNumber" Index of chunk to be read (dependent of chunk length).

% Check inputs and adjust
if nargin==1
    chunkLength = 1;
    chunkNumber = 1;
    disp(['Reading only first frame. ' newline ...
    'Data length is ' num2str(info.PrimaryData.Size(3)) '.' newline ...
    'To load entire data specify that number as chunk length on the second input.'])
elseif nargin==2
    chunkNumber = 1;
end

% trims off the last frames
% if chunkLength * chunkNumber > info.PrimaryData.Size(3)
%     chunkLength = info.PrimaryData.Size(3) - chunkLength*(chunkNumber-1);
% end

% Open file
fid = fopen(info.Filename,'r');

% Extract x and y sizes explicitly
xsize = info.PrimaryData.Size(2); % Note that xsize is the second, not the first value.
ysize = info.PrimaryData.Size(1);

frameLength = xsize*ysize; % Frame length is the product of X and Y axis lengths;

% Compute offset to current chunk
offset = info.PrimaryData.Offset + ... Header information takes 2880 bytes.
            (chunkNumber-1) * ... 
            chunkLength * ... 
            frameLength * ...
            2; % Because each integer takes two bytes.

% Find target position on file.
fseek(fid,offset,'bof');

% Read data.
data = fread(fid,frameLength*chunkLength,'int16'); 

% Format data.
data = reshape(data,[xsize ysize chunkLength]); 
% Temporarily removed for compatibility with det file (20-08-19) data = permute(data,[2 1 3]); 
% Data needs to be transposed because MATLAB indexes rows first, whereas the TSM files store 'xsize' first.


% Close file.
fclose(fid);
end