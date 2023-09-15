%% Database Barplots

function barplotSpotDB(countA, countB, snames, mnames, triplet)

spotsTotal = sum(countA, 'all');
fontSize = 8;

figure(1)

hFig=gcf;
set(hFig, 'Position', [80 50 400 700]);
ha = tight_subplot(2, 1, [.09 .04], [.1 .1], [.1 .04]);

axes(ha(1)); %upper graph

p2 = bar(countA, 'stacked', 'FaceColor', 'flat');
colormap(jet);
for k = 1:size(countA, 2) %setting up legend
    p2(k).CData = k;
end
xlabel('Mineral'); 
set(gca, 'XTick', 1:size(countB, 2), 'xticklabel', mnames, 'fontsize', fontSize);
ylabel('Total');
grid on 
title('Spots per mineral'); %graph properties
lgd2 = legend(snames, 'Location', 'eastoutside');
lgd2.Title.String = 'Samples'; 
lgd2.FontSize = fontSize;

axes(ha(2)); %lower graph

p1 = bar(countB, 'stacked');
rColors = triplet; %creating color matrix (= PhaseMap)
for j = 1:size(countB, 2) %setting up legend
    p1(j).FaceColor = 'flat';
    p1(j).CData = repmat(rColors(j, :), size(countA, 2), 1);
end
xlabel('Sample'); 
set(gca, 'XTick', 1:size(countA, 2), 'xticklabel', snames, 'fontsize', fontSize);
xtickangle(60)
ylabel('Total');
grid on
title('Spots per sample'); %graph properties
lgd1 = legend(mnames, 'Location', 'eastoutside'); 
lgd1.Title.String = 'Minerals'; 
lgd1.FontSize = fontSize;

t = sgtitle(['Stacked barplots: population= ', num2str(spotsTotal)]);
t.FontSize = fontSize*1.5;

clear p1 p2 lgd1 lgd2 j k hFig

end