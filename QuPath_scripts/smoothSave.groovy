import static qupath.lib.gui.scripting.QPEx
import qupath.lib.images.writers.ome.OMEPyramidWriter

def tilesize = 512
def outputDownsample = 1
def pyramidscaling = 2
def compression = OMEPyramidWriter.CompressionType.J2K_LOSSY     //J2K //UNCOMPRESSED //LZW

def imageData = getCurrentImageData()

def op = ImageOps.buildImageDataOp()
        .appendOps(ImageOps.Filters.gaussianBlur(10.0),
                ImageOps.Core.ensureType(qupath.lib.images.servers.PixelType.UINT8))

def serverSmooth = ImageOps.buildServer(imageData, op, imageData.getServer().getPixelCalibration())
print serverSmooth.getPreferredDownsamples()

def pathOutput = buildFilePath(PROJECT_BASE_DIR, "smoothed-32.ome.tif")

new OMEPyramidWriter.Builder(serverSmooth)
        .compression(compression)
        .parallelize()
        .tileSize(tilesize)
        .channelsInterleaved() // Usually faster
        .scaledDownsampling(outputDownsample, pyramidscaling)
        .build()
        .writePyramid(pathOutput)
