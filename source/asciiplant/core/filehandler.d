module asciiplant.core.filehandler;

import asciiplant.core.base;
import std.file: write;
import std.conv: to;

class FileHandler : IFileHandler
{
    import std.xml;
    import std.file;
    import std.algorithm: filter;
    
    override public RawData loadDataFromFile(string filename, ref Settings settings)
    {
        string xmlstr = cast(string) read(filename);
        check(xmlstr);
        
        auto parser = new DocumentParser(xmlstr);

        parser.onStartTag["settings"] = (ElementParser parser)
        {
            parser.onEndTag["direction"] = (in Element e) { settings.direction = to!Direction(e.text()); };
            parser.onEndTag["margin-x"] = (in Element e) { settings.boxMarginX = to!long(e.text()); };
            parser.onEndTag["margin-y"] = (in Element e) { settings.boxMarginY = to!long(e.text()); };
            parser.onEndTag["join-to-center"] = (in Element e) { settings.isJoinToCenter = to!bool(e.text()); };
            parser.onEndTag["boxes-first"] = (in Element e) { settings.isCreateAllBoxesFirst = to!bool(e.text()); };
            parser.onEndTag["show-arrow-descr"] = (in Element e) {
                settings.isShowArrowDescriptions = to!bool(e.text());
            };
            parser.parse();
        };
        
        // TODO nodes/node links/link
        
        Node[] nodes;
        parser.onStartTag["node"] = (ElementParser parser)
        {
            Node node = new Node(-1, null);
            parser.onEndTag["id"] = (in Element e) { node.id = to!int(e.text()); };
            parser.onEndTag["content"] = (in Element e) { node.content = to!dstring(e.text()); };
            parser.onEndTag["is-marked"] = (in Element e) { node.isMarked = to!bool(e.text()); };
            parser.parse();
            nodes ~= node;
        };
        
        Link[] links;
        parser.onStartTag["link"] = (ElementParser parser)
        {
            Link link = new Link(null, null, null);
            parser.onEndTag["description"] = (in Element e) { link.description = to!dstring(e.text()); };
            parser.onEndTag["from-node"] = (in Element e) {
                link.fromNode = findNodeByStringId(nodes, e.text());
                link.fromNode.outgoingLinks ~= link;
            };
            parser.onEndTag["to-node"] = (in Element e) {
                link.toNode = findNodeByStringId(nodes, e.text());
                link.toNode.incomingLinks ~= link;
            };
            parser.onEndTag["is-marked"] = (in Element e) { link.isMarked = to!bool(e.text()); };
            parser.parse();
            links ~= link;
        };
        
        parser.parse();
        
        return new RawData(nodes, links);
    }
    
    override public void saveDataToFile(RawData rawData, Settings settings, string filename)
    {
        Document document = new Document(new Tag("workspace"));
        
        Element settingsElement = new Element("settings");
        settingsElement ~= new Element("direction", to!string(settings.direction));
        settingsElement ~= new Element("margin-x", to!string(settings.boxMarginX));
        settingsElement ~= new Element("margin-y", to!string(settings.boxMarginY));
        settingsElement ~= new Element("join-to-center", to!string(settings.isJoinToCenter));
        settingsElement ~= new Element("boxes-first", to!string(settings.isCreateAllBoxesFirst));
        settingsElement ~= new Element("show-arrow-descr", to!string(settings.isShowArrowDescriptions));
        // TODO box and arrow chars
        
        Element nodes = new Element("nodes");
        Element links = new Element("links");
        foreach (ref Node node; rawData.nodes) {
            Element nodeElement = new Element("node");
            nodeElement ~= new Element("id", to!string(node.id));
            nodeElement ~= new Element("content", to!string(node.content));
            nodeElement ~= new Element("is-marked", to!string(node.isMarked));
            nodes ~= nodeElement;
        }
        foreach (ref Link link; rawData.links) {
            Element linkElement = new Element("link");
            linkElement ~= new Element("description", to!string(link.description));
            linkElement ~= new Element("from-node", to!string(link.fromNode.id));
            linkElement ~= new Element("to-node", to!string(link.toNode.id));
            linkElement ~= new Element("is-marked", to!string(link.isMarked));
            links ~= linkElement;
        }
        
        document ~= settingsElement;
        document ~= nodes;
        document ~= links;
        std.file.write(filename, document.toString);
    }
    
    override public void saveStringToFile(string content, string filename)
    {
        std.file.write(filename, content);
    }
    
    private Node findNodeByStringId(ref Node[] nodes, string idString)
    {
        return nodes.filter!(n => n.id == to!int(idString)).front();
    }
}
