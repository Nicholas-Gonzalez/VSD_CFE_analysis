% This script is the main pipeline for data processing.

%% Define variables for other sections. Always run this section first.

% Folder containing all, or any subset of, the experiments.
masterFolder = fileread('TSM_path_appdata.txt');

% List .tsm files in experiment folders.
listf = dir(fullfile(masterFolder, '10*.tsm'));

%  % Temporary: ignore folders already extracted.
%  listf_conv = dir(fullfile(masterFolder, '1*conv*.mat'));
%  listf = listf(~ismember({listf.folder},{listf_conv.folder}));

fpath = join(string([{listf.folder}', {listf.name}']),'\');


%% Find the optimal frame for drawing the kernels. This step will also create the .mat files on which data will be saved at other sections.
disp('running find_kframe')
% Find optimal frame for each file.
for a = 1:length(listf)
    find_kframe(fpath{a},false);% I removed trial, I had this before I relized that it is better to encode and read trial numbe in the filename itself
end

disp('Optimal frames for kernel drawing have been saved. Please, draw kernels for each file before proceeding.')

%% Extract raw, filtered and denoised data.
disp('running extract raw')

%get time each CFE was created to search for corresponding VSD recording
dfolder = dir(masterFolder);
cfeconn = [fpath,  strings(length(fpath),1)];
for f=3:length(dfolder)
    if ~contains(dfolder(f).name,'.')
        sfolder = dir(fullfile(dfolder(f).folder,dfolder(f).name));
        rhsidx = find(contains({sfolder.name},'.rhs'),1);
        timedif = double(string({dfolder.datenum}))-sfolder(rhsidx).datenum;
        if min(abs(timedif))<0.01
            [~,idx] = min(abs(timedif));
            vsdnm = dfolder(idx).name;
            cfeconn(contains(cfeconn(:,1),vsdnm(1:end-2)), 2) = fullfile(dfolder(f).folder, dfolder(f).name, sfolder(rhsidx).name);
        end
    end
end


% Extract data for each file.
for a = 3%:length(listf)
    detname = fullfile(replace(cfeconn{a,1}, '.tsm', 'kernel.det'));  
    if ~exist(detname,'file') 
        disp([ detname ' not found.'])
        continue
    else
%         try % In case there is an error on a specific file.
            % extracts extracellular nerve data
            %rawNerves = extractTBN(folder,trial);
            
            % extracts VSD data and stores it raw, filtered, and denoised
            tic
            %rawVSD = extractTSM(cfeconn{a,1},detname);
            toc
            filteredVSD = vsd_ellipTSM(rawVSD);
            filteredVSD(1:1000,:) = 0; % Zero out first second to remove artifact (shutter+bleaching+filtering).
            filteredVSD(end-1000:end,:) = 0; % Zero out last second to remove artifact .
            filteredVSDZ = zscore(filteredVSD,[],1); % z-scores filtered data for plotting purposes
            denoisedVSD = pca_denoise(filteredVSD);
            
            rawBNC = extractTBN(fullfile(replace(cfeconn{a,1}, '.tsm', '.tbn')));
            
            %notes = string(readcell(fullfile(fileparts(cfeconn{a,2}),'notes.xlsx')));
            %IntanSignals = notes(2:end,notes(1,:)=="good channels");
            
            [~,~,roixy]=readdet(detname);
            
            tiffnm = replace(cfeconn{a,1},'.tsm','_frame.tif');
            frameim = imread(tiffnm);
            %vsd_stacked_plotter_tsm(filteredVSDZ,1:size(rawVSD,2),cfeconn{a,2},frameim,IntanSignals,IntanSignals,roixy);
            
            % calls Rodrigo's plotter function that plots all data,
            %   including raw, filtered, and denoised side-by-side
            %   in each trial
%             vsd_all_plotter_tsm(rawVSD,filteredVSDZ,denoisedVSD);
            
%         catch ME
%             fprintf([ 'Couldn''t read %s\t\t' ME.message '\t\t' ME.stack(1).name '\t\tLine ' num2str(ME.stack(end-1).line) '\n'],fnames{a})
%         end
    end
end

%% Spike detection and convolution
% 
% % Detect spikes for each file.
% for A = 1:length(listf)
%     
%     trial = listf(A).name(1:end-3); % Remove .da to obtain trial name.
%     folder = listf(A).folder;
%     matF = dir(fullfile(folder,[trial 'pre*.mat']));
%     try % In case there is an error on a specific file.
%         %delete(fullfile(folder,[trial '_conv_' date '.mat']))
%         
%         load(fullfile(folder,matF.name),'vsddata')
%         vsd_filtered_ns = vsd_ellip(vsddata);
%         vsdDenoise_ns = pca_denoise(vsd_filtered_ns);
%         
%         [vsd_spiketime,vsd_visualize_spike,vsd_detect_all,~]=detect_spikes_vsd(vsdDenoise_ns);
%         vsd_convFRMat = ksGaussian(vsd_detect_all);
%         
%         save(fullfile(folder,[trial '_convNEW_' date]),'vsd_spiketime','vsd_visualize_spike','vsd_detect_all','vsd_convFRMat')
%         clearvars('vsdDenoise_ns','vsd_spiketime','vsd_visualize_spike','vsd_detect_all','vsd_convFRMat')
%     catch
%         disp(['Failed to detect and convolve spikes.' newline 'Folder: ' folder newline 'Trial: ' trial])
%     end
% end