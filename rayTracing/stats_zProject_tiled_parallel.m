function [time_elapsed] = stats_zProject_tiled_parallel(sourceDir, pos_new1, montage_dim, stats_mode, destFolder)
tic;

pixel_type = 'uint8';
im_height = pos_new1.Height; 
im_width = pos_new1.Width;
im_channels = pos_new1.Channels;
tileNames = pos_new1.tileName;

try 
    pca_montage = montage_dim.pca_montage;
    U = pca_montage.U;
    U = U(:, 1:3); %for RGB
    mu = pca_montage.mu;   
catch
    disp('Missing PCA-Coefficient matrix for variables.')
end
n_tile_layers = montage_dim.n_tile_layers;
n_zStacks = montage_dim.n_zStacks;

M = 2; %number of workers, total=8 with 16 threads (logical processors)
%Note: monitor that there is not RAM overload to reduce M.
parfor (i = 1:n_zStacks, M)
    img_stats = []; %clearing (runtime error)
    img_stats_index = []; 
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
    
    %Maths following Fiji>Stack>Z-project
    switch stats_mode
        case 'mean' %double
            img_stats = mean(temp_mtx, 4);%requires uint()    
            
        case 'max' %uint8
            [max_temp, max_index] = max(temp_mtx, [], 4); 
            img_stats = max_temp;
            img_stats_index = max_index;

        case 'min' %uint8
            [min_temp, min_index] = min(temp_mtx, [], 4);
            img_stats = min_temp;
            img_stats_index = min_index;
        case 'sum' %double
            img_stats = sum(temp_mtx, 4); 

        case 'std' %double
            img_stats = std(single(temp_mtx), 0, 4); %RAM issue:to single, double

        case 'median' %uint8
            img_stats = median(temp_mtx, 4); 

        case 'pca'           
            X = double(transpose(reshape(temp_mtx, [], temp_channels*n_tile_layers)));            
            X_demean = X - mu;
            score_3pc = X_demean'*U;
            
            pc1 = reshape(score_3pc(:, 1), temp_height, temp_width); %R
            pc2 = reshape(score_3pc(:, 2), temp_height, temp_width); %G
            pc3 = reshape(score_3pc(:, 3), temp_height, temp_width); %B
            img_stats = cat(3, pc1, pc2, pc3);
    end
    check = size(img_stats_index, 1) > 0; %if matrix

    %Saving  
    destTileName = strcat(stats_mode, '_', tileName);
    fullFileName = fullfile(destFolder, destTileName);
    %for max/min linear index
    destTileName_index = strcat(stats_mode, 'Index_', tileName);
    fullFileName_index = fullfile(destFolder, destTileName_index);

    if sum(ismember({'sum', 'std', 'pca'}, stats_mode))

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
        img_stats = uint8(img_stats);        
        imwrite(img_stats, fullFileName, 'compression', 'none')
        %for max/min
        if check %in transparent workspace
            img_stats_index = uint8(img_stats_index); %<256 steps
            imwrite(img_stats_index, fullFileName_index, 'compression', 'none')
        end
       
    end
    
%     clear img_stats img_stats2
    fprintf('tile #: %d, stat: %s \n', i, stats_mode)
end
fprintf('%s completed.\n', stats_mode)

time_elapsed = toc;
end