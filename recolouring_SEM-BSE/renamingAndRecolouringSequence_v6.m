%% Root folder (channels)
clc
clear

rootFolder = 'E:\Alienware_March 22\current work\rodrigo work\32';
sample = ''; %type
destination = 'result_V1';

parentDir = fullfile(rootFolder, sample);
destDir = fullfile(parentDir, destination);
mkdir(destDir)

cd(parentDir);
scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsFolder2 = 'E:\Alienware_March 22\current work\00-new code May_22';

addpath(scriptsFolder);
addpath(fullfile(scriptsFolder, '\bfmatlab')) %bio-formats 
addpath(fullfile(scriptsFolder, '\distCorr'))
addpath(fullfile(scriptsFolder, '\distCorr\montageInteractive\'))
addpath(scriptsFolder2);
addpath(fullfile(scriptsFolder2, '\rayTracing'));

%Saving directory
destination2 = 'rgb_debug';
destDir2 = fullfile(destDir, destination2);
mkdir(destDir2)

% source = 'renamed';
% 
% parentDir = fullfile(rootFolder, sample);
% sourceDir = fullfile(parentDir, source);
% mkdir(sourceDir)
% cd(parentDir);

%Notes:
%gridNumberer(dim_tiles, sel_type, sel_order)
%e.g.: 'column-by-column'=2; 'down & right'=1
%e.g.: 'row-by-row'=1; 'right & down'=1
%e.g.: 'snake-by-rows'=3; 'right & down'=1
%1,1 preferred by TrakEM2

%e.g.: 
%'Image%3f.tif'
%'TileScan_003--stage%2f.tif';        
%'TileScan_001--Stage%3d.tif'
%'tile_x%3d_y%3d.tif'
%'TileScan_001--Stage00.tif'
%'PPL_%dof9.tif'
%'XPL\d*_of_9.tif'
%'tile_\d*.tif'
%'#1_\d*_\d*.tif';
%'Tile_\d*_\d*.tif';

%% Understand Montage configuration

dim = [16, 7]; %e.g.: [rows, cols]; interpreting montage

rescaleOption = 0; %yes/no (keep original bitdepth)
targetBit = 8; % or any other lower bit scale
saveOption = 0; %optional: tile saving not useful for recolouring
n_bins = 256; %default= 8-bit; histogram intervals

%Tiling sequence
fprintf('Reference grid sequence:\n')
[referenceGrid, ~] = gridNumberer(dim, 2, 1); %Type, Order

fprintf('Desired grid sequence:\n')
[desiredGrid, ~] = gridNumberer(dim, 1, 1); 

%Tile naming
[fileNames] = GetFileNames(parentDir, '.tif'); 
name_pattern = '#1_\d*_\d*.tif'; %(edit manually)
fileNames2 = regexp(fileNames, name_pattern, 'match');
fileNames3 = string(fileNames2(~any(cellfun('isempty', fileNames2), 1)));

%sort numerically (ascending order) --> preventing step
q0 = regexp(fileNames3, '\d*', 'match'); 
q1 = str2double(cat(1, q0{:}));
%Example: q0 = regexp(fileNames3, '\d*', 'match'); 

%edit manually
%[q1_index, ii] = sortrows(q1, [1]); 
[q1_index, ii] = sortrows(q1, [2, 3]); 
%[]: select the columns with the parsed numeric values for sorting
%between [] we can tell if it is ascending (+)

fileNames_sorted = fileNames3(ii); %input file names

position_ind = desiredGrid(referenceGrid(:));
tileNames = sprintf('tile_%04d.tif,', position_ind);
%e.g.: %02d wont be properly read by TrakEM2 after >100 tiles
tileNames1 = strsplit(tileNames, ',');
fileNames_renamed = tileNames1(1:end-1);

%info
n_images = length(fileNames_sorted);
temp_info = imfinfo(fileNames_sorted{1});
n_rows = temp_info.Height;
n_cols = temp_info.Width;
% n_rows = 1024;
% n_cols = 1024;
imgDim = [n_rows, n_cols];
%medicine: if image comes with burned scale or legend

%Begin storing info
mosaicInfo.fileNames_sorted = fileNames_sorted; %reside in parentDir
mosaicInfo.fileNames_renamed = fileNames_renamed;
mosaicInfo.n_images = n_images;
mosaicInfo.imgDim = imgDim;
mosaicInfo.mosaicDim = dim;
mosaicInfo.referenceGrid = referenceGrid;
mosaicInfo.desiredGrid = desiredGrid;

%Tile stats (mandatory)
tic;

filePaths_renamed = fullfile(destDir, fileNames_renamed);

[tile_stats] = montageSavedRenamedTiles(mosaicInfo, ...
    targetBit, rescaleOption, saveOption, filePaths_renamed);

[N, edges] = histcounts(tile_stats(:, 4), 256);
[M, I] = max(N);
mosaic_mode = (edges(I) + edges(I+1))/2;

%Continue storing
mosaicInfo.mosaic_min = min(tile_stats(:, 1));
mosaicInfo.mosaic_max = max(tile_stats(:, 2));
mosaicInfo.mosaic_mean = mean(tile_stats(:, 3));
mosaicInfo.mosaic_mode = mosaic_mode;
mosaicInfo.mosaic_std = sqrt(sum(tile_stats(:, 5).^2));

save(fullfile(destination, 'mosaicInfo.mat'), "mosaicInfo", '-v7.3');

t.tileStats = toc;

%% Stacking tile histograms

%8-bit: [0, 255], 16-bit: [0, 65535]
TH_array = [0, 65535]; % default=[mosaic_min, mosaic_max]

tic;

[mosaic_edges, mosaic_counts, mosaic_counts_log] = ...
    montageHistogramStacking(mosaicInfo, TH_array, n_bins);

t.tileHistogram = toc;

%% Forming RGB scroll
close all force

%Multi-level TH: Automatic suggestion from log-scaled histogram
N = 3; %requested thresholds
[thresh_h, metric_h] = multiTH_extract(mosaic_counts_log, N, mosaic_edges);

%Histogram and suggested thresholds
montageLogHistogram(mosaic_edges, mosaic_counts, mosaic_counts_log, thresh_h, destDir2)

%8-bit: [0, 255], 16-bit: [0, 65535]
th_split = [28004, 46800]; %manual for BSE; =thresh_h for hyperspectral
[split_parameters] = montageSplitTH(mosaic_edges, th_split, destDir2);

% %%Single tile check-up
% sel_image = floor((mosaicInfo.n_images)/2) + 11;
% filterSize = 5;
% [img_med] = recolouredTile(sel_image, mosaicInfo, mosaic_edges, ...
%     split_parameters, filterSize, destDir2);

% th_manual = [12904, 13500]; %manual for BSE; =thresh_h %for hyperspectral
tileColourCheck(mosaicInfo, mosaic_edges, split_parameters, th_split)

%% Saving mosaic tiles

filterSize = tunnedParameters.filterSize;
split_parameters = tunnedParameters.split_parameters;

split_table = array2table(split_parameters);
split_table.Properties.VariableNames = {'From', 'To', 'Range', 'multiplyFactor', 'binWidth'};

tunnedParameters.split_table = split_table;
save(fullfile(destDir2, 'recolouringMetadata.mat'), "tunnedParameters")

tic;
montageSaveRecolouredTiles(mosaicInfo, mosaic_edges, split_parameters, filterSize, destDir2);
t.tileRecolouredSave = toc;

t
%the pipeline continues in TrakEM2 for montaging RGB tiles
