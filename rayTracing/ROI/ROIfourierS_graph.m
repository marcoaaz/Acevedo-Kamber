function ROIfourierS_graph(roiHandle, sel_modes, available)

fitCell = roiHandle.UserData.fitRGB;
xCell = roiHandle.UserData.xCell;
yCell = roiHandle.UserData.yCell;
legendCell = roiHandle.UserData.legendCell;


%% Plot 1: Raw spectra

hFig = figure(9);
clf('reset') %clearing the automatic plot
pos = get(hFig, 'Position');
set(hFig, 'Position', pos);
ha = tight_subplot(1, 2, [.08 .08], [.08 .1], [.06 .08]);

k = 0;
for sel = sel_modes %[2, 3], ppl and xpl
    k = k + 1;

    fitresult = fitCell{k};
    w = fitresult{1}.w; %assuming 1 channel (bounded estimation)
    optical_period = 2*pi/w; %period

    xData = xCell{k};
    yData = yCell{k};
    legend_str = legendCell{k};

    axes(ha(k));

    h1 = plot(fitresult{1}, xData{1}, yData{1}, '*r');
    hold on
    h2 = plot(fitresult{2}, xData{2}, yData{2}, '*g');
    hold on
    h3 = plot(fitresult{3}, xData{3}, yData{3}, '*b');
    hold off

    %config
    extraMargin = 0.05*max([yData{:}], [], 'all'); %10
    xlim([0, optical_period+ 1])
    ylim([min([yData{:}], [], 'all')-extraMargin, max([yData{:}], [], 'all')+extraMargin])
%     ylim([0, 255])
    grid on
    set(h1(2), 'color', [1, 0, 0])
    set(h2(2), 'color', [0, 1, 0])
    set(h3(2), 'color', [0, 0, 1])
    legend(legend_str, 'Location', 'SouthOutside', 'Interpreter', 'none');
    title(strcat('Pixel profile: ', available{sel}))
    xlabel('Angle°', 'Interpreter', 'none');
    ylabel('Pixel (8-bit)', 'Interpreter', 'none');    
end

end