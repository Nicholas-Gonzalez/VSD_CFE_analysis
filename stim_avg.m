function stim_avg(intan,vsd)

% read intan file
[amp_data, itm, st_data,st_param,notes,amp_ch, board_adc_ch, board_adc_data] = read_Intan_RHS2000_file(intan);

stimulated = find(any(st_data>0,2));%channels with stimulation


% read vsd file
[fpath,fname,fext] = fileparts(vsd); 
W = -100:100; % window of average trace

dur = length(W);

warning('off','MATLAB:imagesci:fitsinfo:unknownFormat'); %<-----suppressed warning
info = fitsinfo(vsd);
warning('on','MATLAB:imagesci:fitsinfo:unknownFormat')

xsize = info.PrimaryData.Size(2); % Note that xsize is second value, not first.
ysize = info.PrimaryData.Size(1);
zsize = info.PrimaryData.Size(3); % Length of recording
sr = info.PrimaryData.Keywords{cellfun(@(x) strcmp(x,'EXPOSURE'),info.PrimaryData.Keywords(:,1)),2};
vtm = 0:sr:zsize*sr-sr;


for S=1:length(stimulated)
    stimtm = find(diff(st_data(stimulated(S),:)>0));
    stimtm = stimtm([true, diff(stimtm)>200]);
    
    sidx = round(itm(stimtm)/sr);
    
    data = zeros(ysize,xsize,dur);
    
    frameLength = xsize*ysize; % Frame length is the product of X and Y axis lengths;
    
    fid = fopen(info.Filename,'r');
    for s=1:length(sidx)
        offset = info.PrimaryData.Offset + ... Header information takes 2880 bytes.
                    (sidx(s)-1)*frameLength*2; % Because each integer takes two bytes.
        
        % Find target position on file.
        fseek(fid,offset,'bof');
        
        % Read data.
        fdata = fread(fid,frameLength*dur,'int16=>double');% single saves about 25% processing time and requires half of memory 
        if length(fdata)<xsize*ysize*dur
            break
        end
        fdata = reshape(fdata,[xsize ysize dur]);
        
        % Format data.
        data = data + fdata;
    end
    fclose(fid);
    
    data = data/length(sidx);
    data0 = data(:,:,1)*double(int16(inf))/max(data(:,:,1),[],'all');% maximized to 16bit integer
    data0rep = repmat(data(:,:,1),1,1,dur-1);
    data2 = (data(:,:,2:end) - data0rep)./data0rep;% need to normalize and then maximize to 16bit integer
    data2  = data2 * double(int16(inf))/max(abs(data2(:)));
    data2 = data2 - min(data2(:));
    
    data = uint16(cat(3,data0,data2));
    
    % write image file
    imwrite(data(:,:,1),fullfile(fpath,[fname '_' num2str(S) '.tif']))
    for f=2:dur
        imwrite(data(:,:,f),fullfile(fpath,[fname '_' num2str(S) '.tif']),'WriteMode','append')
    end
    
    disp([fname '_' num2str(S) '.tif'])
end
end