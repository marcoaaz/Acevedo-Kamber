# -*- coding: utf-8 -*-
"""
Created on Mon Apr 11 13:07:25 2022

@author: n10832084
"""

#!/usr/bin/python3

import os
import sys
import pyvips

imageFolder = sys.argv[1]
filename_mode = sys.argv[2]; #'median'
tiles_across = 19
tiles_down = 10

#load tiles and rejoin
tiles = []
for y in range(0, tiles_down):
    for x in range(0, tiles_across):
        fileName_expression = f"{x}_{y}.tif"
        fileName = os.path.join(imageFolder, filename_mode + "_" + fileName_expression)
        fileName_parse = f"{fileName}"
        tiles.append(pyvips.Image.new_from_file(fileName_parse))
        
image = pyvips.Image.arrayjoin(tiles, across=tiles_across)

#crop background borders (optional)
#left, top, width, height = image.find_trim(threshold=1, background=[0])
#image = image.crop(left, top, width, height) #modify accordingly

#stretch and format
low = image.percent(5)
high = image.percent(95)
image = (image - low) * (255 / (high - low))
image = image.cast("uchar")

parentFolder = os.path.abspath(os.path.join(imageFolder, os.pardir))
destFile = os.path.join(parentFolder, filename_mode + "_uint8.tif")
image.write_to_file(destFile)

