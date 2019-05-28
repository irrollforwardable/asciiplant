module asciiplant.core.modelhandler;

import asciiplant.core.base;
import asciiplant.core.pathfinder;
import std.algorithm.mutation: remove;
import std.algorithm.searching: countUntil;

class ModelHandler
{
    private int currId;
    private RawData _rawData;
    private PathFinder _pathFinder;
    
    this()
    {
        this.currId = 0;
        this._rawData = new RawData();
        this._pathFinder = new PathFinder();
    }
    
    public Node createNode(dstring content)
    {
        return createNode(++currId, content);
    }
    
    public Node createNode(int id, dstring content)
    {
        if (findNodeById(id) is null) {
            Node node = new Node(id, content);
            _rawData.nodes ~= node;
            return node;
        }
        // TODO throw Exception
        return null;
    }
    
    public void deleteNode(Node node)
    {
        long index = _rawData.nodes.countUntil(node);
        if (index >= 0) {
            _rawData.nodes = _rawData.nodes.remove(index);
            foreach (ref Link incomingLink; node.incomingLinks) {
                deleteLink(incomingLink);
            }
            foreach (ref Link outgoingLink; node.outgoingLinks) {
                deleteLink(outgoingLink);
            }
        }
    }
    
    public Link linkNodes(Node fromNode, Node toNode, dstring description)
    {
        if (fromNode is null || toNode is null) {
            return null;
        }
        if (findLinkByNodes(fromNode, toNode) is null) {
            Link link = new Link(fromNode, toNode, description);
            _rawData.links ~= link;
            fromNode.outgoingLinks ~= link;
            toNode.incomingLinks ~= link;
            return link;
        }
        // TODO throw Exception
        return null;
    }
    
    public void deleteLink(Link link)
    {
        long index = _rawData.links.countUntil(link);
        if (index >= 0) {
            _rawData.links = _rawData.links.remove(index);
            
            // Remove reference from the fromNode
            long fromIndex = link.fromNode.outgoingLinks.countUntil(link);
            if (fromIndex >= 0) {
                link.fromNode.outgoingLinks = link.fromNode.outgoingLinks.remove(fromIndex);
            }
            
            // Remove reference from the toNode
            long toIndex = link.toNode.incomingLinks.countUntil(link);
            if (toIndex >= 0) {
                link.toNode.incomingLinks = link.toNode.incomingLinks.remove(toIndex);
            }
        }
    }
    
    public Node findNodeById(int id)
    {
        foreach (Node node; _rawData.nodes) {  // TODO use functional expression
            if (node.id == id) {
                return node;
            }
        }
        return null;
    }
    
    public Link findLinkByNodes(Node fromNode, Node toNode)
    {
        foreach (Link link; _rawData.links) { // TODO use functional expression
            if (link.fromNode == fromNode && link.toNode == toNode) return link;
        }
        return null;
    }
    
    @property public RawData rawData()
    {
        return _rawData;
    }
    
    @property public void rawData(RawData rawData)
    {
        _rawData = rawData;
        currId = rawData.maxNodeId;
    }
    
    @property public PathFinder pathFinder()
    {
        return _pathFinder;
    }
}
