# -*- coding: utf-8 -*-
"""
Created on Thu Apr  7 11:34:49 2022

@author: n10832084
"""

#import os
#vipshome = 'C:\\Users\\n10832084\\AppData\\Local\\vips-dev-8.12\\bin'
#os.environ['PATH'] = vipshome + ';' + os.environ['PATH']

import sys
import pyvips

images = [pyvips.Image.new_from_file(filename, access='sequential')
          for filename in sys.argv[2:]]

mips = images[0].bandrank(images[1:], index=len(images) - 1)
mips.write_to_file(sys.argv[1])

