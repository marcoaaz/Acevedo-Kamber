function [fileNames, fileNames_simpleSorting] = GetFileNames(sourceDir, suffix) 

%sourceDir = source directory
%format = suffix of file names

%parentDir = convertCharsToStrings(parentDir); %'' gives char, "" gives str
suffix_str = convertCharsToStrings(suffix);

MyFolderInfo = dir(sourceDir); 
%exclude invalid entries returned by the dir command
MyFolderInfo = MyFolderInfo(~cellfun('isempty', {MyFolderInfo.date})); 

fileFlags = [MyFolderInfo.isdir];
fileInfo = MyFolderInfo(~fileFlags);

fileNames = cell(1, numel(fileInfo));
for i = 1:numel(fileInfo)
    fileNames{i} = fileInfo(i).name;
end

flag = endsWith(fileNames, suffix_str); %select only *.tif files
fileNames = fileNames(flag);

try
    %Option: sorting by numeric index
    %Sort by section/sample name
    q0 = regexp(fileNames,'\d*', 'match'); 
    q1 = str2double(cat(1,q0{:}));
    [~, ii] = sortrows(q1, 1); %alternatives: [1, 2], 'ascend'
    fileNames_simpleSorting = fileNames(ii); %cell
catch
    fileNames_simpleSorting = 'unsorted';
    
    disp('There is no numerical naming')
end

end 