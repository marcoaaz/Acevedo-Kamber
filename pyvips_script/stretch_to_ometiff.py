# -*- coding: utf-8 -*-
"""
Created on Wed Apr 20 12:21:04 2022

@author: n10832084
"""

# -*- coding: utf-8 -*-
"""
Created on Sat Apr  9 09:32:29 2022

@author: n10832084
"""

#!/usr/bin/python3

import sys
import pyvips

image = pyvips.Image.new_from_file(sys.argv[1])

# openslide will add an alpha ... drop it
if image.hasalpha():
    image = image[:-1]  
    
low = image.percent(5) #5
high = image.percent(95) #95
image = (image - low) * (255 / (high - low))

image = image.cast("uchar")
#left, top, width, height = image.find_trim(threshold=2, background=[0, 0, 0])
#image = image.crop(left, top, width, height)

#image.write_to_file(sys.argv[2])

channel_list = []
r, g, b = image.bandsplit()
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

#ome_to_vips

im.write_to_file(sys.argv[2], compression="lzw", tile=True, 
                 tile_width=512, tile_height=512,  
                 pyramid=True, subifd=True, bigtiff=True)