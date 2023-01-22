clear all
clc

%% Alternative 1: import 4D image stack

workingDir = 'E:\Alienware_March 22\current work\Leica_RL XPL rotation\stacks';
cd(workingDir)

fileName = 'Image_hartzburgite_20X_2.1dof_15planes_20x_ppl-0_Z_01.tif';
imageName = fullfile(workingDir, fileName);

struct1 = imfinfo(imageName); %<4GB tif, or requires Bioformat Exporter plugin
n_rows = struct1(1).Height;
n_cols = struct1(1).Width;
n_channels = struct1(1).BitDepth/8;
n_images = length(struct1);
% list = setdiff(1:n_images, 2); %exclude images
list = setdiff(1:n_images, []); %ALL
n_list = length(list);

img_stack = zeros(n_rows, n_cols, n_list*n_channels, 'uint8');
k=0;
for i = list
    k = k + 1;
    from = 1 + 3*(k-1);
    to = from + 2;

    temp_img = imread(imageName, i);
    img_stack(:, :, from:to) = temp_img;
end

%% Alternative 2: import mat
clear 
clc

workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\pytorch_test';
fileName = 'all_modes2.mat';
imageName = fullfile(workingDir, fileName);
cube = load(imageName);
img_stack = cube.img_stack_multiplex;
n_rows = size(img_stack, 1);
n_cols = size(img_stack, 2);
n_channels = 3;


%% Ray tracing demo

img1 = img_stack(:, :, 1:3);
img2 = img_stack(:, :, 4:6);
img3 = img_stack(:, :, 22:24);
img_ppl = reshape(img_stack(:, :, 4:21), n_rows, n_cols, n_channels, []);
img_xpl = reshape(img_stack(:, :, 22:end), n_rows, n_cols, n_channels, []);

[xpl_max, xpl_maxIdx] = max(img_xpl, [], 4);
[xpl_min, xpl_minIdx] = min(img_xpl, [], 4);
[ppl_max, ppl_maxIdx] = max(img_ppl, [], 4);
[ppl_min, ppl_minIdx] = min(img_ppl, [], 4);
xpl_range = xpl_max-xpl_min;
ppl_range = ppl_max-ppl_min;

P = prctile(xpl_min, [0, 99], 'all');
xpl_min_rs = uint8(rescale(xpl_min, 0, 255, "InputMax", P(2)));

new_stack = cat(4, img1, ppl_min, ppl_max, xpl_range);
img_stack2 = reshape(new_stack, n_rows, n_cols, []);

new_stack_sum = uint8(rescale(sum(new_stack, 4), 0, 255));

%%
close all

figure
montage({img1, img2, img3}, 'Size', [1 3]);
figure
montage({xpl_min_rs, xpl_max, xpl_range}, 'Size', [1 3]);
figure
montage({ppl_min, ppl_max, ppl_range}, 'Size', [1 3]);
figure,
imshow(img_stack2(:, :, 1:3))

figure
imshow(new_stack_sum)
figure
histogram(new_stack_sum)
%%

destDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\pytorch_test';

% fileName2 = fullfile(destDir, strrep(fileName, '.tif', '.mat'));
% tiffwrite(img_stack_multiplex, fileName)
% save(fileName2, 'img_stack', '-mat', '-v7.3') %mat for binary 

fileName3 = fullfile(destDir, strrep(fileName, '.tif', '_condensed.mat'));
save(fileName3, 'img_stack2', '-mat', '-v7.3') %mat for binary 

%% Becke line test

%Fiji>Edit>Selection>Specify
width = 2000;
height = 2000;
x_tl = 5794;
y_tl = 6605;
x_br = x_tl+width - 1;
y_br = y_tl+height - 1;

img_sub1 = img_stack(y_tl:y_br, x_tl:x_br, :); %z=1 is stage lowered max
img_sub = double(reshape(img_sub1, height, width, n_channels, n_images));

figure %checkup
imshow(img_sub1(:, :, 1:3))
%%

k = n_images;
idx_back = [];
idx_ahead = [];
img_operation = zeros(height, width, n_channels, n_images-1, 'double');
stage_sense = 1;
m = 0;
for i = 1:n_images-1    
    m = m + 1;
    idx_back = [idx_back, k];
    idx_ahead = [idx_ahead, k-1];

    img_operation(:, :, :, m) = stage_sense*(img_sub(:, :, :, k) - img_sub(:, :, :, k-1));

    k = k-1; %next
end

P = prctile(img_operation, [1 99], "all");
P
img_operation2 = uint8(rescale(img_operation, 0, 255, "InputMin", P(1), "InputMax", P(2)));

%Saving
for i = 1:n_images-1
    fileName = ['tile_', num2str(i), '.tif'];
    imwrite(img_operation2(:, :, :, i), fileName)
end

%%
img_test = permute(img_operation2, [1, 2, 4, 3]); %sliceViewer
sliceViewer(img_test)

figure
subplot(1, 2, 1)
histogram(img_operation(:, :, :, 1))
subplot(1, 2, 2)
histogram(img_operation2(:, :, :, 1))

%%





