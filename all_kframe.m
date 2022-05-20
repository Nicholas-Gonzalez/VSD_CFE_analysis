function all_kframe()

[fnames, fpath] = uigetfile('*.tsm',"MultiSelect",'on');
files = fullfile(fpath,fnames);

if ischar(files)
    disp(['find_kframes   ',files])
    find_kframe(files,false);
else
    for f=1:length(files)
        disp(['find_kframes   ',files{f}])
        try
            find_kframe(files{f},false);
        catch
            warning(['could not execute for ' files{f}])
        end
    end
end

disp('finished')
end

% Index in position 3 exceeds array bounds. Index must not exceed 1.
% 
% Error in find_kframe (line 117)
%         pre_pic=[mov_pic(:,:,numfrm/10+(d-1)*numfrm/10)  ;  inf(ysize,xsize)];
% 
% Error in all_kframe (line 7)
%     find_kframe(files{f},false);