% Create the function for the ValueChangedFcn callback:
function cBoxAll(src, event, cb_cell, fig, lbl3)

data = guidata(fig);
sel_layer = data.selLayer;
sel_level = data.selLevel;
ref_size_list = data.refSizeList;
str0_1 = data.maxHeapSize;

sel_layer_prev = data.selLayerPrev; %
data.selLayerPrev = sel_layer; %caching

val = event.Value;
n_items = length(cb_cell);
for i = 1:n_items
    cb_current = cb_cell{i};
    if val
        cb_current.Enable = 'off';
        sel_layer(i) = 1;
    else
        cb_current.Enable = 'on';
        sel_layer(i) = sel_layer_prev(i);
    end
end
% display(sel_layer)

data.selLayer = sel_layer;
guidata(fig, data) %place it back

%modify text
str4 = ref_size_list(sel_level + 1)*sum(sel_layer); %indexing starts in 1
if str4 < str0_1
    size_text = sprintf('File size estimate = <em>%.3f GB (uncompressed)</em>', str4);
else
    size_text = sprintf('File size estimate = <b style="color:red;"><em>%.3f GB (uncompressed)</em></b>', str4);
end
lbl3.Text = size_text;

end