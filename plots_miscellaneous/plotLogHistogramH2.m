function plotLogHistogramH2(pixelPopulations, PM_names, triplet, destinationDir)
%Horizontal histogram (log10 X-axis)

%data
n_masks = length(pixelPopulations);
population_pct = 100*pixelPopulations/sum(pixelPopulations);

hz_line_idx = find(population_pct < 1, 1); %
if isempty(hz_line_idx)
    hz_line_x = (2*n_masks + 1)/2;
else    
    hz_line_x = (2*hz_line_idx- 1)/2;
end

x = 1:n_masks;
y = pixelPopulations;

%setup
text1 = 'Rock-forming';
text2 = 'Accessories';
min_value = 10^floor(log10(min(y)));
max_value = 10^ceil(log10(max(y)));
barTopper = compose('%0.1f', population_pct); %sprintf
fontSize = 9;
fontColor = 'white';
handleToThisBarSeries = gobjects(n_masks, 1);
color_rockForming = 0.9*[1, 1, 1];
color_accessory = 0.7*[1, 1, 1];
xy_rockForming = [(hz_line_x)/2, 0.7*max_value];
xy_accessory = [(n_masks + hz_line_x)/2, 0.7*max_value];
patch_alpha = 1;

figure; 
hFig=gcf;
set(hFig, 'Position', [900 50 500 700]); %left-bottom width height

patch([min_value min_value max_value max_value], ...
    [hz_line_x n_masks+1 n_masks+1 hz_line_x], color_accessory,'FaceAlpha', patch_alpha)
hold on
patch([min_value min_value max_value max_value], ...
    [0 hz_line_x hz_line_x 0], color_rockForming, 'FaceAlpha', patch_alpha)

for i = 1:n_masks  
  
    %Plot one single bar as a separate bar series.  
    handleToThisBarSeries(i) = barh(x(i), y(i), 'BarWidth', 0.9);
  
    %bar color  
    set(handleToThisBarSeries(i), 'FaceColor', triplet(i,:)); 
  
    % Place text on the bar    
    txt1= text(1.2*min_value, x(i), PM_names{i}, ...
      'FontSize', fontSize*1.1, 'interpreter', 'none', ...
      'Color', fontColor, 'FontWeight', 'bold', 'FontSmoothing', 'off');  
end
% yline(hz_line_x, '-b', 'Rock-forming above', 'LabelHorizontalAlignment', 'right')


txt2= text(xy_rockForming(2), xy_rockForming(1), text1, ...
      'FontSize', fontSize*1.2, 'interpreter', 'none', ...
      'Color', 'b', 'FontWeight', 'bold', 'FontSmoothing', 'off', ...
      'Rotation', 270, 'HorizontalAlignment','center'); %90
txt3= text(xy_accessory(2), xy_accessory(1), text2, ...
      'FontSize', fontSize*1.2, 'interpreter', 'none', ...
      'Color', 'b', 'FontWeight', 'bold', 'FontSmoothing', 'off', ...
      'Rotation', 270, 'HorizontalAlignment','center');
hold off

xlim([min_value, max_value]); %comfortability
ylim([0, n_masks+1])

set(gca, 'XScale', 'log', 'XTick', power(10, 0:10), 'GridAlpha', .3, 'Layer', 'top');
xticks(power(10, 0:10)); %, 'Layer', 'top'

set(gca, 'YDir', 'reverse');
set(gca, 'ytick', [1:n_masks], 'yticklabel', barTopper, ...
    'XGrid', 'on', 'XMinorGrid', 'off')
set(gca, 'YAxisLocation', 'right')

title('Modal mineralogy (vol.% log-scale)', 'FontSize', fontSize*1.2);
xlabel('Pixel population', 'FontSize', fontSize*1.2);

%save figure window
figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'mineralogyLogHistogram2.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end