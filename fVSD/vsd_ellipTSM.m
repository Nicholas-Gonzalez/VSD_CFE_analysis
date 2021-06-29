function [filtered] = vsd_ellipTSM(data)
% Simple Elliptic filter for VSD data. Fixed parameters for now.
[b,a] = ellip(2,0.1,40,[5 25]*2/1000);
filtered = filtfilt(b,a,data);
end

