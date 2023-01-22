
function ROIfourierS_data(roiHandle, img, color_space, range_modes, sel_modes, pol_angle)

%extracts logical mask
logicalMask = createMask(roiHandle);
sz = size(logicalMask);
ind = find(logicalMask); %column-major order
[row, col] = ind2sub(sz, ind);

px_rgb_test = double(img(row, col, :, :));
px_rgb = squeeze(mean(px_rgb_test, [1, 2]));
[px, channelNames] = switchColourSpace(px_rgb, color_space);

%% Fitting curves

n_channels = 3; 
rl_range = range_modes{1};
ppl_range = range_modes{2};
xpl_range = range_modes{3};

fitCell = cell(1, length(sel_modes));
xCell = cell(1, length(sel_modes));
yCell = cell(1, length(sel_modes));
legendCell = cell(1, length(sel_modes));
k= 0;
for sel = sel_modes %[2, 3], ppl and xpl

    k = k + 1;
    %Axis
    switch sel
        case 1
            data = px(:, rl_range);%1:2 %(3xn_layers) selected     
            data_range = rl_range;
            optical_period = 0;
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
    w_fixed = 2*pi/(optical_period);%default period
    
    %Fit model
    fitresult = cell(1, n_channels);
    gof = cell(1, n_channels);
    period = cell(1, n_channels);
    xData = cell(1, n_channels);
    yData = cell(1, n_channels);
    legend_str = cell(1, n_channels);

    for c = 1:n_channels %1:n_channels

        y = data(c, :);
        [xData_temp, yData_temp] = prepareCurveData( x, y );

        %Fourier-1
%         [fitresult{c}, gof{c}] = createFit_one(xData_temp, yData_temp, w_fixed);
        %Fourier-2
        [fitresult{c}, gof{c}] = createFit_two(xData_temp, yData_temp, w_fixed);

        xData{c} = xData_temp;
        yData{c} = yData_temp;
        
        w = fitresult{c}.w;
        period{c} = 2*pi/w; %period
        legend_str{c} = {sprintf('%s: %0.1f', channelNames{c}, period{c}); 
            sprintf('%s_fit', channelNames{c})};    
    end    
    
    %pass to other loop
    fitCell{k} = fitresult;
    xCell{k} = xData;
    yCell{k} = yData;
    legendCell{k} = cat(1, legend_str{:});
end

roiHandle.UserData.fitRGB = fitCell;
roiHandle.UserData.xCell = xCell;
roiHandle.UserData.yCell = yCell;
roiHandle.UserData.legendCell = legendCell;

end