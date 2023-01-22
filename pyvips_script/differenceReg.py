# -*- coding: utf-8 -*-
"""
Created on Sat Apr 16 09:57:33 2022

@author: n10832084
"""

#!/usr/bin/python3

#from pathlib import Path, PureWindowsPath
import sys
import pyvips

# text1 = 'r"' + sys.argv[1] + '"'
# text2 = 'r"' + sys.argv[2] + '"'
# path1 = Path(PureWindowsPath(text1))
# path2 = Path(PureWindowsPath(text2))    
# image1 = pyvips.Image.new_from_file(path1)
# image2 = pyvips.Image.new_from_file(path2)

image1 = pyvips.Image.new_from_file(sys.argv[1])
image2 = pyvips.Image.new_from_file(sys.argv[2])

image = image1.subtract(image2)
low = -255
high = +255
image = (image - low) * (255 / (high - low))

image = image.cast("uchar")

image.write_to_file(sys.argv[3])