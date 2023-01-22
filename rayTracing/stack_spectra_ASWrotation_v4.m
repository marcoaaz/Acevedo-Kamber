%Root directory
%Writen by Marco Acevedo Zamora, QUT - 8-Aug-2022
%Last modified 23-Jan-2023

clear 
clc

workingDir = 'E:\Alienware_March 22\02-Research geology\05-QUT\VS200 set up Olympus\Trialling vs200\6-aug-2022 trial\stageRotation\convertVSIimages';
% workingDir = 'E:\Alienware_March 22\02-Research geology\05-QUT\VS200 set up Olympus\Trialling vs200\6-aug-2022 trial\stageRotation\convertVSIimages';
cd(workingDir)

scriptDir = 'E:\Alienware_March 22\current work\00-new code May_22';
scriptDir2 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
addpath(scriptDir)
addpath(fullfile(scriptDir, 'pyramidConverter/'))
addpath(fullfile(scriptDir, 'rayTracing/'))     
addpath(fullfile(scriptDir, 'SLIC_Achanta/'))
addpath(fullfile(scriptDir2, 'ROI'))
addpath(fullfile(scriptDir2, 'plots_miscellaneous'))

%% Importing data

folderName1 = workingDir;
ds1 = datastore(folderName1,...
"IncludeSubfolders",true, "FileExtensions", ".tif", "Type", "image");

folderName2 = fullfile(workingDir, '*', '*-source-metadata.xml'); %wildcards
ds2 = datastore(folderName2,...
"FileExtensions", ".xml", "Type", "file", "ReadFcn", @xml2struct);

n_layers = length(ds1.Files);

%angle
reset(ds2)
X = [];
while hasdata(ds2)
      T = read(ds2);
      X{end+1} = T.Properties.Groupsu_0.MicroscopeTemplate.PolarizationAngle.Attributes.value;
end
expression2 = '\d+';
pol_angle = str2double(string(regexp(X, expression2, 'match')));

reset(ds1) %info
img_temp = read(ds1);
n_rows = size(img_temp, 1);
n_cols = size(img_temp, 2);
n_channels = size(img_temp, 3);

reset(ds1)
sel_range = 1:n_layers; 

img_sRGB = zeros(n_rows, n_cols, n_channels, n_layers, "uint8");
img_HSV = zeros(n_rows, n_cols, n_channels, n_layers, "double");
img = zeros(n_rows, n_cols, n_channels, n_layers, "uint8");
k = 0;
for i = drange(sel_range)
    k = k + 1;
    temp_img = read(ds1);

    img_sRGB(:, :, :, k) = temp_img; %used for color transforms
    img_HSV(:, :, :, k) = rgb2hsv(double(temp_img)/255);   
    %linearized
    img(:, :, :, k) = rgb2lin(temp_img, 'ColorSpace', 'srgb'); %'OutputType', 'double', 
end

%User input (modify accordingly)
%Y-axis
available = {'RL', 'PPL', 'XPL'}; 

%X-axis, [1:6]
%PPL[1:178], XPL[179:184], RL/_ppl/_xpl[185:187], Label[188]
rl_range = [185:187]; %manual edit
ppl_range = [1:178];
xpl_range = [179:184];
range_modes = {rl_range, ppl_range, xpl_range};
sel_modes = [2, 3];

% img1 = lin2rgb(img(:, :, :, min(rl_range)),'OutputType', 'uint8'); %ugly histogram
img1 = img_sRGB(:, :, :, min(rl_range));
img2 = img_sRGB(:, :, :, min(ppl_range));
img3 = img_sRGB(:, :, :, min(xpl_range));

%% Mandatory: Live mode 

close all

figure

hImage = imshow(img2);
ax = gca; %alternative: fig = gcf; ax = fig.CurrentAxes;

hCircle = images.roi.Circle(...
    'Center', [n_cols/2 n_rows/2],...
    'Radius', 12,...
    'Parent', ax,...
    'Color', 'r');

color_space = 1; %1= RGB, 2=CIElab, 3=HSV
addlistener(hCircle, 'MovingROI',...
    @(varargin)ROIfourierS_data(hCircle, img, color_space, range_modes, sel_modes, pol_angle)); %'MovingROI'
addlistener(hCircle, 'ROIMoved',...
    @(varargin)ROIfourierS_graph(hCircle, sel_modes, available)); 
% addlistener(hCircle, 'ROIMoved',...
%     @(varargin)opticalWave3D(hCircle)); 

%% Optional: Pick pixel

close all

figure
montage({img1, img2, img3}, 'Size', [1 3]);
title('Click a pixel in the RL image:')

h = drawpoint("Color", 'r');
pos = h.Position;
px_col = ceil(pos(1));
px_row = ceil(pos(2));
px_rgb = double(squeeze(img(px_row, px_col, :, :)));

ROIfourierSeriesGraph(pol_angle, px_rgb, 1, sel_modes, range_modes, available)

%% Optional: Examine ROI spectra with App-Curve Fitter

%Live
logicalMask = createMask(hCircle);
sz = size(logicalMask);
ind = find(logicalMask); %column-major order
[row, col] = ind2sub(sz, ind);

px_rgb_test = double(img(row, col, :, :));
px_rgb_test = rgb2lin(px_rgb_test, ...
    'OutputType', 'double', 'ColorSpace','srgb'); %linearize
px = squeeze(mean(px_rgb_test, [1, 2]));

%Static
% px = px_rgb;
data = px(:, ppl_range); %6 points xpl_range
x = pol_angle(ppl_range);
y_R = data(1, :);
y_G = data(2, :);
y_B = data(3, :);

% w = 0.0349;%180
 w =   0.03722;
period = 2*pi/w;
period

%More details
% coeff = coeffvalues(fitresult{1});
% coeff(:, end) = value;



%% Save cfit to examine with fPolarOffset.m

%save fitted model
fitCell = hCircle.UserData.fitRGB;
sel_ch_idx = 3; %value in HSV
model1 = fitCell{1}{sel_ch_idx};
model2 = fitCell{2}{sel_ch_idx};
model_st.ppl_model = model1;
model_st.xpl_model = model2;

%% Save model within structure for plotting spectra in 3D
destDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\';
destFile = fullfile(destDir, 'channel_models.mat');
save(destFile, "model_st", '-mat', '-v7.3')

 

