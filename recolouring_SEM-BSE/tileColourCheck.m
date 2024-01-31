function tileColourCheck(mosaicInfo, mosaic_edges, split_parameters, th_manual)

% h = findall( 0, 'type', 'figure' ); %clear 
% h.delete

%default values
destDir2 = '';
%sliders
sel_image = floor((mosaicInfo.n_images)/2) + 11;
filterSize = 3;
sliderWidth1 = mosaicInfo.n_images;
sliderWidth2 = 20;

%GUI first image
%Interpreting tiling pattern
[sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo);

%GUI data for callback functions
data.sld1_value = sel_image;
data.sld2_value = filterSize;
data.th_manual = th_manual;
data.split_parameters = split_parameters;

%% Interface

%Figure
fig_width = 1350;
fig_height = 600;

hFig = uifigure;
hFig.Name = 'SEM-BSE recolouring';
hFig.Position = [50, 50, fig_width, fig_height];

guidata(hFig, data) %upload

[img_med, img_greyscale] = recolouredTile(sel_image_ref, mosaicInfo, mosaic_edges, ...
    split_parameters, filterSize, destDir2);

%Framing
left_side = 1050;
y_start = 200;
y_step = 35;
width_panel = 1100;
y_val1 = y_start-y_step; %buttons
y_val2 = y_start-2*y_step;
y_val3 = y_start - 4*y_step;
left_button = 170;
left_text_box = 90; %edit box
width_text_box = 60;


%Original image
ax1 = uiaxes(hFig, 'Position', [50 50 500 500]);

hImg = imshow(img_greyscale,'Parent', ax1);
pixel_info = impixelinfo(hImg);
set(pixel_info, 'Position', [left_side 80 300 20])

ax1.Title.String = 'Original greyscale';

%Image being modified
ax2 = uiaxes(hFig, 'Position', [550 50 500 500]);

hImg1 = imshow(img_med,'Parent', ax2);
pixel_info = impixelinfo(hImg1);
set(pixel_info, 'Position', [left_side 50 300 20])

ax2.Title.String = sprintf( ...
    'Recoloured tile (%s) in RGB (%s)', sel_fN_s, sel_fN_r);
ax2.Title.Interpreter = 'none';

%synchronize
linkaxes([ax1, ax2], 'xy')

%% slider 1 (image tile)
sld1 = uislider(hFig, ...
    'ValueChangingFcn', @(sld1, event) slider1Moving(event, ax1, ax2, ...
    mosaicInfo, mosaic_edges, destDir2, hFig));

sld1.Position(1:3) = [200 50 700];
sld1.Limits = [1, sliderWidth1];
sld1.Value = sel_image; %default

%slider 2 (filter)
sld2 = uislider(hFig, ...
    'ValueChangingFcn', @(sld2, event) slider2Moving(event, ax2, ...
    mosaicInfo, mosaic_edges, destDir2, hFig));

sld2.Position(1:3) = [left_side 500 200];
sld2.Limits = [1, sliderWidth2];
sld2.Value = filterSize; %default

%Manual thresholds
p = uipanel(hFig, 'Position', [left_side 150 fig_width-width_panel 280]);

%Labels
lbl1 = uilabel(p, 'Text', '', ...
    'Position', [5 y_val1 100 20]);
lbl1.Text = '<b style="color:blue;">Threshold 1 =</b>';
lbl1.Interpreter = 'html';

lbl2 = uilabel(p, 'Text', '', ...
    'Position', [5 y_val2 100 20]);
lbl2.Text = '<b style="color:blue;">Threshold 2 =</b>';
lbl2.Interpreter = 'html';

%edit field 1
ef1 = uieditfield(p, 'Numeric', 'RoundFractionalValues','on', ...
    'Position', [left_text_box y_val1 width_text_box 20], ...
    'Enable', 'on', 'Editable', 'on', 'ValueDisplayFormat', '%.0f');
ef1.Limits = [0 65535];
ef1.Value = th_manual(1);

%edit field 2
ef2 = uieditfield(p, 'Numeric', 'RoundFractionalValues','on', ...
    'Position', [left_text_box y_val2 width_text_box 20], ...
    'Enable', 'on', 'Editable', 'on', 'ValueDisplayFormat', '%.0f');
ef2.Limits = [0 65535];
ef2.Value = th_manual(2);

%% Buttons

btn1 = uibutton(p, "Text", "Update1", "Position", [left_button y_val1 60 25]);
btn1.ButtonPushedFcn = @(src,event)buttonPushed1(ax2, ...
    mosaicInfo, mosaic_edges, destDir2, hFig, ef1);

btn2 = uibutton(p, "Text", "Update2", "Position", [left_button y_val2 60 25]);
btn2.ButtonPushedFcn = @(src,event)buttonPushed2(ax2, ...
    mosaicInfo, mosaic_edges, destDir2, hFig, ef2);

%OK button
btn3 = uibutton(p, "Text", "Update", "Position", [left_button y_val3 60 55]);
btn3.ButtonPushedFcn = @(src, event)ButtonPushed_out(hFig);
btn3.Text = 'OK';

end

%% Callback functions

%OK button
function ButtonPushed_out(hFig)

data = guidata(hFig);
tunnedSetup.sel_image = data.sld1_value;
tunnedSetup.filterSize = data.sld2_value;
tunnedSetup.split_parameters = data.split_parameters; 
tunnedSetup.th_manual = data.th_manual;

assignin("base", "tunnedParameters", tunnedSetup) %bring it to workspace
disp('Updated output.')    

closereq();
end

%bottom threshold
function buttonPushed1(ax, mosaicInfo, mosaic_edges, destDir2, hFig, ef1)

data = guidata(hFig);
th_manual = data.th_manual;    
sel_image = data.sld1_value;
filterSize = data.sld2_value;

value_temp = floor(ef1.Value);
th_manual(1) = value_temp;

[split_parameters] = montageSplitTH(mosaic_edges, th_manual, destDir2);

[sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo);

[img_med] = recolouredTile(sel_image_ref, mosaicInfo, mosaic_edges, ...
split_parameters, filterSize, destDir2);

ax.Children.CData = img_med;

%update
data.th_manual = th_manual;
data.split_parameters = split_parameters;
guidata(hFig, data)
end

%top threshold
function buttonPushed2(ax, mosaicInfo, mosaic_edges, destDir2, hFig, ef2)

data = guidata(hFig);
th_manual = data.th_manual;    
sel_image = data.sld1_value;
filterSize = data.sld2_value;

value_temp = floor(ef2.Value);
th_manual(2) = value_temp;

[split_parameters] = montageSplitTH(mosaic_edges, th_manual, destDir2);

[sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo);

[img_med] = recolouredTile(sel_image_ref, mosaicInfo, mosaic_edges, ...
split_parameters, filterSize, destDir2);

ax.Children.CData = img_med;

%update
data.th_manual = th_manual;
data.split_parameters = split_parameters;
guidata(hFig, data)
end

%Selected image tile
function slider1Moving(sld1, ax1, ax2, ...
    mosaicInfo, mosaic_edges, destDir2, hFig)
    
sel_image = floor(sld1.Value);

data = guidata(hFig);
filterSize = data.sld2_value;    
split_parameters = data.split_parameters;  

[sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo);

[img_med, img_greyscale] = recolouredTile(sel_image_ref, mosaicInfo, ...
    mosaic_edges, split_parameters, filterSize, destDir2);

ax1.Children.CData = img_greyscale;

ax2.Children.CData = img_med;
ax2.Title.String = sprintf( ...
    'Recoloured tile (%s) in RGB (%s)', ...
    sel_fN_s, sel_fN_r);
ax2.Title.Interpreter = 'none';

%update
data.sld1_value = sel_image;
guidata(hFig, data)
end

%Filter
function slider2Moving(sld2, ax, ...
    mosaicInfo, mosaic_edges, destDir2, hFig)
        
filterSize = floor(sld2.Value);

data = guidata(hFig);
sel_image = data.sld1_value;
split_parameters = data.split_parameters;  

[sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo);

[img_med] = recolouredTile(sel_image_ref, mosaicInfo, mosaic_edges, ...
split_parameters, filterSize, destDir2);

ax.Children.CData = img_med;

%update
data.sld2_value = filterSize;
guidata(hFig, data)
end

%% Helper function

function [sel_idx, sel_image_ref, sel_fN_s, sel_fN_r...
    ] = selectedToRefSelected(sel_image, mosaicInfo)
%Interpreting tiling pattern
desiredGrid = mosaicInfo.desiredGrid;
referenceGrid = mosaicInfo.referenceGrid;
fileNames_sorted = mosaicInfo.fileNames_sorted; %row-major
fileNames_renamed = mosaicInfo.fileNames_renamed;

%desiredGrid follows fileName_sorted (row-major down-right)
sel_idx = (desiredGrid == sel_image); 
sel_image_ref = referenceGrid(sel_idx);
sel_fN_s = fileNames_sorted{sel_image_ref};
sel_fN_r = fileNames_renamed{sel_idx}; %same as TrakEM2 canvas

end


