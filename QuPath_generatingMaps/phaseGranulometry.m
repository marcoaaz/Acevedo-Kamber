function [finer_pixels, original_pixels] = phaseGranulometry(map_binary, sizeMax, destinationDir)
%% Granulometry
%gpuDevice %if you have latest versions of CUDA and GPU driver

n_masks = length(map_binary);

width = 512; %ROI dim
height = 512;

tl_x = 1000; tl_y = 1000;
br_x = tl_x + width; br_y = tl_y + height;

%Option: pre-treatment (structuring element SE, r>0)
SE_base = strel('disk', 0, 0); %r= radius; %n approximates a larger SE
%SE_base.Neighborhood %checks binary mtx (offset if non-flat)

original_pixels = zeros(1, n_masks); %for storing
coarser_pixels = zeros(n_masks, sizeMax);
finer_pixels = zeros(n_masks, sizeMax);
for i = 1:n_masks
    mineral_binary = map_binary{i};
    subset = gpuArray(mineral_binary(tl_x:br_x, tl_y:br_y));
    %option: pre-treatment (filling holes)
    subset_base = imclose(subset, SE_base); 
        
    for j = 1:sizeMax
        SE = strel('disk', j, 0); 
        subset_opened = imopen(subset, SE); %morphological operation
        coarser_pixels(i, j) = sum(gather(subset_opened), 'all');
    end

    original_pixels(i) = sum(gather(subset_base), 'all');
    finer_pixels(i, :) = original_pixels(i) - coarser_pixels(i, :);    
end

%saving
finerPixelsfile = 'finerPixels.csv'; %aprox. min elapsed time
fullDest = fullfile(destinationDir, finerPixelsfile);
writematrix(finer_pixels, fullDest) 

%saving
originalPixelsfile = 'originalPixels.csv'; %aprox. min elapsed time
fullDest = fullfile(destinationDir, originalPixelsfile);
writematrix(original_pixels, fullDest) 

end