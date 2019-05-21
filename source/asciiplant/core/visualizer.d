module asciiplant.core.visualizer;

import asciiplant.core.base;
import std.string: splitLines;
import std.algorithm: canFind, filter;
import std.algorithm.sorting: sort;
import std.algorithm.mutation: remove, reverse;
import std.typecons: Tuple, tuple;
import std.algorithm.searching: minElement;
import std.range: enumerate;
import std.conv;
import std.ascii: newline;
import std.stdio;

private const char EMPTY_CHAR = ' ';

// TODO split into smaller modules and create a package

class AsciiVisualizer
{
    private Settings settings;
    private Canvas canvas;
    private Box[] boxes;
    private Arrow[] arrows;
    private Node[] processedNodes;       // nodes for which boxes have already been created
    
    this(Settings settings)
    {
        this.settings = settings;
        this.canvas = new Canvas(settings);
    }
    
    public string getAsciiVisualization(RawData rawData)
    {        
        boxes = [];
        arrows = [];
        processedNodes = [];
        canvas.clear();
        
        debug writeln("Nodes in visualization:\n", rawData.nodes);
        // Create box objects
        Node[] sortedNodes = rawData.nodes.sort!((node1, node2) => 
                node1.incomingLinks.length == 0 && node2.incomingLinks.length > 0)
            .release;
        debug writeln("Sorted nodes in visualization:\n", sortedNodes);
        foreach (ref Node node; sortedNodes) {
            createBoxesRecursively(null, null, node);
        }
        
        // Create arrow objects
        if (settings.isCreateAllBoxesFirst) {
            foreach (ref Link link; rawData.links) {
                createArrow(link, null, null);
            }
        }
        
        normalize();
        
        // Adjust canvas size to match maximal coordinates
        Coord maxCoord = getMaxCoord();
        debug writeln("Width=", maxCoord.x + 1, "; Height=", maxCoord.y + 1);
        canvas.setWidth(maxCoord.x + 1);
        canvas.setHeight(maxCoord.y + 1);
        
        // Draw objects
        foreach (ref Box box; boxes) {
            canvas.draw(box);
        }
        foreach (ref Arrow arrow; arrows) {
            canvas.draw(arrow);
        }
        
        return canvas.toString();
    }
    
    public Node getNodeAt(long x, long y)
    {
        foreach (ref Box box; boxes) {
            if (x >= box.coord.x && x < box.coord.x + box.width
                    && y >= box.coord.y && y < box.coord.y + box.height) {
                return box.node;
            }
        }
        return null;
    }

    public Link getLinkAt(long x, long y)
    {
        foreach (ref Arrow arrow; arrows) {
            foreach (ref Coord arrowCoord; arrow.coordSequence) {
                if (x == arrowCoord.x && y == arrowCoord.y) {
                    return arrow.link;
                }
            }
        }
        return null;
    }
    
    private void normalize()
    {
        Coord minCoord = getMinCoord();
        if (minCoord.x < 0 || minCoord.y < 0) {
            moveObjectsBy(minCoord.x < 0 ? -minCoord.x : 0, minCoord.y < 0 ? -minCoord.y : 0);
        }
    }
    
    private void moveObjectsBy(long diffX, long diffY)
    {
        debug writeln("Normalize objects: x=", diffX, " y=", diffY);
        foreach (ref Box box; boxes) {
            box.setCoordAt(box.coord.x + diffX, box.coord.y + diffY);
        }
        foreach (ref Arrow arrow; arrows) {
            foreach (ref Coord arrowCoord; arrow.coordSequence) {
                arrowCoord.setAt(arrowCoord.x + diffX, arrowCoord.y + diffY);
            }
        }
    }
    
    private Drawable getObjectAt(long x, long y)
    {
        foreach (ref Box box; boxes) {
            if (processedNodes.canFind(box.node)
                    && x >= box.coord.x && x <= box.coord.x + box.width - 1
                    && y >= box.coord.y && y <= box.coord.y + box.height - 1) {
                return box;
            }
        }
        foreach (ref Arrow arrow; arrows) {
            foreach (ref Coord coord; arrow.coordSequence) {
                if (x == coord.x && y == coord.y) {
                    return arrow;
                }
            }
        }
        return null;
    }
    
    private Box getBoxByNode(Node node)
    {
        return boxes.filter!(box => box.node == node).front();
    }
    
    private Coord getMinCoord()
    {
        Coord result = new Coord(0, 0);
        
        if (boxes.length > 0) result.setAt(boxes[0].coord.x, boxes[0].coord.y);
        
        foreach (ref Box box; boxes) {
            if (box.coord.x < result.x) result.setAt(box.coord.x, result.y);
            if (box.coord.y < result.y) result.setAt(result.x, box.coord.y);
        }
        foreach (ref Arrow arrow; arrows) {
            foreach (ref Coord arrowCoord; arrow.coordSequence) {
                if (arrowCoord.x < result.x) result.setAt(arrowCoord.x, result.y);
                if (arrowCoord.y < result.y) result.setAt(result.x, arrowCoord.y);
            }
        }
        return result;
    }
    
    private Coord getMaxCoord()
    {
        Coord result = new Coord(0, 0);
        
        if (boxes.length > 0) result.setAt(boxes[0].coord.x + boxes[0].width, boxes[0].coord.y + boxes[0].height);
        
        foreach (ref Box box; boxes) {
            if (box.coord.x + box.width > result.x) result.setAt(box.coord.x + box.width, result.y);
            if (box.coord.y + box.height > result.y) result.setAt(result.x, box.coord.y + box.height);
        }
        foreach (ref Arrow arrow; arrows) {
            foreach (ref Coord arrowCoord; arrow.coordSequence) {
                if (arrowCoord.x > result.x) result.setAt(arrowCoord.x, result.y);
                if (arrowCoord.y > result.y) result.setAt(result.x, arrowCoord.y);
            }
        }
        return result;
    }
    
    private long getMaxY(Drawable[] objects)
    {
        long result = 0;
        foreach (ref Drawable object; objects) {
            if (auto box = cast (Box) object) {
                long potentialY = box.coord.y + box.height;
                if (potentialY > result) {
                    result = potentialY;
                }
            } else if (auto arrow = cast (Arrow) object) {
                foreach (ref Coord coord; arrow.coordSequence) {
                    result = coord.y > result ? coord.y : result;
                }
            }
        }
        return result;
    }
    
    private long getMaxX(Drawable[] objects)
    {
        long result = 0;
        foreach (ref Drawable object; objects) {
            if (auto box = cast (Box) object) {
                long potentialX = box.coord.x + box.width;
                if (potentialX > result) {
                    result = potentialX;
                }
            } else if (auto arrow = cast (Arrow) object) {
                foreach (ref Coord coord; arrow.coordSequence) {
                    result = coord.x > result ? coord.x : result;
                }
            }
        }
        return result;
    }
    
    private Drawable[] getObjectsCoveredByArea(long leftX, long rightX, long topY, long bottomY)
    {
        Drawable[] result;
        for (long y = topY; y <= bottomY; y++) {
            for (long x = leftX; x <= rightX; x++) {
                Drawable objectAtCoord = getObjectAt(x, y);
                if (objectAtCoord !is null && !result.canFind(objectAtCoord)) {
                    result ~= objectAtCoord;
                }
            }
        }
        return result;
    }
    
    private Coord[] findCoordSequencePath(Coord startCoord, Coord destinationCoord, long minLength)
    {
        auto startObject = getObjectAt(startCoord.x, startCoord.y);
        auto endObject = getObjectAt(destinationCoord.x, destinationCoord.y);
        if (startObject !is null) {
            debug writeln("WARNING: startCoord(", startCoord.x, ", ", startCoord.y, ") is on in object! ", startObject);
            return null;
        } else if (endObject !is null) {
            debug writeln("WARNING: destinationCoord(", destinationCoord.x, ", ", destinationCoord.y, ") is on in object! ", endObject);
            return null;
        }
        
        AStarPoint startPoint = new AStarPoint(null, startCoord);
        AStarPoint endPoint = new AStarPoint(null, destinationCoord);
        
        AStarPoint[] openPoints;
        AStarPoint[] visitedPoints;
        
        openPoints ~= startPoint;
        
        Tuple!(int, int)[] nextRelXYs = [tuple(-1, -1), tuple(0, -1), tuple(1, -1), tuple(1, 0), tuple(1, 1),
                                         tuple(0, 1), tuple(-1, 1), tuple(-1, 0)];
        
        while (openPoints.length > 0) {
            auto minFPoint = openPoints.enumerate.minElement!"a.value.f";
            long currIndex = minFPoint[0];
            AStarPoint currPoint = minFPoint[1];
            
            // Move current point from openPoints to visitedPoints
            openPoints = openPoints.remove(currIndex);
            visitedPoints ~= currPoint;
            
            // If destination is reached
            if (currPoint.coord.equals(endPoint.coord)) {
                Coord[] result;
                AStarPoint resultPoint = currPoint;
                result ~= resultPoint.coord;
                while (resultPoint.parent !is null) {
                    resultPoint = resultPoint.parent;
                    result ~= resultPoint.coord;
                }
                return result.reverse();
            }
            
            // Create next points
            AStarPoint[] nextPoints;
            foreach (Tuple!(int, int) nextRelXY; nextRelXYs) {
                long nextX = currPoint.coord.x + nextRelXY[0];
                long nextY = currPoint.coord.y + nextRelXY[1];
                
                if (getObjectAt(nextX, nextY) !is null
                        || visitedPoints.canFind!(
                                visitedPoint => nextX == visitedPoint.coord.x && nextY == visitedPoint.coord.y)) {
                    continue;
                }
                
                nextPoints ~= new AStarPoint(currPoint, new Coord(nextX, nextY));
            }
            
            // Loop through next points
            foreach (ref AStarPoint nextPoint; nextPoints) {
                nextPoint.g = currPoint.g + 1;
                nextPoint.h = (nextPoint.coord.x - endPoint.coord.x)^^2 + (nextPoint.coord.y - endPoint.coord.y)^^2;
                nextPoint.f = nextPoint.g + nextPoint.h;
                
                if (openPoints.canFind!(openPoint => 
                                            nextPoint.coord.x == openPoint.coord.x
                                            && nextPoint.coord.y == openPoint.coord.y)) {
                    continue;
                }
                
                openPoints ~= nextPoint;
            }
        }
        
        return null;
    }
    
    private void createBoxesRecursively(Box parentBox, Link link, Node node)
    {
        if (processedNodes.canFind(node)) {
            // Create arrow to already drawn box if option to create boxes with arrows simultaneously is on
            if (!settings.isCreateAllBoxesFirst && parentBox !is null) {
                createArrow(link, parentBox, getBoxByNode(node));
            }
            return;
        }
        
        debug writeln("Creating box: ", node.content);
        if (parentBox !is null) {
            debug writeln("from parentBox: ", parentBox.lines[0], "\n");
        }
        Box box = new Box(node, new Coord(0, 0), settings.boxMarginX, settings.boxMarginY, settings.isJoinToCenter);
        boxes ~= box;
        
        // Adjust box coordinates relatively to other boxes that are already drawn
        long newBoxX = 0;
        long newBoxY = 0;
        if (settings.direction == Direction.NW) {
            // TODO
        } else if (settings.direction == Direction.N) {
            // TODO arrow length for both x and y
            long arrowLength = link !is null ? link.description.length + 4 : 2;  // TODO
            newBoxX = parentBox !is null ? parentBox.coord.x : 0;
            newBoxY = parentBox !is null ? parentBox.coord.y - box.height - arrowLength : 0;
            Drawable[] coveredObjects = getObjectsCoveredByArea(
                newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            while (coveredObjects.length > 0) {
                long maxX = getMaxX(coveredObjects);
                long horizontalDistance = parentBox !is null 
                    ? parentBox.coord.y <= newBoxY + box.height
                        ? arrowLength
                        : 1 
                    : 1;  // TODO check next box coord somehow
                newBoxX = maxX + horizontalDistance;
                coveredObjects = getObjectsCoveredByArea(newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            }
        } else if (settings.direction == Direction.NE) {
            // TODO
        } else if (settings.direction == Direction.E) {
            // TODO arrow length for both x and y
            long arrowLength = link !is null ? link.description.length + 4 : 2;  // TODO
            newBoxX = parentBox !is null ? parentBox.coord.x + parentBox.width + arrowLength : 0;
            newBoxY = parentBox !is null ? parentBox.coord.y : 0;
            Drawable[] coveredObjects = getObjectsCoveredByArea(
                newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            while (coveredObjects.length > 0) {
                long maxY = getMaxY(coveredObjects);
                long verticalDistance = parentBox !is null 
                    ? (parentBox.coord.x + parentBox.width) >= newBoxX
                        ? arrowLength
                        : 1 
                    : 1;  // TODO check next box coord somehow
                newBoxY = maxY + verticalDistance;
                coveredObjects = getObjectsCoveredByArea(newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            }
        } else if (settings.direction == Direction.SE) {
            // TODO
        } else if (settings.direction == Direction.S) {
            // TODO arrow length for both x and y
            long arrowLength = link !is null ? link.description.length + 4 : 2;  // TODO
            newBoxX = parentBox !is null ? parentBox.coord.x : 0;
            newBoxY = parentBox !is null ? parentBox.coord.y + parentBox.height + arrowLength : 0;
            Drawable[] coveredObjects = getObjectsCoveredByArea(
                newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            while (coveredObjects.length > 0) {
                long maxX = getMaxX(coveredObjects);
                long horizontalDistance = parentBox !is null 
                    ? (parentBox.coord.y + parentBox.height) >= newBoxY
                        ? arrowLength
                        : 1 
                    : 1;  // TODO check next box coord somehow
                newBoxX = maxX + horizontalDistance;
                coveredObjects = getObjectsCoveredByArea(newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            }
        } else if (settings.direction == Direction.SW) {
            // TODO
        } else if (settings.direction == Direction.W) {
            // TODO arrow length for both x and y
            long arrowLength = link !is null ? link.description.length + 4 : 2;  // TODO
            newBoxX = parentBox !is null ? parentBox.coord.x - box.width - arrowLength : 0;
            newBoxY = parentBox !is null ? parentBox.coord.y : 0;
            Drawable[] coveredObjects = getObjectsCoveredByArea(
                newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            while (coveredObjects.length > 0) {
                long maxY = getMaxY(coveredObjects);
                long verticalDistance = parentBox !is null 
                    ? parentBox.coord.x <= newBoxX + box.width
                        ? arrowLength
                        : 1 
                    : 1;  // TODO check next box coord somehow
                newBoxY = maxY + verticalDistance;
                coveredObjects = getObjectsCoveredByArea(newBoxX, newBoxX + box.width, newBoxY, newBoxY + box.height);
            }
        }
        box.setCoordAt(newBoxX, newBoxY);
        
        processedNodes ~= node;
        
        // Create arrow from parent box to current box if option to create boxes with arrows simultaneously is on
        if (!settings.isCreateAllBoxesFirst && parentBox !is null) {
            createArrow(link, parentBox, box);
        }
        
        // Create boxes that are linked from current box
        foreach (ref Link outgoingLink; node.outgoingLinks) {
            createBoxesRecursively(box, outgoingLink, outgoingLink.toNode);
        }
    }
    
    private void createArrow(Link link, Box fromBox, Box toBox)
    {
        fromBox = fromBox !is null ? fromBox : getBoxByNode(link.fromNode);
        toBox = toBox !is null ? toBox : getBoxByNode(link.toNode);
        
        PlugsPathTriple[] plugsPathTriples;
        foreach (ref Plug fromPlug; fromBox.plugs) {
            if (fromPlug.isAvailable) {
                foreach (ref Plug toPlug; toBox.plugs) {
                    if (toPlug.isAvailable) {
                        debug writeln("\nPreparing to search path between plugs ", fromBox.lines[0], "(", fromPlug.coord.x, ", ", fromPlug.coord.y, ") >>> ", toBox.lines[0], "(", toPlug.coord.x, ", ", toPlug.coord.y, ")");
                        Coord[] coordSequence = findCoordSequencePath(
                            new Coord(fromPlug.coord.x, fromPlug.coord.y),
                            new Coord(toPlug.coord.x, toPlug.coord.y),
                            link.description.length
                        );
                        
                        // Calculate how many times coordSequence crosses other arrows
                        int crosses = 0;
                        foreach (ref Coord coord; coordSequence) {
                            foreach (ref Arrow arrow; arrows) {
                                foreach (ref Coord arrowCoord; arrow.coordSequence) {
                                    if (coord.x == arrowCoord.x && coord.y == arrowCoord.y) crosses++;
                                }
                            }
                        }

                        if (coordSequence.length > 0) {
                            plugsPathTriples ~= new PlugsPathTriple(fromPlug, coordSequence, toPlug, crosses);
                        }
                        debug writeln("Path coords from ", fromBox.lines[0], "(", fromPlug.coord.x, ", ", fromPlug.coord.y, ") >>> ", toBox.lines[0], "(", toPlug.coord.x, ", ", toPlug.coord.y, ") = ", coordSequence);
                    }
                }
            }
        }

        if (plugsPathTriples.length > 0) {
            // Find plugsPathTriple with the shortest path that ideally does not cross any other arrows
            // TODO use std.algorithm.sorting.multiSort instead
            PlugsPathTriple[] pptSorted = plugsPathTriples.sort!(
                (ppt1, ppt2) => ppt1.crosses != ppt2.crosses 
                    ? ppt1.crosses < ppt2.crosses 
                    : ppt1.path.length < ppt2.path.length)
                .release;
        
            // Close both plugs
            pptSorted[0].fromPlug.isAvailable = false;
            pptSorted[0].toPlug.isAvailable = false;
        
            // Create new Plugs if option to join to center is turned on
            if (settings.isJoinToCenter) {
                pptSorted[0].fromPlug.box.createPlugNextTo(pptSorted[0].fromPlug);
                pptSorted[0].toPlug.box.createPlugNextTo(pptSorted[0].toPlug);
            }

            arrows ~= new Arrow(link, fromBox, toBox,
                                pptSorted[0].fromPlug, pptSorted[0].toPlug,
                                pptSorted[0].path);
        }
    }
}

class Canvas
{
    private Settings settings;
    private char[][] area;
    private long width;  // must not be modified from outside!
    
    this(Settings settings)
    {
        this.settings = settings;
        char[] tmpFirst;
        tmpFirst ~= EMPTY_CHAR;
        area ~= tmpFirst;
        width = area[0].length;
    }
    
    private void draw(Box box)
    {
        debug writeln("Drawing box: x=", box.coord.x, "; y=", box.coord.y, "; width=", box.width, "; height=", box.height, "; ", box.lines[0]);
        
        area[box.coord.y][box.coord.x] = settings.getBoxNW(box.node.isMarked);
        area[box.coord.y][box.coord.x + box.width - 1] = settings.getBoxNE(box.node.isMarked);
        area[box.coord.y + box.height - 1][box.coord.x] = settings.getBoxSW(box.node.isMarked);
        area[box.coord.y + box.height - 1][box.coord.x + box.width - 1] = settings.getBoxSE(box.node.isMarked);
        for (long x = box.coord.x + 1; x < box.coord.x + box.width - 1; x++) {
            area[box.coord.y][x] = settings.getBoxN(box.node.isMarked);
            area[box.coord.y + box.height - 1][x] = settings.getBoxS(box.node.isMarked);
        }
        for (long y = box.coord.y + 1; y < box.coord.y + box.height - 1; y++) {
            area[y][box.coord.x] = settings.getBoxW(box.node.isMarked);
            area[y][box.coord.x + box.width - 1] = settings.getBoxE(box.node.isMarked);
        }
        
        int yOffset = 0;
        foreach (string line; box.lines) {
            int xOffset = 0;
            foreach (char c; line) {
                // +1 means border line width
                area[box.coord.y + box.marginY + yOffset + 1][box.coord.x + box.marginX + xOffset + 1] = c;
                xOffset++;
            }
            yOffset++;
        }
    }
    
    private void draw(Arrow arrow)
    {
        debug writeln("Drawing arrow: ", arrow.link.fromNode.content, " >>> ", arrow.link.toNode.content);
        long descrStartIndex = (arrow.coordSequence.length - arrow.link.description.length) / 2;
        long descrEndIndex = descrStartIndex + arrow.link.description.length;
        foreach (size_t index, ref Coord coord; arrow.coordSequence) {
            if (coord.x >= 0 && coord.y >= 0) {
                auto chr = settings.getArrH(arrow.link.isMarked);
                
                // TODO
                if (coord.x == arrow.fromPlug.coord.x && coord.y == arrow.fromPlug.coord.y) {
                    // First outgoing char
                    if (arrow.fromPlug.direction == Direction.NW) {
                        chr = settings.getArrNWSE(arrow.link.isMarked);
                    } else if (arrow.fromPlug.direction == Direction.N) {
                        if (index + 1 < arrow.coordSequence.length
                                && arrow.coordSequence[index + 1].y == coord.y) {
                            chr = settings.getArrBottom(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrV(arrow.link.isMarked);
                        }
                    } else if (arrow.fromPlug.direction == Direction.NE) {
                        chr = settings.getArrSWNE(arrow.link.isMarked);
                    } else if (arrow.fromPlug.direction == Direction.E || arrow.fromPlug.direction == Direction.W) {
                        if (index + 1 < arrow.coordSequence.length
                                && arrow.coordSequence[index + 1].x == coord.x) {
                            if (arrow.coordSequence[index + 1].y < coord.y) {
                                chr = settings.getArrTop(arrow.link.isMarked);
                            } else if (arrow.coordSequence[index + 1].y > coord.y) {
                                chr = settings.getArrBottom(arrow.link.isMarked);
                            }
                        } else {
                            chr = settings.getArrH(arrow.link.isMarked);
                        }
                    } else if (arrow.fromPlug.direction == Direction.SE) {
                        chr = settings.getArrNWSE(arrow.link.isMarked);
                    } else if (arrow.fromPlug.direction == Direction.S) {
                        if (index + 1 < arrow.coordSequence.length
                                && arrow.coordSequence[index + 1].y == coord.y) {
                            chr = settings.getArrTop(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrV(arrow.link.isMarked);
                        }
                    } else if (arrow.fromPlug.direction == Direction.SW) {
                        chr = settings.getArrSWNE(arrow.link.isMarked);
                    }
                } else if (coord.x == arrow.toPlug.coord.x && coord.y == arrow.toPlug.coord.y) {
                    // Destination arrow
                    if (arrow.toPlug.direction == Direction.NW) {
                        chr = settings.getArrNWSE(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.N) {
                        chr = settings.getArrDown(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.NE) {
                        chr = settings.getArrSWNE(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.E) {
                        chr = settings.getArrLeft(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.SE) {
                        chr = settings.getArrNWSE(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.S) {
                        chr = settings.getArrUp(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.SW) {
                        chr = settings.getArrSWNE(arrow.link.isMarked);
                    } else if (arrow.toPlug.direction == Direction.W) {
                        chr = settings.getArrRight(arrow.link.isMarked);
                    }
                } else if (settings.isShowArrowDescriptions
                           && index >= descrStartIndex && index < descrEndIndex && arrow.link.description.length > 0) {
                    // Description letters
                    if (arrow.coordSequence[descrStartIndex].x < arrow.coordSequence[descrEndIndex].x) {
                        // Forward direction
                        chr = arrow.link.description[index - descrStartIndex];
                    } else if (arrow.coordSequence[descrStartIndex].x > arrow.coordSequence[descrEndIndex].x) {
                        // Backward direction
                        chr = arrow.link.description[descrEndIndex - index - 1];
                    } else {
                        if (arrow.coordSequence[descrStartIndex].y < arrow.coordSequence[descrEndIndex].y) {
                            // Forward direction
                            chr = arrow.link.description[index - descrStartIndex];
                        } else {
                            // Backward direction
                            chr = arrow.link.description[descrEndIndex - index - 1];
                        }
                    }
                } else if (index > 0 && index < arrow.coordSequence.length) {
                    if (arrow.coordSequence[index-1].x == coord.x
                        && (arrow.coordSequence[index-1].y == coord.y - 1
                            || arrow.coordSequence[index-1].y == coord.y + 1)) {
                        chr = settings.getArrV(arrow.link.isMarked);
                    }
                    // \
                    //  '-->
                    else if (arrow.coordSequence[index-1].x == coord.x - 1
                        && arrow.coordSequence[index-1].y == coord.y - 1) {
                        if (arrow.coordSequence[index+1].x == coord.x + 1
                            && arrow.coordSequence[index+1].y == coord.y) {
                            chr = settings.getArrTop(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrNWSE(arrow.link.isMarked);
                        }
                    }
                    //    /
                    // <-'
                    else if (arrow.coordSequence[index-1].x == coord.x + 1
                        && arrow.coordSequence[index-1].y == coord.y - 1) {
                        if (arrow.coordSequence[index+1].x == coord.x - 1
                            && arrow.coordSequence[index+1].y == coord.y) {
                            chr = settings.getArrTop(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrSWNE(arrow.link.isMarked);
                        }
                    }
                    // <-.
                    //    \
                    else if (arrow.coordSequence[index-1].x == coord.x + 1
                        && arrow.coordSequence[index-1].y == coord.y + 1) {
                        if (arrow.coordSequence[index+1].x == coord.x - 1
                            && arrow.coordSequence[index+1].y == coord.y) {
                            chr = settings.getArrBottom(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrNWSE(arrow.link.isMarked);
                        }
                    }
                    //  .->
                    // /
                    else if (arrow.coordSequence[index-1].x == coord.x - 1
                        && arrow.coordSequence[index-1].y == coord.y + 1) {
                        if (arrow.coordSequence[index+1].x == coord.x + 1
                            && arrow.coordSequence[index+1].y == coord.y) {
                            chr = settings.getArrBottom(arrow.link.isMarked);
                        } else {
                            chr = settings.getArrSWNE(arrow.link.isMarked);
                        }
                    }
                }
                                
                area[coord.y][coord.x] = chr;
            }
        }
    }
    
    private void setWidth(long width)
    {
        long diff = width - area[0].length;
        if (diff > 0) {
            foreach (ref char[] line; area) {
                for (int i = 0; i < diff; i++) {
                    line ~= EMPTY_CHAR;
                }
            }
        } else if (diff < 0) {
            // TODO
        }
        this.width = width;
    }
    
    private void setHeight(long height)
    {
        long diff = height - area.length;
        if (diff > 0) {
            for (int i = 0; i < diff; i++) {
                char[] line;
                for (int j = 0; j < width; j++) {
                    line ~= EMPTY_CHAR;
                }
                area ~= line;
            }
        } else if (diff < 0) {
            area = area[0..height];
        }
    }
    
    private void clear()
    {
        foreach (ref char[] line; area) {
            for (size_t c = 0; c < line.length; c++) {
                line[c] = ' ';
            }
        }
    }
    
    private string toString()
    {
        char[] result;
        foreach (ref char[] line; area) {
            result ~= line ~ newline;
        }
        return result.idup;
    }
}

abstract class Drawable {}

class Box : Drawable
{
    private Node node;
    private string[] lines;
    private Coord coord;
    private long width, height;
    private long marginX, marginY;
    private Plug[] plugs;
    
    this(Node node, Coord coord, long marginX, long marginY, bool isJoinToCenter)
    {
        this.node = node;
        this.lines = node.content.splitLines();  // TODO unnecessary memory allocation. Use lineSplitter instead.
        this.width = getMaxLineLength(lines) + (marginX * 2) + 2;  // + 2 means border line from both sides
        this.height = lines.length + (marginY * 2) + 2;  // + 2 means border line from both sides
        this.marginX = marginX;
        this.marginY = marginY;
        this.coord = coord;
        
        // Adjust perimeter if not enough place for Plugs
        long pmDiff = calculateFunctionalPerimeter() - (node.incomingLinks.length + node.outgoingLinks.length);
        debug writeln("Perimeter = ", calculateFunctionalPerimeter(), " - ", (node.incomingLinks.length + node.outgoingLinks.length), " = ", pmDiff);
        if (pmDiff < 0) {
            width += (pmDiff / 2) + 1;  // TODO based on direction icrease either width or height
            debug writeln("Perimeter adjusted: width=", width);
        }
        
        //           plugN
        //             *
        //        .---------.
        // plugW *|   box   |* plugE
        //        '---------'
        //             *
        //           plugS
        if (isJoinToCenter) {
            // Only create 4 central Plugs. Neighbour Plugs to be created dynamically during next Join creation.
            plugs ~= new Plug(new Coord((width / 2), -1), Direction.N, this);
            plugs ~= new Plug(new Coord(width, (height / 2)), Direction.E, this);
            plugs ~= new Plug(new Coord((width / 2), height), Direction.S, this);
            plugs ~= new Plug(new Coord(-1, (height / 2)), Direction.W, this);
        } else {
            // Create all possible Plugs.
            for (long x = coord.x + 1; x < coord.x + width - 1; x++) {
                plugs ~= new Plug(new Coord(x, -1), Direction.N, this);
                plugs ~= new Plug(new Coord(x, height), Direction.S, this);
            }
            for (long y = coord.y + 1; y < coord.y + height - 1; y++) {
                plugs ~= new Plug(new Coord(coord.x + width, y), Direction.E, this);
                plugs ~= new Plug(new Coord(coord.x - 1, y), Direction.W, this);
            }
        }
        debug writeln("Plugs of box (", lines[0], ") at creation time: ", plugs.length);
    }
    
    private void createPlugNextTo(Plug plug)
    {
        if (plug.box != this) {
            return;
        }
        if (plug.direction == Direction.N || plug.direction == Direction.S) {
            long xCenter = coord.x + (width / 2);
            long xLeft = plug.coord.x - 1;
            long xRight = plug.coord.x + 1;
            if (plug.coord.x == xCenter) {
                // Create new Plugs on both sides of the given Plug if it is in center
                if (xLeft > coord.x) {
                    plugs ~= new Plug(new Coord(xLeft, plug.coord.y), plug.direction, this);
                }
                if (xRight < coord.x + width - 1) {
                    plugs ~= new Plug(new Coord(xRight, plug.coord.y), plug.direction, this);
                }
            } else if (plug.coord.x < xCenter && xLeft > coord.x) {
                plugs ~= new Plug(new Coord(xLeft, plug.coord.y), plug.direction, this);
            } else if (plug.coord.x > xCenter && xRight < coord.x + width - 1) {
                plugs ~= new Plug(new Coord(xRight, plug.coord.y), plug.direction, this);
            }
        } else if (plug.direction == Direction.E || plug.direction == Direction.W) {
            long yCenter = coord.y + height / 2;
            long yUp = plug.coord.y - 1;
            long yDown = plug.coord.y + 1;
            if (plug.coord.x == yCenter) {
                // Create new Plugs on both sides of the given Plug if it is in center
                if (yUp > coord.y) {
                    plugs ~= new Plug(new Coord(plug.coord.x, yUp), plug.direction, this);
                }
                if (yDown < coord.y + height - 1) {
                    plugs ~= new Plug(new Coord(plug.coord.x, yDown), plug.direction, this);
                }
            } else if (plug.coord.x < yCenter && yUp > coord.y) {
                plugs ~= new Plug(new Coord(plug.coord.x, yUp), plug.direction, this);
            } else if (plug.coord.x > yCenter && yDown < coord.y + height - 1) {
                plugs ~= new Plug(new Coord(plug.coord.x, yDown), plug.direction, this);
            }
        }
    }
    
    private void setCoordAt(long x, long y)
    {
        long diffX = x - coord.x;
        long diffY = y - coord.y;
        coord.setAt(x, y);
        foreach (ref Plug plug; plugs) {
            plug.coord.setAt(plug.coord.x + diffX, plug.coord.y + diffY);
        }
    }
    
    private long calculateFunctionalPerimeter()
    {
        return 2 * (width - 2 + height - 2);
    }
}

class Arrow : Drawable
{
    private Link link;
    private Box fromBox, toBox;
    private Plug fromPlug, toPlug;
    private Coord[] coordSequence;
    
    this(Link link, Box fromBox, Box toBox, Plug fromPlug, Plug toPlug, ref Coord[] coordSequence)
    {
        this.link = link;
        this.fromBox = fromBox;
        this.toBox = toBox;
        this.fromPlug = fromPlug;
        this.toPlug = toPlug;
        this.coordSequence = coordSequence;
    }
}

class Plug
{
    private Coord coord;
    private Direction direction;
    private Box box;
    private bool isAvailable;
    
    this(Coord coord, Direction direction, Box box)
    {
        this.coord = coord;
        this.direction = direction;
        this.box = box;
        this.isAvailable = true;
    }
}

class Coord
{
    private long x, y;
    
    this(long x, long y)
    {
        setAt(x, y);
    }
    
    private void setAt(long x, long y)
    {
        this.x = x;
        this.y = y;
    }
    
    private bool equals(Coord anotherCoord)
    {
        return x == anotherCoord.x && y == anotherCoord.y;
    }
    
    private bool equals(long anotherX, long anotherY)
    {
        return x == anotherX && y == anotherY;
    }
    
    override string toString() const pure @safe
    {
        return "(" ~ to!string(x) ~ ", " ~ to!string(y) ~ ")";
    }
}

class AStarPoint
{
    private AStarPoint parent;
    private Coord coord;
    long g, h, f;
    
    this(AStarPoint parent, Coord coord)
    {
        this.parent = parent;
        this.coord = coord;
        g = 0;  // Distance between the current point and the start point
        h = 0;  // Estimated distance from the current node to the end node
        f = 0;  // Total cost of the point (g + h)
    }
    
    override string toString() const pure @safe
    {
        return "(" ~ to!string(coord.x) ~ ", " ~ to!string(coord.y) ~ ")";
    }
}

class PlugsPathTriple
{
    private Plug fromPlug, toPlug;
    private Coord[] path;
    private int crosses;  // how many times coord sequense crosses other arrows
    
    this(Plug fromPlug, ref Coord[] path, Plug toPlug, int crosses)
    {
        this.fromPlug = fromPlug;
        this.path = path;
        this.toPlug = toPlug;
        this.crosses = crosses;
    }
}

private long getMaxLineLength(string[] lines)
{
    long result = 0;
    foreach (string line; lines) {
        if (line.length > result) result = line.length;
    }
    return result;
}
