function plotStackedV(AIM_pct, minerals, labels2, triplet1, destinationDir)
%Stacked bar plot (vertical)

n_masks = length(minerals);
n_minerals = length(labels2);

fontSize = 10;

hFig = figure; %stacked barplot
set(hFig, 'Position', [600 150 700 400]); %left-bottom width height

%rows are minerals, columns are percentages
p = barh(1:n_masks, AIM_pct', 0.5, 'stack');

%Layout
axis([0 inf 0 n_masks+1]); %[xmin xmax ymin ymax]
yhandle = xlabel('Sample');
set(gca, 'YTickLabel', minerals, 'fontsize', fontSize*0.8) % Change tick labels
yticks(1:n_masks); 
% ytickangle(90)
set(yhandle, 'FontSize', fontSize) 
set(yhandle,'FontWeight','bold') %bold font

xlabel('Wt %'); 
tl = title('Modal mineralogy');
tl.FontSize = fontSize*1.2;
%Legend
for j = 1:n_minerals
    %    colorSet = [colorSet myColors];
    p(j).FaceColor = 'flat';
    p(j).CData = repmat(triplet1(j, :), n_masks, 1);
end
lgd = legend(p, labels2, 'Location', 'eastoutside');
lgd.FontSize = fontSize*0.8;
lgd.Title.String = 'Mineral';
set(gca, 'YDir','reverse')

hold off

figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'mineralogyLogHistogramH.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end
