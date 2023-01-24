%% Root folder
clear 
clc

scriptDir = 'E:\Alienware_March 22\current work\00-new code May_22\AZtec_phaseMap';
sourceDir = 'E:\Alienware_March 22\current work\Rob_export\6KB63_phase map\6KB63_BT3_GL6';
workingDir = fullfile(sourceDir, 'pointGrid');
cd(workingDir)
addpath(scriptDir)

%Question: how to retrieve the BigWarp transform matrices

fileName = 'phase_map_labeled.tif';
aztecMap_original = fullfile(sourceDir, fileName);

%% Import map

%labels
rasterMap = imread(aztecMap_original);
rasterVector = rasterMap(:);
[n_rows, n_cols] = size(rasterMap);
n_pixels = n_rows*n_cols;

%time for 56 M; unknown (probably 4 hrs 30 min)
%time for 1M; 5min

%filter out background
idx_zero = rasterMap == 0;
idx_zero = idx_zero(:);
rasterVector = rasterVector(~idx_zero);
bottom_pixel = 1;
top_pixel = sum(~idx_zero);
% bottom_pixel = 5000;
% top_pixel = bottom_pixel+1000000; %n_pixels

%coordinates
[row_idx, col_idx] = ind2sub([n_rows, n_cols], 1:n_pixels); %colum-major
z_values = ones(n_pixels, 1); %not if 2D
% pos_mtx = [col_idx', row_idx', z_values];
pos_mtx = [col_idx', row_idx'];
pos_mtx = pos_mtx(~idx_zero, :);

%subsetting for computational cost
pos_mtx1 = pos_mtx(bottom_pixel:top_pixel, :);
rasterVector1 = rasterVector(bottom_pixel:top_pixel);
n_pixels_sel = length(rasterVector1);

%% Run Once..
fileName = 'pointGrid_full.csv';
writematrix(pos_mtx1, fileName, 'Delimiter', ',') %Use BigWarp macro script

%% Adapting information (QuPath)

fileName_transformed = 'full_grid.csv'; %edit

informativeTable = fullfile(sourceDir, 'mineralTable_8813x6402.xlsx');
mergedTable = readtable(informativeTable, 'Sheet', 'Minerals');
tripletTable = readtable(informativeTable, 'Sheet', 'Triplet');
tripletMtx = tripletTable{:, :}; %RGB (for learned quPath classes)

label_name = mergedTable.Mineral;
label_number = mergedTable.Label;
n_labels = length(label_number);

label_str = strings([n_pixels_sel, 1]);
for i = 1:n_labels
    idx_temp = (rasterVector1 == label_number(i)); %modify 
    label_str(idx_temp) = label_name(i);
end

columnNames = {'x', 'y', 'class'};
transformedXY = readmatrix(fileName_transformed);

%manual test (uncomment)
% n_points = size(transformedXY, 1);
% label_str = repmat('fonny', [n_points, 1]);

%Translation
%QuPath import differs when dealing with the RGB map vs grid
% tform_translation = eye(3, 3);
tform_translation = [1, 0, 0;
    0, 1, 0;
    4.415, 4.235, 1];

%Upscaling to pyramid Level-0
s = 2; %=2 for Level-1 reference
tform_scale = [s, 0, 0;
    0, s, 0;
    0, 0, 1];

tform = affine2d(tform_translation*tform_scale);

u = transformedXY(:, 1);
v = transformedXY(:, 2);
[x, y] = transformPointsForward(tform, u, v);
quPath_points = table(x, y, label_str, 'VariableNames', columnNames);

%Saving
fileName3 = 'quPath_grid_upscaled.csv';
fileName4 = strrep(fileName3, '.csv', '.tsv');
fileDest = fullfile(workingDir, fileName3); %change by *.tsv 
writecell(columnNames, fileDest, "WriteMode", 'append', 'Delimiter', 'tab')
writetable(quPath_points, fileDest, 'WriteMode', 'append', 'Delimiter', 'tab')
%reformatting
delete(fileName4) %
status = copyfile(fileName3, fullfile(workingDir, fileName4));
delete(fileName3)

%% failed

%requires pixel sizes to be far more accurate
aztecMap1 = 'ROTATED_phase_map_labeled.tif channel 1_phase_map_labeled.tif channel 1_xfm_0.tif';
pixelSize = 4.140625; %microns/px ; see AZtec project metadata
target_pixelSize = 0.5474796199354856; %microns/px ; see *.vsi metadata
scaleFactor = pixelSize/target_pixelSize;

aztecMap2 = 'phase_map_labeled.tif channel 1_phase_map_labeled.tif channel 1_xfm_0.tif';
rasterMap = imread(aztecMap2);
rasterMap_originalresize(rasterMap, 0.5, 'nearest'); %requires know scale

%%
close all

classes = unique(rasterMap);
n_classes = length(classes);
cmap = jet(n_classes);
s = rng; %1,'philox'  specify seed and algorithm
% rng(s)
cmap_new = cmap(randperm(n_classes), :);
rasterMap_rgb = label2rgb(rasterMap, cmap_new, 'k');

figure
imshow(rasterMap_rgb)
hold on
plot(1:1000, 1:1000, '.r', 'MarkerSize', 6)