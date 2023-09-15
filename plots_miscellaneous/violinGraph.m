function [subset_idx] = violinGraph(AllDB, Mass, sample_sel, elementNames, order)

%optional arguments: , i, j 

DB_minerals = AllDB.Mineral;
mineralNames = unique(DB_minerals); %see if I can subset this
DB_samples = AllDB.Sample;

%select mineral
choices = cell2table(mineralNames, 'VariableNames', {'Minerals'}, ...
    'RowNames', string(1:length(mineralNames)));
disp(choices);
index = input('Select an option:\n');
% index = i;
mineral_sel = mineralNames{index}; %choosen a mineral by abbreviation

%Select variable
choices = cell2table(elementNames, 'VariableNames', {'Elements'}, ...
    'RowNames', string(1:length(elementNames)));
disp(choices);
element_idx = input('Select an option:\n');
% element_idx = j;
element_sel = elementNames{element_idx}; %choosen a mineral by abbreviation

sample_idx = ismember(DB_samples, sample_sel);
mineral_idx = ismember(DB_minerals, mineral_sel); %supposed to be 1 mineral
subset_idx = sample_idx & mineral_idx;

%Input
sel_labels = AllDB{subset_idx, 'Sample'};
sel_Mass = Mass(subset_idx, element_idx);
vector= table2array(sel_Mass);
category= cellstr(sel_labels);

figure
vs = violinplot(vector, category, 'GroupOrder', order); %, 'ShowData', false
ylabel('ppm');
title(strcat('Violin plot:' , {' '}, element_sel, {' in '}, mineral_sel));
grid on

end