
%Script 'qupathPhaseMap_v10_simplified.m'

%Script to build a phase map from a QuPath project that contains a trained
%pixel classifier and the corresponding labelled (predicted) image (ome.tif
%output). It outputs a folder named after the classifier with the desired
%outputs including:
%*Phase maps and modal mineralogy (Acevedo Zamora & Kamber, 2023)
%*Multiresolution as-sociation matrices (Koch, 2017), 
%*Adjacency (or accessibility) maps (Kim et al., 2022). 

%Created: 20-Aug-24, Marco Acevedo
%Updated: 26-Nov-24, Marco Acevedo

%Citation:
%Publication: https://doi.org/10.3390/min13020156
%Repository: https://github.com/marcoaaz/Acevedo-Kamber/tree/main/QuPath_generatingMaps

%Script documentation:
%Obtaining original colouring: 
%https://levelup.gitconnected.com/how-to-convert-argb-integer-into-rgba-tuple-in-python-eeb851d65a88

close all
clear
clc

%User input:

%QuPath project
rootFolder = 'E:\Alienware_March 22\current work\rodrigo work\UHP32\QUPath_segmentation_project';
classifierName = 'Marco_3-Dec_trial1'; %*.ome.tif saved from QuPath
class_bg = {'Background'}; %edit this
rot_angle = 90; %phase map rotation angle (counter-clockwise)
radius = 1; %kernel radius for multi-scale Association Index
resolution = 1; %microns/pixel for grain size distribution plots and stats
sizeMax = 30; %default=60 in pixels

%Phase map to reconstruct
% phasemap_inputName = strcat(classifierName, '.ome.tif');%default
phasemap_inputName = 'Marco_3-Dec_trial1_ZoneA.ome.tif'; %manual (if sub-sets, previous experiments, etc.)

%Information:
%class_bg: for background, write only existing ones: {'epoxy', 'glass_polish', 'background'}
%resolution: check original input image metadata and Pixel Classifier 'Resolution' value
%sizeMax: virtual sieve for morphological operation (corresponds to plot X-axis)

%Script begins

%Root folders
cd(rootFolder);
scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsMarco2 = 'E:\Alienware_March 22\current work\00-new code May_22';
addpath(scriptsMarco);
addpath(fullfile(scriptsMarco, 'quPath bridge'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'external_package\rgb'));
addpath(fullfile(scriptsMarco, 'plots_miscellaneous'));
% addpath(fullfile(scriptsMarco2, 'hex_and_rgb_v1.1.1'));

%Reading data
clear sampleName %suffix replacement
test = strfind(phasemap_inputName, 'ome');
if ~isempty(test)
    idx1 = strfind(phasemap_inputName, '.ome.tif');
    sampleName = phasemap_inputName(1:idx1(end)-1);
    
else
    idx1 = strfind(phasemap_inputName, '.tif');
    sampleName = phasemap_inputName(1:idx1(end)-1);
    
end
classifierFile = strcat(classifierName, '.json');
classifierFolder = fullfile(rootFolder, 'classifiers', 'pixel_classifiers');

addpath(classifierFolder)
destinationDir = fullfile(rootFolder, sampleName);
mkdir(destinationDir);

%Intermediate file names
fileName1 = fullfile(destinationDir, 'classifier_metadata.xlsx');
fileName2 = fullfile(destinationDir, 'species.xlsx');
fileName3 = fullfile(destinationDir, 'phasemap_label_full.tif');
fileName_mask = 'sectionMask.tif';

%Importing project metadata
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
minerals = label_table.name;
triplet = [label_table.R, label_table.G, label_table.B]/255;

%Save in readable format
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
n_masks = n_labels;
population = zeros(1, n_masks);
for i = 1:n_masks   %1:n_masks  
       
    %calculate number of pixels
    temp_index = series1_plane1 == i-1; %QuPath convention
    population(i) = sum(temp_index, 'all');
end


format compact %displaying list
options = table(minerals, 'VariableNames', {'Mask'}, ...
    'RowNames', string(1:length(minerals)));
disp(options);

phasemap_original = series1_plane1 + 1; %adjusted for next section; quPath naming (-1)
n_rows_original = size(phasemap_original, 1);
n_cols_original = size(phasemap_original, 2);

%Option 1: Fixing margin artifacts and zeroing background classes
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

    %last touch:    
    fg_mask_filled = imfill(bwareafilt(fg_mask, 2), 'holes');
    
    %Cropping (preliminary): use foreground
    [row, col] = ind2sub([n_rows_original, n_cols_original], find(fg_mask(:)));
    
    % width_mask = max(col); %Focusing on Field of view
    % height_mask = max(row);
    width_mask = n_cols_original; %Temporal fix for Laser routine
    height_mask = n_rows_original;

    %cropping
    phasemap = phasemap_original(1:height_mask, 1:width_mask);
    section_mask0 = fg_mask_filled(1:height_mask, 1:width_mask); %cropping    
    section_mask = bwareafilt(section_mask0, 1); %Keeping largest area (map)   

elseif adequate_test == 0
    
    phasemap = phasemap_original;
    section_mask = ~bg_mask;    
end
phasemap(~section_mask) = 0; %ignore background classes
imwrite(section_mask, fullfile(destinationDir, fileName_mask)); %useful outside the script

% Pre-check (optional)
close all
hFig = figure;
hFig.Position = [100, 100, 1400, 500];

subplot(1, 2, 1)
imshow(bg_mask)
title('bg-mask: Map fringes')
subplot(1, 2, 2)
imshow(section_mask)
title('section-mask: Map outline (manually edited)')

%% Ranking phases by pixel numbers, re-labelling, and exporting phase maps

bg_index = ismember(original_labels, bg_label);

tablerank_0 = table(original_labels, minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});
tablerank = tablerank_0(~bg_index, :);
tablerank = sortrows(tablerank, 3, 'descend'); %rank by number of pixels
n_phases = size(tablerank, 1);
tablerank1 = tablerank;
tablerank1.NewLabel = (1:n_phases)';

phasemap1 = zeros(size(phasemap), 'uint8'); %preallocate
for i = 1:n_phases
    temp_original = tablerank1.Label(i);
    temp_new = tablerank1.NewLabel(i); %find ranking

    mask_phase = (phasemap == temp_original);    
    phasemap1(mask_phase) = temp_new;%re-labelling     
end

%Save
writetable(tablerank1, fileName2, 'Sheet', 'phaseMap'); %stats
imwrite(uint8(phasemap1), fileName3); %labelled image (all classes)

%%Option 1: Variables for plots

tablerank1 = readtable(fileName2, 'Sheet', 'phaseMap');
minerals_original = tablerank1.Mineral %PM_names = table2cell(tablerank(:, 2))'
triplet_original = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];

%Data for plots
%Option 1= phaseMap; Option 2= phaseMap_renamed (manually edited)

tablerank2 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap'); 
population1 = tablerank2.Pixels; 
minerals1 = tablerank2.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];

%User: Define the phases for plotting

mineral_targets = minerals_original; %default
% mineral_targets = {'Apatite'; 'Foram1'; 'Foram2'};

%Plot mineralogy
[PM_RGB] = phasemapCheck(phasemap1, minerals_original, ...
    triplet_original, mineral_targets, rot_angle, destinationDir);

plotLogHistogramH(population1, minerals1, triplet1, destinationDir)
plotLogHistogramH2(population1, minerals1, triplet1, destinationDir)

%% Multiscale Association Index Matrix (following Koch, 2017)
%Note: this section can run out of memory (consider ROI), runtime= ~15 min

%ROI [tl_row, tl_col, br_row, br_col]
pos_ROI = floor([1, 1, size(phasemap1, 1), size(phasemap1, 2)]);%default 
class_map_temp = phasemap1(pos_ROI(1):pos_ROI(3), pos_ROI(2):pos_ROI(4));
class_map = imrotate(class_map_temp, rot_angle); %counter-clockwise

fg_labels = tablerank1.NewLabel;
n_labels = length(fg_labels);
minerals2 = minerals_original;
triplet2 = triplet_original;

tic;

connectivity = 'four';
[AIM, AIM_pct, access_map] = phasemapAIM(class_map, radius, connectivity, ...
    destinationDir); 

%Note: subsetting causes problems, still needs fixing (future work)
%[AIM, AIM_pct, access_map] = phasemapAIM(class_map(1500:2000, 1500:2000), 1, 'four', destinationDir); %15 min

names_LtoR = {'Cpx', 'Garnet', 'Opx', 'Olivine'}; %edit from feedback
plotStackedH_sorted(AIM_pct, minerals2, triplet2, names_LtoR, destinationDir)
%plotStackedH(AIM_pct, minerals2, triplet2, destinationDir)

t.AIM = toc;

close all

[adjacency_map, adjacency_rgb] = adjacencyCheck(class_map, access_map, ...
    fg_labels, minerals2, triplet2, destinationDir);



%% Granulometry

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
[finer_pixels, original_pixels] = phaseGranulometry(binary, sizeMax, destinationDir);

%Grain size distribution (microns)
plotGranulometry(finer_pixels, original_pixels, sizeMax, minerals_original, triplet_original, resolution, destinationDir)

t.granulometry = toc;

%Statistics: grain measurements using binaries 
%copied from shapeStatistics_v3.m

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

