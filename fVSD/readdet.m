function [det,pixels,kern_center,kernel_size,kernpos]=readdet(fpath,xsize)
% Function for reading kernel coordinates from .det file
% xsize and ysize added because camera can aquire in different dimensions

if nargin<2
    xsize = 256;
end

% pixSz = 256; % Size of the acquired image on which kernels were drawn. Currently assumes X and Y dimensions are the same.

fid_det = fopen(fpath,'r');
det = textscan(fid_det,'%f','Delimiter',{',','\n'});
det = cell2mat(det);
det(isnan(det)) = 0;
det(diff(det)==0) = [];
det = [0; det];
fclose(fid_det);

pixels = mod(det,xsize);
pixels(:,2) = ceil(det/xsize);
pixels(pixels(:,1)==0,1) = xsize;

kernpos = find(~det);
kernel_size = diff(kernpos)-1;
kernpos(end) = [];
kern_center = zeros(length(kernpos),2);
for a=1:length(kernpos)
    if a<length(kernpos) 
        B = pixels(kernpos(a)+1:kernpos(a+1)-1,:);
    else
        B = pixels(kernpos(a)+1:end-1,:);
    end
    kern_center(a,:) = mean(B);
end

end


