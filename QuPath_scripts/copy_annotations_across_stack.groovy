/**
 * Copy QuPath annotations across see_annotations_stack or timepoints.
 *
 * This is a convenience script to help (slightly) annotating in 3D or 4D images.
 *
 * (This hasn't been very thoroughly checked - if it doesn't seem to work for you,
 * it might just not work... you can use the comments to discuss this)
 *
 * @author Pete Bankhead
 */

// Specify how many extra see_annotations_stack/timepoints to add
// These values can be negative (to go in the opposite direction)
int deltaZ = 1
int deltaT = 0

def viewer = getCurrentViewer()
def plane = viewer.getImagePlane()
def selected = getSelectedObjects().findAll {it.getROI().getImagePlane() == plane}
if (!selected) {
    println 'Using all annotations on selected slice'
    selected = getAnnotationObjects().findAll {it.getROI().getImagePlane() == plane}
}

int zStart = deltaZ < 0 ? plane.getZ() + deltaZ : plane.getZ()
int tStart = deltaT < 0 ? plane.getT() + deltaT : plane.getT()
int zEnd = deltaZ < 0 ? plane.getZ() : plane.getZ() + deltaZ
int tEnd = deltaT < 0 ? plane.getT() : plane.getT() + deltaT

print([zStart, zEnd])
print([tStart, tEnd])

def newObjects = []
for (int t = tStart; t <= tEnd; t++) {
    for (int z = zStart; z <= zEnd; z++) {
        print([z, t])
        if (z == plane.getZ() && t == plane.getT())
            continue
        def updated = selected.collect { updatePlane(it, z, t) }
        newObjects.addAll(updated)
        if (Thread.interrupted()) {
            println 'Interrupted!'
            return
        }
    }
}
println 'Adding ' + newObjects.size() + ' object(s)'

println newObjects
addObjects(newObjects)


PathObject updatePlane(pathObject, z, t) {
    def roi = GeometryTools.geometryToROI(pathObject.getROI().getGeometry(), ImagePlane.getPlane(z, t))
    return PathObjects.createAnnotationObject(roi, pathObject.getPathClass())
}
