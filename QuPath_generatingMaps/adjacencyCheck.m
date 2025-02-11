
function [adjacency_map, adjacency_rgb] = adjacencyCheck( ...
    class_map, access_map, ...
    fg_labels, minerals2, triplet2, destinationDir)

fg_labels = fg_labels'; %transpose

%Adjacency phase maps
rows = size(class_map, 1);
cols = size(class_map, 2);
n_labels = length(minerals2);

%Plot aspect
fgColor = 0.4*[1, 1, 1];
bgColor = rgb('SkyBlue');

adjacency_map = cell(1, n_labels);
adjacency_rgb = cell(1, n_labels);
for sel = fg_labels %inner mineral to watch and understand

    binary_temp = (class_map == sel);    
    
    temp_map = zeros(rows, cols);
    for not_sel = setdiff(fg_labels, sel) %neighbour
        
        binary_adj_temp = logical(access_map{sel, not_sel});
        temp_map(binary_adj_temp) = not_sel; %labelling           
    end
    
    %figure, imshow(temp_map)
    labels1 = unique(temp_map);
    labels2 = setdiff(labels1, 0);

    mineral_mask = label2rgb(binary_temp, fgColor, bgColor);
    % figure, imshow(mineral_mask)   

    B = labeloverlay(mineral_mask, ...
        temp_map, 'Colormap', triplet2, 'Transparency', 0, 'IncludedLabels', labels2); 
        
    %save
    temp_name = strcat('adjacency_', minerals2{sel}, '.tif');
    imwrite(B, fullfile(destinationDir, temp_name), 'compression', 'none')
    
    %return
    adjacency_map{sel} = temp_map;
    adjacency_rgb{sel} = B;
end

%debug: 
% figure, imshow(adjacency_rgb{sel})
% title(strcat('Adjacency of', {' '}, string_C2{sel}))

end