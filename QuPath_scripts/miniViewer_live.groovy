//import static qupath.lib.gui.scripting.QPEx
import qupath.lib.gui.viewer.overlays.*
import qupath.lib.regions.*
import qupath.imagej.tools.IJTools
import qupath.imagej.gui.IJExtension
import ij.*
import qupath.opencv.tools.OpenCVTools
import org.bytedeco.opencv.opencv_core.Size
import static org.bytedeco.opencv.global.opencv_core.*
import static org.bytedeco.opencv.global.opencv_imgproc.*

// Request an ImageJ instance - this will open the GUI if necessary
// This isn't essential, but makes it it possible to interact with any image that is shown
IJExtension.getImageJInstance()

def makeServer(imageData, ops) {



    def op = ImageOps.buildImageDataOp().appendOps(*ops)
    def server = ImageOps.buildServer(imageData, op, imageData.getServer().getPixelCalibration())
    return server
}

def imageData = getCurrentImageData()
def ops = [
        ImageOps.Filters.gaussianBlur(10.0),
        ImageOps.Core.ensureType(qupath.lib.images.servers.PixelType.UINT8) // this clips values outside the 0 to 255 range so the tile exporter can save JPEG or PNG
]

def viewer = getCurrentViewer()
def overlay = PixelClassificationOverlay.create(
        viewer.getOverlayOptions(),
        imageData2 -> makeServer(imageData2, ops),
        null)

viewer.setCustomPixelLayerOverlay(overlay)
overlay.setLivePrediction(true)
