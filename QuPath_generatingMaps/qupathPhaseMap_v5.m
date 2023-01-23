%% Root folder (channels)
close all
clear
clc

scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsMarco2 = 'E:\Alienware_March 22\current work\00-new code May_22';
addpath(scriptsMarco);
addpath(fullfile(scriptsMarco, 'quPath bridge'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'rgb'));
addpath(fullfile(scriptsMarco, 'plots_miscellaneous'));
% addpath(fullfile(scriptsMarco2, 'hex_and_rgb_v1.1.1'));

%QuPath project
rootFolder = 'D:\18RBE-006h_third_files\tiles_16RBE-006h_third\qupath_segmentation';
cd(rootFolder);

sampleName = '';
destinationDir = fullfile(rootFolder, sampleName);
mkdir(destinationDir);
%%
classifierName = '9Nov_RT_res2_scale1_features4_v2';
classifierFolder = fullfile(rootFolder, 'classifiers', 'pixel_classifiers');
addpath(classifierFolder)

quPathRGB = readtable('quPathRGB_apr22.csv');
dbRGB = readtable('color&density.csv');
classifierFile = strcat(classifierName, '.json');

%% Importing

%Parse classifier metadata
S = fileread(classifierFile);
outStruct = jsondecode(S);

%model input
inputChannels = struct2cell(outStruct.op.colorTransforms);
channelList = join(string(inputChannels), ', ');
n_channels = outStruct.metadata.inputNumChannels;
inputResolution = outStruct.metadata.inputResolution.pixelHeight.value; %x=y
tileWidth = outStruct.metadata.inputWidth; %x=y
pixelType = outStruct.op.op.ops{3, 1}.pixelType;

%machine learning model
classifierType = outStruct.pixel_classifier_type;
trainedClassifier = outStruct.op.op.ops{2, 1}.model.class;
n_trees = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.ntrees;
max_depth = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.training_params.max_depth;
featureList = outStruct.op.op.ops{1, 1}.ops{1, 1}.ops.features;
featureList = join(string(featureList), ', ');

%model output
outputClassificationLabels = outStruct.metadata.outputChannels; %name, colorRGB
outputLabels = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.class_labels;
temp_table = struct2table(outputClassificationLabels);
temp_table = addvars(temp_table, outputLabels, 'NewVariableNames', 'label');

%QuPath classifier description
%note: initial "" avoids character conversion
summary_items = ["number of channels", 'channel names', 'resolution', 'tile width', 'bit depth', ...
    'classifier type', 'classifier name', 'number of trees', 'max depth', 'filters']';
array_items = [n_channels, channelList, inputResolution, tileWidth, pixelType, ...
    classifierType, trainedClassifier, n_trees, max_depth, featureList]';
summary_table = table(summary_items, array_items, 'VariableNames', {'Item', 'Value'});

%Mineral labels
%https://levelup.gitconnected.com/how-to-convert-argb-integer-into-rgba-tuple-in-python-eeb851d65a88
dataType = 'int32';
a = int32(temp_table.color);
B = bitand(a, 255, dataType);
G = bitand(bitsrl(a, 8), 255, dataType);
R = bitand(bitsrl(a, 16), 255, dataType);
alpha = bitand(bitsrl(a, 24), 255, dataType);
rgb_append = double([R, G, B, alpha]);
rgb_append = array2table(rgb_append);
rgb_append.Properties.VariableNames = {'R', 'G', 'B', 'alpha'};

% label_table = addvars(temp_table, rgb_append, 'NewVariableNames', );
label_table = horzcat(temp_table, rgb_append);

writetable(label_table, 'classifier_metadata.xlsx', 'Sheet', 'Labels')
writetable(summary_table, 'classifier_metadata.xlsx', 'Sheet', 'Summary')

%Reading Phase Map image pyramid (OME-TIFF)
% classifierName = 'Marco5_RT_res2_scale1_features5_v2'; %comment: manual input

data = bfopen(strcat(classifierName, '.ome.tif')); %4_final.ome.tif
seriesCount = size(data, 1);
series1 = data{1, 1};
metadataList = data{1, 2};

series1_planeCount = size(series1, 1);
series1_plane1 = series1{1, 1}; %unmodified
series1_label1 = series1{1, 2};
series1_colorMap1 = data{1, 3}{1, 1};

original_labels = unique(series1_plane1) + 1; %for new mapping

%Map preview
n_masks = size(series1_colorMap1, 1);
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

phasemap = series1_plane1 + 1; %adjusted for next section

%% Option 1: Fixing margin artifacts (Following annotations)
% (1) Away from shiny phases (sulfides), opticalColorBalance.m zeroed the
%darkest sample matrix pixels
% (2) Section corners were not accurately cropped in opticalMasking.m

%Options: 
bg_string1 = 'epoxy';
bg_label1 = find(strcmp(minerals, bg_string1)); %determined in quPath
bg_string2 = 'glass_polish'; %e.g.: glass_polish, background, epoxy
bg_label2 = find(strcmp(minerals, bg_string2));%quPath naming (-1)
bg_string3 = 'background'; 
bg_label3 = find(strcmp(minerals, bg_string3));%quPath naming (-1)

% %for 3 conditions
bg_mask = (phasemap == bg_label1) | (phasemap == bg_label2) | (phasemap == bg_label3);
bg_label = [bg_label1, bg_label2, bg_label3];

% %for 2 conditions
% bg_mask = (phasemap == bg_label1) | (phasemap == bg_label2);
% bg_label = [bg_label1, bg_label2];

%for 1 condition
% bg_mask = (phasemap == bg_label2);
% bg_label = [bg_label2];

[row, col] = ind2sub([size(bg_mask, 1), size(bg_mask, 2)], find(bg_mask(:)));
width_mask = max(col);
height_mask = max(row);

%3 options, edit manually (according to experiment outline)
% section_mask = imfill(bwareafilt(~bg_mask, 1), 'holes'); %largest object
% section_mask = imfill(bwareafilt(bg_mask, 2), 'holes'); %largest object
section_mask = imfill(bg_mask, 'holes');


%last touch:
section_mask = ~section_mask;
section_mask = imfill(bwareafilt(section_mask, 2), 'holes');

%cropping
section_mask = section_mask(1:height_mask, 1:width_mask); %cropping
phasemap = phasemap(1:height_mask, 1:width_mask); 

close all
hFig = figure;
hFig.Position = [100, 100, 1400, 500];
subplot(1, 2, 1)
imshow(bg_mask)
title('bg-mask: Map fringes')
subplot(1, 2, 2)
imshow(section_mask)
title('section-mask: Map outline (manually edited)')

%% Option 2: Fixing margin artifacts (Following User drawing)

figure,
imshow(label2rgb(phasemap, 'jet', 'k', 'shuffle'))
h = drawcircle('Color', 'k', 'FaceAlpha', 0.4);
section_mask = createMask(h);
ROI = regionprops(section_mask, 'BoundingBox'); %top left X, Y, W, H
ROI = ROI.BoundingBox;
tl_row = ceil(ROI(2));
tl_col = ceil(ROI(1));
br_row = tl_row + ROI(4) - 1;
br_col = tl_col + ROI(3) - 1;
pos_ROI = [tl_row, tl_col, br_row, br_col];
imshow(section_mask)

%% Ranking and filtering 

phasemap(~section_mask) = 0; %apply mask

tablerank = table(([1:n_masks])', minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});
tablerank = sortrows(tablerank, 3, 'descend'); %rank by number of pixels

%from Option 1:
% %edit manually
% bg_index1 = strcmp(tablerank.Mineral, bg_string1);
% bg_index2 = strcmp(tablerank.Mineral, bg_string2);
% bg_index = bg_index1 | bg_index2;
% 
% tablerank1 = tablerank(~bg_index, :);

%from Option 2:
tablerank1 = tablerank;
tablerank1.NewLabel = (1:size(tablerank1, 1))';
bg_label = []; %any


%saving population
speciesFile = 'species.xlsx';
fullDest = fullfile(destinationDir, speciesFile);
writetable(tablerank1, fullDest, 'Sheet', 'phaseMap');

%Update variable mapping (QuPath --> PhaseMap script)
phasemap1 = phasemap;
%rearranging QuPath phasemap by population ranking
for i = setdiff(original_labels', bg_label)
    mask_phase = phasemap == i;
    label_index = tablerank1.Label == i;
    temp_label = tablerank1.NewLabel(label_index);
    
    phasemap1(mask_phase) = temp_label;    
end

%% Variables for plots

tablerank1 = readtable('species.xlsx');

population_original = tablerank1.Pixels; 
minerals_original = tablerank1.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet_original = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];
n_masks_original = length(minerals_original);
minerals_original

%Plot: phase map
rot_angle = 0; %rotation angle
[PM_RGB] = phasemapCheck(phasemap1, minerals_original, triplet_original, rot_angle, destinationDir);


%% Optional: mini-DB

tablerank1 = readtable('species.xlsx');

%---------
%optional:
abbreviations = {'plg', 'opx', 'CPX', 'amph', ...
    'Ti-oxide', 'inddingsite', 'iddingsite', 'iddingzite', 'spinel', 'serpentine', ...
    'olivine', 'quartz', 'garnet', 'biotite', ...
    'pyrite', 'chalcopyrite', 'chlorite', 'chloritoid', ...
    'apatite', 'titanite', 'orthoclase', 'muscovite', ...
    'patina', 'sulfide1', 'sulfide2', 'alt-opx', ...
    'clay-olivine', 'oxide1', 'clay2-amph', 'clay3-plg', ...
    'clay1-biotite', 'clay4-garnet', 'clay1-plg', 'clay-Kfds', ...
    'microcline', 'zircon', 'enstatite'
    };

mineral_db = {'Plagioclase', 'Orthopyroxene', 'Clinopyroxene', 'Amphibole', ...
    'Ilmenite', 'Iddingsite', 'Iddingsite', 'Iddingsite', 'Spinel', 'Serpentine', ...
    'Olivine', 'Quartz', 'Garnet', 'Biotite', ...
    'Pyrite', 'Chalcopyrite', 'Chlorite', 'Chloritoid', ...
    'Apatite', 'Titanite', 'Orthoclase', 'Muscovite', ...
    'Patina', 'Sulfide', 'Sulfide', 'Orthopyroxene (altered)', ...
    'Olivine (altered)', 'Oxide', 'Amphibole (altered)', 'Plagioclase (altered)', ...
    'Biotite (altered)', 'Garnet (altered)', 'Plagioclase (altered)', 'Feldspar (altered)', ...
    'Microcline', 'Zircon', 'Enstatite'
    };

%----------

%mandatory
%unwanted
mineral_list = tablerank1.Mineral;
unwanted_list = {'epoxy', 'glass_polish', 'hole', 'fluidInclusion', 'background'};
unwanted_idx = ismember(mineral_list, unwanted_list);
tablerank2 = tablerank1(~unwanted_idx, :);

%optional
% renamed
mineral_list = tablerank2.Mineral;
known_list = ismember(abbreviations, mineral_list);
known_list_place = ismember(mineral_list, abbreviations);
known_abbreviations = abbreviations(known_list);
known_db = mineral_db(known_list);
n_known = sum(known_list);
known_db_sorted = cell(1, n_known);
for m = 1:n_known
    idx_temp = strcmp(mineral_list, known_abbreviations(m));
    known_db_sorted(idx_temp) = known_db(m);
end

unknown_list = {'mineral1', 'mineral2', 'mineral3', 'silicate1', 'accessory1'};
unknown_idx = ismember(mineral_list, unknown_list);
n_unknown = sum(unknown_idx);
renamed_list = cell(1, n_unknown);
for k = 1:n_unknown
    renamed_list(k) = strcat('Unknown', {' '}, num2str(k));
end
%--------
tablerank2.significantMineral = tablerank2.Mineral;
%--------
tablerank2.significantMineral(known_list_place) = known_db_sorted(known_list_place);
tablerank2.significantMineral(unknown_idx) = renamed_list;
%-----
writetable(tablerank2, 'species.xlsx', 'Sheet', 'phaseMap_renamed', 'WriteMode', 'overwritesheet')

%% Data for histogram

cd('./9Nov_output_v2/')
tablerank2 = readtable('species.xlsx', 'Sheet', 'phaseMap_renamed');
population1 = tablerank2.Pixels; 
minerals1 = tablerank2.significantMineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];
n_masks1 = length(minerals1);
minerals1

%Manual editing: PhaseMap (original resolution)
%Optional: manual customizing (after studying the plot)
% minerals1{1} = 'olivine';
% minerals1{2} = 'serpentine';
% minerals1{3} = 'opx';
% minerals1{4} = 'epoxy';
% minerals1{5} = 'cpx';
% minerals1{6} = 'unknown1';
% minerals1{7} = 'spinel';
% minerals1{8} = 'unknown2';

% triplet1(1, :) = [0    1.0000    0.4961];
% triplet1(2, :) = [0.1172    0.5625    1.0000];
% triplet1(3, :) = [1.0000    1.0000    0.8750]; %pale yellow
% triplet1(3, :) = [0    0.3906         0.3];
% triplet1(4, :) = [0.6    0.5469         0];
% triplet1(5, :) = [1.0000    0.5469         0];
% triplet1(6, :) = [255, 0, 255]/255;
% triplet1(7, :) = [255, 255, 0]/255;
% triplet1(8, :) = [0    0.3906         0];

%Plot: modal mineralogy 
close all 
plotLogHistogramH(population1, minerals1, triplet1, destinationDir)
plotLogHistogramH2(population1, minerals1, triplet1, destinationDir)

