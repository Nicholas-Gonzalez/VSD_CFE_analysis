function [frame,frame_pic]=find_kframe(fpath,fig_visible)
%This fuction finds the best frame to draw the kernels.  It saves the frame
%as (eg.  101_frame.tif).  It also saves the frame number and a matrix of
% the frame in a matlab document (eg.  101pre_date.mat).
%
% INPUT:
% fpath =  name and path of file, be sure to include extension
%
% EXAMPLE:
% [frame,frame_pic]=find_kframe('D:\Data\CFE_VSD\21-08-18\VSD_CFE001.tsm');

%% -------------------------------Parameters--------------------------------%
numfrm=200;
dark_frms=200;% specify the number of dark frames
avg_frms=200;

if nargin==0
    [file, path, id] = uigetfile('C:\Users\cneveu\Desktop\Data\*.tsm','Select tsm file');
    fpath = fullfile(path,file);
end

if nargin<2
    fig_visible = true;
end
monitor=2;
figure_size=1;
pic_size=.5;

[folder,fname,fileType] = fileparts(fpath); % Either 'da' or 'tsm'.
trial = char(regexp(fname,'\d+$','match'));
headerLength = [2560*2 2880]; % Header lengths for 'da' and 'tsm' files, respectively.

%% -------------------------------------------------------------------------%

MP = get(0,'MonitorPositions');

%Archive old matlab files
file=dir(fullfile(folder, [trial 'pre_*.mat']));
if size(file,1)
    if ~exist(fullfile(folder, 'Archives'),'dir');    mkdir(fullfile(folder, 'Archives'));      end
    copyfile(fullfile(folder, file.name), fullfile(folder, 'Archives'))
    delete(fullfile(folder, file.name))
end

if strcmp(fileType,'.da')
    fid = fopen(fpath,'r');
    header = fread(fid, 2560, 'int16');
    xsize = header(385);
    ysize = header(386);
    all_frm = header(2001)+header(2002)*32000;%determine duration of recording
    headerLength(2)=[]; % Delete header length of other file type.
elseif strcmp(fileType,'.tsm')
    fid = fopen(fpath,'r');
    warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
    info = fitsinfo(fpath);
    warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')
    xsize = info.PrimaryData.Size(2); % Note: xsize is the second, not the first value.
    ysize = info.PrimaryData.Size(1);
    all_frm = info.PrimaryData.Size(3);
    headerLength(1)=[]; % Delete header length of other file type.
end

% this output is supressed - Rodrigo 07/01/2021
fseek(fid, headerLength,'bof');% go back to begining of .da file
frms=zeros(1,dark_frms);
for z=1:dark_frms
    the_frame=double(fread(fid, xsize*ysize, 'int16'));% captures frame
    frms(z) = mean(the_frame);
end
drk_threshold=0;%2*mean(frms);

%make average frame
cnt_frm=1; frm_avg=zeros(xsize*ysize,1); a=0;
fseek(fid, headerLength,'bof');% go back to begining of .da file
while a==0
    frm_avg = frm_avg+double(fread(fid, xsize*ysize, 'int16'));% captures frame
    a=fseek(fid, xsize*ysize*round(all_frm / avg_frms)*2, 'cof');% skips over frames
    cnt_frm=cnt_frm+1;
end
frm_avg=frm_avg/cnt_frm;
frm_avg_r=reshape(frm_avg,xsize,ysize)'; 

pixels=reshape(1:xsize*ysize,xsize,ysize)'; 
a=0;   count_frm1=1;   pic=zeros(ysize,xsize,numfrm);  % CHANGED FOR 'TSM', ORIGINALLY "pic=zeros(xsize,ysize,numfrm);". 2020-08-17
mov_pic=pic(:,:,numfrm-1);  dist_mean=zeros(numfrm,1); movement1=dist_mean; std_frm=dist_mean;
frm_sub1=zeros(1,xsize*ysize); act_frm=1;  real_frm=dist_mean;
fseek(fid, headerLength,'bof');% go back to begining of .da file
while a==0
    frmd = double(fread(fid, xsize*ysize, 'int16'));% captures frame
    std_frm(count_frm1)=mean(std(frmd(pixels(20:100,5:end))));
    
    if mean(frmd)>drk_threshold
        pic(:,:,count_frm1)=reshape(frmd,xsize,ysize)'; %adds frame to picture
        
        if mean(frm_sub1)>drk_threshold
            dist_mean(count_frm1)=immse(frmd(pixels(20:100,:)) , frm_avg(pixels(20:100,:)));
            movement1(count_frm1)=immse(frmd(pixels(20:100,:)) , frm_sub1(pixels(20:100,:)));
            mov_pic(:,:,count_frm1)=(pic(:,:,count_frm1)-frm_avg_r)./frm_avg_r;
        end
        
        real_frm(count_frm1)=act_frm;
        count_frm1=count_frm1+1;
    end
    a=fseek(fid, xsize*ysize*round(all_frm / numfrm)*2, 'cof');% skips over frames
    frm_sub1=frmd;% retain for next loop to compare
    act_frm=act_frm+1;
end
rpic = pic;
pic=pic/max(max(max(pic(10:end-10,10:end-10))));


see_pic=zeros(ysize*2,0);
mov_frms=10;
for d=1:round(mov_frms/2)
    if numfrm/10+(d+4)*numfrm/10<=size(mov_pic,3)
        pre_pic=[mov_pic(:,:,numfrm/10+(d-1)*numfrm/10)  ;  mov_pic(:,:,numfrm/10+(d+4)*numfrm/10) ];
    else
        pre_pic=[mov_pic(:,:,numfrm/10+(d-1)*numfrm/10)  ;  inf(ysize,xsize)];
    end
    see_pic=[see_pic  pre_pic];
end

%save frame
[~,I]=min(dist_mean(dist_mean>0));
idx=I+sum(dist_mean(1:I-1)==0);
frame=real_frm(idx)*round(all_frm / numfrm);
frame_pic=pic(:,:,idx);
frame_pic_raw = rpic(:,:,idx);

imwrite(pic(:,:,1),fullfile(folder,[fname  '_imstack.tif']))
for i=2:size(pic,3)
    imwrite(pic(:,:,i),fullfile(folder,[fname  '_imstack.tif']),'WriteMode','append')
end

imwrite(frame_pic,fullfile(folder, [fname  '_frame.tif']))
save(fullfile(folder, [fname '_' date]),'frame','frame_pic','rpic','frame_pic_raw')

%generate data figure
close(findobj(0, 'Name', 'Contrast'))
fig1 = figure('Name' , 'Contrast','NumberTitle' , 'off','Visible',fig_visible);
subplot(2,3,1:3); image(see_pic*200); ax=gca; ax.Title.String='Frame Normalized Subtraction';
for e=1:round(mov_frms/2)
    if e<round(mov_frms/2);   line(xsize*[e e] , [0 256],'Color','k','LineWidth',1);  end
    text(e+(e-1)*xsize , 0 , num2str(numfrm/10+(e-1)*numfrm/10) , 'VerticalAlignment','top','BackgroundColor',[1 1 1]);
    text(e+(e-1)*xsize , ysize , num2str(numfrm/10+(e+4)*numfrm/10) , 'VerticalAlignment','top','BackgroundColor',[1 1 1]);
end
line([0 size(see_pic,2)] , [ysize ysize] , 'Color' , 'k' , 'LineWidth' , 1);
subplot(2,3,4);plot(std_frm(std_frm>0)); hold on; scatter(I,std_frm(I));        ax=gca; ax.Title.String='Frame Standard Devation';
subplot(2,3,5);plot(dist_mean);          hold on; scatter(idx,dist_mean(idx));  ax=gca; ax.Title.String='Distance to Mean';
subplot(2,3,6);plot(movement1);          hold on; scatter(idx,movement1(idx));    ax=gca; ax.Title.String='Distance to Previous Frame';

% set(gcf,'Position',[round(MP(monitor,1)*.75) MP(monitor,2)+MP(monitor,2)*0.01  figure_size.*MP(monitor,4)-MP(monitor,4)*0.08   figure_size.*MP(monitor,4)-MP(monitor,4)*0.08]);

%save data figure
saveas(fig1,fullfile(folder, [fname '_frame_selection_data.png']))

close(findobj(0, 'Name', 'Picture'))
fig2 = figure('Name' , 'Picture','NumberTitle' , 'off','Visible',fig_visible);
frm_avg_r=frm_avg_r/max(max(frm_avg_r(10:end-10,10:end-10)));
image(repmat(frm_avg_r,[1 1 3]))
% set(gcf,'Position',[round(MP(monitor,1)*.75) MP(monitor,2)+MP(monitor,2)*0.01  pic_size.*MP(monitor,4)-MP(monitor,4)*0.08   pic_size.*MP(monitor,4)-MP(monitor,4)*0.08]);

%save picture
saveas(fig2,fullfile(folder, [fname '_picture.png']))


fclose(fid);

end