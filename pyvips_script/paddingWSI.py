# -*- coding: utf-8 -*-
"""
Created on Wed Apr 13 13:27:26 2022

@author: n10832084
"""

#!/usr/bin/python3

#https://libvips.github.io/pyvips/enums.html#pyvips.enums.CompassDirection
#https://libvips.github.io/pyvips/vimage.html#pyvips.Image.gravity
            
import os
import sys
import pyvips

size = sys.argv[2].split()
width_sz = int(size[0])
height_sz = int(size[1])

for filename in sys.argv[1:]:
    x = pyvips.Image.new_from_file(filename)
    x = x.gravity("north-west", width_sz, height_sz, background=0)
    
    pathName, file_extension = os.path.splitext(filename)
    
    x.write_to_file(pathName + "_padded" + file_extension)