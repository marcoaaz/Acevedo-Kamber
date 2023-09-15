%% Bivariate Plot for mineral assemblage

function bivariateGraph(DB_minerals, Mass, mineralNames, triplet)

n_minerals = length(mineralNames);
matrix = table2array(Mass);
MassLab = Mass.Properties.VariableNames;

%User interface
choices = cell2table(MassLab', 'VariableNames', {'Elements'}, ...
    'RowNames', string(1:length(MassLab)));
disp(choices);
index = input('Select an option:\n');
x1 = MassLab{index}; %check in PM_names

pairs = setdiff(MassLab, x1);
n_pairs = length(pairs);

%Settings (large plot)
nB = n_pairs; %number of plots
nf = ceil(nB^0.5); %distribution of sub-plots
if nf^2 - nB >= nf
    nrows = nf-1;
    ncolumns = nf;
else 
    nrows = nf;
    ncolumns = nf;
end
clear nf nB

figure; 
hFig=gcf;
clf
set(hFig, 'Position', [50 30 1100 700]);
ha = tight_subplot(nrows, ncolumns, [.08 .04], [.06 .09], [.04 .03]);

sz=10;%size of points in plot
for j = 1:n_pairs
    axes(ha(j));    
    x2 = pairs{j};    
    for i = 1:n_minerals
        idx = strcmp(DB_minerals, mineralNames{i});
        dn1 = strcmp(MassLab, x1); %look up for concentrations
        dn2 = strcmp(MassLab, x2); 
        
        x = matrix(idx, dn1);
        y = matrix(idx, dn2);
        x(x == -1) = NaN;
        y(y == -1) = NaN;

        L(i) = scatter(x, y, sz, triplet(i, :), '*'); %yellow    
        hold on
    end
    hold off
    xlabel(strcat(x1, {' '}, 'ppm')); 
    ylabel(strcat(x2, {' '}, 'ppm'));
    grid on
end
t = sgtitle(sprintf('Bivariate plots for %s (mineral assemblage)', x1));
t.FontSize = 12;
lgd = legend(L, mineralNames, 'Location', 'eastoutside'); 
lgd.Title.String = 'Minerals'; 
lgd.FontSize= 10;

end