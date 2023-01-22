# -*- coding: utf-8 -*-
"""
Created on Mon May 23 13:05:41 2022

@author: n10832084
"""

#!/usr/bin/python3

#documentation at:
#https://github.com/libvips/libvips/issues/2600
#https://stackoverflow.com/questions/47852390/making-a-huge-image-mosaic-with-pyvips
#https://scikit-image.org/docs/stable/api/skimage.registration.html#skimage.registration.phase_cross_correlation

import os
import sys
import pyvips
import glob
import re
import skimage
from skimage.color import rgb2gray
from skimage.registration import phase_cross_correlation
import numpy as np
#import imgreg_dft as ird #requires python v2.7

# map vips formats to np dtypes
format_to_dtype = {
    'uchar': np.uint8,
    'char': np.int8,
    'ushort': np.uint16,
    'short': np.int16,
    'uint': np.uint32,
    'int': np.int32,
    'float': np.float32,
    'double': np.float64,
    'complex': np.complex64,
    'dpcomplex': np.complex128,
}

# map np dtypes to vips
dtype_to_format = {
    'uint8': 'uchar',
    'int8': 'char',
    'uint16': 'ushort',
    'int16': 'short',
    'uint32': 'uint',
    'int32': 'int',
    'float32': 'float',
    'float64': 'double',
    'complex64': 'complex',
    'complex128': 'dpcomplex',
}

imageFolder = sys.argv[1] 
filename_modality_str = "x_RL x_ppl x_xpl" #["mean", "median", "sum"]
filename_orientation_str = "x_ppl-0_ x_xpl-0_"
filename_modality = filename_modality_str.split()
filename_orientation = filename_orientation_str.split()

fixed_idx = 0
fixed_name = filename_modality[fixed_idx]
moving_names = list(set(filename_modality) - set([fixed_name]))

#QuPath: image aligner copy-paste
valueSet_modalities = [    
    [
     [1.0000, 	 0.0000,	 0.5227], 
     [-0.0000,	 1.0000,	 2.0219]
     ], #ppl
    [
     [1.0000, 	 0.0000,	 -2.2757], 
     [0.0000,	 1.0000,	 1.9821] 
    ], #%xpl
    ]

#%% Parsing file names


pattern1 = re.compile(r".*/(.*)\.tif")
wsi_series = []
for filename in glob.glob(f"{sys.argv[1]}/*.tif"):
    match = pattern1.match(filename)
    if match:
        str_temp = match.group(1)        
    wsi_series.append(str_temp)

#n_moving = len(moving_orientations)
scale = 10
shift_modality = []
for idx in range(0, 1): #2
    wsi_list = [s for s in wsi_series if moving_names[idx] in s]    
    base_orientation = [m for m in wsi_series if filename_orientation[idx] in m]    
    moving_orientations = list(set(wsi_list) - set([base_orientation]))
    moving_orientations.sort() #alphabetical
    
    
    #fixed
    fileName_fixed = os.path.join(imageFolder, base_orientation[0] + '.tif')
    print('fixed:' + base_orientation[0])
    
    temp_fixed = pyvips.Image.new_from_file(fileName_fixed, access="sequential") #access="sequential", 
    temp_fixed_rz = temp_fixed.resize(1/scale, vscale= 1/scale)
    mem_fixed = temp_fixed_rz.write_to_memory()
    np_fixed = np.ndarray(buffer=mem_fixed,
                   dtype=format_to_dtype[temp_fixed_rz.format],
                   shape=[temp_fixed_rz.height, temp_fixed_rz.width, temp_fixed_rz.bands])
    grey_fixed = rgb2gray(np_fixed)
    
    #moving loop
    shift_orientation = []
    k = 0
    for moving_image in moving_orientations:   
        fileName = os.path.join(imageFolder, moving_image + '.tif')
        fileName_parse = f"{fileName}"
        k = k + 1
        print('moving ' + str(k) + ': ' + moving_image)           
        
        temp_moving = pyvips.Image.new_from_file(fileName_parse, kernel="nearest", access="sequential") #access="sequential"
        temp_moving_rz = temp_moving.resize(1/scale, vscale= 1/scale)
        mem_moving = temp_moving_rz.write_to_memory()
        np_moving = np.ndarray(buffer=mem_moving,
                       dtype=format_to_dtype[temp_moving_rz.format],
                       shape=[temp_moving_rz.height, temp_moving_rz.width, temp_moving_rz.bands])
        grey_moving = rgb2gray(np_moving)

        shift, error, phasediff = phase_cross_correlation(grey_moving, grey_fixed, space='real') #upsample_factor = scale, overlap_ratio=0.95
        shift_orientation.append(shift)
        
        print(shift_orientation) 
        
    shift_modality.append(shift_orientation)
        
#     for y in range(0, tiles_down):
#         for x in range(0, tiles_across):
#             

print(shift_modality)    




            