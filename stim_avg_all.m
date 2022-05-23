

[file, path,~] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select tsm file','MultiSelect','on');
fpath = fullfile(path,file);

filelist = dir(fullfile(path, '**\*.*')); % gets all files and subfolders in directory
filelist = string(join([{filelist.folder}' {filelist.name}'],'\')); % turn all files into full pathstrings
filelist = filelist(contains(filelist,'.rhs'));

info = readcell(fullfile(path,'notes.xlsx'));

for f=1:length(fpath)
    fidx = find(ismember(info(:,1),replace(file{f},'.tsm','')));
    intan = filelist(contains(filelist,info{fidx,2}));
    if length(intan)>1
        intan = filelist(contains(filelist, string(join([info(fidx,2),info(fidx,2)],'\'))  ));% if first file in folder of multiple intan files the folder name is the same as file name
    end
    stim_avg(intan,fpath{f})
end