function [tile_stats] = montageSavedRenamedTiles(mosaicInfo, ...
    targetBit, rescaleOption, saveOption, filePaths_renamed)

n_images = mosaicInfo.n_images;
imgDim = mosaicInfo.imgDim;
fileNames_sorted = mosaicInfo.fileNames_sorted;

tile_stats = zeros(n_images, 6);
for i = 1:n_images %optional: parfor    
        
    %e.g.: %02d wont be properly read by TrakEM2 after >100 tiles
    temp_img = imread(fileNames_sorted{i});
    temp_img = temp_img(1:imgDim(1), 1:imgDim(2));

    %tile stats (1000 images 1000x1000 in 40 sec)
    %min, max, mean, median, mode, std
    tile_stats(i, :) = [
        min(temp_img, [], 'all'), ...
        max(temp_img, [], 'all'), ...
        mean(temp_img, 'all'), ....
        median(temp_img, 'all'), ...
        mode(temp_img, 'all'), ...
        std(double(temp_img), 0, 'all'), ... %0: n-1
        ]; 

    %tile allocation
    switch rescaleOption
        case 0
            temp_img1 = temp_img;
        
        case 1 %each tile channel            
            n_channels = size(temp_img, 3);
            temp_img_rescaled = zeros(imgDim(1), imgDim(2), n_channels);

            for ii = 1:n_channels
                Im16 = temp_img(:, :, ii);
                dbIm16 = double(Im16)+1;
                db16min = min(dbIm16(:)); 
                db16max = max(dbIm16(:));
        
                % Scales linearly to full range (ImageJ style)
                Norm_woOffSet = (dbIm16 - db16min)/(db16max - db16min); 
                temp_img_rescaled(:, :, ii) = Norm_woOffSet*2^targetBit-1; % back to 0:2^8-1    
            end          
            temp_img1 = uint8(temp_img_rescaled);        
    end
    
    switch saveOption
        case 1
            imwrite(temp_img1, filePaths_renamed, 'compression', 'none');

    end    
    disp(num2str(i))

end

end