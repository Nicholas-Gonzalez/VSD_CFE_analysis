Excel = readcell('C:\Users\Owner\OneDrive\Desktop\Byrne Lab\BMP times.xlsx');

%full run is 3:24
for expNumber = 11:11
    FirstDate = num2str(char(Excel(expNumber,1)));

%full run is 1:2
for i = 2:2
    chari = num2str(i);


file = strcat('E:\VSD_Data\VSD\Nick (initial storage)\',FirstDate,'\00',chari,'_filtered.mat');
disp(['loading...   ' file])
props = matfile(file);
props = props.props;
data = props.data;
data = double(data)./repmat(props.d2uint,1,size(data,2)) + repmat(props.min,1,size(data,2));% Important! need to convert to double-precision
disp('done loading')



channel = 1:20;%'V-046';% string of channel name or index of the channel. You can use multiple indexes for the channel or multiple channel names as string array.
param1 = 'thr1';
param2 = '';
vrange1 = -0.1:-0.2:-5;
vrange2 = vrange1;
Wlim = [-1000, 1000];% limits of the window to capture the spike (for calculating amplitude)

if isstring(channel) && length(channel)>1
	cidx = nan(size(channel));
	for n=1:length(channel)
		cidx(n) = find(props.ch==channel(n));
	end
elseif ischar(channel) || isstring(channel)
	cidx = find(props.ch==channel);
else
	cidx = channel;
end

dparams = props.spikedetection.params(cidx(1));% default parameters
dparams.ckdv = true;
dparams.ck1 = true;
dparams.ck2 = true;

%actual parameters. can modify these
dparams.thr1 = -2.2;
dparams.dur1 = 2;
dparams.gpdvdur = 18; %gap for thr1
dparams.thr2 = 2.2;
dparams.dur2 = 2;
dparams.gapdur = 18; %gap for thr2

sf = diff(props.tm(1:2));
W = Wlim(1):Wlim(2);

if isempty(param2)
	param2 = 'nothing';
	vrange2 = 1;
	dparams.nothing = 1;
end


count = 0;
temp = size(props.ch);
channelNum = temp(1,1);
for n=1:channelNum
if contains(props.ch(n),"V") == 1
    count = count +1;                     
end
end
count = 1;
channelNum = 1;

count2 =0; %tracks current V channel
count3 = 0; %tracks current fig number
count4 = 0; %tracks current number of channels in fig (1-20)



for a=1:channelNum %%plots the traces
    if a ~= channelNum
       if contains(props.ch(24),"V") == 1
         
           count2 = count2 +1;
           count4 = count4 +1;
            if count - count2 > 20 && mod(count4, 20) == 1
                left = 0.05;
                right = 0.05;
                bottom = 0.05;
                height = (1 - bottom)/20;
                width = 1 - left - right;
                fig = figure('Visible', 'off');
                ax = gobjects(count);
            elseif mod(count4,20) ==1
                left = 0.05;
                right = 0.05;
                bottom = 0.05;
                num = count - count2 +1;
                height = (1 - bottom)/num;
                width = 1 - left - right;
                fig = figure('Visible', 'off');
                ax = gobjects(count);
            end
          
           
               ax(count4) = axes('Position',[left, 1 - count4*height, width, height]);
                [spikes, aspike, ~,logic] = spikedetection_algorithm(dparams,W,data(a,:),[],sf);
                
             
               plot(props.tm(1:50:end), props.data(a,1:50:end));hold on
               ylowlim = ax(count4).YLim(1);
               if ~isempty(spikes)
                    scatter(props.tm(spikes), repelem(ylowlim, length(spikes)), 5, 'd', 'filled'); 
               end
    
                ax(count4).XTick = [];
                ax(count4).YTick = [];
                ax(count4).XAxis.Visible = 'off';
                ylabel(char(props.ch(a)),'Rotation',0,'FontSize', 7)
                ax(count4).YLabel.Position(1) = -5;
                xlim([-2,122]);
    
                if mod(count4, 20) == 0
                    count3 = count3 +1;
                    char3 = num2str(count3);
                   
                    xlabel('Time(s)');
                    fig.Position(3:4) = [1000 1000];
                    
                    %puts images in Recording Spikes Test2 folder, NOT Test
                    exportgraphics(fig, fullfile(strcat('C:\Users\Owner\OneDrive\Desktop\Recording Spikes Test2\'),strcat(FirstDate,'_00',chari,'_spikes',char3,'.png')), 'Resolution', 600);
                    close(fig)
                    count4 = 0;
                end
               
       end
    else
         if contains(props.ch(24),"V") == 1
             count2 = count2 +1;
             count4 = count4 +1;
             if count4 == 1
                left = 0.05;
                right = 0.05;
                bottom = 0.05;
                num = count - count2 +1;
                height = (1 - bottom)/num;
                width = 1 - left - right;
                fig = figure('Visible', 'off');
                ax = gobjects(count);
             end
           
           ax(count4) = axes('Position',[left, 1 - count4*height, width, height]);
            [spikes, aspike, ~,logic] = spikedetection_algorithm(dparams,W,data(24,:),[],sf);
            
            %300,000 to 525,000
            plot(props.tm(350000:50:525000), props.data(24,350000:50:525000));hold on
             ylowlim = ax(count4).YLim(1);
           
             if ~isempty(spikes)
                scatter(props.tm(spikes), repelem(5000, length(spikes)), 20, 'd', 'filled'); 
             end
            
            ax(count4).YTick = [];
            ax(count4).Box = 'off';
            ylabel(char(props.ch(24)),'Rotation',0,'FontSize', 7)
            ax(count4).YLabel.Position(1) = -5;
            xlim([22.5,34]);

            count3 = count3 +1;
            xlabel('Time(s)');
            fig.Position(3:4) = [1000 1000];
            char3 = num2str(count3);

            exportgraphics(fig, fullfile(strcat('C:\Users\Owner\OneDrive\Desktop\Recording Spikes Test2\'),strcat(FirstDate,'_00',chari,'_spikes',char3,'.png')), 'Resolution', 600);
            close(fig)
         end
    end
end
   
end
disp(strcat('exp',{' '},num2str(expNumber-2),'/22 done'))
end

disp('All done')