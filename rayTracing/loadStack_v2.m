

%% Root dir
clear all
clc

workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\22-dec-22\stacks_re\re_output';
cd(workingDir)

scriptPath1 = 'E:\Alienware_March 22\current work\00-new code May_22\rayTracing';
scriptPath2 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
addpath(scriptPath1)
addpath(scriptPath2)

fileName = 'concatenated.tif';
imageName = fullfile(workingDir, fileName);
destFolder = fullfile(workingDir, strrep(fileName, '.tif', ''));
mkdir(destFolder)

%% Optional: Monitoring 4D image stack (texture descriptors)

struct1 = imfinfo(imageName); %<4GB tif, or requires Bioformat Exporter plugin
n_rows = struct1(1).Height;
n_cols = struct1(1).Width;
n_channels = struct1(1).BitDepth/8;
n_images = length(struct1);
% list = setdiff(1:n_images, 2); %exclude images
list = setdiff(1:n_images, []); %ALL
n_list = length(list);

img_stack_3D = zeros(n_rows, n_cols, n_list*n_channels, 'uint8');
img_stack_4D = zeros(n_rows, n_cols, n_channels, n_list, 'uint8');
k=0;
texture_numbers = zeros(n_list, 4);
for i = list
    k = k + 1;
    from = 1 + 3*(k-1);
    to = from + 2;
    temp_img = imread(imageName, i);

    %descriptors
    texture_numbers(k, 1) = entropy(temp_img);
    texture_numbers(k, 2) = mean(temp_img, "all");
    texture_numbers(k, 3) = skewness(temp_img, 1, "all");
    texture_numbers(k, 4) = std(double(temp_img), 0, 'all', 'omitnan');
    glcms = graycomatrix(rgb2gray(temp_img));
    stats = graycoprops(glcms); %contrast, correlation, energy, homogeneity
    texture_numbers(k, 5) = stats.Contrast;
    texture_numbers(k, 6) = stats.Correlation;
    texture_numbers(k, 7) = stats.Energy;
    texture_numbers(k, 8) = stats.Homogeneity;

    img_stack_3D(:, :, from:to) = temp_img;
    img_stack_4D(:, :, :, k) = temp_img;
end
texture_numbers_n = (texture_numbers - min(texture_numbers, [], 1))./...
    (max(texture_numbers, [], 1) - min(texture_numbers, [], 1));

%% Optional: Informative plot
x = 1:n_list;
[idx, C] = kmeans(texture_numbers_n(:, [1, 2, 3, 4, 5, 7]), 6);
idx' %suggested clustering
width = 2;

hFig = figure;
hFig.Position = [50, 50, 1400, 600];

hold all
plot(x, texture_numbers_n(:, 1), "LineWidth", width)
plot(x, texture_numbers_n(:, 2), "LineWidth", width)
plot(x, texture_numbers_n(:, 3), "LineWidth", width)
plot(x, texture_numbers_n(:, 4), "LineWidth", width)
plot(x, texture_numbers_n(:, 5), "LineWidth", width, "LineStyle","-.")
plot(x, texture_numbers_n(:, 6), "LineWidth", width, "LineStyle","--")
plot(x, texture_numbers_n(:, 7), "LineWidth", width, "LineStyle","--")
plot(x, texture_numbers_n(:, 8), "LineWidth", width, "LineStyle","--")
hold off
grid on
legend({'entropy', 'mean', 'skewness', 'std', ...
    'contrast', 'correlation', 'energy', 'homogeneity'}, 'Location', 'eastoutside')
xlabel('Image stack plane')
ylabel('Normalized value')
xlim([0, n_list+ 1])
title('Textural information per modality')

n = 1;
img_temp = img_stack_4D(:, :, :, n);
figure
imshow(img_temp)

%% Checkup

% img1 = img_stack_4D(:, :, :, a);
% img2 = img_stack_4D(:, :, :, b);
% img3 = img_stack_4D(:, :, :, c);
% 
% figure
% montage({img1, img2, img3}, 'Size', [1 3]);

%% Ray tracing from single image stacks (patches)

struct1 = imfinfo(imageName); %<4GB tif, or requires Bioformat Exporter plugin
n_rows = struct1(1).Height;
n_cols = struct1(1).Width;
n_channels = struct1(1).BitDepth/8;
n_images = length(struct1);
% list = setdiff(1:n_images, 2); %exclude images
list = setdiff(1:n_images, []); %ALL
n_list = length(list);

%edit manually
sel_modality = {'RL PPL', 'RL XPL', 'TL PPL', 'TL XPL'};
n_modalities = length(sel_modality);
% rlBF_range,
rlPPL_range = 1:19; %2:7
rlXPL_range = 20:38; %8:19
tlPPL_range = 39:57; %20:25
tlXPL_range = 58:n_list; %26:n_list
sel_range = {rlPPL_range, rlXPL_range, tlPPL_range, tlXPL_range};

%Informative structure
info_struct.Height = n_rows; 
info_struct.Width = n_cols;
info_struct.Channels = n_channels;
info_struct.n_tile_layers = n_modalities;
info_struct.sel_range = sel_range;
info_struct.sel_modality = sel_modality;

% {'mean', 'max', 'min', 'range', 'sum', 'std', 'median', 'maxHSV', 'minHSV', 'rangeHSV'}
% stats_list = {'maxHSV', 'minHSV', 'rangeHSV', 'sum', 'std', 'median'};
stats_list = {'mean', 'max', 'min', 'range', 'sum', 'std', 'median', 'maxHSV', 'minHSV', 'rangeHSV'};
n_options = length(stats_list);

time_elapsed = zeros(1, n_options);
for k = 1:n_options     
    %parallel computing
    [time_elapsed] = stats_zProject(imageName, info_struct, stats_list{k}, destFolder);
end

%% Pick up manually (for Multi SLIC testing)

stack_manual = zeros(n_rows, n_cols, n_channels, n_modalities, "uint8");
%xpl
k = 0;
for j = tlXPL_range
    k = k +1;
    stack_manual(:, :, :, k) = imread(imageName, j);
end
size(stack_manual)

%ppl
ppl_temp = imread(imageName, tlPPL_range(1));
stack_temp = cat(4, ppl_temp, stack_manual);

%Save
% destDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\pytorch_test';
destDir = fullfile(workingDir, 'rayTracing_stacks');
mkdir(destDir);
destFile = fullfile(destDir, strrep(fileName, '.tif', '_manual.mat'));
save(destFile, 'stack_temp', '-mat', '-v7.3') %mat for binary 

%% Pick up and save matrix (for Autoencoder)

sourceDir = destFolder;
[fileNames, fileNames_simpleSorting] = GetFileNames(sourceDir, '.tif'); 
interesting_types = {'max_RL PPL', 'min_RL PPL', 'max_TL PPL', 'min_TL PPL', ...
    'range_TL XPL', 'range_RL XPL'}; %6 layers
interesting_types = strcat(interesting_types, '.tif');
n_types = length(interesting_types);
idx_types = ismember(fileNames, interesting_types); %check

stack_temp = [];
for i = 1:n_types
    img_temp = imread(fullfile(sourceDir, interesting_types{i}));
    stack_temp = cat(4, stack_temp, img_temp);
end

%Save
% destDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\pytorch_test';
destDir = fullfile(workingDir, 'rayTracing_stacks');
mkdir(destDir);
destFile = fullfile(destDir, strrep(fileName, '.tif', '.mat'));
save(destFile, 'stack_temp', '-mat', '-v7.3') %mat for binary 


%%





