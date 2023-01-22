function [pca_montage, time_elapsed] = stats_zProject_tiled_pca(sourceDir, pos_new1, montage_dim, stats_mode, destFolder)

tic;

pixel_type = 'uint8';
n_tile_layers = montage_dim.n_tile_layers;
n_zStacks = montage_dim.n_zStacks;
im_height = pos_new1.Height; 
im_width = pos_new1.Width;
im_channels = pos_new1.Channels;

tileNames = pos_new1.tileName;
k = 0;
for i = 1:n_zStacks %n_zStacks
    img_stats = []; %clearing (runtime error)
    k = k + 1; %counter
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
  
    switch stats_mode
        case 'pca' %double
            mtx_long = double(transpose(reshape(temp_mtx, [], temp_channels*n_tile_layers)));
            if k == 1
                n_samples_seen = size(mtx_long, 2);
            %     n_samples = n_samples + n_samples_seen;
                mu = mean(mtx_long, 2);
                [U, S, ~] = svd(mtx_long - mu, 'econ');
                n_components = [];   
            end
        
            %PCA the incremental way:
            [U, S, mu, n_samples_seen] = incrementalPCA...
               (mtx_long, U, S, mu, n_samples_seen, n_components);            
        
    end
    
    %Saving  
    destTileName = strcat(stats_mode, '_', tileName);
    fullFileName = fullfile(destFolder, destTileName);

%     imwrite(img_stats, fullFileName, 'compression', 'none')
  
    fprintf('tile #: %d, stat: %s \n', i, stats_mode)
end
fprintf('%s completed.\n', stats_mode)

vect_max = max(S, [], 1);
vect_sum = vect_max/sum(S, 'all')*100;
energy_thresh = sum(vect_sum(1:3));

%Storing data
pca_montage.U = U; %PC's (columns)
pca_montage.S = S; %SVD diagonal (columns, sorted)
pca_montage.mu = mu; %mean, single column
pca_montage.n_samples_seen = n_samples_seen;
pca_montage.energy_thresh = energy_thresh;

time_elapsed = toc;

end