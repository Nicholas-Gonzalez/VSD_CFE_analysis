function compareim(im,title)

nim = size(im,1);
figure('Position',[1969 402 1843 420]);
for f=1:nim
    ax = subplot(1,nim,f);
    imagesc(im{f});
    ax.Title.String = title{f};
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    pbaspect([1 1 1])
end

uicontrol('Style','pushbutton','String','label','Callback',@label)



function label(hObject,eventdata)
x = 1;
y = 1;
axs = findobj(hObject.Parent,'Type','Axes');
while ~isempty(x)
    [x,y] = ginput(1);
    if ~isempty(x)
        cax = get(hObject.Parent,'CurrentAxes');
        title = cax.Title.String;
        id = regexp(title,'(?<!\()\d+(?!\))','match');
        id = num2str(double(string(id)));
        for a = 1:length(axs)
            subplot(axs(a))
            text(x,y,id)
        end
    end
end

