function registerim(im1fn,im2fn)
% this function allows you to register two images together into two
% channels, still working on this function


if nargin==0
    [file1, path1, ~] = uigetfile({'*.tif';'.png';'.jpeg'},'Select file','MultiSelect','off');
    if ~any(file1); return;end
else
    [file1, path1, fext1] = fileparts(im1fn);
    file1 = [file1,fext1];
end
im1 = loadit(path1,file1);

if nargin<2
    [file2, path2, ~] = uigetfile({'*.tif';'.png';'.jpeg'},'Select file','MultiSelect','off');
    if ~any(file2); return;end
else
    [file2, path2, fext2] = fileparts(im2fn);
    file2 = [file2,fext2];    
end
im2 = loadit(path2,file2);


while ~all(size(im1)==size(im2)) 
    if size(im2,1)/size(im1,1)==size(im2,2)/size(im1,2)
        im2 = imresize(im2,size(im1,1)/size(im2,1));
        disp(['Changed size of image2 to fit image1, '  num2str(size(im1,2)) 'x' num2str(size(im1,1)) ' pixels'])
    else
        msgbox({'Images not the same aspect ratio.', ['Image1 is ' num2str(size(im1,2)) 'x' num2str(size(im1,1)) ' pixels'], ['Image2 is ' num2str(size(im2,2)) 'x' num2str(size(im2,1)) ' pixels']})
        [file2, path2, ~] = uigetfile({'*.tif';'.png';'.jpeg'},'Select file','MultiSelect','off');
        if isempty(file2);return;end
        im = loadit(path2,file2);
    end
end


fig = figure('MenuBar','none');
fig.Position([3 4]) = [700 200];

axes('Position',[0.6 0 0.4 1])
imex = imshow(im);

uicontrol(fig,"Units","normalized","Position",[0.1 0.8 0.17 0.1], "Style","text","String",file1,"FontSize",8)
uicontrol(fig,"Units","normalized","Position",[0.27 0.8 0.17 0.1], "Style","text","String",file2,"FontSize",8)
uicontrol(fig,"Units","normalized","Position",[0.44 0.8 0.16 0.1], "Style","text","String",'none',"FontSize",8)

uicontrol(fig,"Units","normalized","Position",[0 0.55 0.1 0.2], "Style","text","String","Red","FontSize",10)
Rg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.6 0.5 0.2],'BorderType','none','Tag','redchannel');
uicontrol(Rg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Rg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Rg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0 0.35 0.1 0.2], "Style","text","String","Green","FontSize",10)
Gg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.4 0.5 0.2],'BorderType','none','Tag','greenchannel');
uicontrol(Gg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Gg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Gg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0 0.15 0.1 0.2], "Style","text","String","Blue","FontSize",10)
Bg = uibuttongroup(fig,'Units','normalized','Position',[0.1 0.2 0.5 0.2],'BorderType','none','Tag','bluechannel');
uicontrol(Bg,"Units","normalized","Position",[0.16 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])
uicontrol(Bg,"Units","normalized","Position",[0.49 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"Value",1,"String",[])
uicontrol(Bg,"Units","normalized","Position",[0.82 0 0.33 1], "Style","radiobutton",...
    "Callback",@update_example,"String",[])

uicontrol(fig,"Units","normalized","Position",[0.4 0 0.2 0.1], "Style","pushbutton","String","Update",...
    "Callback",@replaceim,"FontSize",8)

guidata(fig,struct('intan_tag',props.intan_tag,'im2',im2,'im1',im1,'imex',imex,...
    'file1',fullfile(path1,file1),'file2',fullfile(path2,file2),'imsel',[2 2 2]));

function im = loadit(path,file)
for f=1:3
    try
        imp = double(imread(fullfile(path,file),'Index',f));
        if f==1
            im = zeros([size(imp) 3]);
        end
        im(:,:,f) = imp/max(imp,[],'all');
    catch
        im(:,:,f) = im(:,:,1);
    end
end

function update_example(hObject,eventdata)
aprops = guidata(hObject);

cim = cat(4,aprops.im0, aprops.im, zeros(size(aprops.im)));
im = zeros(size(aprops.im));

bg = get(get(findobj(hObject.Parent.Parent,'Tag','redchannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,1) = cim(:,:,1,bg);
aprops.imsel(1) = bg;

bg = get(get(findobj(hObject.Parent.Parent,'Tag','greenchannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,2) = cim(:,:,2,bg);
aprops.imsel(2) = bg;

bg = get(get(findobj(hObject.Parent.Parent,'Tag','bluechannel'),'Child'),'Value');
bg = find(flipud(ismember(string(bg),'1')));
im(:,:,3) = cim(:,:,3,bg);
aprops.imsel(3) = bg;

guidata(hObject,aprops)
set(aprops.imex,'CData',im)