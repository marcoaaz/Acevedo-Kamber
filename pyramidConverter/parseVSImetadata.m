function [outStruct, parsedMetadata, objectivesMetadata] = parseVSImetadata(str2)

%medicine of xml.txt
S = fileread(str2);
S = regexprep(S, 'µm', 'micron');
new_filename = 'xml_reformated.txt';
fid = fopen(new_filename, 'w');
fwrite(fid, S); %save
fclose(fid);
outStruct = xml2struct(new_filename);

%Interpret metadata (entire acquisition in same order as all data)
temp_struct = outStruct.OME.Instrument.Objective;
n_configurations = length(temp_struct);

%Metadata of objectives
temp_objectiveMeta = cell(n_configurations, 1);
for i = 1:n_configurations
    temp_objectiveMeta{i} = struct2table(temp_struct{1, i}.Attributes, 'AsArray', true);     
end
temp_objectiveMeta2 = vertcat(temp_objectiveMeta{:});
col_names = temp_objectiveMeta2.Properties.VariableNames;
objectivesMetadata = convertvars(temp_objectiveMeta2, col_names, 'string');

%Metadata of all images
n_files = length(outStruct.OME.Image);

temp_name = strings(n_files, 1);
temp_basicMetadata = cell(n_files, 1);
temp_exposure = strings(n_files, 1);
temp_gain = strings(n_files, 1);
for i = 1:n_files
    
    %%n, series name
    temp_name(i) = outStruct.OME.Image{1, i}.Attributes.Name;     
    %basic metadata
    temp_basicMetadata{i, 1} = struct2table(outStruct.OME.Image{1, i}.Pixels.Attributes, 'AsArray', true); 
    %optional metadata
    try        
        temp_exposure(i) = outStruct.OME.Image{1, i}.Pixels.Plane.Attributes.ExposureTime; %s
        temp_gain(i) = outStruct.OME.Image{1, i}.Pixels.Channel.DetectorSettings.Attributes.Gain;           
    catch        
        temp_exposure(i) = '';
        temp_gain(i) = '';    
    end
end

basicMeta = temp_basicMetadata{1, 1}; %determines table columns
for ii = 2:n_files
    basicMeta = tblvertcat(basicMeta, temp_basicMetadata{ii, 1});
end

%gathering
temp_correlativeIdx = [1:n_files]' - 1;
NewVarNames = {'SeriesIndex', 'SeriesName', 'Exposure', 'Gain'};
parsedMetadata = addvars(basicMeta, temp_correlativeIdx, temp_name, temp_exposure, temp_gain, ...
    'NewVariableNames', NewVarNames, 'Before', 1);

beep

end