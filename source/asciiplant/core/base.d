module asciiplant.core.base;

/**
* Cardinal directions of visual ASCII representation of data.
* Define direction in which every child Node (Box) is placed relatively to its parent.
*/
enum Direction {NW, N, NE, E, SE, S, SW, W};

/**
* Represents a single piece of information.
*/
class Node
{
    public int id;
    public dstring content;
    public Link[] incomingLinks, outgoingLinks;
    public bool isMarked;
    
    this(int id, dstring content)
    {
        this.id = id;
        this.content = content;
        this.isMarked = false;
    }
    
    override public string toString() const pure @safe
    {
        import std.string: splitLines;
        import std.utf: toUCSindex;
        import std.conv: to;

        size_t limit = 17;  // TODO parameter in Settings
        auto substr = splitLines(content[0 .. (limit > content.length ? content.length : content.toUCSindex(limit))])[0];
        if (substr.length < content.length) {
            substr ~= "...";
        }

        return "id=" ~ to!string(id) ~ ": " ~ to!string(substr);
    }
}

/**
* Directional link between two nodes.
*/
class Link
{
    public dstring description;
    public Node fromNode, toNode;
    public bool isMarked;
    
    this(Node fromNode, Node toNode, dstring description)
    {
        this.fromNode = fromNode;
        this.toNode = toNode;
        this.description = description;
        this.isMarked = false;
    }
}

/**
* Sequence of links representing path from one Node to another.
*/
class Path
{
    public Link[] links;
    
    this(Link[] links)
    {
        this.links = links;
    }
    
    @property ulong length()
    {
        return links.length;
    }
    
    override public string toString() const pure @safe
    {
        import std.conv: to;
        
        string result = "";
        for (size_t i = 0; i < links.length; i++) {
            if (i == 0) {
                result ~= links[i].fromNode.toString;
            }
            result ~= " --" ~ (links[i].description.length > 0 ? "[" ~ to!string(links[i].description) ~ "]" : "") ~ "--> " ~ links[i].toNode.toString;
        }
        return result;
    }
}

class RawData
{
    public Node[] nodes;
    public Link[] links;
    
    this(){}
    
    this(ref Node[] nodes, ref Link[] links)
    {
        this.nodes = nodes;
        this.links = links;
    }
    
    @property int maxNodeId()
    {
        int result = 1;
        foreach (ref Node node; nodes) {  // TODO use functional expression
            if (node.id > result) result = node.id;
        }
        return result;
    }
}

class Settings
{
    private Direction _direction;
    private dchar boxNW, boxNWm, boxN, boxNm, boxNE, boxNEm, boxE, boxEm, boxSE, boxSEm, boxS, boxSm, boxSW, boxSWm,
    boxW, boxWm, arrH, arrHm, arrV, arrVm, arrSWNE, arrSWNEm, arrNWSE, arrNWSEm, arrTop, arrTopm,
    arrBottom, arrBottomm, arrUp, arrUpm, arrRight, arrRightm, arrDown, arrDownm, arrLeft, arrLeftm;
    private long _boxMarginX, _boxMarginY;
    private bool _isCreateAllBoxesFirst, _isJoinToCenter, _isShowArrowDescriptions;
    
    this()
    {
        this(
            Direction.E,
            '.', '.',    // Box NW unmarked / marked
            '-', '=',    // Box N unmarked / marked
            '.', '.',    // Box NE unmarked / marked
            '|', '#',    // Box E unmarked / marked
            '\'', '\'',  // Box SE unmarked / marked
            '-', '=',    // Box S unmarked / marked
            '\'', '\'',  // Box SW unmarked / marked
            '|', '#',    // Box W unmarked / marked
            '-', '*',    // Arrow horizontal unmarked / marked
            '|', '*',    // Arrow vertical unmarked / marked
            '/', '*',    // Arrow SWNE unmarked / marked
            '\\', '*',   // Arrow NWSE unmarked / marked
            '\'', '*',   // Arrow top unmarked / marked
            '.', '*',    // Arrow bottom unmarked / marked
            '^', '^',    // Arrow up unmarked / marked
            '>', '>',    // Arrow right unmarked / marked
            'v', 'v',    // Arrow down unmarked / marked
            '<', '<',    // Arrow left unmarked / marked
            0, 0, false, true, true
        );
    }
    
    this(Direction direction, dchar boxNW, dchar boxNWm, dchar boxN, dchar boxNm, dchar boxNE, dchar boxNEm,
         dchar boxE, dchar boxEm, dchar boxSE, dchar boxSEm, dchar boxS, dchar boxSm, dchar boxSW, dchar boxSWm,
         dchar boxW, dchar boxWm, dchar arrH, dchar arrHm, dchar arrV, dchar arrVm, dchar arrSWNE, dchar arrSWNEm,
         dchar arrNWSE, dchar arrNWSEm, dchar arrTop, dchar arrTopm, dchar arrBottom, dchar arrBottomm, dchar arrUp,
         dchar arrUpm, dchar arrRight, dchar arrRightm, dchar arrDown, dchar arrDownm, dchar arrLeft, dchar arrLeftm,
         long boxMarginX, long boxMarginY, bool isCreateAllBoxesFirst, bool isJoinToCenter,
         bool isShowArrowDescriptions)
    {
        this.direction = direction;
        this.boxNW = boxNW;
        this.boxNWm = boxNWm;
        this.boxN = boxN;
        this.boxNm = boxNm;
        this.boxNE = boxNE;
        this.boxNEm = boxNEm;
        this.boxE = boxE;
        this.boxEm = boxEm;
        this.boxSE = boxSE;
        this.boxSEm = boxSEm;
        this.boxS = boxS;
        this.boxSm = boxSm;
        this.boxSW = boxSW;
        this.boxSWm = boxSWm;
        this.boxW = boxW;
        this.boxWm = boxWm;
        this.arrH = arrH;
        this.arrHm = arrHm;
        this.arrV = arrV;
        this.arrVm = arrVm;
        this.arrSWNE = arrSWNE;
        this.arrSWNEm = arrSWNEm;
        this.arrNWSE = arrNWSE;
        this.arrNWSEm = arrNWSEm;
        this.arrTop = arrTop;
        this.arrTopm = arrTopm;
        this.arrBottom = arrBottom;
        this.arrBottomm = arrBottomm;
        this.arrUp = arrUp;
        this.arrUpm = arrUpm;
        this.arrRight = arrRight;
        this.arrRightm = arrRightm;
        this.arrDown = arrDown;
        this.arrDownm = arrDownm;
        this.arrLeft = arrLeft;
        this.arrLeftm = arrLeftm;
        this._boxMarginX = boxMarginX;
        this._boxMarginY = boxMarginY;
        this._isCreateAllBoxesFirst = isCreateAllBoxesFirst;
        this._isJoinToCenter = isJoinToCenter;
        this._isShowArrowDescriptions = isShowArrowDescriptions;
    }
    
    public dchar getBoxNW(bool isMarked)
    {
        if (!isMarked)
            return boxNW;
        else
            return boxNWm;
    }
    
    public void setBoxNW(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxNW = value;
        else
            boxNWm = value;
    }
    
    public dchar getBoxN(bool isMarked)
    {
        if (!isMarked)
            return boxN;
        else
            return boxNm;
    }
    
    public void setBoxN(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxN = value;
        else
            boxNm = value;
    }
    
    public dchar getBoxNE(bool isMarked)
    {
        if (!isMarked)
            return boxNE;
        else
            return boxNEm;
    }
    
    public void setBoxNE(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxNE = value;
        else
            boxNEm = value;
    }
    
    public dchar getBoxE(bool isMarked)
    {
        if (!isMarked)
            return boxE;
        else
            return boxEm;
    }
    
    public void setBoxE(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxE = value;
        else
            boxEm = value;
    }
    
    public dchar getBoxSE(bool isMarked)
    {
        if (!isMarked)
            return boxSE;
        else
            return boxSEm;
    }
    
    public void setBoxSE(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxSE = value;
        else
            boxSEm = value;
    }
    
    public dchar getBoxS(bool isMarked)
    {
        if (!isMarked)
            return boxS;
        else
            return boxSm;
    }
    
    public void setBoxS(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxS = value;
        else
            boxSm = value;
    }
    
    public dchar getBoxSW(bool isMarked)
    {
        if (!isMarked)
            return boxSW;
        else
            return boxSWm;
    }
    
    public void setBoxSW(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxSW = value;
        else
            boxSWm = value;
    }
    
    public dchar getBoxW(bool isMarked)
    {
        if (!isMarked)
            return boxW;
        else
            return boxWm;
    }
    
    public void setBoxW(dchar value, bool isMarked)
    {
        if (!isMarked)
            boxW = value;
        else
            boxWm = value;
    }
    
    public dchar getArrH(bool isMarked)
    {
        if (!isMarked)
            return arrH;
        else
            return arrHm;
    }
    
    public void setArrH(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrH = value;
        else
            arrHm = value;
    }
    
    public dchar getArrV(bool isMarked)
    {
        if (!isMarked)
            return arrV;
        else
            return arrVm;
    }
    
    public void setArrV(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrV = value;
        else
            arrVm = value;
    }
    
    public dchar getArrSWNE(bool isMarked)
    {
        if (!isMarked)
            return arrSWNE;
        else
            return arrSWNEm;
    }
    
    public void setArrSWNE(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrSWNE = value;
        else
            arrSWNEm = value;
    }
    
    public dchar getArrNWSE(bool isMarked)
    {
        if (!isMarked)
            return arrNWSE;
        else
            return arrNWSEm;
    }
    
    public void setArrNWSE(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrNWSE = value;
        else
            arrNWSEm = value;
    }
    
    public dchar getArrTop(bool isMarked)
    {
        if (!isMarked)
            return arrTop;
        else
            return arrTopm;
    }
    
    public void setArrTop(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrTop = value;
        else
            arrTopm = value;
    }
    
    public dchar getArrBottom(bool isMarked)
    {
        if (!isMarked)
            return arrBottom;
        else
            return arrBottomm;
    }
    
    public void setArrBottom(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrBottom = value;
        else
            arrBottomm = value;
    }
    
    public dchar getArrUp(bool isMarked)
    {
        if (!isMarked)
            return arrUp;
        else
            return arrUpm;
    }
    
    public void setArrUp(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrUp = value;
        else
            arrUpm = value;
    }
    
    public dchar getArrRight(bool isMarked)
    {
        if (!isMarked)
            return arrRight;
        else
            return arrRightm;
    }
    
    public void setArrRight(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrRight = value;
        else
            arrRightm = value;
    }
    
    public dchar getArrDown(bool isMarked)
    {
        if (!isMarked)
            return arrDown;
        else
            return arrDownm;
    }
    
    public void setArrDown(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrDown = value;
        else
            arrDownm = value;
    }
    
    public dchar getArrLeft(bool isMarked)
    {
        if (!isMarked)
            return arrLeft;
        else
            return arrLeftm;
    }
    
    public void setArrLeft(dchar value, bool isMarked)
    {
        if (!isMarked)
            arrLeft = value;
        else
            arrLeftm = value;
    }
    
    @property Direction direction()
    {
        return _direction;
    }

    @property void direction(Direction direction)
    {
        this._direction = direction;
    }
    
    @property long boxMarginX()
    {
        return _boxMarginX;
    }

    @property void boxMarginX(long boxMarginX)
    {
        this._boxMarginX = boxMarginX;
    }
    
    @property long boxMarginY()
    {
        return _boxMarginY;
    }

    @property void boxMarginY(long boxMarginY)
    {
        this._boxMarginY = boxMarginY;
    }
    
    @property bool isCreateAllBoxesFirst()
    {
        return _isCreateAllBoxesFirst;
    }

    @property void isCreateAllBoxesFirst(bool isCreateAllBoxesFirst)
    {
        this._isCreateAllBoxesFirst = isCreateAllBoxesFirst;
    }
    
    @property bool isJoinToCenter()
    {
        return _isJoinToCenter;
    }

    @property void isJoinToCenter(bool isJoinToCenter)
    {
        this._isJoinToCenter = isJoinToCenter;
    }
    
    @property bool isShowArrowDescriptions()
    {
        return _isShowArrowDescriptions;
    }
    
    @property void isShowArrowDescriptions(bool isShowArrowDescriptions)
    {
        this._isShowArrowDescriptions = isShowArrowDescriptions;
    }
}

interface IFileHandler
{
    RawData loadDataFromFile(string filename, ref Settings settings);
    void saveDataToFile(RawData rawData, Settings settings, string filename);
    void saveStringToFile(string content, string filename);
}
