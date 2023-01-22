function opticalWave3D(roiHandle)
%E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\ROI
%Function for plotting spectra using a dynamic ROI handle

fitCell = roiHandle.UserData.fitRGB;
% xCell = roiHandle.UserData.xCell;
% yCell = roiHandle.UserData.yCell;
% legendCell = roiHandle.UserData.legendCell;

sel_ch_idx = 3;
model_st.ppl_model = fitCell{1}{sel_ch_idx};
model_st.xpl_model = fitCell{2}{sel_ch_idx};
  
laps = 1;
x1_sg = 1:laps*180; %free to choose
[original, modelPolar, ppl_max_calc, shifted] = fPolarOffset(x1_sg, model_st);    

%% Plot 2: optical wave in 3D

hFig = figure(10);
pos = get(hFig, 'Position');
set(hFig, 'Position', pos);

% plot3(x1_sg, original{1}, original{2}, '*k')
% hold on
plot3(x1_sg, shifted{1}, shifted{2}, '*b')
hold off
grid on
ylim([0, 1])
zlim([0, 1])
xlabel('Angle (radians)')
ylabel('PPL intensity')
zlabel('XPL intensity')
title(sprintf('Luminosity wave, offset= %.0f degrees', ppl_max_calc))

end