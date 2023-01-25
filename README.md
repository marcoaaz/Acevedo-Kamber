# Acevedo-Kamber
Scripts of the petrographic image analysis pipeline (Option A and Option B). The input can be multi-pol optical scans of a full thin-section that have been downloaded from OlyVIA (Olympus ASW) software via a server access. See the full description in Acevedo Zamora and Kamber (2023) Suplementary material 1. 

Workflow:


<img src="https://user-images.githubusercontent.com/61703106/213952990-e21d25d1-d3eb-430f-8b87-fbffcbb44cd5.jpg" width=70% height=70%>

If using this code (or snippets), please cite the corresponding authors below and the open-source brain developers of the software used in recognition of their work. We specially thank the open-source bio-imaging community (https://forum.image.sc/) for the fundamental packages used within our pipeline. 

Citation in MDPI and ACS Style:


Acevedo Zamora, M.A.; Kamber, B.S. Petrographic Microscopy with Ray Tracing and Segmentation from Multi-Angle Polarisation Whole-Slide Images. Minerals 2023, 13, 156. https://doi.org/10.3390/min13020156 


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

