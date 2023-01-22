clear
clc
%Written by Marco Acevedo Z., QUT. 15-Aug-2022
%The MaxHeapSize of the Java Virtual Machine
%(JDFv17 for Windows 64-bit; not the JRE) should be permanently adjusted
%before using this script to have image pyramids of higher fidelity.

archCPU = computer('arch');
if strcmp(archCPU, 'win64')
    disp('Proceed with each script section')
else
    disp('Due to your CPU architecture (32-bit), your maximum RAM available is 2GB.')
end

%Root folder (edit accordingly)

%Dependencies
bfFolder = 'C:\Users\n10832084\AppData\Local\bftools'; %Bioformat command-line folder
%https://docs.openmicroscopy.org/bio-formats/6.8.1/users/comlinetools/conversion.html
libvipsFolder = 'C:\Users\n10832084\AppData\Local\vips-dev-8.12\bin';
%https://github.com/libvips/build-win64-mxe/releases/tag/v8.12.2

scriptDir = 'E:\Alienware_March 22\current work\00-new code May_22\pyramidConverter'; %location of code
marcoFolder = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts';

%Input
workingDir = 'D:\beckeLine_30micron'; %acquisition file folder

%Default 
cd(workingDir)
addpath(scriptDir)
addpath(marcoFolder)
addpath(workingDir)

str1 = fullfile(workingDir, 'Image_xenolith_20x_30planes.vsi');
[~, sectionName, ~] = fileparts(str1);  %output file name of script (option: manual)
% sectionName = strrep(str1, '.vsi', ''); 
str2 = fullfile(workingDir, 'xml.txt');
unfoldDir = fullfile(workingDir, strcat(sectionName));
command = ['cd /d "' bfFolder '"']; %to another drive; or system() cannot change between drives
command_libvips = ['cd "' libvipsFolder '"'];

%% Obtain metadata (Olympus *.vsi) 

tic;

delete(str2) %required to avoid undesired appending 

command1 = ['showinf -no-upgrade -omexml -nopix -omexml-only "' str1 '" >> "' str2 '"'];

%showinf -no-upgrade -nopix -omexml-only test.ome.tiff >> "showinf-output.txt"
[status1, cmdout1] = system(strcat(command, ' & ', command1));

if status1 == 1
    disp(command1)
    disp(cmdout1)
end

%Save xml.txt and parse meaningful metadata
[outStruct, parsedMetadata, objectivesMetadata] = parseVSImetadata(str2);

%gather panel info
[parsedMetadata_updated, ref_table2] = indexVSImetadata(parsedMetadata);

writetable(objectivesMetadata, strcat(sectionName, '_metadata.xlsx'), 'Sheet', 'objectives');
writetable(parsedMetadata_updated, strcat(sectionName, '_metadata.xlsx'), 'Sheet', 'metadata');
writetable(ref_table2, strcat(sectionName, '_metadata.xlsx'), 'Sheet', 'reference');
disp('The information was saved.')

t1 = toc;

%User input: GUI
mag_expression = '20x';%Edit: subset target acquisition
mag_idx = contains(ref_table2.SeriesName, mag_expression);
ref_table3 = ref_table2(mag_idx, :);

pyramidMenu_v2(ref_table3);

%% Export flat image from pyramidal data tree (Olympus format)
cd(bfFolder)
tic;

%option 1: flat images
folderName = strcat(unfoldDir, strcat('_flat', sprintf('_scale%d', sel_level)));
mkdir(folderName)

%calculating series number
SeriesName = parsedMetadata_updated.SeriesName; %whole list
SeriesIndex = parsedMetadata_updated.SeriesIndex;
SeriesName_sub = ref_table3.SeriesName; %sel
SeriesIndex_sub = ref_table3.SeriesIndex;
idx_sel1 = SeriesIndex_sub + sel_level; %option 1
idx_sel2 = idx_sel1(sel_layer); %option 2
n_selected = length(idx_sel2);

one_cond = sum(sel_layer == 1);
zero_cond = sum(sel_layer == 0);
condition1 = (one_cond == 0) && (zero_cond > 0); %empty
condition2 = (one_cond > 0) && (zero_cond == 0); %all
condition3 = (one_cond > 0) && (zero_cond > 0); %some

if condition1
    disp('Please, return to the GUI and select at least 1 layer.')

elseif condition2 || condition3        
    parfor j = 1:n_selected %parfor
        plane_series = idx_sel2(j);
        plane_idx = (SeriesIndex == plane_series);
        plane_name = SeriesName(plane_idx);
        
        str3 = fullfile(folderName, strcat(sectionName, '_', plane_name, '.tif'));         
               
        command3 = ['bfconvert -series ' num2str(plane_series) ' -overwrite "' str1 '" "' str3 '" -padded'];
        command3 = char(join(command3, ''));       
        
        input_command = [command, ' & ', command3];
        [status3, cmdout3] = system(input_command);
        if status3 == 1
            disp(input_command)
            disp(cmdout3)
        end
    end
end
t2 = toc;
disp('Done. In case you rerun the code, rename your files to not overwrite them.')
%For flat images:
%bfconvert -series 3 -overwrite "C:\Users\n10832084\OneDrive
%- Queensland University of Technology\Desktop\paper 1\Export\17BSK043.vsi"
%"C:\Users\n10832084\OneDrive - Queensland University of
%Technology\Desktop\paper 1\Export\scripted\17BSK043_%%n_core1.tif"

%For tiled images: tiles = 49 megas --> 55 min, 22% CPU use
% bfconvert -tilex 4096 -tiley 4096 -overwrite "C:\Users\n10832084\OneDrive
% - Queensland University of Technology\Desktop\paper
% 1\Export\17BSK043.vsi" "C:\Users\n10832084\OneDrive - Queensland
% University of Technology\Desktop\paper
% 1\Export\scripted\17BSK043_%%n_tile_%%x_%%y_%%m.tif"    

%Oother options:
% BF_MAX_MEM=24g bfconvert
% -tilex 512 -tiley 512 (using 256 is always successfull)
% -crop 0,0,2048,2048
% -overwrite -compression LZW (JPEG; JPEG-2000; depends on client software decoding)
% -swap XYZTC

cd(workingDir)

%% Option 2 (dont run): tiled images (run in only 1 core)
%for 23 GB *.vsi: 4096x4096 tiles are saved in 55 min at 22% overall CPU use

tic;

folderName = strcat(unfoldDir, '_tiled');
mkdir(folderName)

str4 = fullfile(folderName, strcat(sectionName, '_series_%%s_tile_%%x_%%y.tif'));  %_%%m
command4 = ['bfconvert -tilex 4096 -tiley 4096 -overwrite "' str1 '" "' str4 '" -padded'];
command4 = char(join(command4, ''));

input_command = [command, ' & ', command4];
[status4, cmdout4] = system(input_command);
if status4 == 1
    disp(input_command)
    disp(cmdout4)
end

t3 = toc;

%% Image registration (LIBVIPS using QuPath transforms)
%https://www.libvips.org/API/current/libvips-resample.html#vips-affine

tic;

%QuPath image alignment plugin transforms
folderName = strcat(unfoldDir, '_flat_scale0'); %from Option 1
[keySet] = GetFileNames(folderName, '.tif'); 

info_temp = imfinfo(fullfile(folderName, keySet{1}));
width = info_temp.Width;
height = info_temp.Height;
n_channels = info_temp.BitDepth;
disp(keySet') %reference list (edit below)
fprintf('WxHxC= %d x %d x %d \n', width, height, n_channels)

%% Step 1: Transforms (Edit manually)

keySet2 = keySet(1:end);
% keySet2 = keySet;
%option:
% expression_registering = 'xpl';
% idx_modality = contains(keySet2, expression_registering, "IgnoreCase", true);
% keySet2 = keySet2(idx_modality);

valueSet_modalities = {
    [1.0000, 	 -0.0001,	 2.0709; 0.0001,	 1.0000,	 -6.4049]; %ppl
    [1.0000, 	 0.0000,	 -0.4676; 0.0000,	 1.0000,	 1.7075] %xpl
    };

valueSet_ppl = {
    [1.0000, 	 -0.0000,	 0.2338; 0.0000,	 1.0000,	 0.1443];
    [1.0000, 	 0.0000,	 0.0608; -0.0000,	 1.0000,	 0.3316];
    [1.0000, 	 -0.0000,	 0.3300; 0.0000,	 1.0000,	 -0.0181];
    [1.0000, 	 0.0000,	 0.1469; -0.0000,	 1.0000,	 0.2067];
    [1.0000, 	 0.0000,	 0.1370; -0.0000,	 1.0000,	 0.0466]
    };

valueSet_xpl = {
    [1.0000, 	 0.0000,	 -1.4705; -0.0000,	 1.0000,	 -0.1969];
    [1.0000, 	 -0.0000,	 -0.3791; 0.0000,	 1.0000,	 -0.5947];
    [1.0000, 	 -0.0000,	 -0.2425; 0.0000,	 1.0000,	 -1.2802];
    [1.0000, 	 0.0000,	 -0.4130; -0.0000,	 1.0000,	 1.5691];
    [1.0000, 	 0.0000,	 -1.5919; -0.0000,	 1.0000,	 2.3715]    
    };

for i = 1:length(valueSet_modalities)
    valueSet_modalities{i} = [valueSet_modalities{i}; [0, 0, 1]];
end
for i = 1:length(valueSet_ppl)
    valueSet_ppl{i} = [valueSet_ppl{i}; [0, 0, 1]];
end
for i = 1:length(valueSet_xpl)
    valueSet_xpl{i} = [valueSet_xpl{i}; [0, 0, 1]];     
end
I = eye(3, 3);

%Example (follow printed list of KeySet):
n = 1;
m = 2;
% valueSet = {
%     I;
%     valueSet_modalities{n};
%     valueSet_modalities{n}*valueSet_ppl{1};
%     valueSet_modalities{n}*valueSet_ppl{2};
%     valueSet_modalities{n}*valueSet_ppl{3};
%     valueSet_modalities{n}*valueSet_ppl{4};
%     valueSet_modalities{n}*valueSet_ppl{5};
%     valueSet_modalities{m};
%     valueSet_modalities{m}*valueSet_xpl{1};
%     valueSet_modalities{m}*valueSet_xpl{2};
%     valueSet_modalities{m}*valueSet_xpl{3};
%     valueSet_modalities{m}*valueSet_xpl{4};
%     valueSet_modalities{m}*valueSet_xpl{5};
% };


valueSet = {
    valueSet_modalities{n}*valueSet_ppl{3};
};

bb = [0, 0; width, 0; width, height; 0, height];
tl_x = zeros(1, length(valueSet));
tl_y = zeros(1, length(valueSet));
for j = 1:length(valueSet)
    xform = valueSet{j};
    xform(3, 1) = xform(1, 3); 
    xform(3, 2) = xform(2, 3); %adaptation
    xform(1, 3) = 0; 
    xform(2, 3) = 0;    
    xform1 = inv(xform);%'Image aligner' convention    
    %medicine
    xform1(3,3) = 1;
    xform1(abs(xform1) < 1e-15) = 0;

    tform_translate = affine2d(xform1);
    [x, y] = transformPointsForward(tform_translate, bb(:, 1), (bb(:, 2)));
    tl_x(j) = x(1); %top-left corner
    tl_y(j) = y(1);
end

keySet2'

%% Step 2: execute process (only ppl and xpl)

M = containers.Map(keySet2, valueSet);
n_M = length(M);

parfor k = 1:n_M
    
    str5 = fullfile(folderName, keySet2{k});         
    str6 = strrep(str5, '.tif', '_registered.tif');
    
    temp_mtx = M(keySet2{k});
    str7 = [num2str(temp_mtx(1, 1)) ' ' num2str(temp_mtx(1, 2)) ' ' num2str(temp_mtx(2, 1)) ' ' num2str(temp_mtx(2, 2))];
    str8 = num2str(-temp_mtx(1, 3)); %odx
    str9 = num2str(-temp_mtx(2, 3)); %ody
    
    %defining bounding box
    %old, following: https://github.com/libvips/pyvips/issues/226
%     str_area = [num2str(round(-1*tl_x(k))) ' ' num2str(round(-1*tl_y(k))) ' ' num2str(width) ' ' num2str(height)];
%     command5 = ['vips affine "' str5 '" "' str6 '" "' str7 '" --idx ' str8 ' --idy ' str9 ' --oarea "' str_area '"'];
    %new:
    str_area = [num2str(0) ' ' num2str(0) ' ' num2str(width) ' ' num2str(height)];
    command5 = ['vips affine "' str5 '" "' str6 '" "' str7 '" --odx ' str8 ' --ody ' str9 ' --oarea "' str_area '"'];
    command5 = char(join(command5, ''));       
    
    input_command = [command_libvips, ' & ', command5];
    [status5, cmdout5] = system(input_command);
    if status5 == 1
        disp(input_command)
        disp(cmdout5)
    end    
end
t4 = toc;
disp('The WSIs have been registered.')
% vips affine "C:\Users\n10832084\OneDrive - Queensland University of
    % Technology\Desktop\3 wsi flat\17BSK043_10x_RL BF_01 #8_tile.tif"
    % "C:\Users\n10832084\OneDrive - Queensland University of
    % Technology\Desktop\3 wsi flat\transformed_test.tif" "1 0 0 1" --idx 500
    % --idy 500

%% Slicing WSIs 
%https://www.libvips.org/API/current/Making-image-pyramids.md.html

%QuPath image alignment (combiner or warpy) plugin transforms
folderName = strcat(unfoldDir, '_flat_scale0'); %from Option 1
[keySet3] = GetFileNames(folderName, '_registered.tif'); 
% [keySet3] = GetFileNames(folderName, '.tif');  %manual (no previous section)

%Option 1:
% text1 = "ppl"; text2 = "xpl";
% idx_text1 = contains(keySet3, text1, 'IgnoreCase',true);
% idx_text2 = contains(keySet3, text2, 'IgnoreCase',true);
% idx_text = idx_text1 | idx_text2;
% 
% %Option 2:
expression_slicing = 'ppl'; %User selection
idx_text = contains(keySet3, expression_slicing, "IgnoreCase", true);

% %Option 3:
% text3 = 'RL';
% idx_text = contains(keySet3, text3, 'IgnoreCase',true);

%subsetting
keySet3 = keySet3(idx_text);
disp(keySet3') %reference list (edit below)
%%
n_flat_images = length(keySet3);
parfor k = 1:n_flat_images %parfor
    str10 = fullfile(folderName, keySet3{k});
    
%     str11 = strrep(str10, '.tif', '');  %test
    str11 = strrep(str10, '.tif', '.zip');    
    %issue: https://github.com/libvips/libvips/issues/242

    command6 = ['vips dzsave "' str10 '" "' str11 '" --tile-size 4096 --overlap 0 --depth one --suffix .tif'];
    command6 = char(join(command6, ''));       
    
    input_command = [command_libvips, ' & ', command6];
    [status6, cmdout6] = system(input_command);
    if status6 ~=0
        disp(input_command)
        disp(cmdout6)
    end   
end
disp('The modality WSIs have been sliced.')
 % vips dzsave "C:\Users\n10832084\OneDrive - Queensland University of
    % Technology\Desktop\paper
    % 1\Export\scripted_parallel_flat\17BSK043_10x_ppl-0_01_registered.tif"
    % "C:\Users\n10832084\OneDrive - Queensland University of
    % Technology\Desktop\paper
    % 1\Export\scripted_parallel_flat\17BSK043_10x_ppl-0_01" --tile-size 4096
    % --overlap 0 --depth one --suffix .tif
