clc
clear

%Dependencies
bfFolder = 'C:\Users\n10832084\AppData\Local\bftools'; %Bioformat command-line folder
%https://docs.openmicroscopy.org/bio-formats/6.8.1/users/comlinetools/conversion.html
libvipsFolder = 'C:\Users\n10832084\AppData\Local\vips-dev-8.12\bin';
%https://github.com/libvips/build-win64-mxe/releases/tag/v8.12.2

scriptDir = 'C:\Users\n10832084\Alienware_March 22\current work\00-new code Nov_21\pyramidConverter'; %location of code
marcoFolder = 'C:\Users\n10832084\Alienware_March 22\scripts_Marco\updated MatLab scripts';
workingDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\paper 1\Export\scripted_parallel_flat\'; %acquisition file folder

%Script (default)
cd(workingDir)
addpath(scriptDir)
addpath(marcoFolder)
addpath(workingDir)

sourceDir = fullfile(workingDir, 'ultimate_folder');
destDir = fullfile(workingDir, 'segmentation');
command = ['cd "' bfFolder '"'];
command_libvips = ['cd "' libvipsFolder '"'];

%% bftools - generate separate pyramids from flat images (LONG: 1 hour for 1.5 GB created in parallel)
%https://docs.openmicroscopy.org/bio-formats/6.0.0/formats/pattern-file.html

mkdir(destDir)
sectionName = '17BSK043';

fileNames = GetFileNames(sourceDir, '.tif');
n_files = length(fileNames);
parfor k = 1:n_files
    str5 = fullfile(sourceDir, fileNames{k}); %wild card pattern
    str7 = fullfile(destDir, strcat(sectionName, strrep(fileNames{k}, '.tif', '.ome.tiff')));
           
    %Pyramiding (as time-series due to naming gaps)
    command4 = ['bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat -tilex 512 -tiley 512 -overwrite "' str5 '" "' str7 '"'];
    [status4, cmdout4] = system([command, ' & ', command4]);
    if status4 == 1
        disp(command4)
        disp(cmdout4)
    end
end
%% bftools - generate a pyramid from flat images (LONG waiting time)
%https://docs.openmicroscopy.org/bio-formats/6.0.0/formats/pattern-file.html

mkdir(destDir)
sectionName = '17BSK043';

str5 = fullfile(sourceDir, 'naming.pattern'); %wild card pattern
str7 = fullfile(destDir, strcat(sectionName, '_multichannel.ome.tiff'));

namingPattern = '.*.tif';

fid = fopen(str5, 'w');
fwrite(fid, namingPattern);
fclose(fid);

%Pyramiding (as time-series due to naming gaps)
command4 = ['bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat -tilex 512 -tiley 512 -overwrite "' str5 '" "' str7 '"'];
[status4, cmdout4] = system([command, ' & ', command4]);
if status4 == 1
    disp(command4)
    disp(cmdout4)
end