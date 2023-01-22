function [parsedMetadata_updated, ref_table2] = indexVSImetadata(parsedMetadata)

SeriesName = parsedMetadata.SeriesName;
PhysicalSizeX = parsedMetadata.PhysicalSizeX; %avoid mislabeling
BigEndian = parsedMetadata.BigEndian; %avoid macro image
empty_rows = strcmp(PhysicalSizeX, '') & strcmp(BigEndian, 'true');

n_images = length(PhysicalSizeX);
n_layers = sum(~empty_rows);

level_count = zeros(n_layers, 1);
SeriesName2 = SeriesName;
m = 0;
k = 0;
for i = 1:n_images
    if empty_rows(i) == 0           
        temp_str = SeriesName{i};
        m = m + 1;       
        k = 1;        
    elseif empty_rows(i) == 1
        k = k + 1;    
    end    
    level_count(m) = k;
    SeriesName2{i} = temp_str;
end

parsedMetadata_updated = parsedMetadata;
parsedMetadata_updated.SeriesName = SeriesName2; %filling blanks
SizeC = str2double(parsedMetadata.SizeC);
SizeT = str2double(parsedMetadata.SizeT);
SizeX = str2double(parsedMetadata.SizeX);
SizeY = str2double(parsedMetadata.SizeY);
SizeZ = str2double(parsedMetadata.SizeZ);
bitdepth = 8;
parsedMetadata_updated.MB = (SizeX.*SizeY.*SizeC.*SizeZ.*SizeT)*(bitdepth)/(8*(1024^2));

%%
% # of pyramid levels (Olympus format): 
% %acquisition in highest resolution (not: label, overview, or macro images)
allMetadata = parsedMetadata_updated;

%Reference table
ref_table = parsedMetadata_updated(:, {'SeriesIndex', 'SeriesName', 'MB'});
ref_table1 = ref_table(~empty_rows, :); %get acquisition series
n_acquisitions = size(ref_table1, 1);
ref_table2 = addvars(ref_table1, [1:n_acquisitions]', level_count,...
    'NewVariableNames', {'Number', 'PyramidLevels'}, 'Before', 1);
disp(ref_table2)

end