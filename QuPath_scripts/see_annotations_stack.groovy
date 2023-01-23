/**
 * QuPath script to visualize annotations on all see_annotations_stack, not just the current one.
 *
 * This is handy when annotating structures visible across see_annotations_stack, but where they might
 * appear with better contrast in different slices.
 *
 * @author Pete Bankhead
 */


import qupath.lib.gui.viewer.PathHierarchyPaintingHelper
import qupath.lib.gui.viewer.QuPathViewer
import qupath.lib.gui.viewer.overlays.AbstractOverlay
import qupath.lib.images.ImageData
import qupath.lib.regions.ImageRegion

import java.awt.*
import java.awt.image.BufferedImage

import static qupath.lib.gui.scripting.QPEx.getCurrentViewer

// Optionally scale the opacity so that one can distinguish annotations not on the current slice
double opacity = 0.5

def viewer = getCurrentViewer()
def overlay = new DeepAnnotationOverlay(viewer, opacity)

viewer.getCustomOverlayLayers().removeIf {it.class.name.contains("DeepAnnotationOverlay")}
viewer.getCustomOverlayLayers().add(overlay)

/**
 * Custom overlay to show all annotations (for the same timepoint) even if they are associated
 * with different see_annotations_stack.
 */
class DeepAnnotationOverlay extends AbstractOverlay {

    private QuPathViewer viewer

    protected DeepAnnotationOverlay(QuPathViewer viewer, double opacity) {
        super(viewer.getOverlayOptions())
        this.viewer = viewer
        setOpacity(opacity)
    }

    @Override
    void paintOverlay(Graphics2D g2d, ImageRegion imageRegion, double downsampleFactor, ImageData<BufferedImage> imageData, boolean paintCompletely) {
        def hierarchy = viewer.getHierarchy()
        def options = getOverlayOptions()
        if (hierarchy == null || !isVisible() || !options.showAnnotations)
            return
        def annotations = hierarchy.getAnnotationObjects().findAll {
            def roi = it.getROI()
            return imageRegion.getT() == roi.getT() && imageRegion.getZ() != roi.getZ() &&
                    imageRegion.intersects(roi.getBoundsX(), roi.getBoundsY(), roi.getBoundsWidth(), roi.getBoundsHeight())
        }
        if (annotations.isEmpty())
            return

        var comp = getAlphaComposite()
        var previousComposite = g2d.getComposite()
        if (comp != null) {
            g2d = g2d.create()
            if (previousComposite instanceof AlphaComposite)
                g2d.setComposite(comp.derive(((AlphaComposite) previousComposite).getAlpha() * comp.getAlpha() as float))
            else
                g2d.setComposite(comp)
        }
        for (def annotation in annotations) {
            PathHierarchyPaintingHelper.paintObject(
                    annotation, false, g2d, g2d.getClipBounds(), viewer.getOverlayOptions(), hierarchy.getSelectionModel(), downsampleFactor
            )
        }
    }

}
