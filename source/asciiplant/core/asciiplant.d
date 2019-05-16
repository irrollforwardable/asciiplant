module asciiplant.core.asciiplant;

public import asciiplant.core.base;
import asciiplant.core.modelhandler;
import asciiplant.core.visualizer;

/**
 * Facade of the package wrapping up all interface methods required from the outside world.
 *
 * ModelHandler keeps Node and Link objects and provides methods to operate them.
 * IFilehandler is used for loading raw data from file into Node and Link objects and for saving those into file.
 * AsciiVisualizer contains logic of transforming Node and Link objects into ASCII visualized string diagram.
 */
public class Workspace
{
    private ModelHandler modelHandler;
    private IFileHandler fileHandler;
    private AsciiVisualizer asciiVisualizer;
    private Settings _settings;
    
    /**
     * Constructs new Workspace with default handler instances that are included in the package.
     */
    this()
    {
        import asciiplant.core.filehandler;
        this(new FileHandler());
    }
    
    /**
     * Constructs new Workspace with custom file handler provided by user.
     */
    this(IFileHandler fileHandler)
    {
        this._settings = new Settings();
        this.modelHandler = new ModelHandler();
        this.fileHandler = fileHandler;
        this.asciiVisualizer = new AsciiVisualizer(_settings);
    }
    
    /**
     * Creates new Node instance and returns it. Id is assigned automatically.
     * Params:
     *  content = text for the Node
     * Returns: Node
     */
    public Node createNode(string content)
    {
        return modelHandler.createNode(content);
    }
    
    /**
     * Safely deletes provided Node together with all related Link objects.
     * Params:
     *  node - Node to delete
     */
    public void deleteNode(Node node)
    {
        modelHandler.deleteNode(node);
    }
    
    /**
     * Returns Node having provided id.
     * Params:
     *  id - Node id
     */
    public Node findNodeById(int id)
    {
        return modelHandler.findNodeById(id);
    }
    
    /**
     * Creates new Link instance between provided Nodes and returns it.
     * Params:
     *  fromNode = source Node
     *  toNode = destination Node
     *  description = link description text
     * Returns: Link
     */
    public Link linkNodes(Node fromNode, Node toNode, string description)
    {
        return modelHandler.linkNodes(fromNode, toNode, description);
    }
    
    /**
     * Delete provided Link object.
     * Params:
     *  link - Link to delete
     */
    public void deleteLink(Link link)
    {
        modelHandler.deleteLink(link);
    }
    
    /**
     * Returns Link that joins provided nodes.
     * Params:
     *  fromNode = source Node
     *  toNode = destination Node
     * Returns: Link
     */
    public Link findLinkByNodes(Node fromNode, Node toNode)
    {
        return modelHandler.findLinkByNodes(fromNode, toNode);
    }
    
    /**
     * Finds and returns list of possible Paths between provided Nodes.
     * Params:
     *  fromNode - source Node
     *  toNode - destination Node
     * Returns: Path[]
     */
    public Path[] findPaths(Node fromNode, Node toNode)
    {
        return modelHandler.pathFinder.findPaths(fromNode, toNode);
    }
    
    /**
     * Finds and returns list of shortest possible Paths between provided Nodes.
     * Params:
     *  fromNode - source Node
     *  toNode - destination Node
     * Returns: Path[]
     */
    public Path[] findShortestPaths(Node fromNode, Node toNode)
    {
        return modelHandler.pathFinder.findShortestPaths(fromNode, toNode);
    }
    
    /**
     * Mark all Nodes and Links of the given Path.
     * Params:
     *  path - Path to mark
     */
    public void markPath(Path path)
    {
        foreach (size_t index, Link link; path.links) {
            link.isMarked = true;
            link.toNode.isMarked = true;
            if (index == 0) link.fromNode.isMarked = true;
        }
    }
    
    /**
     * Reset marking of all objects.
     */
    public void resetAllMarks()
    {
        foreach (Node node; modelHandler.rawData.nodes) {
            if (node.isMarked) node.isMarked = false;
        }
        foreach (Link link; modelHandler.rawData.links) {
            if (link.isMarked) link.isMarked = false;
        }
    }
    
    /**
     * Generates and returns visualized ASCII diagram string.
     * Returns: string
     */
    public string visualize()
    {
        return asciiVisualizer.getAsciiVisualization(modelHandler.rawData);
    }
    
    /**
     * Load data from the given file into Node and Link objects of the model handler.
     * Params:
     *  filename - file name (including path)
     */
    public void loadFromFile(string filename)
    {
        modelHandler.rawData = fileHandler.loadDataFromFile(filename, _settings);
    }
    
    /**
     * Save data of Node and Link objects to the given file.
     * Params:
     *  filename - file name (including path)
     */
    public void saveDataToFile(string filename)
    {
        fileHandler.saveDataToFile(modelHandler.rawData, _settings, filename);
    }
    
    /**
     * Save visualization to the given file.
     * Params:
     *  filename - file name (including path)
     */
    public void saveVisualizationToFile(string filename)
    {
        string result = visualize();
        fileHandler.saveStringToFile(result, filename);
    }

    /**
     * Get Node of the Box which contains provided x and y coordinate.
     * Params:
     *  x - x coordinate
     *  y - y coordinate
     */
    public Node getNodeAt(long x, long y)
    {
        return asciiVisualizer.getNodeAt(x, y);
    }

    /**
     * Get Link of the Arrow which contains provided x and y coordinate.
     * Params:
     *  x - x coordinate
     *  y - y coordinate
     */
    public Link getLinkAt(long x, long y)
    {
        return asciiVisualizer.getLinkAt(x, y);
    }
    
    @property Node[] nodes() {
        return modelHandler.rawData.nodes;
    }
    
    @property Link[] joins() {
        return modelHandler.rawData.links;
    }
    
    @property Settings settings()
    {
        return _settings;
    }
}
