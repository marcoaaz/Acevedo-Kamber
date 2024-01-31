
function montageLogHistogram(mosaic_edges, mosaic_counts, m_c_log_rescaled, thresh_h, destDir2)

N = length(thresh_h);
bin_width = mosaic_edges(2) - mosaic_edges(1);

hFig = figure;
hFig.Position = [100, 100, 1200, 600];

h1 = histogram('BinEdges', mosaic_edges, 'BinCounts', m_c_log_rescaled, ...
    'FaceAlpha', 0.5, 'FaceColor', [0.5, 0.5, 0], 'EdgeColor', 'none');
hold on
h2 = histogram('BinEdges', mosaic_edges, 'BinCounts', mosaic_counts, ...
    'FaceAlpha', 1, 'FaceColor', [0, 0, 0], 'EdgeColor', 'none');

yLimits = get(gca, 'YLim');  % Get the range of the y axis
xLimits = get(gca, 'XLim');
deltaX = (xLimits(2) - xLimits(1))/80;
for i = thresh_h    
    h3 = line([i, i], yLimits, 'LineWidth', 1, 'Color', 'r','LineStyle','--');
    % h3 = xline(thresh, '-b', 'LineWidth', 4);
    text_rotated = text(i - deltaX, yLimits(2)/2, num2str(round(i)), 'Color', 'b', 'Rotation', 90);
end
hold off
title(sprintf('Mosaic histogram, Multi-Outsu TH= %d', N))
ylabel('Counts & Log-counts (normalized)')
xlabel(sprintf('Intensity, bin width= %.1f (16-bits)', bin_width))

%Memo figure
saveas(hFig, fullfile(destDir2, 'mosaicInfo_plot.tiff'))

% figure_frame = getframe(gcf);
% fulldest = fullfile(destDir2, 'mosaicIntensities_log.tif'); 
% imwrite(figure_frame.cdata, fulldest, 'Compression', 'none')

end