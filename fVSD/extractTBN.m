function data = extractTBN(folder,trial)

    % turbo resource: http://www.redshirtimaging.com/support/Turbo-SM.html
    

    % reads .tbn file as "short integer" (as described in Turbo-SM64
    %   user manual), which in MATLAB is int16.  Then indexes the first
    %   two values in this vector.  Value #1 is the number of channels,
    %   and value #2 is the BNC-to-camera ratio
    fileID = fopen(fullfile(folder,[trial,'.tbn']));
    A2 = fread(fileID,'int16');
    fclose(fileID);
    TBNchannels = A2(1);
    TBNBNCratio = A2(2);
    channels = abs(TBNchannels);
    
    % reads .tbn file as float64 format and uses this to plot
    fileID2 = fopen(fullfile(folder,[trial,'.tbn']));
    A3 = fread(fileID2,'float64');
    fclose(fileID2);
    
    %trims off first 2 values of A2
    %A2(1:2) = [];
    
    plotVals = A3;
    
    % NOTE: we get a 1:1 ratio of BNC:camera using A3.  Specifically,
    %   when we extract the int16 data, we find that there are 8
    %   channels, and the data is stored in float64.  However, A3 values
    %   seems to be agregiously out of range.  Why?  Dunno.
    
    time = length(plotVals)/channels;
    data = zeros(channels,time);
    
    for i = 1:channels
        
        data(i,:) = plotVals(((i-1)*time+1):time*i);
        
    end
    
end