function plotLogHistogramH(pixelPopulations, PM_names, triplet, destinationDir)

%Horizontal histogram (log10 X-axis)

n_masks = length(pixelPopulations);
population_pct = 100*pixelPopulations/sum(pixelPopulations);

figure; 
hFig=gcf;
set(hFig, 'Position', [900 50 500 700]); %left-bottom width height

x = 1:n_masks;
y = pixelPopulations;
min_value = 10^floor(log10(min(y)));
max_value = 10^ceil(log10(max(y)));

fontSize = 9;
handleToThisBarSeries = gobjects(n_masks, 1);
for i = 1:n_masks
  
  %Plot one single bar as a separate bar series.
  handleToThisBarSeries(i) = barh(x(i), y(i), 'BarWidth', 0.9);
  % Apply the color to this bar series.
  set(handleToThisBarSeries(i), 'FaceColor', triplet(i,:));
 
  % Place text on the bar
%   barTopper = CommaFormat(y(i));
  barTopper = sprintf('%0.1f pct', population_pct(i));  
  
%   text(2*min_value, x(i), barTopper, 'FontSize', fontSize, 'FontWeight','bold', 'BackgroundColor', 'w');%*0.8
  text(1.2*y(i), x(i), barTopper, ...
      'FontSize', fontSize, 'FontWeight','bold', 'BackgroundColor', 'w');%*0.8
    
  hold on;  
  
end
grid on;
xticks(power(10, 0:10));
xlim([min_value, max_value]); %comfortability
yticks(1:n_masks);
set(gca, 'YDir', 'reverse');
set(gca, 'XScale', 'log');

title('Modal mineralogy by Vol.%', 'FontSize', fontSize*1.2);
xlabel('Population (log-scale)', 'FontSize', fontSize*1.2);
ylabel('Ranked list', 'FontSize', fontSize*1.2);
lgd = legend(handleToThisBarSeries, PM_names, 'Location', 'southeastoutside'); %'southeast'
lgd.NumColumns = 1;
lgd.FontSize = 9;

%save figure window
figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'mineralogyLogHistogramH.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end