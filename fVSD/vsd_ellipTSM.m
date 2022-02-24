function [filtered] = vsd_ellipTSM(data)
    
    % Simple Elliptic filter for VSD data. Fixed parameters for now.
    [b,a] = ellip(2,0.1,40,[5 25]*2/1000);
    filtered = filtfilt(b,a,data);

    % DO NOT PERFORM Z-SCORING HERE, because it will be re-zscored in
    %   the pca_denoise function.
    % simple z-scoring to standardize data similar to denoised TSM
    %   function.  z-scoring standarization is specific to each column
    %   (i.e. ROI) with additional settings specified.
    %filtered = zscore(filtered,[],2);

end

