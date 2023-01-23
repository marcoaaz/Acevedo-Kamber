/**
 * Transform an ImageServer to 8-bit in QuPath, with scaling.
 *
 * Note that this *kind of* works (I think) in v0.2... but is quite hack-y,
 * and may not be entirely reliable (i.e. I've seen some errors).
 *
 * @author Pete Bankhead
 */


import qupath.lib.color.ColorModelFactory
import qupath.lib.images.servers.ImageServer
import qupath.lib.images.servers.ImageServerBuilder
import qupath.lib.images.servers.ImageServerMetadata
import qupath.lib.images.servers.PixelType
import qupath.lib.images.servers.TransformingImageServer
import qupath.lib.images.writers.ome.OMEPyramidWriter
import qupath.lib.regions.RegionRequest

import java.awt.image.BufferedImage
import java.awt.image.DataBuffer
import java.awt.image.WritableRaster

import static qupath.lib.gui.scripting.QPEx.*

def imageData = getCurrentImageData()

// Output server path
def path = buildFilePath(PROJECT_BASE_DIR, 'converted-8bit-other.ome.tif')

// Create a scaling & bit-depth-clipping server
def server = new TypeConvertServer(imageData.getServer(), 100f, 0f)

// Write the pyramid
new OMEPyramidWriter.Builder(server)
        .parallelize()
        //.downsamples(20)
        .downsamples(server.getPreferredDownsamples())
        .bigTiff()
        .channelsInterleaved()
        .build()
        .writePyramid(path)
print 'Done!'

class TypeConvertServer extends TransformingImageServer<BufferedImage> {

    private float scale = 1f
    private float offset = 0
    private ImageServerMetadata originalMetadata
    def cm = ColorModelFactory.getDummyColorModel(8)

    protected TypeConvertServer(ImageServer<BufferedImage> server, float scale, float offset) {
        super(server)
        this.scale = scale
        this.offset = offset
        this.originalMetadata = new ImageServerMetadata.Builder(server.getMetadata())
                .pixelType(PixelType.UINT8)
                .build()
    }

    public ImageServerMetadata getOriginalMetadata() {
        return originalMetadata
    }

    @Override
    protected ImageServerBuilder.ServerBuilder<BufferedImage> createServerBuilder() {
        throw new UnsupportedOperationException()
    }

    @Override
    protected String createID() {
        return TypeConvertServer.class.getName() + ": " + getWrappedServer().getPath() + " scale=" + scale + ", offset=" + offset
    }

    @Override
    String getServerType() {
        return "Type converting image server"
    }

    public BufferedImage readBufferedImage(RegionRequest request) throws IOException {
        def img = getWrappedServer().readBufferedImage(request);
        def raster = img.getRaster()
        int nBands = raster.getNumBands()
        int w = img.getWidth()
        int h = img.getHeight()
        def raster2 = WritableRaster.createInterleavedRaster(DataBuffer.TYPE_BYTE, w, h, nBands, null)
        float[] pixels = null
        for (int b = 0; b < nBands; b++) {
            pixels = raster.getSamples(0, 0, w, h, b, (float[])pixels)
            for (int i = 0; i < w*h; i++) {
                pixels[i] = (float)GeneralTools.clipValue(pixels[i] * scale + offset, 0, 255)
            }
            raster2.setSamples(0, 0, w, h, b, pixels)
        }
        return new BufferedImage(cm, raster2, false, null)
    }

}