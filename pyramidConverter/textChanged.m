% Code the callback function.
function textChanged(src, event, fig, lbl3)

data = guidata(fig);
sel_layer = data.selLayer;
str0_1 = data.maxHeapSize;
sel_level = event.Value;
ref_size_list = data.refSizeList;

data.selLevel = sel_level;

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