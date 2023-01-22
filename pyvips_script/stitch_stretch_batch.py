# -*- coding: utf-8 -*-
"""
Created on Tue Apr 12 11:13:17 2022

@author: n10832084
"""
#!/usr/bin/python3

#documentation at:
#https://libvips.github.io/pyvips/vimage.html
#https://www.libvips.org/API/current/Examples.html
#https://github.com/libvips/libvips/issues/2600   
    
    
import os
import sys
import pyvips
import glob
import re

imageFolder = sys.argv[1]
sourceFolder = os.path.split(imageFolder)
sourceFolder2 = sourceFolder[-1]

filename_mode_str = sys.argv[2]
#filename_mode = "max min std" #["mean", "median", "sum"]
filename_mode = filename_mode_str.split()

# scan tileset
max_x = 0
max_y = 0
root = ""
pattern = re.compile(r".*/(.*)_(\d+)_(\d+)\.tif")
for filename in glob.glob(f"{sys.argv[1]}/*_*_*.tif"):
    match = pattern.match(filename)
    if match:
        root = match.group(1)
        max_x = max(max_x, int(match.group(2)))
        max_y = max(max_y, int(match.group(3)))
print(f"mosaic of WxH= {max_x + 1}x{max_y + 1} tiles")

tiles_across = max_x + 1
tiles_down = max_y + 1

for statsMode in filename_mode:
    print(f"statistic running: {sourceFolder2} in {statsMode}")
    #load tiles and rejoin
    tiles = []
    for y in range(0, tiles_down):
        for x in range(0, tiles_across):
            fileName_expression = f"{x}_{y}.tif"
            fileName = os.path.join(imageFolder, statsMode + "_" + fileName_expression)
            fileName_parse = f"{fileName}"
            tiles.append(pyvips.Image.new_from_file(fileName_parse))
            
    image = pyvips.Image.arrayjoin(tiles, across=tiles_across)
    
    #crop background borders (optional)
    #left, top, width, height = image.find_trim(threshold=1, background=[0])
    #image = image.crop(left, top, width, height) #modify accordingly
    
    if not ((statsMode == 'minIndex') | (statsMode == 'maxIndex')):        
        #stretch and format
        low = image.percent(1) #5
        high = image.percent(99) #95
        image = (image - low) * (255 / (high - low))
    image = image.cast("uchar")
    
    parentFolder = os.path.abspath(os.path.join(imageFolder, os.pardir))
    
    #Pipeline A: paper 1
    #destFile = os.path.join(parentFolder, sourceFolder2 + "_" + statsMode + ".tif")    
    #image.write_to_file(destFile)    
    
    #Pipeline B: upload to OlyVIA/ASW server 
    #ome_to_vips (saves as float, IrfanView sees RGB)    
    destFile = os.path.join(parentFolder, sourceFolder2 + "_" + statsMode + ".ome.tif")
    image.write_to_file(destFile, predictor="horizontal", compression="lzw", 
                        tile=True, tile_width=512, tile_height=512,  
                       pyramid=True, subifd=True, bigtiff=True) # compression="lzw", "deflate"
    