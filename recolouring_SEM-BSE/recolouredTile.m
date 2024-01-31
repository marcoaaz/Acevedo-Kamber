function [img_RGB_med, img_greyscale] = recolouredTile(sel_image, mosaicInfo, ...
    mosaic_edges, split_parameters, filterSize, destDir2)

fileNames_sorted = mosaicInfo.fileNames_sorted;
imgDim = mosaicInfo.imgDim;
n_rows = imgDim(1);
n_cols = imgDim(2);
n_channels = size(split_parameters, 1);
  
temp_img = imread(fileNames_sorted{sel_image});
temp_img2 = temp_img(1:n_rows, 1:n_cols); %crop

%clipping    
temp_img2(temp_img2 < mosaic_edges(1)) = mosaic_edges(1);
temp_img2(temp_img2 > mosaic_edges(end)) = mosaic_edges(end);

temp_24bit = zeros(n_rows, n_cols, n_channels, 'uint8');
for j= 1:n_channels
    channel_temp = double(temp_img2);
    channel_mask_down = temp_img2 < split_parameters(j, 1);
    channel_mask_up = temp_img2 > split_parameters(j, 2);
    
    channel_rescaled = (channel_temp - split_parameters(j, 1))*split_parameters(j, 4);
    channel_rescaled(channel_mask_down) = 0;
    channel_rescaled(channel_mask_up) = 0;

    temp_24bit(:, :, j) = uint8(channel_rescaled);
end

img_R = medfilt2(temp_24bit(:, :, 1), [filterSize, filterSize]);
img_G = medfilt2(temp_24bit(:, :, 2), [filterSize, filterSize]);
img_B = medfilt2(temp_24bit(:, :, 3), [filterSize, filterSize]);

img_RGB_med = cat(3, img_R, img_G, img_B);
img_greyscale = temp_img;

%Saving (not in a loop)
%format = '.tif';
% tileName = strcat('tile_', sprintf('%04d', position), format);
% imwrite(temp_24bit, fullfile(destDir2, tileName), 'compression', 'none');
end