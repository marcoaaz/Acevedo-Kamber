import qupath.lib.regions.*
import qupath.imagej.tools.IJTools
import qupath.opencv.tools.OpenCVTools
import org.bytedeco.opencv.opencv_core.Size
import static org.bytedeco.opencv.global.opencv_core.*
import static org.bytedeco.opencv.global.opencv_imgproc.*
import ij.*

// Read BufferedImage region
def server = getCurrentServer()
def roi = getSelectedROI()
double downsample = 4.0
def request = RegionRequest.createInstance(server.getPath(), downsample, roi)
def img = server.readBufferedImage(request)

// Convert to an OpenCV Mat, then apply a difference of Gaussians filter
def mat = OpenCVTools.imageToMat(img)
mat2 = mat.clone()
GaussianBlur(mat, mat2, new Size(15, 15), 2.0)
GaussianBlur(mat, mat, new Size(15, 15), 1.0)
subtract(mat, mat2, mat)
mat2.close()

// Convert Mat to an ImagePlus, setting pixel calibration info & then show it
def imp = OpenCVTools.matToImagePlus(mat, "My image")
IJTools.calibrateImagePlus(imp, request, server)
imp.show()
