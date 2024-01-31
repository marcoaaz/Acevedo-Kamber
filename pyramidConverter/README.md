The graphical user interface should be opened from the MatLab script 'combineScript_parallel.m' (found in the pyramidConverter folder). 

The figure below shows that:

1. The available image pyramid levels from the *.vsi files (proprietary format) can be read printed in the Command Window.
2. The 'SeriesName' index (see the printed table) should be entered as the 'Max. desired resolution'.
3. The multi-pol images to export should be thicked on the selection menu (top left) before clicking the 'Process' button (final step).

Interface:
<img src="https://github.com/marcoaaz/Acevedo-Kamber/assets/61703106/ca5f53bb-1b5c-46af-8f30-3756231e14cd" width=90% height=90%>

The current computer system specification are given in the panel below. The size of the processed image cannot be larger than the Java 'MaxHeapSize' at any time to avoid crashing the process. 

Running smoothly requires having a JDK installation (Java for developers) and changing the MaxHeapSize to accommodate larger images at any given time.
