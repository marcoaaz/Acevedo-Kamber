# -*- coding: utf-8 -*-
"""
Created on Wed Aug 24 12:17:53 2022

@author: n10832084

"""
#!/usr/bin/python3

#documentation at:
#https://libvips.github.io/pyvips/vimage.html#pyvips.Image.tiffsave
#https://libvips.github.io/pyvips/enums.html#pyvips.enums.ForeignTiffCompression
#https://github.com/libvips/pyvips/issues/170
#https://github.com/libvips/libvips/issues/2600

import os
import sys
import pyvips
import glob
print("vips version: " + str(pyvips.version(0))+"."+str(pyvips.version(1))+"."+str(pyvips.version(2)))

imageFolder = sys.argv[1]
filename = 'rgb.ome.tif'
  
channel_list = []      
filename_R = os.path.join(imageFolder, 'red.ome.tif')
filename_G = os.path.join(imageFolder, 'green.ome.tif')
filename_B = os.path.join(imageFolder, 'blue.ome.tif')

r = pyvips.Image.new_from_file(filename_R)    
if r.hasalpha():
    r = r[:-1]

g = pyvips.Image.new_from_file(filename_G)    
if g.hasalpha():
    g = g[:-1]
    
b = pyvips.Image.new_from_file(filename_B)    
if b.hasalpha():
    b = b[:-1]
    
channel_list.append(r)
channel_list.append(g) 
channel_list.append(b)                 

#stack vertically ready for OME 
im = pyvips.Image.arrayjoin(channel_list, across=1)

image_width = channel_list[0].width #image are of = XY size
image_height = channel_list[0].height
image_bands = len(channel_list)
print('Final Image dimentions(WxHxC):', image_width, image_height, image_bands)

#Set tiff tags necessary for OME-TIFF
im = im.copy()
im.set_type(pyvips.GValue.gint_type, "page-height", image_height)

# build minimal OME metadata. TODO: get calibration and channel names
im.set_type(pyvips.GValue.gstr_type, "image-description",
f"""<?xml version="1.0" encoding="UTF-8"?>
<OME xmlns="http://www.openmicroscopy.org/Schemas/OME/2016-06"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.openmicroscopy.org/Schemas/OME/2016-06 http://www.openmicroscopy.org/Schemas/OME/2016-06/ome.xsd">
    <Image ID="Image:0">
        <!-- Minimum required fields about image dimensions -->
        <Pixels DimensionOrder="XYCZT"                
                ID="Pixels:0"
                SizeC="{image_bands}"
                SizeT="1"
                SizeX="{image_width}"
                SizeY="{image_height}"
                SizeZ="1"
                Type="uint8">
        </Pixels>        
    </Image>
</OME>""")
im_name_str = filename.replace('.ome.tif', '.ome.tiff') #MIST output
im_name = os.path.join(imageFolder, im_name_str)

#vips_to_ome (saves as uint8, IrfanView sees greyscale)
im.tiffsave(im_name, compression="lzw", tile=True, 
            tile_width=512, tile_height=512, 
            pyramid=True, subifd=True, bigtiff = True) 
#note: 'lzw', 'jpeg', 'jp2k'; bigtiff = True

