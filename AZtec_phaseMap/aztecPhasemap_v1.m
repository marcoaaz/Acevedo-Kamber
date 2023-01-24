%This script construct the phase map from manually exported spectral
%segmentation masks in AZtec v3.3 software (Oxford Instruments)
%Author: Marco A. Acevedo Zamora
%% Root folder (channels)
clear
clc

rootFolder = 'E:\Alienware_March 22\current work\Rob_export\robert samples\xenolith 18-rbe-006h\';
sourceName = 'phase map_bf1';
sourceDir = fullfile(rootFolder, sourceName);
cd(rootFolder)

sampleName = ['18-RBE-006h', '_', sourceName];
destinationDir = fullfile(rootFolder, sampleName);
mkdir(destinationDir);

scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsMarco2 = 'E:\Alienware_March 22\current work\00-new code May_22';
addpath(scriptsMarco);
addpath(fullfile(scriptsMarco, 'quPath bridge'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'rgb'));
addpath(fullfile(scriptsMarco, 'plots_miscellaneous'));

%Search files
[keySet1] = GetFileNames(sourceDir, '.tif'); 
[keySet2] = GetFileNames(sourceDir, '.tiff'); 
keySet = string([keySet1, keySet2]);

%Files to exclude: if layer is missaligned or not required
null_idx1 = strcmp(keySet, 'bse montage.tiff'); 
null_idx2 = strcmp(keySet, 'Unassigned pixels.tif'); %garbage
null_idx3 = strcmp(keySet, 'phase image_dataOnly.tif'); 
% null_idx4 = strcmp(keySet, '2 SiAlO.tif'); %missaligned
null_idx = null_idx1 | null_idx2 | null_idx3;

keySet_filtered = keySet(~null_idx);
n_images = length(keySet_filtered);
keySet_filtered'

%% Understanding phase map: run only the first time

population = zeros(n_images, 1);
for i = 1:n_images
    fileName = fullfile(sourceDir, keySet_filtered{i});
    temp_img = imread(fileName);
    temp_mask = (temp_img(:, :, 1) > 0) ...
        | (temp_img(:, :, 2) > 0) ...
        | (temp_img(:, :, 3) > 0);

    population(i) = sum(temp_mask, "all");
end
n_rows = size(temp_mask, 1);
n_cols = size(temp_mask, 2);

mineralTable = table(keySet_filtered', population, ...
    'variableNames', {'Mineral', 'Pixels'});

%Parsing AZtec phase labeling 
clear tokenNames
expression1 = ['(?<aztecNumber>\d+)\s(?<elementList>[a-zA-Z]*).tif(f)?'];
tokenNames = regexp(keySet_filtered, expression1, 'names');
n_images = length(tokenNames);

clear struct_empty 
struct_empty.aztecNumber = ""; 
struct_empty.elementList = ""; 
for j = 1:n_images
    test = length(tokenNames{j});
    if test == 0        
        tokenNames{j} = struct_empty;        
    end
end
struct_temp = [tokenNames{[1:end]}];
table_temp = struct2table(struct_temp); %tile location info

mineralTable = horzcat(mineralTable, table_temp);
mineralTable = sortrows(mineralTable, 'Pixels', 'descend');
mineralTable = addvars(mineralTable, [1:n_images]', 'NewVariableNames', 'Label');

fileName = ['mineralTable_', sprintf('%dx%d', n_cols, n_rows), '.xlsx'];
writetable(mineralTable, fullfile(destinationDir, fileName), 'Sheet', 'Masks', 'WriteMode','overwritesheet')

%% Merging phases (user input)

%exporting convention (required)
expression = '(?<Mineral>\w+):';
expression_layers = '\s(?<layer>.+)(,)?(\n)?';
expression_phaseMask = '(?<phaseMask>.+).tif(f)?';

%edit manually
str2 = fullfile(sourceDir, 'mineralList.txt');

S = fileread(str2);
end_idx = regexp(S, '=', 'end');
from = end_idx(end)+1;
S_cell = strsplit(S(from:end), '\n');
n_items = length(S_cell);

mineralTable.Route = mineralTable.Mineral;
phaseMask_text = mineralTable.Mineral; %comparisson
temp1 = regexp(phaseMask_text, expression_phaseMask, 'names');
temp2 = struct2table([temp1{[1:end]}]);
phaseMask_text = temp2.phaseMask;

colNames = mineralTable.Properties.VariableNames;
merged_table = mineralTable;
merged_table(:,:) = []; %create empty copy

itemStruct = regexp(S_cell, expression, 'names');

route_cell = cell(0); %pre-allocating
idx_repeated = false(size(mineralTable, 1), 1);
for k = 1:n_items %1:n_items
    test = length(itemStruct{k});
    if test == 1        
        mineralName = itemStruct{k}.Mineral;
        text = S_cell{k};
        textStruct = regexp(text, expression_layers, 'names');
        textList = strsplit(textStruct.layer, {', '});
        textList = strtrim(textList); %delete newline

        %searching data
        idx_sum = ismember(phaseMask_text, textList);
        idx_repeated = idx_repeated | idx_sum;
        temp_routes = strjoin(mineralTable.Mineral(idx_sum), ', ');        
        
        %modifying
        pixel_sum = sum(mineralTable.Pixels(idx_sum));
        temp_table = cell2table({mineralName, pixel_sum, 'merged', 'merged', 0, temp_routes});
        temp_table.Properties.VariableNames = colNames;

        merged_table = vertcat(merged_table, temp_table);
    end
end
mineralTable2 = vertcat(mineralTable(~idx_repeated, :), merged_table);
mineralTable2 = sortrows(mineralTable2, 'Pixels', 'descend');
mineralTable2.Label = [1:size(mineralTable2, 1)]';

writetable(mineralTable2, fullfile(destinationDir, fileName), 'Sheet', 'Minerals', 'WriteMode','overwritesheet')

%% Building new phasemap

%Reload from previous run
fileName = 'mineralTable_9680x6927.xlsx';
mineralTable2 = readtable(fullfile(destinationDir, fileName), 'Sheet', 'Minerals');
n_minerals = size(mineralTable2, 1);

%Process
tableFile = GetFileNames(fullfile(destinationDir), '.xlsx');
found_dim = regexp(tableFile, '_(?<n_col>\d+)x(?<n_row>\d+)', 'names');
dim_temp = [found_dim{[1:end]}];
n_rows = str2double(dim_temp.n_row);
n_cols = str2double(dim_temp.n_col);

phase_map = zeros(n_rows, n_cols, 'uint8');
for m = 1:n_minerals
    imageFiles = mineralTable2.Route(m);
    imageStr = strsplit(string(imageFiles), ', '); %ensure is not cell

    merged_mask = false([n_rows, n_cols]);
    for n = 1:length(imageStr)
        temp_img = imread(fullfile(sourceDir, imageStr(n)));
%         temp_mask = temp_img(:, :, 1) > 0;
        temp_mask = (temp_img(:, :, 1) > 0) ...
        | (temp_img(:, :, 2) > 0) ...
        | (temp_img(:, :, 3) > 0);

        merged_mask = merged_mask | temp_mask;
    end

    label = mineralTable2.Label(m);
    phase_map(merged_mask) = label;
end
imwrite(phase_map, fullfile(destinationDir, 'phase_map_labeled.tif'))

%% Plot
close all

%color
cmap = [lines(n_minerals); hsv(n_minerals)];
s = rng(34);
r= randperm(2*n_minerals);
cmap = cmap(r', :);
cmap = cmap(1:n_minerals, :);
triplet_table = array2table(cmap);
triplet_table.Properties.VariableNames = {'R', 'G', 'B'};
writetable(triplet_table, fullfile(destinationDir, fileName), 'Sheet', 'Triplet', 'WriteMode','overwritesheet')

% phase_map_rgb = label2rgb(phase_map, cmap, 'k'); %, 'k', 'shuffle'
% imwrite(phase_map_rgb, fullfile(destinationDir, 'phase_map_rgb.tif'))

population1 = mineralTable2.Pixels; 
minerals1 = mineralTable2.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = triplet_table{:, :};
n_masks1 = length(minerals1);

rot_angle = 180; %rotation angle
[PM_RGB] = phasemapCheck(phase_map, minerals1, triplet1, rot_angle, destinationDir);
plotLogHistogramH(population1, minerals1, triplet1, destinationDir)

