%% Root folder

parentDir = 'E:\Alienware_March 22\current work\data_DMurphy\91690-81r5w-glass-overview\fields';
cd(parentDir);

scriptsFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';
addpath(scriptsFolder);
addpath(fullfile(scriptsFolder, 'distCorr code'))
    
%% Import Metadata

fileName = 'bse-png.hdr';
bseHdr_str = struct2table(dir(fullfile(parentDir, '**', fileName)));
bseHdr_folder = fullfile(bseHdr_str.folder, bseHdr_str.name);

%Available file names (constant = asuming all folders are equal)
endout = regexp(bseHdr_folder, filesep, 'split');
sectionNames = cell(length(endout), 1);
for m = 1:length(endout)
    sectionNames{m} = endout{m}{end-1}; %focus on folder name
end 

%% Interrogating metadata (Ogliore R.)

imagedir= bseHdr_folder;
nfiles=numel(imagedir);

WD=zeros(nfiles,1);
YStage=zeros(nfiles,1);
XStage=zeros(nfiles,1);

for ii=1:nfiles
    
    fileName = imagedir{ii};
    fid = fopen(fileName); %[imagedir(ii).folder '/' imagedir(ii).name]
    dd = textscan(fid,'%s');
    dd=dd{1};
    fclose(fid);

    wdstr='WD=';
    ss=strfind(dd,wdstr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    WD(ii)=str2double(ll((numel(wdstr)+1):end));
      
    xstr='StageX=';
    ss=strfind(dd,xstr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    XStage(ii)=str2double(ll((numel(xstr)+1):end));
    
    ystr='StageY=';
    ss=strfind(dd,ystr);
    index = false(1, numel(ss));
    for k = 1:numel(ss)
      if numel(ss{k} == 1)==0
         index(k) = 0;
      else
         index(k) = 1;
      end     
    end
    ll=dd{index};
    YStage(ii)=str2double(ll((numel(ystr)+1):end));
    
end

%% Transforming coordinates

spatialResolution = 1; %microns/px
XStage_px = (10^6)*XStage/spatialResolution;
YStage_px = (10^6)*YStage/spatialResolution;
tileSize_px = 1000; %check metadata

XStage1 = max(XStage_px) - XStage_px; %inverting axis (TIMA)
YStage1 = YStage_px - min(YStage_px); %max(YStage) - 
metadata = table(str2double(sectionNames), XStage1, YStage1, ...
    'VariableNames', {'Tile', 'X', 'Y'});
metadata1 = sortrows(metadata, 'Tile', 'ascend');
writetable(metadata1, 'positionXY.xlsx')

nrows= int64(max(YStage1)+tileSize_px);
ncols= int64(max(XStage1)+tileSize_px);
canvas = ones(nrows, ncols); %preallocating

%% Plot tiling reconstruction

close all
hFig = figure;
ax = gca;

imshow(canvas)
for i = 1:nfiles
    hRectangle = drawrectangle(ax, ...
        'Position', [XStage1(i), YStage1(i), tileSize_px, tileSize_px], ...
        'InteractionsAllowed', 'none', 'LineWidth', 0.5, 'FaceAlpha', 0.1);
  
    hPoint = drawpoint(ax, ...
        'Position', [XStage1(i), YStage1(i)], ...
        'Color', 'r', 'Deletable', false, 'DrawingArea', 'unlimited');
    text(XStage1(i), YStage1(i), sectionNames{i}, ...
        'FontSize', 7, 'clipping', 'on')
%     hPoint.Label = sectionNames{i}; %update to MatLab 2020b
%     hPoint.LabelAlpha = 0;
    hPoint.MarkerSize = 3;
    
end
xlim([-10, ncols+10])
ylim([-10, nrows+10])

%% Reconfiguring tiling (grid collection)

nrows_tiles = round(nrows/tileSize_px);
ncols_tiles = round(ncols/tileSize_px);
dim_tiles = [nrows_tiles, ncols_tiles];

%Type: row-by-row; Order: right & down --> Desired
[referenceGrid, tiling_name] = gridNumberer(dim_tiles, 1, 1); 

%Mapping
corner_x = metadata1.X;
corner_y = metadata1.Y;

%artificial grid
span_x = 0:tileSize_px:(ncols-tileSize_px+1); %without overlap (TIMA)
span_y = 0:tileSize_px:(nrows-tileSize_px+1);
[X_mesh, Y_mesh] = meshgrid(span_x, span_y);
all_points = double([X_mesh(:), Y_mesh(:)]);
all_labels = referenceGrid(:); %column-major order, left to right

oldLabel = zeros(length(all_labels), 1);
for i = 1:length(all_labels)    
    [D, I] = pdist2([corner_x, corner_y], all_points(i, :), 'euclidean', ...
        'Smallest', 1); %minimum value
    if D < 100 %tolerance
        oldLabel(i) = metadata1.Tile(I);
    end    
end
mapping = [all_labels, oldLabel];

%% Read and write image tiles

% Create destination folder
mydir  = pwd;
idcs   = strfind(mydir, filesep); %'/'
newdir = mydir(1:idcs(end)-1);

% dirDenominations = {'BSE', 'CL'}; %'phasemap', 'PixelMask'
% fileDenominations = {'bse.png', 'sem-CL.png'}; %'maplayout.tif', 'pixelmask.png'
dirDenominations = {'BSE'}; 
fileDenominations = {'bse.png'};
outputFormat = '.tif';

n_denominations = length(fileDenominations);
for i = 1:n_denominations
    %specific destination
    destFolder = fullfile(newdir, dirDenominations{i});
    mkdir(destFolder);
    
    structure_temp = struct2table(dir(fullfile(parentDir, '**', ...
        fileDenominations{i})));
    folder_temp = fullfile(structure_temp.folder, structure_temp.name);    
    
    endout = regexp(folder_temp, filesep, 'split'); %file names available
    folderName_temp = zeros(length(endout), 1);
    for m = 1:length(endout)
        folderName_temp(m) = str2double(endout{m}{end-1}); %focus on folder name
    end    
    
    image_reference = imread(folder_temp{1});    
    image_size = size(image_reference); %tileSize_px
    for j = 1:size(mapping, 1) 
        index_temp = folderName_temp == mapping(j, 2); %oldLabel
        folderName_temp1 = mapping(j, 1);

        %step not stored in memory
        if sum(index_temp) > 0                                
            image_temp = imread(folder_temp{index_temp}); %reading 
        elseif sum(index_temp) == 0            
            if isa(image_reference, 'uint8')
                image_temp = uint8(zeros(image_size));
            elseif isa(image_reference, 'uint16')
                image_temp = uint16(zeros(image_size));
            else
                disp('Modify code if image is not 8/16-bit')
            end
        end
        %leading zeros %03d (might cause TrakEM2 issue at importing)
        fileName = strcat('tile_', sprintf('%03d', folderName_temp1), outputFormat);%num2str(folderName_temp1)
        fileRoute = fullfile(destFolder, fileName);
        imwrite(image_temp, fileRoute); %saving
    end
end

