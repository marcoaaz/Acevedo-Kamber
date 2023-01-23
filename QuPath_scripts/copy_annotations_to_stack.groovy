import static qupath.lib.gui.scripting.QPEx.*
import qupath.lib.regions.ImagePlane

def imageData = getCurrentImageData()
def server = imageData.getServer()

int zStart = 0
int zEnd = server.nZSlices()-1
int tStart = 0
int tEnd = server.nTimepoints()-1
def newObjects = []
def planeList = []

if (server.nZSlices() >0 || server.nTimepoints() >0){

    for (int t = tStart; t <= tEnd; t++) {
        for (int z = zStart; z <= zEnd; z++) {
            def plane_temp = ImagePlane.getPlane(z, t)
            planeList.addAll(plane_temp)
        }
    }
    int n_planes = planeList.size() - 1

    for (int ii = 0; ii <= n_planes; ii++) {
        def plane = planeList.get(ii)
        def selected = getSelectedObjects().findAll {it.getROI().getImagePlane() == plane}
        if (!selected) {
            println 'Using all annotations on selected slice'
            selected = getAnnotationObjects().findAll {it.getROI().getImagePlane() == plane}
        }

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
    }

}

println 'Adding ' + newObjects.size() + ' object(s)'
println newObjects
addObjects(newObjects)

PathObject updatePlane(pathObject, z, t) {
    def roi = GeometryTools.geometryToROI(pathObject.getROI().getGeometry(), ImagePlane.getPlane(z, t))
    return PathObjects.createAnnotationObject(roi, pathObject.getPathClass())
}
