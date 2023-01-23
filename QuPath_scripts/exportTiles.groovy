import static qupath.lib.gui.scripting.QPEx.*

def imageData = getCurrentImageData()
def server = getCurrentServer()
def path = server.getPath()

// Define output path (relative to project)
def name = GeneralTools.getNameWithoutExtension(server.getMetadata().getName())
def pathOutput = buildFilePath(PROJECT_BASE_DIR, 'tiles', name)
mkdirs(pathOutput)

// Define output resolution
//double requestedPixelSize = 10.0
//double downsample = requestedPixelSize / imageData.getServer().getPixelCalibration().getAveragedPixelSize()
double downsample = 1
//def request = RegionRequest.createInstance(path, downsample, x, y, width, height)

// Create an exporter that requests corresponding tiles from the original & labeled image servers
new TileExporter(imageData)
        .downsample(downsample)     // Define export resolution
        .imageExtension('.tif')     // Define file extension for original pixels (often .tif, .jpg, '.png' or '.ome.tif')
        .tileSize(256)              // Define size of each tile, in pixels
        //.labeledServer(labelServer) // Define the labeled image server to use (i.e. the one we just built)
        //.region(request)
        .annotatedTilesOnly(false)  // If true, only export tiles if there is a (labeled) annotation present
        .overlap(64)                // Define overlap, in pixel units at the export resolution
        .includePartialTiles(true)
        .writeTiles(pathOutput)     // Write tiles to the specified directory

