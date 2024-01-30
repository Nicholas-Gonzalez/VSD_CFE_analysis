
def = '';
im = zeros(256,256,0);
cnt = 1;
while 1==1
    [file, path] = uigetfile([def '*.mat']);
    if file==0;return;end
    if cnt == 1;figure;end
    disp(fullfile(path,file))
    def = path;
    data = load(fullfile(path,file));
    im(:,:,cnt) = data.frame_pic_raw;
    histogram(data.frame_pic_raw);hold on
    cnt = cnt + 1;
end

%%
figure
for i = 1:size(im,3)
   histogram(im(:,:,i));hold on
end