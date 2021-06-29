function [det,pixels,kern_center,kernel_size,kernpos]=readdet(fpath,trial)
% Function for reading kernel coordinates from .det file
% "fpath" -- Full path where .det file is located.
% "trial" -- File name of the target .det file, minus the extension.

% 
% Parameters

pixSz = 256; % Size of the acquired image on which kernels were drawn. Currently assumes X and Y dimensions are the same.

detfile = dir(fullfile(fpath, [num2str(trial) '*.det']));
fid_det = fopen(fullfile(fpath, detfile.name),'r');
det = textscan(fid_det,'%f','Delimiter',{',','\n'});
det = cell2mat(det);
det(isnan(det)) = 0;
det(diff(det)==0) = [];
det = [0; det];
fclose(fid_det);

pixels = mod(det,pixSz);
pixels(:,2) = ceil(det/pixSz);
pixels(pixels(:,1)==0,1) = pixSz;

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


