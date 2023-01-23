import static qupath.lib.gui.scripting.QPEx.*

import javafx.application.Platform
import qupath.lib.images.ImageData
import qupath.lib.images.servers.ImageServerProvider
import qupath.lib.images.servers.TransformedServerBuilder

import java.awt.image.BufferedImage

def path1 = 'C:\\Users\\Acer\\Desktop\\fullFile test\\Image_90.vsi - 4x_ppl_0_01'
def path2 = 'C:\\Users\\Acer\\Desktop\\fullFile test\\Image_90.vsi - 4x_ppl_18_01'

// Open two images
def server1 = ImageServerProvider.buildServer(path1, BufferedImage)
def server2 = ImageServerProvider.buildServer(path2, BufferedImage)

// Extract a channel from the second image
server2 = new TransformedServerBuilder(server2)
        //.extractChannels(2)
        .build()

// Merge the images by concatenating channels
def serverMerged = new TransformedServerBuilder(server1)
        .concatChannels(server2)
        .build()

// Open in the current viewer
def imageData = new ImageData<BufferedImage>(serverMerged)
Platform.runLater {
    getCurrentViewer().setImageData(imageData)
}
