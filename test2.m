Excel = readcell('C:\Users\Owner\OneDrive\Desktop\Byrne Lab\BMP times.xlsx');



file = strcat('E:\VSD_Data\VSD\Nick (initial storage)\23-12-15-1\002_filtered.mat');
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





