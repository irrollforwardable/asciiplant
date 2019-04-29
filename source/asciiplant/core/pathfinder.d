module asciiplant.core.pathfinder;

import asciiplant.core.base;

class PathFinder
{    
    public Path[] findPaths(Node fromNode, Node toNode)
    {
        Link[] tempLinks;
        Path[] paths;

        if (fromNode !is null && toNode !is null) {
            fillPathList(fromNode.outgoingLinks, toNode, tempLinks, paths, 0);
        }
                    
        return paths;
    }
    
    public Path[] findShortestPaths(Node fromNode, Node toNode)
    {
        Path[] shortestPaths;
        Path[] paths = findPaths(fromNode, toNode);
        
        if (paths.length > 0) {
            ulong minLength = paths[0].length;
            foreach (ref Path path; paths) {
                if (path.length < minLength) {
                    minLength = path.length;
                }
            }
            foreach (ref Path path; paths) {
                if (path.length == minLength) {
                    shortestPaths ~= path;
                }
            }
            // TODO use functional expression: shortestPaths = paths.filter!(p => p.length == minLength);
        }
        
        return shortestPaths;
    }
    
    private void fillPathList(Link[] links, Node targetNode, ref Link[] tempLinks, ref Path[] pathList, int depthLevel)
    {
        foreach (Link link; links) {
            // Remove all links from deeper levels than current one from temporary link list
            if (tempLinks.length > depthLevel) {
                tempLinks = tempLinks[0..depthLevel];
            }
            
            if (link.toNode == targetNode) {
                // If destination node of the current link is the node we are searching for
                tempLinks ~= link;
                Path tempPath = new Path(tempLinks.dup);
                pathList ~= tempPath;
            } else {
                tempLinks ~= link;
                fillPathList(link.toNode.outgoingLinks, targetNode, tempLinks, pathList, depthLevel + 1);
            }
        }
    }
}
