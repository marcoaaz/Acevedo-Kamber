
import javafx.application.Platform
import org.locationtech.jts.geom.util.AffineTransformation
import qupath.lib.images.ImageData
import qupath.lib.images.servers.ImageChannel
import qupath.lib.images.servers.ImageServer
import qupath.lib.images.servers.ImageServers
import qupath.lib.roi.GeometryTools

import java.awt.geom.AffineTransform
import java.awt.image.BufferedImage
import java.util.stream.Collectors

import static qupath.lib.gui.scripting.QPEx.*
import qupath.lib.images.servers.TransformedServerBuilder

def project = getProject()
def entry = project.getImageList()
//def entry = project.getImageList().find {it.getImageName() == "Image_90.vsi - 4x_ppl-0_01"}
//def imageData = entry.readImageData()
//def currentServer = imageData.getServer()

print("Current image list: " + entry);
