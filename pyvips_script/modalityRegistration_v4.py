# -*- coding: utf-8 -*-
"""
Created on Wed May 25 11:37:20 2022

@author: n10832084
"""

#!/usr/bin/python3

#documentation at:
#https://github.com/libvips/libvips/issues/2600
#https://stackoverflow.com/questions/47852390/making-a-huge-image-mosaic-with-pyvips
#https://scikit-image.org/docs/stable/api/skimage.registration.html#skimage.registration.phase_cross_correlation
#https://www.libvips.org/API/current/Examples.md.html

import os
import sys; print(sys.version)
import glob
import re
import time

import pyvips
import numpy as np; print("numpy version: {}".format(np.__version__))
import skimage; print("skimage version: {}".format(skimage.__version__))
from skimage.color import rgb2gray
from skimage.registration import phase_cross_correlation

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


# sectionName = '2512-PTS'
# unfoldDir = os.path.join(imageFolder, sectionName + '_flat2')
# os.mkdir(unfoldDir)
# print("Directory '% s' created" % sectionName)

imageFolder = os.path.join(sys.argv[1], sys.argv[2])

filename_modality_str = "x_RL x_ppl x_xpl" #["mean", "median", "sum"]
filename_orientation_str = "x_ppl-0_ x_xpl-0_"
filename_modality = filename_modality_str.split()
filename_orientation = filename_orientation_str.split()

fixed_idx = 0
fixed_name = filename_modality[fixed_idx]
moving_names = list(set(filename_modality) - set([fixed_name]))
moving_names.sort()

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

#file names
pattern1 = re.compile(r".*/(.*)\.tif")
wsi_series = []
for filename in glob.glob(f"{imageFolder}/*.tif"): #(f"{sys.argv[1]}/*.tif"):
    match = pattern1.match(filename)
    if match:
        str_temp = match.group(1)        
    wsi_series.append(str_temp)

#%% Affine matrix calculation


#56Kx38Kx3, 10X magnification, 6GB flat image
static_width = 2800 #15K, < min(width, height)
scale_pyramid = 2**4 #exported level '0'=1
desired_upscale = 50*scale_pyramid #even number
# scale0 = 61592 x 45753
# scale2 = 15398x11439
# scale3 = 7699x5720
# scale4 = 3850x2860

print('\n')
print(f"registering to {fixed_name}...")
print(f"ROIs will be {static_width}x{static_width}")

start = time.time()

shift_modality = []
error_modality = []
for idx in range(0, 2): #2
    wsi_list = [s for s in wsi_series if moving_names[idx] in s]    
    base_orientation = [m for m in wsi_series if filename_orientation[idx] in m]    
    
    moving_orientations = set(wsi_list) - set(base_orientation)
    moving_orientations_ls = list(moving_orientations)
    moving_orientations_ls.sort() #alphabetical
    
    print('\n')
    print('fixed:' + base_orientation[0])
    print('moving:' + ' '.join(moving_orientations_ls))
    print('\n')
    
    #fixed
    fileName_fixed = os.path.join(imageFolder, base_orientation[0] + '.tif')       
    temp_fixed = pyvips.Image.new_from_file(fileName_fixed, access="sequential") #access="sequential"    
    small_fixed = temp_fixed.crop(0, 0, static_width, static_width)
    
    mem_fixed = small_fixed.write_to_memory()
    np_fixed = np.ndarray(buffer= mem_fixed,
                    dtype= format_to_dtype[small_fixed.format],
                    shape= [small_fixed.height, small_fixed.width, small_fixed.bands])
    grey_fixed = rgb2gray(np_fixed)
    #mask for phase-correlation (optional)
    #mask = np.ones(grey_fixed.shape).astype(bool)     
    
    #moving loop
    shift_orientation = []
    error_orientation = []
    k = 0
    for moving_image in moving_orientations_ls: 
        k = k + 1
        fileName = os.path.join(imageFolder, moving_image + '.tif')         
        print('moving ' + str(k) + ': ' + moving_image)           
        
        temp_moving = pyvips.Image.new_from_file(fileName, access="sequential") #access="sequential"
        small_moving = temp_moving.crop(0, 0, static_width, static_width)
        
        mem_moving = small_moving.write_to_memory()
        np_moving = np.ndarray(buffer= mem_moving,
                        dtype= format_to_dtype[small_moving.format],
                        shape= [small_moving.height, small_moving.width, small_moving.bands])
        grey_moving = rgb2gray(np_moving)        
        
        #(y,x) shifts and the normalized rms error (shift, error, phasediff)
        shift, error, __ = phase_cross_correlation(grey_moving, grey_fixed,                                                                                  
                                        normalization= 'phase', overlap_ratio=0.7,
                                        upsample_factor = desired_upscale) 
        #, space='real', upsample_factor = scale, overlap_ratio=0.95, 
        #, reference_mask=mask, normalization= None,
        
        shift = np.asarray(shift, dtype="object")*scale_pyramid
        T = np.identity(3)
        T[0][2] = shift[1]
        T[1][2] = shift[0]
        shift_orientation.append(T)
        error_orientation.append(error)                                  
        print(f"Translation: row, y= {shift[0]:.4f}; col, x= {shift[1]:.4f}; rms error= {error:.4f}") #:.12f        
        
    #end loop
    shift_modality.append(shift_orientation)
    error_modality.append(error_orientation)

print('\n')
print(f"Alignment estimation took {(time.time() - start)/60:.2} min")
print('\n')

#%% Image registration
#https://github.com/libvips/pyvips/issues/226

imageFolder_fullRes = os.path.join(sys.argv[1], sys.argv[3])

start = time.time()

for idx in range(0, 2): #2
    wsi_list = [s for s in wsi_series if moving_names[idx] in s]    
    base_orientation = [m for m in wsi_series if filename_orientation[idx] in m]    
        
    moving_orientations_ls = wsi_list
    moving_orientations_ls.sort() #alphabetical      
    
    #moving loop
    k = 0
    for moving_image in moving_orientations_ls:
        k = k + 1        
        
        fileName = os.path.join(imageFolder_fullRes, moving_image + '.tif')        
        destFolder = fileName.replace('.tif', '')
        
        print(f"Registering..{moving_image}") #:.12f
        temp_moving = pyvips.Image.new_from_file(fileName, access="sequential") #access="sequential"
        
        #Image registration
        if k == 1: #fixed image at the top
            T= np.identity(3) 
        else:
            T = shift_modality[idx][k-2]                   
        
        #T has to be inverted (QuPath 'Image aligner' convention)
        
        registered_moving = temp_moving.affine((T[0][0], T[0][1], T[1][0], T[1][1]), 
                                              odx = T[0][2], ody = T[1][2],
                                              oarea = (0, 0, 
                                                        temp_moving.width, 
                                                        temp_moving.height))         
        
        registered_moving.dzsave(destFolder, tile_size=4096, 
                                  overlap=0, depth='one', suffix='.tif')                               
        
    #end loop
   
print('\n')
print(f"Image registration took {(time.time() - start)/60:.2} min")
print('\n')


#%% Image registration





            