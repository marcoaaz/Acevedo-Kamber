function [PM_RGB] = phasemapCheck(phasemap1, minerals1, triplet1, mineral_targets, rot_angle, destinationDir)

%Input 
% phasemap1: labeled image after removing artifact classes around the sample fringes
% minerals1: corresponding re-labeled classes
% triplet1: corresponding RGB colours (respecting QuPath)
% minerals_targeted: relevant classes to separate
% rot_angle: rotation angle for displaying (0, 90, 180, etc.)
% destinationDir: folder to save outputs

phasemap_modif = phasemap1;
n_masks = length(minerals1);
triplet = double(triplet1);

present_temp = ismember(minerals1, mineral_targets);
n_masks1 = sum(present_temp);
triplet2 = triplet(present_temp, :);

k = 0;
for i = 1:n_masks
    mask_temp = (phasemap1 == i);
    if present_temp(i) == 1
        k = k + 1;
        phasemap_modif(mask_temp) = k;
    else
        phasemap_modif(mask_temp) = 0;
    end
end
phasemap1 = phasemap_modif;

PM_RGB_temp = label2rgb(phasemap1, triplet2, 'k', 'noshuffle'); %convert to RGB
PM_RGB = imrotate(PM_RGB_temp, rot_angle); %activate: if section is vertical

%% Plot

hFig = figure;

imshow(PM_RGB, triplet2);

%colorbar
posTicks = (1:(n_masks1 + 1)) - 0.5;
Ticks = posTicks/n_masks1; %scaled from 0 to 1
c = colorbar('eastoutside', 'Ticks', Ticks, 'TickLabels', mineral_targets, ...
    'TickDirection', 'out', 'TickLength', 0.005, 'TickLabelInterpreter','none'); %include empty pixels
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

%% save RGB image for registration

imageFile = 'phasemap_target_RGB.tif';
fullDest = fullfile(destinationDir, imageFile); 
imwrite(PM_RGB, fullDest, 'Compression', 'none'); %save tif 24-bit

%save figure window
figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'phasemap_target_legend.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end