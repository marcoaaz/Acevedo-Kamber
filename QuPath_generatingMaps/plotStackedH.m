function plotStackedH(AIM_pct, minerals, triplet, destinationDir)
%Stacked bar plot (horizontal)
%only considers labels > 0 (background)

n_masks = length(minerals);
fontSize = 10;

hFig = figure; %stacked barplot
set(hFig, 'Position', [600 150 700 400]); %left-bottom width height

%rows are minerals, columns are percentages
p = bar(1:n_masks, AIM_pct', 0.5, 'stack');

%Layout
axis([0 n_masks+1 0 inf]);

ylabel('Frequency % (row-wise)'); 

xhandle = xlabel('Target mineral', 'Interpreter','none');
set(xhandle, 'FontSize', fontSize) 
set(xhandle, 'FontWeight', 'bold') %bold font
set(gca, 'XTickLabel', minerals, 'fontsize', fontSize) % Change tick labels
xticks(1:n_masks); 
xtickangle(90)
xaxisproperties= get(gca, 'XAxis');
xaxisproperties.TickLabelInterpreter = 'none'; 

tl = title('Association index matrix');
tl.FontSize = fontSize*1.2;

%Legend
for j = 1:length(minerals)
    %    colorSet = [colorSet myColors];
    p(j).FaceColor = 'flat';
    p(j).CData = repmat(triplet(j, :), n_masks, 1);
end
lgd = legend(p, minerals, 'Location', 'eastoutside', 'Interpreter', 'none');
lgd.FontSize = fontSize*0.8;
lgd.Title.String = 'Contacting mineral';

figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'AIMstackedHistogramH.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end