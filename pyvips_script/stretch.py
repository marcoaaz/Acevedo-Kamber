# -*- coding: utf-8 -*-
"""
Created on Sat Apr  9 09:32:29 2022

@author: n10832084
"""

#!/usr/bin/python3

import sys
import pyvips

image = pyvips.Image.new_from_file(sys.argv[1])
low = image.percent(1) #5
high = image.percent(99) #95
image = (image - low) * (255 / (high - low))

image = image.cast("uchar")
#left, top, width, height = image.find_trim(threshold=2, background=[0, 0, 0])
#image = image.crop(left, top, width, height)

image.write_to_file(sys.argv[2])