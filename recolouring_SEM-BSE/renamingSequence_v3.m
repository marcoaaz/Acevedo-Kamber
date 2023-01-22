%% Root folder (channels)
clc
clear

rootFolder = 'E:\Alienware_March 22\current work\data_DMurphy\91690-81r5w-glass-overview\BSE\shading_corrected';
sample = ''; %type
destination = 'result2';

parentDir = fullfile(rootFolder, sample);
destDir = fullfile(parentDir, destination);
mkdir(destDir)

cd(parentDir);
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsFolder2 = 'E:\Alienware_March 22\current work\00-new code May_22';

addpath(scriptsFolder);
addpath(fullfile(scriptsFolder, '\bfmatlab')) %bio-formats 
addpath(fullfile(scriptsFolder, '\distCorr code'))
addpath(scriptsFolder2);
addpath(fullfile(scriptsFolder2, 'rayTracing/'));

%% Montage configuration

% source = 'renamed';
% 
% parentDir = fullfile(rootFolder, sample);
% sourceDir = fullfile(parentDir, source);
% mkdir(sourceDir)
% cd(parentDir);

dim = [42, 18]; %e.g.: [rows, cols]; [3, 3]; [6, 5]; [15, 19]

fprintf('Reference grid sequence:\n')
[referenceGrid, ~] = gridNumberer(dim, 1, 1); %Type, Order
%e.g.: 'column-by-column'=2; 'down & right'=1
%e.g.: 'row-by-row'=1; 'right & down'=1
%e.g.: 'snake-by-rows'; 'right & down'

fprintf('Desired grid sequence:\n')
[desiredGrid, ~] = gridNumberer(dim, 1, 1); %preferred by TrakEM2
%Type: row-by-row; Order: right & down

[fileNames] = GetFileNames(parentDir, '.tif'); 
% name_pattern = 'Tile_\d*_\d*.tif'; %(edit manually)
name_pattern = 'tile_\d*.tif'; %(edit manually)

fileNames2 = regexp(fileNames, name_pattern, 'match');
fileNames3 = string(fileNames2(~any(cellfun('isempty', fileNames2), 1)));
%e.g.: 
%'Image%3f.tif'
%'TileScan_003--stage%2f.tif';        
%'TileScan_001--Stage%3d.tif'
%'tile_x%3d_y%3d.tif'
%'TileScan_001--Stage00.tif'
%'PPL_%dof9.tif'
%'XPL\d*_of_9.tif'
%'tile_\d*.tif'

%sort numerically (ascending order) --> preventing step
q0 = regexp(fileNames3,'\d*','match'); 
q1 = str2double(cat(1, q0{:}));

%edit manually (if 2 or more values involved)
[q1_index, ii] = sortrows(q1, [1]); %between [] we tell if ascending (+)
% [q1_index, ii] = sortrows(q1, [1, 2]);

fileNames_sorted = fileNames3(ii); %cell
n_images = length(fileNames_sorted);

%% Saving renamed

tic;

rescaleOption = 0;
TgBit = 8; % or any other lower bit scale
format = '.tif';
tile_stats = zeros(n_images, 6);
for i = 1:n_images %parfor
    temp_position = find(referenceGrid == i);
    position = desiredGrid(temp_position);
        
    %e.g.: %02d wont be properly read by TrakEM2 after >100 tiles
    temp_img = imread(fileNames_sorted{i});
    
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
            dim_yx = size(temp_img, [1, 2]);
            n_channels = size(temp_img, 3);
            temp_img_rescaled = zeros(dim_yx(1), dim_yx(2), n_channels);
            for ii = 1:n_channels
                Im16 = temp_img(:, :, ii);
                dbIm16 = double(Im16)+1;
                db16min = min(dbIm16(:)); 
                db16max = max(dbIm16(:));
        
                % Scales linearly to full range (ImageJ style)
                Norm_woOffSet = (dbIm16-db16min)/(db16max-db16min); 
                temp_img_rescaled(:, :, ii) = Norm_woOffSet*2^TgBit-1; % back to 0:2^8-1    
            end
            temp_img1 = uint8(temp_img_rescaled);
        
    end

    %New naming sequence (edit)
    tileName = strcat('tile_', sprintf('%04d', position), format);
%     tileName = strcat('tile_', sprintf('%03d', position), format);

    %Save tiles
    imwrite(temp_img1, fullfile(destDir, tileName), 'compression', 'none');

    disp(num2str(i))
end

%mosaic statistics
n_rows = size(temp_img, 1);
n_cols = size(temp_img, 2);
n_pixels = n_images*n_rows*n_cols;
mosaic_min = min(tile_stats(:, 1));
mosaic_max = max(tile_stats(:, 2));
mosaic_mean = mean(tile_stats(:, 3));
[N, edges] = histcounts(tile_stats(:, 4), 256);
[M, I] = max(N);
mosaic_mode = (edges(I) + edges(I+1))/2;
mosaic_std = sqrt(sum(tile_stats(:, 5).^2));

mosaicInfo.n_rows = n_rows;
mosaicInfo.n_cols = n_cols;
mosaicInfo.n_pixels = n_pixels;
mosaicInfo.mosaic_min = mosaic_min;
mosaicInfo.mosaic_max = mosaic_max;
mosaicInfo.mosaic_mean = mosaic_mean;
mosaicInfo.mosaic_mode = mosaic_mode;
mosaicInfo.mosaic_std = mosaic_std;
save(fullfile(destination, 'mosaicInfo.mat'), "mosaicInfo", '-v7.3');

t = toc;

%% Stack histogram

% TH_bottom = mosaic_min; %edit manually
% TH_top = mosaic_max;
TH_bottom = 700; %edit manually, bottom = 0; default= 700
TH_top = 63000; %top = 65535; default= 63000
n_bins = 256;

mosaic_min_range = max(TH_bottom, mosaic_min); %script
mosaic_max_range = min(TH_top, mosaic_max);
range = mosaic_max_range - mosaic_min_range;
bin_width = range/n_bins;

tic;

mosaic_edges = zeros(1, n_bins+1);
mosaic_edges(1) = mosaic_min_range;
for j = 1:n_bins
    mosaic_edges(j+1) = mosaic_edges(j) + bin_width;
end

%calculate counts
tile_counts = zeros(n_images, n_bins);
for i = 1:n_images %parfor
    temp_position = find(referenceGrid == i);
    position = desiredGrid(temp_position);
        
    temp_img = imread(fileNames_sorted{i});
    temp_img(temp_img < mosaic_edges(1)) = mosaic_edges(1);
    temp_img(temp_img > mosaic_edges(end)) = mosaic_edges(end);

    tile_counts(i, :) = histcounts(temp_img(:), mosaic_edges);    
    disp(num2str(i))
end
mosaic_counts = sum(tile_counts, 1);
mosaic_counts_posi = mosaic_counts;
mosaic_counts_posi = mosaic_counts_posi + 1; %prevent -Inf
mosaic_counts_log = log(mosaic_counts_posi);

m_c_log_rescaled = (mosaic_counts_log-min(mosaic_counts_log))*(max(mosaic_counts_posi)-min(mosaic_counts_posi))/(...
    max(mosaic_counts_log)-min(mosaic_counts_log));

t2 = toc;

%% Histogram
close all

%multi-level TH
N = 3;
histoCounts = m_c_log_rescaled; %m_c_log_rescaled, mosaic_counts
histoStructure.mosaic_min = mosaic_min_range;
histoStructure.mosaic_max = mosaic_max_range;
[thresh_h, metric_h] = multiTH_extract(histoCounts, N, histoStructure);

hFig = figure;
hFig.Position = [100, 100, 1200, 600];

h1 = histogram('BinEdges', mosaic_edges, 'BinCounts', m_c_log_rescaled, ...
    'FaceAlpha', 0.5, 'FaceColor', [0.5, 0.5, 0], 'EdgeColor', 'none');
hold on
h2 = histogram('BinEdges', mosaic_edges, 'BinCounts', mosaic_counts, ...
    'FaceAlpha', 1, 'FaceColor', [0, 0, 0], 'EdgeColor', 'none');

yLimits = get(gca, 'YLim');  % Get the range of the y axis
xLimits = get(gca, 'XLim');
deltaX = (xLimits(2) - xLimits(1))/80;
hold on

for i = thresh_h    
    h3 = line([i, i], yLimits, 'LineWidth', 1, 'Color', 'r','LineStyle','--');
    % h3 = xline(thresh, '-b', 'LineWidth', 4);
    text_rotated = text(i - deltaX, yLimits(2)/2, num2str(round(i)), 'Color', 'b', 'Rotation', 90);
end
hold off
title(sprintf('Mosaic intensities, Multi-Outsu N= %d', N))
ylabel('Counts & Log-counts (normalized)')
xlabel(sprintf('Intensity, bin width= %.1f (16-bits)', bin_width))

%% Forming RGB scroll

destination2 = 'rgb';
destDir2 = fullfile(destDir, destination2);
mkdir(destDir2)

figure_frame = getframe(gcf);
fulldest = fullfile(destDir2, 'mosaicIntensities_log.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none')

%edit manually
% th_manual = thresh_h; %for hyper-spectral
th_manual = [13200, 16552]; %for final montage RGB

th_edges = [mosaic_edges(1) th_manual-1 mosaic_edges(end)];
n_channels = length(th_manual) + 1;
split_parameters = zeros(n_channels, 5);
for m = 1:n_channels
    split_parameters(m, 1) = th_edges(m);
    split_parameters(m, 2) = th_edges(m+1);
    range_temp = th_edges(m + 1) - th_edges(m); 
    split_parameters(m, 3) = range_temp;
    split_parameters(m, 4) = 255/range_temp;
    split_parameters(m, 5) = range_temp/256;
end

split_table = array2table(split_parameters);
split_table.Properties.VariableNames = {'From', 'To', 'Range', 'multiplyFactor', 'binWidth'};
writetable(split_table, fullfile(destDir2, 'splitTable.xlsx'));

%% Saving tiles

for i = 1:n_images %parfor n_images
    temp_position = find(referenceGrid == i);
    position = desiredGrid(temp_position);
        
    temp_img = imread(fileNames_sorted{i});
    temp_img(temp_img < mosaic_edges(1)) = mosaic_edges(1);
    temp_img(temp_img > mosaic_edges(end)) = mosaic_edges(end);
    
    temp_24bit = zeros(n_rows, n_cols, n_channels, 'uint8');
    for j= 1:n_channels
        channel_temp = double(temp_img);
        channel_mask_down = temp_img < split_parameters(j, 1);
        channel_mask_up = temp_img > split_parameters(j, 2);
        
        channel_rescaled = (channel_temp - split_parameters(j, 1))*split_parameters(j, 4);
        channel_rescaled(channel_mask_down) = 0;
        channel_rescaled(channel_mask_up) = 0;
        temp_24bit(:, :, j) = uint8(channel_rescaled);
    end
    
    %New naming sequence (edit)
    tileName = strcat('tile_', sprintf('%04d', position), format);
%     tileName = strcat('tile_', sprintf('%03d', position), format);

    %Save tiles
    imwrite(temp_24bit, fullfile(destDir2, tileName), 'compression', 'none');

    disp(num2str(i))
end
%the pipeline continues in TrakEM2 for montaging RGB tiles

%%
close all
figure,
% histogram(temp_24bit(:, :, 3))
imshow(temp_24bit)
