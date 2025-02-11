function plotGranulometry(finer_pixels, original_pixels, sizeMax, minerals, triplet, resolution, destinationDir)

n_masks = size(finer_pixels, 1);

%settings
fontSize = 8;
% resolution= 3.91; %microns/pixel (PhaseMap bf.1, MBS-4)
X = (1:sizeMax)*resolution; 

%Y-axis
Y1 = zeros(n_masks, sizeMax); 
Y2_temp = zeros(1, sizeMax);
finer_frequencies = zeros(n_masks, sizeMax);
Y2 = zeros(n_masks, sizeMax);
for i = 1:n_masks
    %cummulative
    Y1(i, :) = 100*finer_pixels(i, :)/original_pixels(i); 
    %frequencies
    Y2_temp(1, 2:end) = finer_pixels(i, 1:end-1);
    finer_frequencies(i, :) = finer_pixels(i, :) - Y2_temp(1, :);
    Y2(i, :) = 100*(finer_frequencies(i, :))/original_pixels(i); 
end
Y3 = 100*sum(finer_pixels, 1, 'omitnan')/sum(original_pixels, 'omitnan');%old: nansum
Y4 = 100*sum(finer_frequencies, 1, 'omitnan')/sum(original_pixels, 'omitnan');

figure
for i = 1:n_masks        
    h(i) = plot([0 X], [0 Y1(i, :)], '-', 'Color', triplet(i, :), ...
        'MarkerSize', 4, 'LineWidth', 1);
    hold on
end
hold off
grid on
% set(gca,'color',[0 0 0]) %black background
ylim([0, Inf]);
lgd = legend(h, minerals, 'Location', 'eastoutside', 'FontSize', fontSize*0.8);
title(lgd, 'Minerals')
title('Grain size distribution', 'FontSize', fontSize*1.2);
xlabel('Sieve size (microns)');
ylabel('Cummulative pixel %');

figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'cummulative.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

figure
for i = 1:n_masks    
    h(i) = plot([0 X], [0 Y2(i, :)], '-', 'Color', triplet(i, :), ...
        'MarkerSize', 4, 'LineWidth', 1);
    hold on
end
hold off
grid on
ylim([0, Inf]);
lgd = legend(h, minerals, 'Location', 'eastoutside', 'FontSize', fontSize*0.8);
title(lgd,'Minerals')
title('Granulometry frequency', 'FontSize', fontSize*1.2);
xlabel('Sieve size (microns)');
ylabel('Pixel %');

figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'frequency.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

%Total graph
figure
%cummulative   
h1 = plot([0 X], [0 Y3], '-', 'Color', 'b', 'MarkerSize', 4, 'LineWidth', 1);
hold on
%frequencies
h2 = plot([0 X], [0 Y4], '-', 'Color', 'r', 'MarkerSize', 4, 'LineWidth', 1);
hold off
grid on
ylim([0, Inf]);
lgd = legend([h1 h2], {'cummulative', 'frequencies'}, ...
    'Location', 'eastoutside', 'FontSize', fontSize*0.8);
title(lgd, 'Line')
title('Total cummulative and frequency', 'FontSize', fontSize*1.2);
xlabel('Sieve size (microns)');
ylabel('Pixel %');

figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'total.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end