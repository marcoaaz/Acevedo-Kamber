/**
 If you have annotations within annotations, you may get duplicates. Ask on the forum or change the def pathObjects line.

 To use, have all objects desired in one image, and alignment files in the Affine folder within your project folder.
 If you have not saved those, this script will not work.
 It will use ALL of the affine transforms in that folder to transform the objects in the current image to the destination images
 that are named after the affine files.

 Requires creating each affine transformation from the destination images so that there are multiple transform files with different names.
 Michael Nelson 03/2020
 Script base on: https://forum.image.sc/t/interactive-image-alignment/23745/9
 and adjusted thanks to Pete's script: https://forum.image.sc/t/writing-objects-to-another-qpdata-file-in-the-project/35495/2
 */

// SET ME! Delete existing objects
def deleteExisting = true

// SET ME! Change this if things end up in the wrong place
def createInverse = false

import qupath.lib.objects.PathCellObject
import qupath.lib.objects.PathDetectionObject
import qupath.lib.objects.PathObject
import qupath.lib.objects.PathObjects
import qupath.lib.objects.PathTileObject
import qupath.lib.roi.RoiTools
import qupath.lib.roi.interfaces.ROI

import java.awt.geom.AffineTransform

import static qupath.lib.gui.scripting.QPEx.*

path = buildFilePath(PROJECT_BASE_DIR, 'Affine')

new File(path).eachFile{ f->
    f.withObjectInputStream {
        matrix = it.readObject()


        def name = getProjectEntry().getImageName()


// Get the project & the requested image name
        def project = getProject()
        def entry = project.getImageList().find {it.getImageName() == f.getName()}
        if (entry == null) {
            print 'Could not find image with name ' + f.getName()
            return
        }
        def imageData = entry.readImageData()
        def otherHierarchy = imageData.getHierarchy()
        def pathObjects = getAnnotationObjects()

// Define the transformation matrix
        def transform = new AffineTransform(
                matrix[0], matrix[3], matrix[1],
                matrix[4], matrix[2], matrix[5]
        )
        if (createInverse)
            transform = transform.createInverse()

        if (deleteExisting)
            otherHierarchy.clearAll()

        def newObjects = []
        for (pathObject in pathObjects) {
            newObjects << transformObject(pathObject, transform)
        }
        otherHierarchy.addPathObjects(newObjects)
        entry.saveImageData(imageData)
    }
}
print 'Done!'

/**
 * Transform object, recursively transforming all child objects
 *
 * @param pathObject
 * @param transform
 * @return
 */
PathObject transformObject(PathObject pathObject, AffineTransform transform) {
    // Create a new object with the converted ROI
    def roi = pathObject.getROI()
    def roi2 = transformROI(roi, transform)
    def newObject = null
    if (pathObject instanceof PathCellObject) {
        def nucleusROI = pathObject.getNucleusROI()
        if (nucleusROI == null)
            newObject = PathObjects.createCellObject(roi2, pathObject.getPathClass(), pathObject.getMeasurementList())
        else
            newObject = PathObjects.createCellObject(roi2, transformROI(nucleusROI, transform), pathObject.getPathClass(), pathObject.getMeasurementList())
    } else if (pathObject instanceof PathTileObject) {
        newObject = PathObjects.createTileObject(roi2, pathObject.getPathClass(), pathObject.getMeasurementList())
    } else if (pathObject instanceof PathDetectionObject) {
        newObject = PathObjects.createDetectionObject(roi2, pathObject.getPathClass(), pathObject.getMeasurementList())
    } else {
        newObject = PathObjects.createAnnotationObject(roi2, pathObject.getPathClass(), pathObject.getMeasurementList())
    }
    // Handle child objects
    if (pathObject.hasChildren()) {
        newObject.addPathObjects(pathObject.getChildObjects().collect({transformObject(it, transform)}))
    }
    return newObject
}

/**
 * Transform ROI (via conversion to Java AWT shape)
 *
 * @param roi
 * @param transform
 * @return
 */
ROI transformROI(ROI roi, AffineTransform transform) {
    def shape = RoiTools.getShape(roi) // Should be able to use roi.getShape() - but there's currently a bug in it for rectangles/ellipses!
    shape2 = transform.createTransformedShape(shape)
    return RoiTools.getShapeROI(shape2, roi.getImagePlane(), 0.5)
}
