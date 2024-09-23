%qupathPhaseMap_v9_simplified.m

%Script to build a phase map from a QuPath project that contains a trained
%pixel classifier and corresponding Prediction image (ome.tif output).

%Created: 20-Aug-24, Marco Acevedo

%% Root folder (channels)

close all
clear
clc

scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsMarco2 = 'E:\Alienware_March 22\current work\00-new code May_22';
addpath(scriptsMarco);
addpath(fullfile(scriptsMarco, 'quPath bridge'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'external_package\rgb'));
addpath(fullfile(scriptsMarco, 'plots_miscellaneous'));
% addpath(fullfile(scriptsMarco2, 'hex_and_rgb_v1.1.1'));

%User input:

%QuPath project
rootFolder = 'E:\Teresa_article collab\qupath_project';
cd(rootFolder);

classifierName = '80W_trial5'; %*.ome.tif saved from QuPath
% classifierName = 'Marco5_RT_res2_scale1_features5_v2'; %comment: manual input

phasemap_inputName = strcat(classifierName, '.ome.tif');%default
% phasemap_inputName = 'Marco_13-jul-24_RT_res2_trial4_recoloured.ome.tif'; %comment: manual input

%Script begins
sampleName = strrep(phasemap_inputName, '.ome.tif', ''); %classifierName
destinationDir = fullfile(rootFolder, sampleName);
mkdir(destinationDir);

classifierFolder = fullfile(rootFolder, 'classifiers', 'pixel_classifiers');
addpath(classifierFolder)

%Importing
classifierFile = strcat(classifierName, '.json');

S = fileread(classifierFile); %Parse classifier metadata
outStruct = jsondecode(S);

%model input
inputChannels = struct2cell(outStruct.op.colorTransforms);
channelList = join(string(inputChannels), ', ');
n_channels = outStruct.metadata.inputNumChannels;
inputResolution = outStruct.metadata.inputResolution.pixelHeight.value; %x=y
tileWidth = outStruct.metadata.inputWidth; %x=y
pixelType = outStruct.op.op.ops{3, 1}.pixelType;

%feature maps
featureList = outStruct.op.op.ops{1, 1}.ops{1, 1}.ops.features;
featureList = join(string(featureList), ', ');

%expert annotations (name, colorRGB)
outputClassificationLabels = outStruct.metadata.outputChannels;
temp_table = struct2table(outputClassificationLabels);
n_labels = size(temp_table, 1);

%machine learning model
classifierType = outStruct.pixel_classifier_type;
trainedClassifier = outStruct.op.op.ops{2, 1}.model.class;

switch trainedClassifier
    case 'RTrees'
        %RT
        param_A = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.ntrees; %n_trees        
        param_B = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.training_params.max_depth; %max_depth
        outputLabels = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.class_labels;

    case 'ANN_MLP'
        %ANN
        param_A = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_ann_mlp.layer_sizes; %layerSizes
        param_A = join(string(param_A), ', ');
        param_B = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_ann_mlp.training_params.term_criteria.epsilon; %epsilon
        outputLabels = num2str([1:size(temp_table, 1)]' - 1); %not available in ANN
end
temp_table1 = addvars(temp_table, outputLabels, 'NewVariableNames', 'label'); %metadata

%QuPath classifier description
%note: initial "" avoids character conversion
summary_items = ["number of channels", 'channel names', 'resolution', 'tile width', 'bit depth', 'filters', ...
    'classifier type', 'classifier name', '# trees/layerSizes', 'maxDepth/epsilon']';
array_items = [n_channels, channelList, inputResolution, tileWidth, pixelType, featureList, ...
    classifierType, trainedClassifier, param_A, param_B]';
summary_table = table(summary_items, array_items, 'VariableNames', {'Item', 'Value'});

%Obtaining original colouring
%Documentation: https://levelup.gitconnected.com/how-to-convert-argb-integer-into-rgba-tuple-in-python-eeb851d65a88

dataType = 'int32';
a = int32(temp_table1.color);
B = bitand(a, 255, dataType);
G = bitand(bitsrl(a, 8), 255, dataType);
R = bitand(bitsrl(a, 16), 255, dataType);
alpha = bitand(bitsrl(a, 24), 255, dataType);
rgb_append = double([R, G, B, alpha]);
rgb_append = array2table(rgb_append);
rgb_append.Properties.VariableNames = {'R', 'G', 'B', 'alpha'};

label_table = horzcat(temp_table1, rgb_append);

fileName1 = fullfile(destinationDir, 'classifier_metadata.xlsx');

writetable(label_table, fileName1, 'Sheet', 'Labels')
writetable(summary_table, fileName1, 'Sheet', 'Summary')

%Reading Phase Map image pyramid (OME-TIFF)
data = bfopen(phasemap_inputName); %default
seriesCount = size(data, 1);
series1 = data{1, 1};
metadataList = data{1, 2};

series1_planeCount = size(series1, 1);
series1_plane1 = series1{1, 1}; %unmodified
series1_label1 = series1{1, 2};
series1_colorMap1 = data{1, 3}{1, 1};

original_labels = unique(series1_plane1) + 1; %for new mapping

%Map preview
% n_masks = size(series1_colorMap1, 1);%default
n_masks = n_labels;
population = zeros(1, n_masks);
for i = 1:n_masks   %1:n_masks  
       
    %calculate number of pixels
    temp_index = series1_plane1 == i-1; %QuPath convention
    population(i) = sum(temp_index, 'all');
end

minerals = label_table.name;
triplet = [label_table.R, label_table.G, label_table.B]/255;

format compact %displaying list
options = table(minerals, 'VariableNames', {'Mask'}, ...
    'RowNames', string(1:length(minerals)));
disp(options);

phasemap_original = series1_plane1 + 1; %adjusted for next section; quPath naming (-1)
n_rows_original = size(phasemap_original, 1);
n_cols_original = size(phasemap_original, 2);

%% Option 1: Fixing margin artifacts (Following annotations)

class_bg = {'Background'}; %edit this
%write only existing ones: {'epoxy', 'glass_polish', 'background'}

n_bg = length(class_bg);
adequate_test = sum(ismember(class_bg, minerals));
bg_mask = false(n_rows_original, n_cols_original);

bg_label = [];
if adequate_test > 0    
    
    for m = 1:n_bg
        bg_string1 = class_bg{m};
        temp_label = find(strcmp(minerals, bg_string1)); %depends on QuPath class names
        temp_mask = (phasemap_original == temp_label);
    
        bg_mask = bg_mask | temp_mask;
        bg_label = [bg_label, temp_label];
    end
    fg_mask = ~bg_mask; %default

    %3 options, edit manually (according to experiment outline)
    % section_mask = imfill(bwareafilt(~bg_mask, 1), 'holes'); %largest object
    % section_mask = imfill(bwareafilt(bg_mask, 2), 'holes'); %largest object
    
    % bg_mask_filled = imfill(bg_mask, 'holes'); %if there is a frame around the entire sample, it fails
    % fg_mask = ~bg_mask_filled;

    %last touch:    
    fg_mask_filled = imfill(bwareafilt(fg_mask, 2), 'holes');
    
    %Cropping (preliminary): use foreground
    [row, col] = ind2sub([n_rows_original, n_cols_original], find(fg_mask(:)));
    width_mask = max(col);
    height_mask = max(row);

    section_mask = fg_mask_filled(1:height_mask, 1:width_mask); %cropping
    phasemap = phasemap_original(1:height_mask, 1:width_mask); 

elseif adequate_test == 0
    
    section_mask = ~bg_mask;
    phasemap = phasemap_original;
end

phasemap(~section_mask) = 0; %apply mask

% Pre-check
close all
hFig = figure;
hFig.Position = [100, 100, 1400, 500];
subplot(1, 2, 1)
imshow(bg_mask)
title('bg-mask: Map fringes')
subplot(1, 2, 2)
imshow(section_mask)
title('section-mask: Map outline (manually edited)')

fileName_mask = 'sectionMask.tif';
imwrite(section_mask, fullfile(destinationDir, fileName_mask)); %useful outside the script

%% Ranking and filtering 

%Update variable mapping (QuPath --> PhaseMap script)
%rearranging QuPath phasemap by population ranking
% original_labels_b = [1:n_masks];
bg_index = ismember(original_labels, bg_label);

tablerank_0 = table(original_labels, minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});

tablerank = tablerank_0(~bg_index, :);
tablerank = sortrows(tablerank, 3, 'descend'); %rank by number of pixels
n_phases = size(tablerank, 1);
%from Option 2:
tablerank1 = tablerank;
tablerank1.NewLabel = (1:n_phases)';

%setdiff(original_labels', bg_label)
phasemap1 = phasemap; %preallocate
for i = 1:n_phases
    temp_original = tablerank1.Label(i);
    temp_new = tablerank1.NewLabel(i); %find ranking

    mask_phase = (phasemap == temp_original);    
    phasemap1(mask_phase) = temp_new;%re-labelling     
end

%saving stats
fileName2 = fullfile(destinationDir, 'species.xlsx');
writetable(tablerank1, fileName2, 'Sheet', 'phaseMap');

%saving Full labeled image
fileName3 = fullfile(destinationDir, 'phasemap_label_full.tif');
imwrite(uint8(phasemap1), fileName3);

%%Option 1: Variables for plots

tablerank1 = readtable(fileName2, 'Sheet', 'phaseMap');
population_original = tablerank1.Pixels; 
minerals_original = tablerank1.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet_original = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];
n_masks_original = length(minerals_original);

%Plot: phase map
%define the phases for plotting
minerals_original
mineral_targets = minerals_original; %default
% mineral_targets = {'Apatite'; 'Foram1'; 'Foram2'};

rot_angle = 0; %rotation angle
[PM_RGB] = phasemapCheck(phasemap1, minerals_original, triplet_original, mineral_targets, rot_angle, destinationDir);

% Plot (Option 1 or 2): modal mineralogy 

close all 

%Data for Modal mineralogy histograms
tablerank2 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap'); 
%Option 1= phaseMap; Option 2= phaseMap_renamed

population1 = tablerank2.Pixels; 
minerals1 = tablerank2.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];
n_masks1 = length(minerals1);
minerals1

plotLogHistogramH(population1, minerals1, triplet1, destinationDir)
plotLogHistogramH2(population1, minerals1, triplet1, destinationDir)

%% Association Index Matrix (following Koch, 2017)
% Note: this section can run out of memory (consider ROI)

%ROI
pos_ROI = floor([1, 1, size(phasemap, 1), size(phasemap, 2)]);%default 
%[tl_row, tl_col, br_row, br_col] %ROI

class_map = phasemap1(pos_ROI(1):pos_ROI(3), pos_ROI(2):pos_ROI(4));
rows = size(class_map, 1);
cols = size(class_map, 2);

%Optional: checkup
test_rgb = label2rgb(class_map, triplet_original); %might change to triplet1
figure, imshow(test_rgb)

%optional: if there is no background
bg_label = 0;

%subsetting foreground
all_labels_old = tablerank1.Label;
all_labels_new = tablerank1.NewLabel;
bg_index = (all_labels_old == bg_label);
fg_labels = all_labels_new(~bg_index)'; %transposed
n_labels = sum(~bg_index);
minerals2 = minerals_original(~bg_index);
triplet2 = triplet_original(~bg_index, :);
triplet3 = [0, 0, 0;
    triplet2]; %for Adjacency graph overlay

tic;
%phasemapAIM(map, radius, connectivity, destinationDir)
[AIM, AIM_pct, access_map] = phasemapAIM(class_map, 1, 'four', destinationDir); %15 min
plotStackedH(AIM_pct, minerals2, triplet2, destinationDir)

%Next task: subsetting causes problems, fix it
% [AIM, AIM_pct, access_map] = phasemapAIM(class_map(1500:2000, 1500:2000), 1, 'four', destinationDir); %15 min

%Adjacency phase maps

%Plot aspect
fgColor = 0.4*[1, 1, 1];
bgColor = rgb('SkyBlue');

row_num = 0;
adjacency_map = cell(1, n_labels);
adjacency_rgb = cell(1, n_labels);
for sel = fg_labels %inner mineral to watch and understand
    row_num = row_num + 1;

    col_num = 0; %clear value
    temp_map = zeros(rows, cols);
    for i = setdiff(fg_labels, sel)
        col_num = col_num + 1;

        %Overlay
        temp_map(logical(access_map{row_num, col_num})) = i;    
        binary_temp = (class_map == sel);

        B = labeloverlay(label2rgb(binary_temp, fgColor, bgColor), ...
        temp_map, 'Colormap', triplet3, 'Transparency', 0); 
        %you must include the background color [0, 0, 0]

        %save
        temp_name = strcat('adjacency_', minerals2{row_num}, '.tif');
        imwrite(B, fullfile(destinationDir, temp_name), 'compression', 'none')
    end
        adjacency_map{sel} = temp_map;
        adjacency_rgb{sel} = B;
end
% figure, imshow(adjacency_rgb{sel})
% title(strcat('Adjacency of', {' '}, string_C2{sel}))

t.AIM = toc;

%% Granulometry
close all

tic;

%binaries
binary = cell(1, n_labels);
binary_totals = zeros(1, n_labels);
for i = 1:n_labels   
    temp_binary = (class_map == i);
    binary_totals(i) = sum(temp_binary, 'all');
    binary{i} = temp_binary;
end

%Granulometry (pixels)
sizeMax = 30; %=60 (default) sieve pixels
[finer_pixels, original_pixels] = phaseGranulometry(binary, sizeMax, destinationDir);

%Grain size distribution (microns)
resolution = 10.68376; %microns/pixel (optical at fast acquisition)
plotGranulometry(finer_pixels, original_pixels, sizeMax, minerals_original, triplet_original, resolution, destinationDir)

t.granulometry = toc;

%% Statistics: grain measurements using binaries 
%copied from shapeStatistics_v3.m)

stats_cell = cell(1, n_labels);
for k = 1:n_labels
    
    mask_temp = binary{k};
    stats = regionprops('table', mask_temp, 'all');
    
    label_ID = repmat(k, [size(stats, 1), 1]);
    aspectRatios = stats.MajorAxisLength./stats.MinorAxisLength; %equivalent ellipse
    shapeIndexes = stats.Perimeter./sqrt(stats.Area); %~smoothness and integrity
    n_inclusions = 1 - stats.EulerNumber; %EulerNumber = 1 - number of holes
    
    newColumns = {'Label', 'aspectRatio', 'shapeIndex', 'numberInclusions'};
    stats_temp = addvars(stats, label_ID, aspectRatios, shapeIndexes, n_inclusions, ...
        'Before', 'Area', 'NewVariableNames', newColumns); %Adding labels

    stats_cell{k} = stats_temp;
end
stats2 = vertcat(stats_cell{:});
stats2 = stats2(stats2.Area > 15, :);%filter by area

sub_stats2 = stats2(:, {'Label', 'Area', 'Perimeter', ...
    'shapeIndex', 'Solidity', 'aspectRatio', ...
    'MinorAxisLength', 'Eccentricity', 'Circularity', ...
    'EquivDiameter', 'numberInclusions', 'Orientation'});

writetable(sub_stats2, fullfile(destinationDir, 'shape_stats.xlsx'))

