function trimData = trimRHS(untrimData,t,frames,IntanRate)
  
    % identifies starting point of data (denoted as t=0) and trims off
    %   that value and all values below it in untrimData.  Then trims
    %   off excess, denoted as the number of frames acquired for VSD
    %   (frames) times the rate the Intan system records at (in kHz)
    [~,Index] = intersect(t,0);
    untrimData(:,1:Index) = [];
    trimData = untrimData(:,1:frames*IntanRate);

end