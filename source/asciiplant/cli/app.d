module asciiplant.cli;

import asciiplant.core;
import std.string: isNumeric;
import std.conv: to;
import std.ascii: newline;
import std.array: replace;
import std.stdio;

enum DataType {STR, INT, MULTIPLE};

class Command
{
    private Command parent;
    private string name, description;
    private Command[] nextCommands;
    private Parameter[] parameters;
    private Runnable func;
    
    this(string name, string description, Command[] nextCommands)
    {
        this.name = name;
        this.description = description;
        this.nextCommands = nextCommands;
    }
    
    this(string name, string description, Parameter[] parameters, Runnable func)
    {
        this.name = name;
        this.description = description;
        this.parameters = parameters;
        this.func = func;
    }
    
    this(string name, string description, Runnable func)
    {
        this.name = name;
        this.description = description;
        this.func = func;
    }
    
    private void execute(char[][] arguments)
    {
        if (func !is null) func.run(arguments);
    }

    @property ulong mandatoryParamCount()
    {
        ulong result = 0;
        foreach (Parameter param; parameters) {
            if (param.isMandatory) result++;
        }
        return result;
    }

    @property ulong totalParamCount()
    {
        return parameters.length;
    }
}

class Parameter
{
    private DataType dataType;
    private string description;
    private bool isMandatory;
    
    this(DataType dataType, string description, bool isMandatory)
    {
        this.dataType = dataType;
        this.description = description;
        this.isMandatory = isMandatory;
    }
}

interface Runnable
{
    void run(char[][] arguments);
}

class Parser
{
    private bool isRun, isAutoDraw;
    private Workspace workspace;
    private Command topLevelCmd;
    private string ON = "on";
    private string OFF = "off";
    
    this(Workspace workspace)
    {
        this.isRun = true;
        this.isAutoDraw = true;
        this.workspace = workspace;
        
        auto nodeListCmd = new Command(
            "nodes", "Display list of nodes",
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    foreach (ref Node node; workspace.nodes) {
                        writeln(node);
                    }
                }
            }
        );
        
        auto newNodeCmd = new Command(
            "nn", "Create new node (e.g. nn My node)", [
                new Parameter(DataType.MULTIPLE, "Content text of the node", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node node = workspace.createNode(arguments[0].replace(['\\', 'n'], newline).idup);
                    writeln("Node created with id: ", node.id);
                    drawInConsole();
                }
            }
        );
        auto deleteNodeCmd = new Command(
            "xn", "Delete node by id (e.g. xn 5)", [
                new Parameter(DataType.INT, "Id of the Node to delete", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node node = workspace.findNodeById(to!int(arguments[0].idup));
                    if (node !is null) {
                        workspace.deleteNode(node);
                        writeln("Node deleted");
                        drawInConsole();
                    } else {
                        writeln("Node with id (", arguments[0], ") not found");
                    }
                }
            }
        );
        auto newLinkCmd = new Command(
            "ll", "Create new link between two nodes (e.g. ll 5 1)", [
                new Parameter(DataType.INT, "Node id which the link goes from", true),
                new Parameter(DataType.INT, "Node id which the link comes to", true),
                new Parameter(DataType.MULTIPLE, "Join description", false)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node fromNode = workspace.findNodeById(to!int(arguments[0].idup));
                    if (fromNode is null) writeln("Node with id ", arguments[0], " not found");
                    Node toNode = workspace.findNodeById(to!int(arguments[1].idup));
                    if (toNode is null) writeln("Node with id ", arguments[1], " not found");
                    string description = arguments.length == 3 ? arguments[2].idup : "";
                    Link link = workspace.linkNodes(fromNode, toNode, description);
                    if (link !is null) {
                        writeln("Link between nodes (", fromNode.id, ") and (", toNode.id, ") created");
                        drawInConsole();
                    }
                }
            }
        );
        auto unlinkNodesCmd = new Command(
            "xl", "Remove link between provided nodes by id (e.g. xl 5 1)", [
                new Parameter(DataType.INT, "Node id which the link goes from", true),
                new Parameter(DataType.INT, "Node id which the link comes to", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node fromNode = workspace.findNodeById(to!int(arguments[0].idup));
                    Node toNode = workspace.findNodeById(to!int(arguments[1].idup));
                    Link link = workspace.findLinkByNodes(fromNode, toNode);
                    if (link !is null) {
                        workspace.deleteLink(link);
                        writeln("Link between nodes (", fromNode.id, ") and (", toNode.id, ") removed");
                        drawInConsole();
                    } else {
                        writeln("Link with provided nodes not found");
                    }
                }
            }
        );
        auto findPathsCmd = new Command(
            "pps", "Find and mark all possible paths between provided nodes (e.g. pps 2 6)", [
                new Parameter(DataType.INT, "Node id which the path goes from", true),
                new Parameter(DataType.INT, "Node id which the path comes to", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node fromNode = workspace.findNodeById(to!int(arguments[0].idup));
                    Node toNode = workspace.findNodeById(to!int(arguments[1].idup));
                    Path[] paths = workspace.findPaths(fromNode, toNode);
                    if (paths !is null && paths.length > 0) {
                        writeln("The following paths found and marked:");
                        foreach (size_t index, ref Path p; paths) {
                            writeln(index + 1, ")\t", p);
                            workspace.markPath(p);
                        }
                        drawInConsole();
                    } else {
                        writeln("No paths found");
                    }
                }
            }
        );
        auto findShortestPathsCmd = new Command(
            "pp", "Find and mark shortest path(-s) between provided nodes (e.g. pp 2 6)", [
                new Parameter(DataType.INT, "Node id which the path goes from", true),
                new Parameter(DataType.INT, "Node id which the path comes to", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    Node fromNode = workspace.findNodeById(to!int(arguments[0].idup));
                    Node toNode = workspace.findNodeById(to!int(arguments[1].idup));
                    Path[] paths = workspace.findShortestPaths(fromNode, toNode);
                    if (paths !is null && paths.length > 0) {
                        writeln("The following shortest paths found and marked:");
                        foreach (size_t index, ref Path p; paths) {
                            writeln(index + 1, ")\t", p);
                            workspace.markPath(p);
                        }
                        drawInConsole();
                    } else {
                        writeln("No paths found");
                    }
                }
            }
        );
        auto deleteAllPaths = new Command(
            "xp", "Reset all marked paths",
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.resetAllMarks();
                    drawInConsole();
                }
            }
        );
        auto loadFromFileCmd = new Command(
            "load", "Load structure from provided file (e.g. load /files/mydata.xml)", [
                new Parameter(DataType.STR, "Path to file", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.loadFromFile(arguments[0].idup);
                    writeln("Data structure loaded from file: ", arguments[0]);
                    drawInConsole();
                }
            }
        );
        
        auto saveDataCmd = new Command(
            "d", "data structure (e.g. save d /files/mydata.xml)", [
                new Parameter(DataType.STR, "Path to file", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.saveDataToFile(arguments[0].idup);
                    writeln("Data structure saved to file: ", arguments[0]);
                }
            }
        );
        auto saveDrawingCmd = new Command(
            "v", "visualization (e.g. save v /files/mydata.xml)", [
                new Parameter(DataType.STR, "Path to file", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.saveVisualizationToFile(arguments[0].idup);
                    writeln("Visualization saved to file: ", arguments[0]);
                }
            }
        );
        auto saveCmd = new Command("save", "Save to file", [
            saveDataCmd, saveDrawingCmd
        ]);
        
        auto setDirectionCmd = new Command(
            "direction", "Direction (n, ne, e, se, s, sw, w, nw) (e.g. set direction S)", [
                new Parameter(DataType.STR, "Direction (n, ne, e, se, s, sw, w, nw)", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string airArgument = arguments[0].dup;
                    if (airArgument == "n") {
                        workspace.settings.direction = Direction.N;
                        drawInConsole();
                    } else if (airArgument == "ne") {
                        workspace.settings.direction = Direction.NE;
                        drawInConsole();
                    } else if (airArgument == "e") {
                        workspace.settings.direction = Direction.E;
                        drawInConsole();
                    } else if (airArgument == "se") {
                        workspace.settings.direction = Direction.SE;
                        drawInConsole();
                    } else if (airArgument == "s") {
                        workspace.settings.direction = Direction.S;
                        drawInConsole();
                    } else if (airArgument == "sw") {
                        workspace.settings.direction = Direction.SW;
                        drawInConsole();
                    } else if (airArgument == "w") {
                        workspace.settings.direction = Direction.W;
                        drawInConsole();
                    } else if (airArgument == "nw") {
                        workspace.settings.direction = Direction.NW;
                        drawInConsole();
                    } else {
                        writeln("Direction ", airArgument, " cannot be identified");
                    }
                }
            }
        );
        auto setMarginXCmd = new Command(
            "marginx", "Horizontal margin inside all boxes (e.g. set marginx 3)", [
                new Parameter(DataType.INT, "Horizontal margin value", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.settings.boxMarginX = to!int(arguments[0].idup);
                    drawInConsole();
                }
            }
        );
        auto setMarginYCmd = new Command(
            "marginy", "Vertical margin inside all boxes (e.g. set marginy 2)", [
                new Parameter(DataType.INT, "Vertical margin value", true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    workspace.settings.boxMarginY = to!int(arguments[0].idup);
                    drawInConsole();
                }
            }
        );
        auto setCreateAllBoxesFirst = new Command(
            "boxesfirst", "When on, links are drawn after all boxes have been drawn. When off, each box is drawn together with its links. (e.g. set boxesfirst on)", [
                new Parameter(DataType.STR, ON ~ " / " ~ OFF, true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string argValue = arguments[0].idup;
                    if (argValue == ON) {
                        workspace.settings.isCreateAllBoxesFirst = true;
                        drawInConsole();
                    } else if (argValue == OFF) {
                        workspace.settings.isCreateAllBoxesFirst = false;
                        drawInConsole();
                    } else {
                        writeln("Argument value should be either '", ON, "' or '", OFF, "'");
                    }
                }
            }
        );
        auto setLinkToCenter = new Command(
            "linktocenter", "Draw links from/to centers of boxes (e.g. set linktocenter off)", [
                new Parameter(DataType.STR, ON ~ " / " ~ OFF, true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string argValue = arguments[0].idup;
                    if (argValue == ON) {
                        workspace.settings.isJoinToCenter = true;
                        drawInConsole();
                    } else if (argValue == OFF) {
                        workspace.settings.isJoinToCenter = false;
                        drawInConsole();
                    } else {
                        writeln("Argument value should be either '", ON, "' or '", OFF, "'");
                    }
                }
            }
        );
        auto setShowLinkDescription = new Command(
            "showdescr", "Show link description on arrow (e.g. set showdescr on)", [
                new Parameter(DataType.STR, ON ~ " / " ~ OFF, true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string argValue = arguments[0].idup;
                    if (argValue == ON) {
                        workspace.settings.isShowArrowDescriptions = true;
                        drawInConsole();
                    } else if (argValue == OFF) {
                        workspace.settings.isShowArrowDescriptions = false;
                        drawInConsole();
                    } else {
                        writeln("Argument value should be either '", ON, "' or '", OFF, "'");
                    }
                }
            }
        );
        auto setAutodrawCmd = new Command(
            "autodraw", "Set autodraw on or off (e.g. set autodraw off)", [
                new Parameter(DataType.STR, ON ~ " / " ~ OFF, true)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string argValue = arguments[0].idup;
                    if (argValue == ON) {
                        isAutoDraw = true;
                    } else if (argValue == OFF) {
                        isAutoDraw = false;
                    } else {
                        writeln("Argument value should be either '", ON, "' or '", OFF, "'");
                    }
                }
            }
        );
        auto setCmd = new Command("set", "Set value of provided parameter", [
            setDirectionCmd, setMarginXCmd, setMarginYCmd, setCreateAllBoxesFirst, setLinkToCenter,
            setShowLinkDescription, setAutodrawCmd
        ]);
        
        auto drawCmd = new Command(
            "draw", "Show current data visualization in console",
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    if (workspace.nodes.length > 0) {
                        writeln(workspace.visualize());
                    } else {
                        writeln("No data to visualize!");
                    }
                }
            }
        );
        
        auto helpCmd = new Command(
            "help", "Show help", [
                new Parameter(DataType.STR, "Command name to display help for", false)
            ],
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    string result = "";
                    if (arguments.length == 1) {
                        Command command = findCommand(arguments[0], topLevelCmd);
                        if (command !is null) {
                            generateHelp(command, 0, result);
                            writeln(result);
                        } else {
                            writeln("Command '" ~ arguments[0] ~ "' not found");
                        }
                    } else {
                        generateHelp(topLevelCmd, -1, result);
                        writeln(result);
                    }
                }
            }
        );
        
        auto quitCmd = new Command(
            "quit", "Quit the app",
            new class Runnable
            {
                override void run(char[][] arguments)
                {
                    isRun = false;
                }
            }
        );
        
        this.topLevelCmd = new Command(null, null, [
            newNodeCmd, deleteNodeCmd, newLinkCmd, unlinkNodesCmd, loadFromFileCmd, saveCmd, nodeListCmd,
            findPathsCmd, findShortestPathsCmd, deleteAllPaths, setCmd, drawCmd, helpCmd, quitCmd
        ]);
    }
    
    private Command findCommand(ref char[] name, Command parent)
    {
        foreach (ref Command cmd; parent.nextCommands) {
            if (cmd.name == name) {
                return cmd;
            }
        }
        return null;
    }
    
    private void drawInConsole()
    {
        if (isRun && isAutoDraw && workspace.nodes.length > 0) {
            writeln(workspace.visualize());
        }
    }
    
    private string generateHelp(Command parentCmd, int level, ref string result)
    {
        string spaces = "";
        if (parentCmd.name !is null) {
            result ~= "\n\n";
            for (int i = 0; i < level; i++) {
                result ~= "\t";
                spaces ~= "\t";
            }
            result ~= "- " ~ parentCmd.name ~ "\t" ~ parentCmd.description;
        }
        
        if (parentCmd.parameters.length > 0) {
            result ~= "\n" ~ spaces ~ "\t" ~ "Parameters:";
            foreach (ref Parameter parameter; parentCmd.parameters) {
                result ~= "\n" ~ spaces ~ "\t: " ~ (!parameter.isMandatory ? "[Optional] " : "")
                    ~ parameter.description;
            }
        }
        
        foreach (ref Command command; parentCmd.nextCommands) {
            generateHelp(command, level + 1, result);
        }
        
        return result;
    }
    
    private void parseAndExecute(char[] line)
    {
        Command currCommand = topLevelCmd;
        char[] currToken;
        size_t argIndex = 0;
        char[][] arguments;
        
        charLoop: foreach (size_t cIndex, ref char c; line) {
            if ((c == ' ' || c == '\t' || c == '\n' || c=='\r') && currToken.length > 0) {
                // Process found token
                if (currCommand.parameters.length == 0) {
                    // Parse as command: if no parameters for current command, expect next command
                    currCommand = findCommand(currToken, currCommand);
                    if (currCommand !is null) {
                        debug writeln("Command: ", currCommand.name);
                    } else {
                        writeln("Command '", currToken, "' is not valid!");
                        return;
                    }
                } else {
                    // Parse as argument
                    if (currCommand.parameters.length > argIndex) {
                        if (currCommand.parameters[argIndex].dataType == DataType.MULTIPLE) {
                            arguments ~= line[(cIndex - currToken.length)..($ - 1)];
                            break charLoop;
                        } else if (currCommand.parameters[argIndex].dataType == DataType.INT) {
                            if (isNumeric(currToken, false)) {
                                arguments ~= currToken;
                            } else {
                                writeln("Argument '", currToken, "' must be of INTEGER type.");
                                return;
                            }
                        } else {
                            arguments ~= currToken;
                        }
                    } else {
                        writeln("Invalid number of arguments! Type 'help ", currCommand.name, "' for instructions.");
                        return;
                    }
                    argIndex++;
                }
                currToken = [];
            } else {
                // Add char to unfinished token
                currToken ~= c;
            }
        }
        
        // Final argument validation
        if (currCommand.mandatoryParamCount != arguments.length
                && currCommand.totalParamCount != arguments.length) {
            writeln("Invalid number of arguments: expected ", currCommand.parameters.length,
                    " argument(-s), instead received ", arguments.length, ".\nType 'help ",
                    currCommand.name, "' for instructions");
            return;
        }

        // Execute command
        if (currCommand !is null) {
            import std.exception : collectException;
            auto e = collectException(currCommand.execute(arguments));
            if (e) {
                writeln(e.msg);
            }
        }
    }
}

void main()
{
    char[] buffer;
    Workspace workspace = new Workspace();
    auto parser = new Parser(workspace);
    writeln("Welcome to Asciiplant command line utility!\n- Type 'help' to get available command description.\n- Type 'quit' to exit.");
    while (parser.isRun) {
        write(">>> ");
        readln(buffer);
        parser.parseAndExecute(buffer);
    }
}
