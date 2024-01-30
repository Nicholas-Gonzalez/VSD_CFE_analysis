

while 1==1
    [file, path] = uigetfile('*.tif');
    if file==0;return;end
    disp(fullfile(path,file))
    imp = imread(fullfile(path,file));
end