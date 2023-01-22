
%% Root dir
clear all
clc

workingDir = 'E:\Alienware_March 22\current work\Rob_export\robert samples\xenolith 18-rbe-006h\tru maps_bf1';
cd(workingDir)

scriptPath1 = 'E:\Alienware_March 22\current work\00-new code May_22\rayTracing';
scriptPath2 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
addpath(scriptPath1)
addpath(scriptPath2)

[filepath,name,ext] = fileparts(workingDir);
[fileNames, ~] = GetFileNames(workingDir, '.tif');

%% Optional: Monitoring 4D image stack (texture descriptors)

imageName = fileNames{1};
fileNames'

struct1 = imfinfo(imageName); %<4GB tif, or requires Bioformat Exporter plugin
n_rows = struct1(1).Height;
n_cols = struct1(1).Width;
n_channels = struct1(1).BitDepth/16; %16-bit
n_images = length(fileNames);
% list = setdiff(1:n_images, 2); %exclude images
list = setdiff(1:n_images, []); %ALL
n_list = length(list);

img_stack_3D = zeros(n_rows, n_cols, n_list*n_channels, 'uint16');
k=0;
texture_numbers = zeros(n_list, 4);
for i = list
    k = k + 1;    
    temp_img = imread(fileNames{i});

    %descriptors
    texture_numbers(k, 1) = entropy(temp_img);
    texture_numbers(k, 2) = mean(temp_img, "all");
    texture_numbers(k, 3) = skewness(temp_img, 1, "all");
    texture_numbers(k, 4) = std(double(temp_img), 0, 'all', 'omitnan');

    glcms = graycomatrix(double(temp_img)); %rounding issue
%     glcms = graycomatrix(rgb2gray(temp_img));
    stats = graycoprops(glcms); %contrast, correlation, energy, homogeneity
    texture_numbers(k, 5) = stats.Contrast;
    texture_numbers(k, 6) = stats.Correlation;
    texture_numbers(k, 7) = stats.Energy;
    texture_numbers(k, 8) = stats.Homogeneity;

    img_stack_3D(:, :, k) = temp_img;    
end
texture_numbers_n = (texture_numbers - min(texture_numbers, [], 1))./...
    (max(texture_numbers, [], 1) - min(texture_numbers, [], 1));

%Informative plot
x = 1:n_list;
[idx, C] = kmeans(texture_numbers_n, 3);
idx' %suggested clustering
width = 2;
%% Checkup 1

close all

% hFig = figure;
% hFig.Position = [50, 50, 1400, 600];
% 
% hold all
% plot(x, texture_numbers_n(:, 1), "LineWidth", width)
% plot(x, texture_numbers_n(:, 2), "LineWidth", width)
% plot(x, texture_numbers_n(:, 3), "LineWidth", width)
% plot(x, texture_numbers_n(:, 4), "LineWidth", width)
% plot(x, texture_numbers_n(:, 5), "LineWidth", width, "LineStyle","-.")
% plot(x, texture_numbers_n(:, 6), "LineWidth", width, "LineStyle","--")
% plot(x, texture_numbers_n(:, 7), "LineWidth", width, "LineStyle","--")
% plot(x, texture_numbers_n(:, 8), "LineWidth", width, "LineStyle","--")
% hold off
% grid on
% legend({'entropy', 'mean', 'skewness', 'std', ...
%     'contrast', 'correlation', 'energy', 'homogeneity'}, 'Location', 'eastoutside')
% xlabel('Image stack plane')
% ylabel('Normalized value')
% xlim([0, n_list+ 1])
% title('Textural information per modality')

n = 1;
img_temp = img_stack_3D(:, :, n);
img_temp2 = uint8(rescale(img_temp, 0, 255));
% figure
% imshow(img_temp2)
imtool(img_temp2)

%% Pick up and save matrix (for Autoencoder)

stack_temp = uint8(rescale(img_stack_3D, 0, 255));

%Save
% destDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\pytorch_test';
fileName = fullfile(workingDir, 'TruMap_stacks');
destFile = strcat(fileName, '.mat');
save(destFile, 'stack_temp', '-mat', '-v7.3') %mat for binary 


%% Playing

mode = 'pca';
[img_temp2] = rayTracing_demo(img_stack_3D, mode);

figure
imshow(img_temp2)

function [img_temp2] = rayTracing_demo(img_stack_3D, mode)
switch mode
    case 'mean'
        img_temp = mean(img_stack_3D, 3);
    case 'sum'
        img_temp = sum(img_stack_3D, 3);
    case 'std'
        img_temp = std(double(img_stack_3D), 0, 3); %2nd 
    case 'max'
        img_temp = max(img_stack_3D, [], 3);
    case 'min'
        img_temp = min(img_stack_3D, [], 3);
    case 'pca'
        img_temp = pca_simple(img_stack_3D); %1st 
end

img_temp2 = uint8(rescale(img_temp, 0, 255));
fileName = strcat(mode, '2.tif'); %modofy suffix
imwrite(img_temp2, fileName, 'Compression', 'none')

end

function [img_temp] = pca_simple(img_stack_3D)

[temp_height, temp_width, temp_channels] = size(img_stack_3D);
temp_mtx = double(img_stack_3D);
X = double(transpose(reshape(temp_mtx, [], temp_channels))); 
mu = mean(X, 2);
X_demean = X - mu;

% X_est = X;
%Optional: exclude zero background from estimation
% idx = (X(:, 1) ~= 0) & (X(:, 2) ~= 0) & (X(:, 3) ~= 0);
idx = (mean(X, 1) ~= 0);
X_est = X(:, idx);

[U, S, V] = svd(X_est, 'econ'); %avoid array maximum GB
%S=singular values, U/V= left/right singular vectors

% score_3pc = X_demean(idx, :)'*U;
score_3pc = zeros(size(X, 2), size(X, 1), 'double');
score_temp = X_demean(:, idx)'*U; %transposed output
disp('score_3pc')
size(score_3pc)
disp('score_temp')
size(score_temp)

score_3pc(idx, :) = score_temp;

pc1 = reshape(score_3pc(:, 1), temp_height, temp_width); %R
pc2 = reshape(score_3pc(:, 2), temp_height, temp_width); %G
pc3 = reshape(score_3pc(:, 3), temp_height, temp_width); %B
img_temp = cat(3, pc1, pc2, pc3);

end
