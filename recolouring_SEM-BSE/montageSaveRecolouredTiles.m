function montageSaveRecolouredTiles(mosaicInfo, ...
    mosaic_edges, split_parameters, filterSize, destDir2)

n_images = mosaicInfo.n_images;
referenceGrid = mosaicInfo.referenceGrid;
desiredGrid = mosaicInfo.desiredGrid;
fileNames_sorted = mosaicInfo.fileNames_sorted;
imgDim = mosaicInfo.imgDim;
n_rows = imgDim(1);
n_cols = imgDim(2);
n_channels = size(split_parameters, 1);
format = '.tif';

for i = 1:n_images %parfor n_images    
    position = desiredGrid(referenceGrid == i);
        
    temp_img = imread(fileNames_sorted{i});
    
    %cropping (optional if image comes with burned info)
    temp_img = temp_img(1:n_rows, 1:n_cols); %edit manually

    %clipping    
    temp_img(temp_img < mosaic_edges(1)) = mosaic_edges(1);
    temp_img(temp_img > mosaic_edges(end)) = mosaic_edges(end);
    
    temp_24bit = zeros(n_rows, n_cols, n_channels, 'uint8');
    parfor j= 1:n_channels
        channel_temp = double(temp_img);
        channel_mask_down = temp_img < split_parameters(j, 1);
        channel_mask_up = temp_img > split_parameters(j, 2);
        
        channel_rescaled = (channel_temp - split_parameters(j, 1))*split_parameters(j, 4);
        channel_rescaled(channel_mask_down) = 0;
        channel_rescaled(channel_mask_up) = 0;

        %Median filter
        channel_rescaled = medfilt2(channel_rescaled, [filterSize filterSize], "symmetric") %extend the image at the boundary

        temp_24bit(:, :, j) = uint8(channel_rescaled);
    end
    
    %New naming sequence (edit)
    % tileName = strcat('tile_', sprintf('%03d', position), format); %edit    
    tileName = strcat('tile_', sprintf('%04d', position), format); 
    imwrite(temp_24bit, fullfile(destDir2, tileName), 'compression', 'none');

    disp(num2str(i))
end
%the pipeline continues in TrakEM2 for montaging RGB tiles

end