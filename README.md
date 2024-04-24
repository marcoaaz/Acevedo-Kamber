# Semi-automated mineralogy using optical microscopy and pixel-based classification
The repository contains the scripts of a petrographic image analysis pipeline (Option A and Option B) that supports whole-slide imaging (multi-gigapixel files) for obtaining modal mineralogy. After acquisition in the [VS200 slide scanner](https://www.olympus-lifescience.com/en/solutions-based-systems/vs200/), the inputs are multi-pol optical scans downloaded with OlyVIA software via the local server access (NIS-SQL). Read the full documentation in Suplementary material 1 of the paper:

**Acevedo Zamora, M.A.; Kamber, B.S. Petrographic Microscopy with Ray Tracing and Segmentation from Multi-Angle Polarisation Whole-Slide Images. ***Minerals*** 2023, 13, 156. https://doi.org/10.3390/min13020156** 

Please, also cite the authors of the open-source software (Bioformats, QuPath, VIPS), who can be contacted at the largest bioinformatics imaging [forum](https://forum.image.sc/). 


## Workflow:

<img src="https://user-images.githubusercontent.com/61703106/213952990-e21d25d1-d3eb-430f-8b87-fbffcbb44cd5.jpg" width=70% height=70%>


Opening the QuPath optical mineral phase maps (exported in OME-TIFF) requires [BioFormats MatLab Toolbox](https://www.openmicroscopy.org/bio-formats/downloads/). After download, the folder 'bfmatlab' needs to be extracted and added to the 'path' of the MatLab script 'qupathPhaseMap_v7.m'. Bioformats needs to be downloaded separately since it was not possible to upload the 'bioformats_package.jar' to GitHub since it is >25 MB. If still presenting issues for running the code, send me an email (after carefully reading the paper). Thanks.


Brief description of functionalities:
1. libvips workflow
   + rank.py = maximum intensity projection of a group of images.
   + stretch.py = rescales the pixels to 5-95 percentiles and cast them as uint8 (*.tif)
   + stitch_stretch.py = stitches the tile-based operation images in “10_ppl” folder for one statistic (second argument)
   + stitch_stretch_batch.py = stitches the tile-based operation images in “10_ppl” folder for all statistics (focus group: “max min std” in sys.argv[2])
   + paddingWSI.py = fills zeros the bottom and right sides of the WSI to match the size of tile-based ray-tracing WSI.
   + export_ometiff.py = stack WSIs from flat-images (input folder) to a multi-channel image pyramid (OME-TIFF).
   + concatenate_ometiff.py = concatenate greyscale images into multiband image pyramid (LZW compression) for QuPath.
2. QuPath scripts (IntelliJ):   
   - QuPath-Concatenate channels.groovy = produce an image overlay with multiple channels and considers image transformations and stain deconvolution.
   - Concatenate_test.groovy = concatenate 2 image pyramids in a project.
   - copy_annotations_to_stack.groovy = copy stack annotations to one layer (without redundancy)
   - copy_annotations_across_stack.groovy = copy stack annotations to all layers (without redundancy)
   - see_annotations_stack.groovy = see transparent annotations across all layers in a stack with live update.
   - smoothSave.groovy = saves a live image filter image into an image pyramid.
   - miniViewer_live.groovy = shows the live image filters into canvas.
   - exportTiles.groovy = save indexed tiles (multi-channel) of a WSI into a folder.
3. AZtec (SEM-EDX software) adapter code:
   - pointGrid_quPath = saves an AZtec PhaseMap as a XYZ image for transforming them with thin plate spline transform with a BigWarp script (bigWarp_toArbritaryPoints.groovy) as point grid. The grid is reformatted for importing into QuPath as training data that contributes new classes.
3. MatLab workflow:
   - combineScript_parallel = bioformats convert between pyramids using parfor loop. Parse metadata, export flat images (GUI: pyramidMenu_v2.m)/all tiles, do image registration, and slicing.
   - statsStacks_tiledImport_dzsave.m = check standard tile sequence and perform ray tracing statistics ('mean', 'max', 'min', 'sum', 'std', 'median') using stats_zProject_tiled() function. Optionally, stitches the generated WSIs (later demands stretch.py script).
   - Stats_zProject_tiled_parallel.m = multi-thread ray tracing function for tile collections in sub-folders.
   - Stats_zProject.m = multi-thread ray tracing function for single image stacks (patches).
   - loadStack.m_v2 = reads image patch stacks (4D) and saves as multiplexed image (for Python).
     - It has a ray tracing demo section using ‘stats_zProject.m’.
   - Exploring PPL and XPL
     - stack_spectra_v4.m = reads frame image stack and shows PPL and XPL curves for 1 pixel or a ROI (dynamically). It works in RGB, CieLab and HSV. 
       - It uses createFit.m function within ROIfourierS_data.m function that plots its results with ROIfourierS_graph.m function. 
       - Includes several options for doing multi-pol edge-detection (still in developing)
       - createFit.m function that fits a 2-term Fourier series to pixel spectra.
       - ROIfourierSeriesGraph.m = plots spectra of a picked pixel.
       - opticalWave3D.m (..\ROI) = function to plot the optical spectra angle-PPL-XPL in 3D to compare minerals. Uses functions fPolarOffset.m (containing fourierPolar.m) to approximate the Fourier2 series in polar coordinates and measure the offset of PPL-max [0-180] degrees.
     - simulate_MLevy_v3.m script = plots Michel-Levy and Raith–Sørensen charts using Bloss (1999) equations. The [implementation](https://github.com/marcoaaz/Michel-Levy_colour-chart) follows [Sorensen (2013) paper](10.1127/0935-1221/2013/0025-2252). 
   - renamingSequence_v3.m (> \updated MatLab scripts\distCorr code) = script calculates histograms of a tile sequence (in any order, 16-bit) and stacks the histograms for representing the mosaic. Finally, it outputs a scroll-RGB (8-bit) image tiles of the BSE. Stitching has to be done elsewhere. The script uses multiTH_extract.m function while it renames a tile collection following any scanning pattern (following the ‘Stitching’ plugin in Fiji).
     - multiTH_extract.m = function that allows doing Otsu thresholding on 16-bit image.
   - incrementalPCA.m = function that performs PCA on a large number of images.
   - aztecPhasemap_v1.m = script reconstructs AZtec phase map exports.
   - plotLogHistogramH2.m = function that follows plotLogHistogramH for plotting modal mineralogy with stacked bar histogram and was reformatted for petrography by Balz K.
   - qupathPhaseMap_v7.m = interprets pixel classification maps from QuPath software in the MatLab environment and performs AIM, granulometry, and a few statistical analysis of the shapes.

## Updates

New users might find difficulties installing the dependencies to run the scripts. Ensure that you locate the paths of the functions outlined above. If there are further issues with the scripts and functions, please raise an issue. A Windows OS machine (with a virtual Linux machine) is required to run the sections of the scripts requiring to call the command line.

Thanks.
