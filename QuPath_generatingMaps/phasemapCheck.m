function [PM_RGB] = phasemapCheck(phasemap1, minerals1, triplet1, rot_angle, destinationDir)

%rot_angle: rotation angle for displaying (0, 90, 180, etc.)
n_masks1 = length(minerals1);
triplet2 = double(triplet1);

PM_RGB_temp = label2rgb(phasemap1, triplet2, 'k', 'noshuffle'); %convert to RGB
PM_RGB = imrotate(PM_RGB_temp, rot_angle); %activate: if section is vertical

%Plot
hFig = figure;
imshow(PM_RGB, triplet2);

%colorbar
posTicks = (1:(n_masks1 + 1)) - 0.5;
Ticks = posTicks/n_masks1; %scaled from 0 to 1
c = colorbar('eastoutside', 'Ticks', Ticks, 'TickLabels', minerals1, ...
    'TickDirection', 'out', 'TickLength', 0.005); %include empty pixels
set(c, 'YDir', 'reverse');
c.AxisLocation = 'out';
c.FontSize = 8;
c.Label.String = 'Mineral masks';
c.Label.FontSize = 10;
%accommodate colorbar
decrease_by = 0.05; 
axpos = get(gca, 'position');
axpos(3) = axpos(3) - decrease_by;
set(gca, 'position', axpos);

%save RGB image for registration
imageFile = 'phasemap_RGB.tif';
fullDest = fullfile(destinationDir, imageFile); 
imwrite(PM_RGB, fullDest, 'Compression', 'none'); %save tif 24-bit

%save figure window
figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'phasemap_legend.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end