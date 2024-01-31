function [split_parameters] = montageSplitTH(mosaic_edges, th_manual, destDir2)

th_edges = [mosaic_edges(1) th_manual-1 mosaic_edges(end)];
n_channels = length(th_manual) + 1;

split_parameters = zeros(n_channels, 5);
for m = 1:n_channels
    split_parameters(m, 1) = th_edges(m);
    split_parameters(m, 2) = th_edges(m+1);
    range_temp = th_edges(m + 1) - th_edges(m); 

    split_parameters(m, 3) = range_temp;
    split_parameters(m, 4) = 255/range_temp;
    split_parameters(m, 5) = range_temp/256;
end

end