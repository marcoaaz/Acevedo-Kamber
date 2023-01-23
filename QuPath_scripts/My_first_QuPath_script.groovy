import qupath.lib.scripting.QP
import static qupath.lib.gui.scripting.QPEx.*

imageData = QP.getCurrentImageData();

if (imageData == null) {
    print("No image open!");
    return
}

print("Current image name: " + imageData.getServer().getShortServerName());

hierarchy = imageData.getHierarchy();
print("Current hierarchy contains " + hierarchy.nObjects() + " objects");

