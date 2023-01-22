clear
clc

scriptDir = 'E:\Alienware_March 22\current work\00-new code May_22';
marcoFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';
workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\18RBE-006h_third\New folder';
% workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\18RBE006h_10x\ray tracing';
cd(workingDir)
addpath(scriptDir)
addpath(fullfile(scriptDir, 'rayTracing/'))
addpath(marcoFolder)

%% check folder

listing = dir(workingDir);
listing1 = struct2table(listing);
idx1 = listing1.isdir;
listing2 = listing1(idx1, :); %only containing folders
str = convertCharsToStrings(listing2.name);

%focusing on folders
expression_1 = {'10x_xpl', '10x_ppl', '.', '..', 'System Volume Information'}; %match string
idx_targetFolder = ismember(str, expression_1);
str(idx_targetFolder) = []; %avoid recurrence
listing2(idx_targetFolder, :) = []; %avoid recurrence

%target folders
% expression_2 = {'10x_xpl-', '10x_ppl-', '10x_RL BF_'}; %all
expression_2 = {'10x_xpl'}; %all
sel_cell_1 = strfind(str, expression_2{1});
sel_idx_1 = ~cellfun(@isempty, sel_cell_1); 
% sel_cell_2 = strfind(str, expression_2{2}); 
% sel_idx_2 = ~cellfun(@isempty, sel_cell_2); 
% sel_cell_3 = strfind(str, expression_2{3});
% sel_idx_3 = ~cellfun(@isempty, sel_cell_3); 
% sel_idx = sel_idx_1 | sel_idx_2 | sel_idx_3;%activate at will
sel_idx = sel_idx_1;

listing3 = listing2(sel_idx, :); 
str_sel = listing3.name;
str_sel 

%%

% expression_selected = '10x'; %all, for saving output
expression_selected = expression_2{1}; %only 1

sourceDir = fullfile(workingDir, str_sel, '\0'); %dzsave format

%Understanding tile sequence
tic;

%discovering tile arrangement
i = 1;
[keySet] = GetFileNames(sourceDir{i}, '.tif'); 

expression = ['(?<x>\d*)_(?<y>\d*).tif'];
tokenNames = regexp(keySet, expression, 'names');
struct_temp = [tokenNames{[1:end]}];

table_temp = struct2table(struct_temp); %tile location info
table_temp2 = addvars(table_temp, keySet', 'NewVariableNames', 'tileName', 'Before', 1);
x_num = str2double(table_temp2.x);
y_num = str2double(table_temp2.y);
table_temp3 = addvars(table_temp2, x_num, y_num, 'NewVariableNames', {'x_num', 'y_num'});
[pos_new, ~] = sortrows(table_temp3, {'x_num', 'y_num'}, {'ascend', 'ascend'});

%Understanding image series
n_zStacks = length(keySet);
n_rows = zeros(n_zStacks, 1);
n_cols = zeros(n_zStacks, 1);
n_channels = zeros(n_zStacks, 1);
for m = 1:n_zStacks
    info_structure = imfinfo(fullfile(sourceDir{i}, pos_new.tileName{m}));
    n_rows(m) = info_structure.Height;
    n_cols(m) = info_structure.Width;
    n_channels(m) = info_structure.SamplesPerPixel;
end
pos_new1 = addvars(pos_new, n_rows, n_cols, n_channels, 'NewVariableNames', {'Height', 'Width', 'Channels'});

%caching montage description
montage_dim.n_cols = n_cols(1); %the top-left tile is always complete
montage_dim.n_rows = n_rows(1);
montage_dim.n_channels = n_channels(1);
montage_dim.n_tile_cols = length(unique(x_num));
montage_dim.n_tile_rows = length(unique(y_num));
montage_dim.n_tile_layers = sum(sel_idx);
montage_dim.n_zStacks = n_zStacks;
montage_dim.montage_y_top = n_rows*(max(unique(y_num)) + 1);
montage_dim.montage_x_top = n_cols*(max(unique(x_num)) + 1);

t0 = toc;

[~, name, ~] = fileparts(fileparts(sourceDir));
name 

destFolder = fullfile(fileparts(fileparts(sourceDir{1})), expression_selected);
mkdir(destFolder)
fileName = fullfile(destFolder, 'montage_dim.mat');

%% Tile-based operations 

%Optional: Incremental PCA
[pca_montage, time_pca] = stats_zProject_tiled_pca(sourceDir, pos_new1, montage_dim, 'pca', destFolder);
montage_dim.pca_montage = pca_montage;
save(fileName, "montage_dim", '-v7.3');

%%

montage_dim_str = load(fileName, "montage_dim");
montage_dim = montage_dim_str.montage_dim;
%Ray tracing: following Fiji>Stack>Z-project
%available: 'mean', 'max', 'min', 'sum', 'std', 'median', 'pca'

% stats_list = {'max', 'min', 'std'}; %run only 2 at a time
stats_list = {'max', 'min', 'std', 'pca'};
n_options = length(stats_list);
time_elapsed = zeros(1, n_options);
data_transferred = cell(1, n_options);

for k = 1:n_options     
    %main
    [time_elapsed(k)] = stats_zProject_tiled_parallel(sourceDir, pos_new1, montage_dim, stats_list{k}, destFolder);

    %optional
%     [time_elapsed(k), data_transferred{k}] = stats_zProject_tiled_gpu(sourceDir, pos_new1, montage_dim, stats_list{k}, destFolder);
    
end
%User notes:
%depending on available RAM, you can simultaneously do: 'mean', 'max', 'min', 'sum', 'std', 'median'
%processing up to 24 GB and saving up to 4 GB as limited by MatLab-environment RAM
%use parfor if using stats_zProject_tiled.m function
%the _gpu function might perform better with small patches

sprintf(['Ready. The pipeline continues using ConEmu with Ubuntu with python (pyvips).\n' ...
    'Stitch_stretch_batch.py output have to be renamed as XPL, PPL, etc.,\n'...
    'for avoiding file overwritting.'])

%performance
figure
plot(time_elapsed)
title(sprintf('Performance: %s', join(string(stats_list), ', ')))
xlabel('Statistic')
ylabel('Seconds')

%% Optional: Stitching 

libvipsFolder = 'C:\Users\n10832084\AppData\Local\vips-dev-8.12\bin';
tilesFolder = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\microcline\Export\2512-PTS_flat\10x_xpl';

command_test = fullfile(libvipsFolder, "vips.exe");
command_libvips = ['cd "' tilesFolder '"'];

stats_list = {'pca'}; %run only 2 at a time
n_options = length(stats_list);

pos_new2 = sortrows(pos_new1, [5, 4], {'ascend', 'ascend'}); %row-major order

string3 = string(montage_dim.n_tile_cols);
parfor j = 1:n_options

    raw_join = strcat(stats_list{j}, '_', pos_new2.tileName);
    str_join = join(raw_join, ' ');
    string1 = str_join{1};
    string2 = fullfile(workingDir, stats_list{j});
    
    % command1 = ['vips arrayjoin "' string1 '" "' string2 '.tif" --across 19"'];
    command1 = ['"' command_test '" arrayjoin "' string1 '" "' string2 '.tif" --across ' string3]; %.png
    command1 = char(join(command1, ''));  
    
    [status1, cmdout1] = system(strcat(command_libvips, ' & ', command1));    
    if status1 == 1
        disp(command1)
        disp(cmdout1)
    end

end

%Message if disk is full: TIFFAppendToStrip: Write error at scanline 2944;
%wbuffer_write: write failed



