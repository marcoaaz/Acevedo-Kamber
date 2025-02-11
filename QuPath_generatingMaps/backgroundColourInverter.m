
workingDir = 'E:\paper 3_datasets\conference paper_Goldschmidt\Export\registration\quPath_project\19Sep_RT_test3';

fileName_input = 'phasemap_target_foram1&foram2&apatite_RGB.tif';
fileName_output = strrep(fileName_input, '.tif', '_white.tif');

phasemap_rgb = imread(fullfile(workingDir, fileName_input));
section_mask = imread(fullfile(workingDir, 'sectionMask.tif'));

%switching background to white
phasemap_rgb_white = zeros(size(phasemap_rgb, 1), size(phasemap_rgb, 2), size(phasemap_rgb, 3), 'uint8');

R = phasemap_rgb(:, :, 1);
G = phasemap_rgb(:, :, 2);
B = phasemap_rgb(:, :, 3);
fg_white_mask = (R == 0) & (G == 0) & (B == 0) & section_mask;
R(fg_white_mask) = 255;
G(fg_white_mask) = 255;
B(fg_white_mask) = 255;
phasemap_rgb_white(:, :, 1) = R;
phasemap_rgb_white(:, :, 2) = G;
phasemap_rgb_white(:, :, 3) = B;

imwrite(phasemap_rgb_white, fullfile(workingDir, fileName_output))