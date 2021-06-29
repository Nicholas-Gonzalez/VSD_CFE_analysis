% This script is the main pipeline for data processing.

%% Define variables for other sections. Always run this section first.

% Folder containing all, or any subset of, the experiments.
masterFolder = 'Z:\_Lab Personnell_Summer Students\Rodrigo\VSD_Data\21-06-28\Turbo_data';%'E:\Renan\Operant Conditioning\blinded\*';

% List .da files in experiment folders.
listf = dir(fullfile(masterFolder, '1*.da'));

%  % Temporary: ignore folders already extracted.
%  listf_conv = dir(fullfile(masterFolder, '1*conv*.mat'));
%  listf = listf(~ismember({listf.folder},{listf_conv.folder}));

%% Find the optimal frame for drawing the kernels. This step will also create the .mat files on which data will be saved at other sections.

% Find optimal frame for each file.
for A = 1:length(listf)
    
    trial = listf(A).name(1:end-3); % Remove .da to obtain trial name.
    folder = listf(A).folder;
    try % In case there is an error on a specific file.
        find_kframe(folder,trial);
    catch
        display(['Failed to obtain optimal frame.' newline 'Folder: ' folder newline 'Trial: ' trial])
    end
end

display('Optimal frames for kernel drawing have been saved. Please, draw kernels for each file before proceeding.')

%% Extract raw, filtered and denoised data.

% Extract data for each file.
for A = 1:length(listf)
    
    trial = listf(A).name(1:end-3); % Remove .da to obtain trial name.
    folder = listf(A).folder;    
    if isempty(dir(fullfile(folder,[trial '*.det']))) % Determine whether .det file is present.
        display(['No .det kernel file found for trial ' trial '. Data could not be extracted.'])
        continue
    else
        try % In case there is an error on a specific file.
            extract_data(folder,trial);
        catch
            display(['Failed to extract data.' newline 'Folder: ' folder newline 'Trial: ' trial])
        end
    end
end

%% Spike detection and convolution

% Detect spikes for each file.
for A = 1:length(listf)
    
    trial = listf(A).name(1:end-3); % Remove .da to obtain trial name.
    folder = listf(A).folder;
    matF = dir(fullfile(folder,[trial 'pre*.mat']));
    try % In case there is an error on a specific file.
        %delete(fullfile(folder,[trial '_conv_' date '.mat']))
        
        load(fullfile(folder,matF.name),'vsddata')
        vsd_filtered_ns = vsd_ellip(vsddata);
        vsdDenoise_ns = pca_denoise(vsd_filtered_ns);
        
        [vsd_spiketime,vsd_visualize_spike,vsd_detect_all,~]=detect_spikes_vsd(vsdDenoise_ns);
        vsd_convFRMat = ksGaussian(vsd_detect_all);
        
        save(fullfile(folder,[trial '_convNEW_' date]),'vsd_spiketime','vsd_visualize_spike','vsd_detect_all','vsd_convFRMat')
        clearvars('vsdDenoise_ns','vsd_spiketime','vsd_visualize_spike','vsd_detect_all','vsd_convFRMat')
    catch
        display(['Failed to detect and convolve spikes.' newline 'Folder: ' folder newline 'Trial: ' trial])
    end
end