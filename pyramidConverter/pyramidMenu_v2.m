function pyramidMenu_v2(ref_table3)

close all
h = findall( 0, 'type', 'figure' ); %clear 
h.delete

%available options
list_n = size(ref_table3, 1);
list_options = ref_table3.SeriesName;
n_levels_oly = ref_table3.PyramidLevels(1); %assuming consistency
scaleFactor = 2; %default, edit manually

ref_sizes = ref_table3.MB(1)*(scaleFactor.^(-2*([1:n_levels_oly] - 1)));
%add extra 33% file size (if single output pyramid without compression)
ref_size_list = 1.335*ref_sizes/1024; %GB

%default values
sel_layer = logical(ones(1, list_n)); %logical
sel_level = 2;
str4 = ref_size_list(sel_level + 1)*sum(sel_layer); %indexing starts in 1

%RAM information
% javaRAM = 24; %keep <75% of physical RAM memory
% javaCall = sprintf('java -server -Xms1g -Xmx%dg -Xss8m ', javaRAM);
javaCall = 'java '; %default (8GB in 32GB)

command_java = [javaCall '-XX:+PrintFlagsFinal -version | find "MaxHeapSize"'];
[status_java, cmdout_java] = system(command_java);
if status_java == 1
    disp(cmdout_java)
end

%JDK installation info
expression2 = 'java version\s\S*';
str0_2 = regexp(cmdout_java, expression2, 'match');
str0_2 = string(str0_2);
expression1 = 'MaxHeapSize\s*=\s(\d*)';
str0_1 = regexp(cmdout_java, expression1, 'tokens');
str0_1 = str2double(string(str0_1{1}))/(1024^3); %chose first one

%MatLab settings
[userview, systemview] = memory;
str1 = userview.MemUsedMATLAB/(1024^3);
str2 = userview.MemAvailableAllArrays/(1024^3);
str3 = systemview.PhysicalMemory.Total/(1024^3);
memory_text = sprintf([...
    '<b style="color:blue;">Current system specifications </b>(info. panel):\n\n', ...
    '       <em>%s</em> in use of MaxHeapSize = <em>%.1f GB</em>\n\n', ...
    '       Memory used (MatLab arrays) = <em>%.2f GB</em>\n\n', ...
    '       Memory available (MatLab) = <em>%.1f GB</em>\n\n', ...
    '       Physical memory (RAM) = <em>%.1f GB</em>'], ...
    str0_2, str0_1, str1, str2, str3);

%Visual checking
str_javaVM = version('-java');
fprintf(['JVM within system() function:\n', ...
    '   ', str_javaVM, '\n',  'Note: compare with Windows JDK installation path.\n'])

%GUI data for callback functions
data.selLayer = sel_layer;
data.selLayerPrev = sel_layer; %maybe not required
data.selLevel = sel_level;
data.refSizeList = ref_size_list;
data.maxHeapSize = str0_1;

%% Figure window:

fig_width = 550;
fig_height = 700;
fig = uifigure('Name', 'Input menu', 'Position', [100 100 fig_width fig_height]);
fig.WindowButtonMotionFcn = @mouseMoved;

guidata(fig, data) %upload

%% Selecting pyramid level

y_start = 240;
y_step = 25;
p = uipanel(fig, 'Position', [20 50 fig_width-40 280]);

%File size estimate
if str4 < str0_1
    size_text = sprintf('File size estimate = <em>%.3f GB (uncompressed)</em>', str4);
else
    size_text = sprintf('File size estimate = <b style="color:red;"><em>%.3f GB (uncompressed)</em></b>', str4);
end
lbl3 = uilabel(p, 'Text', size_text, ...
    'Position', [10 y_start-2*y_step 300 20]);
lbl3.Interpreter = 'html';

%Selection
lbl1 = uilabel(p, 'Text', '', ...
    'Position', [10 y_start-y_step 210 20]);
lbl1.Text = '<b style="color:blue;">Max. desired resolution =</b>';
lbl1.Interpreter = 'html';
ef1 = uieditfield(p, 'Numeric', 'RoundFractionalValues','on', ...
    'Position', [160 y_start-y_step 25 20], ...
    'Value', 2, 'Enable', 'on', 'Editable', 'on', ...
    'ValueChangedFcn', {@textChanged, fig, lbl3});
ef1.Limits = [0 n_levels_oly-1]; %indexing starts at 0 (pyramid model)

fraction_text = sprintf('<em>/ %d  level index</em>', n_levels_oly-1);
lbl2 = uilabel(p, 'Text', fraction_text, ...
    'Position', [190 y_start-y_step 150 20]);
lbl2.Interpreter = 'html';

%info panel: RAM memory
lbl4 = uilabel(p, 'Text', memory_text, 'Position', [10 10 fig_width-40 160]);
lbl4.Interpreter = 'html';

%% Image

lbl_image = uilabel(fig, 'Position', [fig_width*2/3-40 fig_height-40 150 25]);
lbl_image.Text = '<b style="color:blue;">Image pyramid model:</b>';
lbl_image.Interpreter = 'html';

im = uiimage(fig, 'Position', [fig_width*1/3+20 340 fig_width*2/3-20 fig_height/2-40]);
im.ImageSource = 'wikipedia_img.png';

%% Check box group

bg = uibuttongroup('Parent', fig, 'Position', [20 340 fig_width*1/3 fig_height/2]);

cb_cell = cell(1, list_n);
for i = 1:list_n
    cb = uicheckbox(bg, 'Value', 1, ...
        'Position', [25 300-i*20 200 12]);
    cb.Text = list_options{i};
    cb.Enable = 'off';
    cb.ValueChangedFcn = {@cBoxChanged, i, fig, lbl3}; %new
    
    cb_cell{i} = cb;
end

% Selector above
cbx = uicheckbox(bg, 'Value', 1, ...
    'Position', [18 312 200 12], ...
    'ValueChangedFcn', {@cBoxAll, cb_cell, fig, lbl3});
cbx.Text = 'Select all';

%% Submit (filter button)

btnX = fig_width/3;
btnY = 10;
btnWidth = 120;
btnHeight = 25;

btn = uibutton(fig, 'push', 'ButtonPushedFcn', {@ButtonPushed_out, fig});
btn.Position = [btnX btnY btnWidth btnHeight];
btn.Text = 'Process';

    function ButtonPushed_out(src, event, fig)
    data = guidata(fig);
    sel_layer = data.selLayer;
    sel_level = data.selLevel;    
    
    disp(sel_layer)
    disp(sel_level) 
    assignin("base", "sel_layer", sel_layer) %bring it to workspace
    assignin("base", "sel_level", sel_level)

    disp('Updated output.')    
    closereq();
    end

    function mouseMoved(src, event)
    mousePos = fig.CurrentPoint;
    if (mousePos(1) >= btnX) && (mousePos(1) <= btnX + btnWidth) ...
            && (mousePos(2) >= btnY) && (mousePos(2) <= btnY + btnHeight)
          fig.Pointer = 'hand';
    else
          fig.Pointer = 'arrow';
    end
    end   

end