
close all
clear
clc

%% Root folder (channels)

scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
scriptsMarco2 = 'E:\Alienware_March 22\current work\00-new code May_22';
addpath(scriptsMarco);
addpath(fullfile(scriptsMarco, 'quPath bridge'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'external_package\rgb'));
addpath(fullfile(scriptsMarco, 'plots_miscellaneous'));
% addpath(fullfile(scriptsMarco2, 'hex_and_rgb_v1.1.1'));

%QuPath project
rootFolder = 'E:\paper 3_datasets\harzburgite_synchrotron_christoph\tiff_HiRes\qupath_harzburgite\segmentation';
cd(rootFolder);

sampleName = '11sep23_test4'; %write new folder
destinationDir = fullfile(rootFolder, sampleName);
mkdir(destinationDir);

%%
classifierName = '11-sep_test4'; %*.ome.tif saved from QuPath
classifierFolder = fullfile(rootFolder, 'classifiers', 'pixel_classifiers');
addpath(classifierFolder)

quPathRGB = readtable('quPathRGB_apr22.csv');
dbRGB = readtable('color&density.csv');
classifierFile = strcat(classifierName, '.json');

%Importing
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

%feature maps
featureList = outStruct.op.op.ops{1, 1}.ops{1, 1}.ops.features;
featureList = join(string(featureList), ', ');

%annotations
outputClassificationLabels = outStruct.metadata.outputChannels; %name, colorRGB
temp_table = struct2table(outputClassificationLabels);

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
temp_table = addvars(temp_table, outputLabels, 'NewVariableNames', 'label'); %metadata

%QuPath classifier description
%note: initial "" avoids character conversion
summary_items = ["number of channels", 'channel names', 'resolution', 'tile width', 'bit depth', 'filters', ...
    'classifier type', 'classifier name', '# trees/layerSizes', 'maxDepth/epsilon']';
array_items = [n_channels, channelList, inputResolution, tileWidth, pixelType, featureList, ...
    classifierType, trainedClassifier, param_A, param_B]';
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

fileName1 = fullfile(destinationDir, 'classifier_metadata.xlsx');
writetable(label_table, fileName1, 'Sheet', 'Labels')
writetable(summary_table, fileName1, 'Sheet', 'Summary')

%Reading Phase Map image pyramid (OME-TIFF)
% classifierName = 'Marco5_RT_res2_scale1_features5_v2'; %comment: manual input

data = bfopen(strcat(classifierName, '.ome.tif')); 
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

phasemap = series1_plane1 + 1; %adjusted for next section; quPath naming (-1)

%% Option 1: Fixing margin artifacts (Following annotations)

class_bg = {'background'}; 
%write only existing ones: {'epoxy', 'glass_polish', 'background'}

n_bg = length(class_bg);
adequate_test = sum(ismember(class_bg, minerals));

if adequate_test > 0
    bg_mask = false(size(phasemap));
    bg_label = [];
    for m = 1:n_bg
        bg_string1 = class_bg{m};
        temp_label = find(strcmp(minerals, bg_string1)); %depends on QuPath class names
        temp_mask = (phasemap == temp_label);
    
        bg_mask = bg_mask | temp_mask;
        bg_label = [bg_label, temp_label];
    end

    %3 options, edit manually (according to experiment outline)
    % section_mask = imfill(bwareafilt(~bg_mask, 1), 'holes'); %largest object
    % section_mask = imfill(bwareafilt(bg_mask, 2), 'holes'); %largest object
    section_mask = imfill(bg_mask, 'holes');
    
    %last touch:
    section_mask = ~section_mask;
    section_mask = imfill(bwareafilt(section_mask, 2), 'holes');
    
    %cropping (preliminary)
    [row, col] = ind2sub([size(bg_mask, 1), size(bg_mask, 2)], find(bg_mask(:)));
    width_mask = max(col);
    height_mask = max(row);
    section_mask = section_mask(1:height_mask, 1:width_mask); %cropping
    phasemap = phasemap(1:height_mask, 1:width_mask); 

elseif adequate_test == 0
    bg_mask = false(size(phasemap));
    section_mask = ~bg_mask;
end

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

%% Option 2 (Manual box): Fixing margin artifacts 
% Follows User drawing; used for Perseverance abration patches

figure,
imshow(label2rgb(phasemap, 'jet', 'k', 'shuffle'))
h = drawcircle('Color', 'k', 'FaceAlpha', 0.4);

section_mask = createMask(h); %refine section_mask

ROI = regionprops(section_mask, 'BoundingBox'); %top left X, Y, W, H
ROI = ROI.BoundingBox;
tl_row = ceil(ROI(2));
tl_col = ceil(ROI(1));
br_row = tl_row + ROI(4) - 1;
br_col = tl_col + ROI(3) - 1;
pos_ROI = [tl_row, tl_col, br_row, br_col];

%pre-check
figure
imshow(section_mask)

%% Ranking and filtering 

phasemap(~section_mask) = 0; %apply mask

tablerank = table(([1:n_masks])', minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});
tablerank = sortrows(tablerank, 3, 'descend'); %rank by number of pixels

%from Option 1: edit manually
% bg_index1 = strcmp(tablerank.Mineral, bg_string1);
% bg_index2 = strcmp(tablerank.Mineral, bg_string2);
% bg_index = bg_index1 | bg_index2;
% 
% tablerank1 = tablerank(~bg_index, :);

% %from Option 2:
tablerank1 = tablerank;
tablerank1.NewLabel = (1:size(tablerank1, 1))';
bg_label = []; %any (deactivate if previously found)

%Update variable mapping (QuPath --> PhaseMap script)
%rearranging QuPath phasemap by population ranking

phasemap1 = phasemap; %preallocate
for i = setdiff(original_labels', bg_label)
    mask_phase = phasemap == i;
    label_index = tablerank1.Label == i;
    temp_label = tablerank1.NewLabel(label_index); %find ranking
    
    phasemap1(mask_phase) = temp_label;    
end

%saving stats
fileName2 = fullfile(destinationDir, 'species.xlsx');
writetable(tablerank1, fileName2, 'Sheet', 'phaseMap');

%saving labeled image
fileName3 = fullfile(destinationDir, 'phasemap_label.tif');
imwrite(uint8(phasemap1), fileName3);

%% Option 1: Variables for plots

tablerank1 = readtable(fileName2, 'Sheet', 'phaseMap');
population_original = tablerank1.Pixels; 
minerals_original = tablerank1.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet_original = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];
n_masks_original = length(minerals_original);
minerals_original

%define the phases for plotting
mineral_targets = minerals_original; %default
% mineral_targets = {'CPX'; 'opx'};

%Plot: phase map
rot_angle = 0; %rotation angle
[PM_RGB] = phasemapCheck(phasemap1, minerals_original, triplet_original, mineral_targets, rot_angle, destinationDir);

%% Option 2: Fix naming for publication with mini-DB

tablerank1 = readtable(fileName2, 'Sheet', 'phaseMap');

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

%% Option 2: Renamed data for Modal mineralogy histograms

cd('./test7/') %type folder name where newly calculated map resides

tablerank2 = readtable('species.xlsx', 'Sheet', 'phaseMap_renamed');
population1 = tablerank2.Pixels; 
minerals1 = tablerank2.significantMineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];
n_masks1 = length(minerals1);
minerals1

%Optional: manually customizing mask names (after studying the plot)
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

%% Plot (Option 1 or 2): modal mineralogy 

%Data for Modal mineralogy histograms
tablerank2 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap'); 
%Option 1= phaseMap; Option 2= phaseMap_renamed

population1 = tablerank2.Pixels; 
minerals1 = tablerank2.Mineral; %PM_names = table2cell(tablerank(:, 2))'
triplet1 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];
n_masks1 = length(minerals1);
minerals1

close all 

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

%% Adjacency graph

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

%% Plot: image measurements


%outlier shapes (for better plots)
TF = isoutlier(sub_stats2{:, 2:end}, 'mean');
disp(sum(double(TF), 1)); %show behavior

data_test1 = isoutlier(sub_stats2{:, 'Area'}, 'mean'); %aspectRatio
data_test2 = isoutlier(sub_stats2{:, 'aspectRatio'}, 'mean'); 
data_test = data_test1 | data_test2;
sub_stats3 = sub_stats2(~data_test, 2:end);

string_C = sub_stats2.Label;
string_C_sub = string_C(~data_test);%ClassID

%figures
% sub_min = min(sub_stats3{:, :}, [], 1); %pixel classifier (doesnt apply)
% sub_max = max(sub_stats3{:, :}, [], 1);
for sel = 1:n_labels
    
    idx = (string_C_sub == sel);
    str_temp = string_C2{sel};
    disp(str_temp)

    stats3 = sub_stats3(idx, :);    
    
    hFig = figure;
    ax = gca;
    set(hFig, 'Position', [50 50 800 600]);
    
    subplot(3, 4, 1)
%     histogram(stats3.MeanIntensity)
%     title('Mean pixel intensity')
%     xlim([sub_min(1), sub_max(1)])

    subplot(3, 4, 2)
    histogram(stats3.Area) % 'BinLimits', [0, 60000] 
    title('Area (px^2)')
%     xlim([sub_min(2), sub_max(2)])

    subplot(3, 4, 3)
    histogram(stats3.Perimeter)
    title('Perimeter (px)')
%     xlim([sub_min(3), sub_max(3)])

    subplot(3, 4, 4)
    histogram(stats3.shapeIndex)
    title('Shape index (roughness)')
%     xlim([sub_min(4), sub_max(4)])

    subplot(3, 4, 5)
    histogram(stats3.Solidity)
    title('Solidity (convexity)')
%     xlim([sub_min(5), sub_max(5)])

    subplot(3, 4, 6)
    histogram(stats3.aspectRatio)
    title('Aspect ratio')
%     xlim([sub_min(6), sub_max(6)])
    
    subplot(3, 4, 7)
    histogram(stats3.MinorAxisLength)
    title('Minor axis length')
%     xlim([sub_min(7), sub_max(7)])

    subplot(3, 4, 8)
    histogram(stats3.Eccentricity)
    title('Eccentricity (elongation)')
%     xlim([sub_min(8), sub_max(8)])

    subplot(3, 4, 9)
    histogram(stats3.Circularity)
    title('Circularity')
%     xlim([sub_min(9), sub_max(9)])

    subplot(3, 4, 10)
    histogram(stats3.EquivDiameter)
    title('Equivalent diameter')
%     xlim([sub_min(10), sub_max(10)])

    subplot(3, 4, 11)
    histogram(stats3.numberInclusions)
    title('Inclusions (1-Euler #)')
%     xlim([sub_min(11), sub_max(11)])

    subplot(3, 4, 12)
    polarhistogram(deg2rad(stats3.Orientation))
    pax = gca;
    pax.ThetaLim = [-90, 90];
    title('Orientation')
    
    sgtitle(strcat('Grain measurements:', {' '}, str_temp, ...
        {' (n='}, num2str(sum(idx)), ')'))    
    %save
    temp_name = strcat('stats_', string_C2{sel}, '.png');    
    saveas(gcf, fullfile(destinationDir, temp_name))    
end
