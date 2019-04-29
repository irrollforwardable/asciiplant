module asciiplant.core.filehandler;

import asciiplant.core.base;
import std.file: write;
import std.conv: to;

class FileHandler : IFileHandler
{
    import std.xml;
    import std.file;
    import std.algorithm: filter;
    
    override public RawData loadDataFromFile(string filename)
    {
        string xmlstr = cast(string) read(filename);
        check(xmlstr);
        
        auto parser = new DocumentParser(xmlstr);
        
        // TODO nodes/node links/link
        
        Node[] nodes;
        parser.onStartTag["node"] = (ElementParser parser)
        {
            Node node = new Node(-1, null);
            parser.onEndTag["id"] = (in Element e) { node.id = to!int(e.text()); };
            parser.onEndTag["content"] = (in Element e) { node.content = e.text(); };
            parser.onEndTag["is-marked"] = (in Element e) { node.isMarked = to!bool(e.text()); };
            parser.parse();
            nodes ~= node;
        };
        
        Link[] links;
        parser.onStartTag["link"] = (ElementParser parser)
        {
            Link link = new Link(null, null, null);
            parser.onEndTag["description"] = (in Element e) { link.description = e.text(); };
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
    
    override public void saveDataToFile(RawData rawData, string filename)
    {
        Document document = new Document(new Tag("workspace"));
        Element nodes = new Element("nodes");
        Element links = new Element("links");
        foreach (ref Node node; rawData.nodes) {
            Element nodeElement = new Element("node");
            nodeElement ~= new Element("id", to!string(node.id));
            nodeElement ~= new Element("content", node.content);
            nodeElement ~= new Element("is-marked", to!string(node.isMarked));
            nodes ~= nodeElement;
        }
        foreach (ref Link link; rawData.links) {
            Element linkElement = new Element("link");
            linkElement ~= new Element("description", link.description);
            linkElement ~= new Element("from-node", to!string(link.fromNode.id));
            linkElement ~= new Element("to-node", to!string(link.toNode.id));
            linkElement ~= new Element("is-marked", to!string(link.isMarked));
            links ~= linkElement;
        }
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