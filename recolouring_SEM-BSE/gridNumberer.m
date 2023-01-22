function [referenceGrid, tiling_name] = gridNumberer(dim_tiles, sel_type, sel_order)

nrows_tiles = dim_tiles(1);
ncols_tiles = dim_tiles(2);

%Menu
tiling_type = {'row-by-row', 'column-by-column', 'snake-by-rows', 'snake-by-columns'};
tiling_order_hz = {'right & down', 'left & down', 'right & up', 'left & up'};
tiling_order_vt = {'down & right', 'down & left', 'up & right', 'up & left'};

%Naming
if mod(sel_type, 2) == 1 %odd
    tiling_order = tiling_order_hz;
    exterior_loop = dim_tiles(1);
    interior_loop = dim_tiles(2);
else
    tiling_order = tiling_order_vt;
    exterior_loop = dim_tiles(2);
    interior_loop = dim_tiles(1);
end
tiling_name = string(strcat('Type:', {' '}, tiling_type{sel_type}, ...
    '; Order:', {' '}, tiling_order{sel_order})); 
disp(tiling_name)

%Creating grid
count = 0;
referenceGrid = zeros(nrows_tiles, ncols_tiles);
for i = 1:exterior_loop
    for j = 1:interior_loop
        count = count + 1;
        
        switch sel_type
            case 1
                switch sel_order
                    case 1
                        row_index = i;                
                        col_index = j;
                    case 2
                        row_index = i;                
                        col_index = ncols_tiles-j+1; 
                    case 3
                        row_index = nrows_tiles-i+1;                
                        col_index = j; 
                    case 4
                        row_index = nrows_tiles-i+1;               
                        col_index = ncols_tiles-j+1;
                end 
            case 2
                 switch sel_order
                    case 1
                        row_index = j;                
                        col_index = i;
                    case 2
                        row_index = j;                
                        col_index = ncols_tiles-i+1; 
                    case 3
                        row_index = nrows_tiles-j+1;                
                        col_index = i; 
                    case 4
                        row_index = nrows_tiles-j+1;               
                        col_index = ncols_tiles-i+1;
                end                 
            case 3
                switch sel_order
                    case 1
                        row_index = i;
                        col_index = j;
                        if mod(row_index, 2) ~= 1 %pair                        
                            col_index = ncols_tiles-j+1;                   
                        end                        
                    case 2
                        row_index = i; 
                        col_index = j;
                        if mod(row_index, 2) == 1 %odd                        
                            col_index = ncols_tiles-j+1;                   
                        end 
                    case 3
                        row_index = nrows_tiles-i+1;                
                        col_index = j; 
                        if mod(row_index, 2) ~= 1 %pair                       
                            col_index = ncols_tiles-j+1;                   
                        end
                    case 4
                        row_index = nrows_tiles-i+1;               
                        col_index = ncols_tiles-j+1;
                        if mod(row_index, 2) == 1 %odd                       
                            col_index = j;                   
                        end
                end                
            case 4
                switch sel_order
                    case 1
                        row_index = j;
                        col_index = i;
                        if mod(col_index, 2) ~= 1 %pair                        
                            row_index = nrows_tiles-j+1;                   
                        end                        
                    case 2
                        row_index = j; 
                        col_index = ncols_tiles-i+1;
                        if mod(col_index, 2) == 1 %odd                        
                            row_index = nrows_tiles-j+1;                   
                        end 
                    case 3
                        row_index = nrows_tiles-j+1;                
                        col_index = i; 
                        if mod(col_index, 2) ~= 1 %pair                       
                            row_index = j;                   
                        end
                    case 4
                        row_index = nrows_tiles-j+1;               
                        col_index = ncols_tiles-i+1;
                        if mod(col_index, 2) == 1 %odd                       
                            row_index = j;                   
                        end
                end 
        end
        referenceGrid(row_index, col_index) = count; %
    end
end

end