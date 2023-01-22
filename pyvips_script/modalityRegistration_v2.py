# -*- coding: utf-8 -*-
"""
Created on Mon May 23 17:04:16 2022

@author: n10832084
"""


#!/usr/bin/python3

#documentation at:
#https://github.com/libvips/libvips/issues/2600
#https://stackoverflow.com/questions/47852390/making-a-huge-image-mosaic-with-pyvips
#https://scikit-image.org/docs/stable/api/skimage.registration.html#skimage.registration.phase_cross_correlation

import os
import sys; print(sys.version)
import glob
import re
import time

import pyvips
import numpy as np; print("numpy version: {}".format(np.__version__))
import matplotlib.pyplot as plt
import skimage; print("skimage version: {}".format(skimage.__version__))
from skimage.color import rgb2gray
from skimage.registration import phase_cross_correlation
from skimage import data, draw
from scipy import ndimage as ndi

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

print(f"registering to {fixed_name}...")
start = time.time()

pattern1 = re.compile(r".*/(.*)\.tif")
wsi_series = []
for filename in glob.glob(f"{sys.argv[1]}/*.tif"):
    match = pattern1.match(filename)
    if match:
        str_temp = match.group(1)        
    wsi_series.append(str_temp)

#n_moving = len(moving_orientations)
#static_width = 5000
scale_pyramid = 2**2 #exported level '0'=1
scale = 4 #even number
# 

shift_modality = []
for idx in range(1, 2): #2
    wsi_list = [s for s in wsi_series if moving_names[idx] in s]    
    base_orientation = [m for m in wsi_series if filename_orientation[idx] in m]    
    
    moving_orientations = set(wsi_list) - set(base_orientation)
    moving_orientations_ls = list(moving_orientations)
    moving_orientations_ls.sort() #alphabetical
    
    #fixed
    fileName_fixed = os.path.join(imageFolder, base_orientation[0] + '.tif')
    print('fixed:' + base_orientation[0])
    
    #small_fixed = pyvips.Image.thumbnail(fileName_fixed, static_width)    
    temp_fixed = pyvips.Image.new_from_file(fileName_fixed, access="sequential") #access="sequential"    
    small_fixed = temp_fixed.resize(1/scale)    
    width = int(float(small_fixed.get("width")))
    height = int(float(small_fixed.get("height")))
    print(f"fixed WxH= {width}x{height}, for algorithm")
    
    mem_fixed = small_fixed.write_to_memory()
    np_fixed = np.ndarray(buffer= mem_fixed,
                    dtype=format_to_dtype[small_fixed.format],
                    shape=[small_fixed.height, small_fixed.width, small_fixed.bands])
    grey_fixed = rgb2gray(np_fixed)
    mask = np.ones(grey_fixed.shape).astype(bool) #mask for phase-correlation (optional)
    
    #moving loop
    shift_orientation = []
    k = 0
    for moving_image in moving_orientations_ls: #for moving_image in moving_orientations_ls:, moving_image= moving_orientations_ls[3]
        fileName = os.path.join(imageFolder, moving_image + '.tif')
        fileName_parse = f"{fileName}"
        k = k + 1
        print('moving ' + str(k) + ': ' + moving_image)           
        
        #small_moving = pyvips.Image.thumbnail(fileName_parse, static_width) #kernel="nearest",  
        temp_moving = pyvips.Image.new_from_file(fileName_parse, access="sequential") #access="sequential"
        small_moving = temp_moving.resize(1/scale)
        
        mem_moving = small_moving.write_to_memory()
        np_moving = np.ndarray(buffer= mem_moving,
                        dtype=format_to_dtype[small_moving.format],
                        shape=[small_moving.height, small_moving.width, small_moving.bands])
        grey_moving = rgb2gray(np_moving)        
        
        #registration
        #Returns the (y,x) shifts and the normalized rms error (shift, error, phasediff)
        shift = phase_cross_correlation(grey_moving, grey_fixed,                                          
                                        upsample_factor = scale,
                                        normalization= None) 
        #, space='real', upsample_factor = scale, overlap_ratio=0.95, 
        #, reference_mask=mask, normalization= None,
        
        shift = np.asarray(shift, dtype="object")*scale_pyramid
        shift_orientation.append(shift)
        
        #np.set_printoptions(precision=3)
        print(f"Detected pixel offset (row, col): {shift}") #:.12f
        #print(f"Detected pixel offset (row, col): {np.around(shift, 3)}")
        
    #end loop
    shift_modality.append(shift_orientation)
        

print(base_orientation)
print(moving_orientations_ls)

print(f"write took {(time.time() - start)/60} min")

#%%

offset_image = ndi.shift(grey_moving, shift[-1]/scale_pyramid)

fig, (ax1, ax2, ax3) = plt.subplots(1, 3, sharex=True, sharey=True,
                                    figsize=(8, 3))

ax1.imshow(grey_fixed, cmap='gray')
ax1.set_axis_off()
ax1.set_title('Reference image')

ax2.imshow(grey_moving, cmap='gray')
ax2.set_axis_off()
ax2.set_title('Corrupted, offset image')

ax3.imshow(offset_image, cmap='gray')
ax3.set_axis_off()
ax3.set_title('Masked pixels')

plt.show()



            