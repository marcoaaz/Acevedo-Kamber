function [time_elapsed, data_transferred] = stats_zProject_tiled_gpu(sourceDir, pos_new1, montage_dim, stats_mode, destFolder)

tic;
ticBytes(gcp);

pixel_type = 'uint8';
n_tile_layers = montage_dim.n_tile_layers;
n_zStacks = montage_dim.n_zStacks;
im_height = pos_new1.Height; 
im_width = pos_new1.Width;
im_channels = pos_new1.Channels;

tileNames = pos_new1.tileName;
M = 4; %8 max
parfor (i = 1:n_zStacks, M)
    img_stats_gpu = []; %clearing (runtime error)
    tileName = tileNames{i};

    %preallocating  
    temp_height = im_height(i);
    temp_width = im_width(i);
    temp_channels = im_channels(i);
    temp_mtx = zeros(temp_height, temp_width, temp_channels, n_tile_layers, pixel_type);
    for j = 1:n_tile_layers        
        temp_fileName = fullfile(sourceDir{j}, tileName);                
        
        img_temp = imread(temp_fileName);          
        temp_mtx(:, :, :, j) = img_temp;
    end        
    
    temp_mtx_gpu = gpuArray(temp_mtx);

    %Maths following Fiji>Stack>Z-project
    switch stats_mode
        case 'mean' %double
            img_stats_gpu = uint8(mean(temp_mtx_gpu, 4));    
        case 'max' %uint8
            [max_temp, ~] = max(temp_mtx_gpu, [], 4); 
            img_stats_gpu = max_temp;    
        case 'min' %uint8
            [min_temp, ~] = min(temp_mtx_gpu, [], 4);
            img_stats_gpu = min_temp;
        case 'sum' %double
            img_stats_gpu = sum(temp_mtx_gpu, 4); %to single
        case 'std' %double
            img_stats_gpu = std(single(temp_mtx_gpu), 0, 4); %to single
        case 'median' %uint8
            img_stats_gpu = median(temp_mtx_gpu, 4); 
    end
    img_stats = gather(img_stats_gpu);

    %Saving  
    destTileName = strcat(stats_mode, '_', tileName);
    fullFileName = fullfile(destFolder, destTileName);

    if sum(ismember({'sum', 'std'}, stats_mode))

        img_stats2 = single(img_stats); %changing format
        
        %Configure file saving
        t = Tiff(fullFileName, 'w');
        tagstruct = [];
        tagstruct.Photometric = Tiff.Photometric.RGB;
        tagstruct.BitsPerSample = 32;
        tagstruct.SamplesPerPixel = 3;
        tagstruct.SampleFormat = 3;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tagstruct.Software = 'MATLAB';        
        tagstruct.ImageLength = temp_height;
        tagstruct.ImageWidth = temp_width; 
            
        setTag(t, tagstruct)
        write(t, img_stats2);
        close(t);    
    else
        imwrite(img_stats, fullFileName, 'compression', 'none')
    end
    
%     clear img_stats img_stats2
    fprintf('tile #: %d, stat: %s \n', i, stats_mode)
end
fprintf('%s completed.\n', stats_mode)

data_transferred = ticBytes(gcp);
time_elapsed = toc;

end