
function [] = ROIfourierSeriesGraph(roiHandle, pol_angle, px_rgb, color_space, sel_modes, range_modes, available)

logicalMask = createMask(roiHandle);
roiHandle.UserData.logicalMask = logicalMask(:);

%Default - edit accordingly
n_channels = 3; 
rl_range = range_modes{1};
ppl_range = range_modes{2};
xpl_range = range_modes{3};

%color_space= 1 %1=RGB, 2=CieLAB, 3=HSV
switch color_space
    case 1
        px = px_rgb;
        channelNames = {'R', 'G', 'B'};
    case 2
        px_lab = rgb2lab(px_rgb', 'ColorSpace', 'adobe-rgb-1998'); 
        px = px_lab';
        channelNames = {'L', 'a', 'b'};
    case 3
        px_hsv = rgb2hsv(px_rgb'/255);
        px = px_hsv';
        channelNames = {'H', 'S', 'V'};
end

%% Plot
hFig = figure(9);
clf('reset') %required for clearing the automatic plot
pos = get(hFig, 'Position');
set(hFig, 'Position', pos);
ha = tight_subplot(1, 2, [.08 .08], [.08 .1], [.06 .08]);

k= 0;
for sel = sel_modes %[2, 3], ppl and xpl
k = k + 1;
    switch sel
        case 1
            data = px(:, rl_range);%1:2 %(3xn_layers) selected     
            data_range = rl_range;
        case 2
            data = px(:, ppl_range);%3:8
            data_range = ppl_range;
            optical_period = 180; %10 steps ppl
        case 3
            data = px(:, xpl_range);%9:14
            data_range = xpl_range;
            optical_period = 90; %5 steps xpl
    end
    x = pol_angle(data_range); %as row    

    %default period
    w_fixed = 2*pi/(optical_period);
    
    fitresult = cell(1, n_channels);
    gof = cell(1, n_channels);
    period = cell(1, n_channels);
    xData = cell(1, n_channels);
    yData = cell(1, n_channels);
    legend_str = cell(1, n_channels);
    for c = 1:n_channels %1:n_channels
        y = data(c, :);
        [xData_temp, yData_temp] = prepareCurveData( x, y );

        %Fourier2
        [fitresult{c}, gof{c}] = createFit_one(xData_temp, yData_temp, w_fixed);
        %Fourier1
%         [fitresult{c}, gof{c}] = createFit_two(xData_temp, yData_temp, w_fixed);

        xData{c} = xData_temp;
        yData{c} = yData_temp;
        
        w = fitresult{c}.w;
        period{c} = 2*pi/w; %period
        legend_str{c} = {sprintf('%s: %0.1f', channelNames{c}, period{c}); 
            sprintf('%s_fit', channelNames{c})};
    
    end    
    legend_str = cat(1, legend_str{:});
    
    % Plot fit with data.
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
    grid on
    set(h1(2), 'color', [1, 0, 0])
    set(h2(2), 'color', [0, 1, 0])
    set(h3(2), 'color', [0, 0, 1])
    legend(legend_str, 'Location', 'NorthEast', 'Interpreter', 'none');
    title(strcat('Pixel profile: ', available{sel}))
    xlabel('Angle°', 'Interpreter', 'none');
    ylabel('Pixel (8-bit)', 'Interpreter', 'none');    
end

end