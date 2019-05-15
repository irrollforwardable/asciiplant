module asciiplant.gui;

import asciiplant.core;
import std.conv: to;
import std.string: isNumeric;
import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.msgbox;

mixin APP_ENTRY_POINT;

enum : int
{
    ACTION_FILE_NEW,
    ACTION_FILE_OPEN,
    ACTION_FILE_SAVE_DATA,
    ACTION_FILE_SAVE_DATA_AS,
    ACTION_FILE_SAVE_VIS,
    ACTION_FILE_EXIT,
    ACTION_NEW_NODE,
    ACTION_EDIT_NODE,
    ACTION_DELETE_NODE,
    ACTION_NEW_LINK_FROM,
    ACTION_NEW_LINK_TO,
    ACTION_EDIT_LINK,
    ACTION_DELETE_LINK,
    ACTION_FIND_PATHS_FROM,
    ACTION_FIND_PATHS_TO,
    ACTION_FIND_SHORTEST_PATHS_FROM,
    ACTION_FIND_SHORTEST_PATHS_TO,
    ACTION_UNMARK_PATHS,
    ACTION_DRAW,
    ACTION_HELP_ONLINE,
    ACTION_HELP_ABOUT
}

extern (C) int UIAppMain(string[] args)
{
    embeddedResourceList.addResources(embedResourcesFromList!("resources.list")());
    Platform.instance.uiLanguage = "en";

    // Common main menu items
    MenuItem newNodeItem = new MenuItem(new Action(ACTION_NEW_NODE, "MENU_ACTIONS_NEWNODE"c));
    MenuItem editNodeItem = new MenuItem(new Action(ACTION_EDIT_NODE, "MENU_ACTIONS_EDITNODE"c));
    MenuItem deleteNodeItem = new MenuItem(new Action(ACTION_DELETE_NODE, "MENU_ACTIONS_DELETENODE"c));
    MenuItem linkFromItem = new MenuItem(new Action(ACTION_NEW_LINK_FROM, "MENU_ACTIONS_NEWLINK_FROM"c));
    MenuItem linkToItem = new MenuItem(new Action(ACTION_NEW_LINK_TO, "MENU_ACTIONS_NEWLINK_TO"c));
    MenuItem editLinkItem = new MenuItem(new Action(ACTION_EDIT_LINK, "MENU_ACTIONS_EDITLINK"c));
    MenuItem deleteLinkItem = new MenuItem(new Action(ACTION_DELETE_LINK, "MENU_ACTIONS_DELETELINK"c));
    MenuItem findPathsFromItem = new MenuItem(new Action(ACTION_FIND_PATHS_FROM, "MENU_PATHS_FINDPATHS_FROM"c));
    MenuItem findPathsToItem = new MenuItem(new Action(ACTION_FIND_PATHS_TO, "MENU_PATHS_FINDPATHS_TO"c));
    MenuItem findShortestPathsFromItem = new MenuItem(new Action(ACTION_FIND_SHORTEST_PATHS_FROM, "MENU_PATHS_SHORTESTPATHS_FROM"c));
    MenuItem findShortestPathsToItem = new MenuItem(new Action(ACTION_FIND_SHORTEST_PATHS_TO, "MENU_PATHS_SHORTESTPATHS_TO"c));
    MenuItem unmarkPathsItem = new MenuItem(new Action(ACTION_UNMARK_PATHS, "MENU_PATHS_UNMARK"c));
    MenuItem drawItem = new MenuItem(new Action(ACTION_DRAW, "MENU_ACTIONS_DRAW"c, "draw", KeyCode.KEY_D, KeyFlag.Control));

    // Main windows and its main parts
    Window window = Platform.instance.createWindow("Asciiplant", null, WindowFlag.Resizable | WindowFlag.ExpandSize, 1000, 600);
    VerticalLayout mainLayout = new VerticalLayout();
    mainLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
    auto mainMenu = new CustomMainMenu(newNodeItem, editNodeItem, deleteNodeItem, linkFromItem, linkToItem,
            editLinkItem, deleteLinkItem, findPathsFromItem, findPathsToItem, findShortestPathsFromItem,
            findShortestPathsToItem, unmarkPathsItem, drawItem);
    auto popupMenu = new CustomPopupMenu(newNodeItem, editNodeItem, deleteNodeItem, linkFromItem, linkToItem,
            editLinkItem, deleteLinkItem, findPathsFromItem, findPathsToItem, findShortestPathsFromItem,
            findShortestPathsToItem, unmarkPathsItem);
    auto workspaceContainer = new WorkspaceContainer("workspaceContainer", popupMenu);
    mainLayout.addChild(mainMenu);
    mainLayout.addChild(workspaceContainer);
    
    // Main menu: keyboard shortcut handling
    mainLayout.keyToAction = delegate(Widget source, uint keyCode, uint flags) {
        return mainMenu.findKeyAction(keyCode, flags);
    };
    
    // Main menu: actions implementation
    mainLayout.onAction = delegate(Widget source, const Action a) {
        if (a.id == ACTION_FILE_NEW) {
            workspaceContainer.workspace = new Workspace();
            workspaceContainer.draw();
            return true;
        } else if (a.id == ACTION_FILE_OPEN) {
            FileDialog dialog = new FileDialog(UIString.fromId("TXT_OPEN_DATA_FILE"), window, null);
            dialog.allowMultipleFiles = false;
            dialog.addFilter(FileFilterEntry(UIString("FILTER_ALL_FILES", "All files (*)"d), "*"));
            dialog.addFilter(FileFilterEntry(UIString("FILTER_XML_FILES", "XML files (*.xml)"d), "*.xml"));
            dialog.filterIndex = 1;
            dialog.dialogResult = delegate(Dialog dialog, const Action result) {
                if (result.id == ACTION_OPEN.id) {
                    string filename = (cast(FileDialog)dialog).filenames[0];
                    workspaceContainer.workspace = new Workspace();
                    workspaceContainer.workspace.loadFromFile(filename);
                    workspaceContainer.filename = filename;
                    workspaceContainer.draw();
                }
            };
            dialog.show();
            return true;
        } else if (a.id == ACTION_FILE_SAVE_DATA) {
            if (workspaceContainer.filename !is null) {
                workspaceContainer.workspace.saveDataToFile(workspaceContainer.filename);
            } else {
                // TODO perform save as
            }
            return true;
        } else if (a.id == ACTION_FILE_SAVE_DATA_AS) {
            FileDialog dialog = new FileDialog(UIString.fromId("TXT_SAVE_DATA_AS"), window, null, FileDialogFlag.Save);
            dialog.allowMultipleFiles = false;
            dialog.addFilter(FileFilterEntry(UIString("FILTER_ALL_FILES", "All files (*)"d), "*"));
            dialog.addFilter(FileFilterEntry(UIString("FILTER_XML_FILES", "XML files (*.xml)"d), "*.xml"));
            dialog.filterIndex = 1;
            dialog.dialogResult = delegate(Dialog dialog, const Action result) {
                if (result.id == ACTION_SAVE.id) {
                    workspaceContainer.filename = (cast(FileDialog)dialog).filename;
                    workspaceContainer.workspace.saveDataToFile(workspaceContainer.filename);
                }
            };
            dialog.show();
            return true;
        }else if (a.id == ACTION_FILE_SAVE_VIS) {
            FileDialog dialog = new FileDialog(UIString.fromId("TXT_EXPORT"), window, null, FileDialogFlag.Save);
            dialog.allowMultipleFiles = false;
            dialog.addFilter(FileFilterEntry(UIString("FILTER_ALL_FILES", "All files (*)"d), "*"));
            dialog.addFilter(FileFilterEntry(UIString("FILTER_TXT_FILES", "TXT files (*.txt)"d), "*.txt"));
            dialog.filterIndex = 1;
            dialog.dialogResult = delegate(Dialog dialog, const Action result) {
                if (result.id == ACTION_SAVE.id) {
                    workspaceContainer.workspace.saveVisualizationToFile((cast(FileDialog)dialog).filename);
                }
            };
            dialog.show();
            return true;
        } else if (a.id == ACTION_FILE_EXIT) {
            window.close();
            return true;
        } else if (a.id == ACTION_NEW_NODE) {
            auto contentWindow = Platform.instance.createWindow(UIString.fromId("TXT_CREATE_NEW_NODE"), window, 1u, 300, 200);
            auto vLayout = new VerticalLayout();
            vLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            // Label
            vLayout.addChild((new TextWidget()).text(UIString.fromId("TXT_TYPE_CONTENT")));
            // Edit box
            auto nodeContent = new EditBox("nodeContent", ""d);
            nodeContent.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            vLayout.addChild(nodeContent);
            // Buttons
            auto bLayout = new TableLayout();
            bLayout.colCount = 2;
            bLayout.alignment(Align.Center);
            bLayout.layoutWidth(FILL_PARENT);
            auto okButton = new Button(null, UIString.fromId("TXT_OK"));
            okButton.click = delegate(Widget src) {
                Node node = workspaceContainer.workspace.createNode(to!string(nodeContent.text));
                contentWindow.close();
                workspaceContainer.draw();
                return true;
            };
            auto cancelButton = new Button(null, UIString.fromId("TXT_CANCEL"));
            cancelButton.click = delegate(Widget src) {
                contentWindow.close();
                return true;
            };
            bLayout.addChild(okButton);
            bLayout.addChild(cancelButton);
            
            vLayout.addChild(bLayout);
            contentWindow.mainWidget = vLayout;
            contentWindow.show();
            return true;
        } else if (a.id == ACTION_EDIT_NODE) {
            Node node = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (node !is null) {
                auto contentWindow = Platform.instance.createWindow(UIString.fromId("TXT_EDIT_NODE"), window, 1u, 300, 200);
                auto vLayout = new VerticalLayout();
                vLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
                // Label
                vLayout.addChild((new TextWidget()).text(UIString.fromId("TXT_TYPE_CONTENT")));
                // Edit box
                auto nodeContent = new EditBox("nodeContent", ""d);
                nodeContent.text(UIString.fromRaw(node.content));
                nodeContent.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
                vLayout.addChild(nodeContent);
                // Buttons
                auto bLayout = new TableLayout();
                bLayout.colCount = 2;
                bLayout.alignment(Align.Center);
                bLayout.layoutWidth(FILL_PARENT);
                auto okButton = new Button(null, UIString.fromId("TXT_OK"));
                okButton.click = delegate(Widget src) {
                    node.content = to!string(nodeContent.text);
                    contentWindow.close();
                    workspaceContainer.draw();
                    return true;
                };
                auto cancelButton = new Button(null, UIString.fromId("TXT_CANCEL"));
                cancelButton.click = delegate(Widget src) {
                    contentWindow.close();
                    return true;
                };
                bLayout.addChild(okButton);
                bLayout.addChild(cancelButton);
            
                vLayout.addChild(bLayout);
                contentWindow.mainWidget = vLayout;
                contentWindow.show();
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_DELETE_NODE) {
            Node node = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (node !is null) {
                workspaceContainer.workspace.deleteNode(node);
                workspaceContainer.draw();
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_NEW_LINK_FROM) {
            Node fromNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (fromNode !is null) {
                workspaceContainer.currLinkFromNode = fromNode;
                if (workspaceContainer.currLinkToNode !is null) {
                    auto contentWindow = Platform.instance.createWindow(UIString.fromId("TXT_NEW_LINK_DESCRIPTION"), window, 1u, 300, 200);
                    auto vLayout = new VerticalLayout();
                    vLayout.layoutWidth(FILL_PARENT);
                    // Label
                    vLayout.addChild((new TextWidget()).text(UIString.fromId("TXT_TYPE_DESCRIPTION")));
                    // Edit box
                    auto linkDescription = new EditLine("linkDescription");
                    linkDescription.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
                    vLayout.addChild(linkDescription);
                    // Buttons
                    auto bLayout = new TableLayout();
                    bLayout.colCount = 2;
                    bLayout.alignment(Align.Center);
                    bLayout.layoutWidth(FILL_PARENT);
                    auto okButton = new Button(null, UIString.fromId("TXT_OK"));
                    okButton.click = delegate(Widget src) {
                        workspaceContainer.workspace.linkNodes(workspaceContainer.currLinkFromNode, workspaceContainer.currLinkToNode, to!string(linkDescription.text));
                        workspaceContainer.resetTemporaryNodes();
                        contentWindow.close();
                        workspaceContainer.draw();
                        return true;
                    };
                    auto cancelButton = new Button(null, UIString.fromId("TXT_CANCEL"));
                    cancelButton.click = delegate(Widget src) {
                        contentWindow.close();
                        return true;
                    };
                    bLayout.addChild(okButton);
                    bLayout.addChild(cancelButton);
            
                    vLayout.addChild(bLayout);
                    contentWindow.mainWidget = vLayout;
                    contentWindow.show();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_NEW_LINK_TO) {
            Node toNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (toNode !is null) {
                workspaceContainer.currLinkToNode = toNode;
                if (workspaceContainer.currLinkFromNode !is null) {
                    auto contentWindow = Platform.instance.createWindow(UIString.fromId("TXT_NEW_LINK_DESCRIPTION"), window, 1u, 300, 200);
                    auto vLayout = new VerticalLayout();
                    vLayout.layoutWidth(FILL_PARENT);
                    // Label
                    vLayout.addChild((new TextWidget()).text(UIString.fromId("TXT_TYPE_DESCRIPTION")));
                    // Edit box
                    auto linkDescription = new EditLine("linkDescription");
                    linkDescription.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
                    vLayout.addChild(linkDescription);
                    // Buttons
                    auto bLayout = new TableLayout();
                    bLayout.colCount = 2;
                    bLayout.alignment(Align.Center);
                    bLayout.layoutWidth(FILL_PARENT);
                    auto okButton = new Button(null, UIString.fromId("TXT_OK"));
                    okButton.click = delegate(Widget src) {
                        workspaceContainer.workspace.linkNodes(workspaceContainer.currLinkFromNode, workspaceContainer.currLinkToNode, to!string(linkDescription.text));
                        workspaceContainer.resetTemporaryNodes();
                        contentWindow.close();
                        workspaceContainer.draw();
                        return true;
                    };
                    auto cancelButton = new Button(null, UIString.fromId("TXT_CANCEL"));
                    cancelButton.click = delegate(Widget src) {
                        contentWindow.close();
                        return true;
                    };
                    bLayout.addChild(okButton);
                    bLayout.addChild(cancelButton);
            
                    vLayout.addChild(bLayout);
                    contentWindow.mainWidget = vLayout;
                    contentWindow.show();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_EDIT_LINK) {
            Link link = workspaceContainer.workspace
                .getLinkAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (link !is null) {
                auto contentWindow = Platform.instance.createWindow(UIString.fromId("TXT_EDIT_LINK_DESCRIPTION"), window, 1u, 300, 200);
                auto vLayout = new VerticalLayout();
                vLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
                // Label
                vLayout.addChild((new TextWidget()).text(UIString.fromId("TXT_TYPE_DESCRIPTION")));
                // Edit box
                auto linkDescription = new EditLine("linkDescription");
                linkDescription.layoutWidth(FILL_PARENT);
                linkDescription.text(UIString.fromRaw(link.description));
                vLayout.addChild(linkDescription);
                // Buttons
                auto bLayout = new TableLayout();
                bLayout.colCount = 2;
                bLayout.alignment(Align.Center);
                bLayout.layoutWidth(FILL_PARENT);
                auto okButton = new Button(null, UIString.fromId("TXT_OK"));
                okButton.click = delegate(Widget src) {
                    link.description = to!string(linkDescription.text);
                    contentWindow.close();
                    workspaceContainer.draw();
                    return true;
                };
                auto cancelButton = new Button(null, UIString.fromId("TXT_CANCEL"));
                cancelButton.click = delegate(Widget src) {
                    contentWindow.close();
                    return true;
                };
                bLayout.addChild(okButton);
                bLayout.addChild(cancelButton);
            
                vLayout.addChild(bLayout);
                contentWindow.mainWidget = vLayout;
                contentWindow.show();
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_LINK_NOT_SELECTED"));
            }
            return true;
        }else if (a.id == ACTION_DELETE_LINK) {
            Link link = workspaceContainer.workspace
                .getLinkAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (link !is null) {
                workspaceContainer.workspace.deleteLink(link);
                workspaceContainer.draw();
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_LINK_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_FIND_PATHS_FROM) {
            Node fromNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (fromNode !is null) {
                workspaceContainer.currPathFromNode = fromNode;
                if (workspaceContainer.currPathToNode !is null) {
                    Path[] paths = workspaceContainer.workspace
                        .findPaths(workspaceContainer.currPathFromNode, workspaceContainer.currPathToNode);
                    foreach (ref Path p; paths) {
                        workspaceContainer.workspace.markPath(p);
                    }
                    workspaceContainer.resetTemporaryNodes();
                    workspaceContainer.draw();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_FIND_PATHS_TO) {
            Node toNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (toNode !is null) {
                workspaceContainer.currPathToNode = toNode;
                if (workspaceContainer.currPathFromNode !is null) {
                    Path[] paths = workspaceContainer.workspace
                        .findPaths(workspaceContainer.currPathFromNode, workspaceContainer.currPathToNode);
                    foreach (ref Path p; paths) {
                        workspaceContainer.workspace.markPath(p);
                    }
                    workspaceContainer.resetTemporaryNodes();
                    workspaceContainer.draw();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_FIND_SHORTEST_PATHS_FROM) {
            Node fromNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (fromNode !is null) {
                workspaceContainer.currPathFromNode = fromNode;
                if (workspaceContainer.currPathToNode !is null) {
                    Path[] paths = workspaceContainer.workspace
                        .findShortestPaths(workspaceContainer.currPathFromNode, workspaceContainer.currPathToNode);
                    foreach (ref Path p; paths) {
                        workspaceContainer.workspace.markPath(p);
                    }
                    workspaceContainer.resetTemporaryNodes();
                    workspaceContainer.draw();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_FIND_SHORTEST_PATHS_TO) {
            Node toNode = workspaceContainer.workspace
                .getNodeAt(workspaceContainer.mainText.caretX, workspaceContainer.mainText.caretY);
            if (toNode !is null) {
                workspaceContainer.currPathToNode = toNode;
                if (workspaceContainer.currPathFromNode !is null) {
                    Path[] paths = workspaceContainer.workspace
                        .findShortestPaths(workspaceContainer.currPathFromNode, workspaceContainer.currPathToNode);
                    foreach (ref Path p; paths) {
                        workspaceContainer.workspace.markPath(p);
                    }
                    workspaceContainer.resetTemporaryNodes();
                    workspaceContainer.draw();
                }
            } else {
                window.showMessageBox(UIString.fromId("TXT_ERROR"), UIString.fromId("TXT_NODE_NOT_SELECTED"));
            }
            return true;
        } else if (a.id == ACTION_UNMARK_PATHS) {
            workspaceContainer.workspace.resetAllMarks();
            workspaceContainer.draw();
            return true;
        } else if (a.id == ACTION_DRAW) {
            workspaceContainer.draw();
            return true;
        } else if (a.id == ACTION_HELP_ONLINE) {
            // TODO
            return true;
        } else if (a.id == ACTION_HELP_ABOUT) {
            window.showMessageBox(
                UIString.fromRaw("About"d),
                UIString.fromRaw("Asciiplant\n\nDeveloped by Žans Kļimovičs\nunder MIT license"d));
            return true;
        }
        return false;
    };
    mainMenu.menuItemClick = delegate(MenuItem item) {
        if (item.action) {
            return mainLayout.dispatchAction(item.action);
        }
        return false;
    };
    
    window.mainWidget = mainLayout;
    window.show();
    
    return Platform.instance.enterMessageLoop();
}

class WorkspaceContainer : VerticalLayout
{
    private Workspace workspace;
    private CustomEditBox mainText;
    private TextWidget statusBar;
    private ComboBox directionList, isLinkToCenterField, isDrawBoxesFirstField, isShowLinkDescrField;
    private EditLine marginXEdit, marginYEdit;
    private Node currLinkFromNode, currLinkToNode, currPathFromNode, currPathToNode;  // temporary Nodes
    private string filename;  // Currently opened file
    
    this(string id, CustomPopupMenu popupMenu)
    {
        super(id);
        workspace = new Workspace();
        
        mainText = new CustomEditBox("ebMain", this);
        mainText.popupMenu = popupMenu;
        
        DockHost dockLayout = new DockHost();
        
        DockWindow settingsDock = new DockWindow("2");
        settingsDock.caption.textResource("CAP_SETTINGS"c);
        settingsDock.dockAlignment(DockAlignment.Right);
        dockLayout.addDockedWindow(settingsDock);
        VerticalLayout settingsLayout = new VerticalLayout();
        // Apply button with its function
        Button applyButton = new Button(null, UIString.fromId("TXT_APPLY"));
        applyButton.click = delegate(Widget src) { 
            applySettings();
            draw();
            return true;
        };
        settingsLayout.addChild(applyButton);
        TableLayout settingsTable = new TableLayout("settings_layout");
        settingsTable.colCount = 2;
        // Row 1
        settingsTable.addChild((new TextWidget(null, "Direction"d)).alignment(Align.Right | Align.VCenter));
        directionList = new ComboBox("directionField", ["DIR_N"c, "DIR_NE"c, "DIR_E"c, "DIR_SE"c, "DIR_S"c, "DIR_SW"c, "DIR_W"c, "DIR_NW"c]);
        directionList.selectedItemIndex(2).layoutWidth(FILL_PARENT);
        settingsTable.addChild(directionList);
        // Row 2
        marginXEdit = new EditLine("marginXField", "0"d);
        marginXEdit.layoutWidth(FILL_PARENT);
        settingsTable.addChild((new TextWidget(null, "Horizontal margin"d)).alignment(Align.Right | Align.VCenter));
        settingsTable.addChild(marginXEdit);
        // Row 3
        marginYEdit = new EditLine("marginYField", "0"d);
        marginYEdit.layoutWidth(FILL_PARENT);
        settingsTable.addChild((new TextWidget(null, "Vertical margin"d)).alignment(Align.Right | Align.VCenter));
        settingsTable.addChild(marginYEdit);
        // Row 4
        isLinkToCenterField = new ComboBox("isLinkToCenterField", ["TXT_YES"c, "TXT_NO"c]);
        isLinkToCenterField.selectedItemIndex(0).layoutWidth(FILL_PARENT);
        settingsTable.addChild((new TextWidget(null, "Link to box center"d)).alignment(Align.Right | Align.VCenter));
        settingsTable.addChild(isLinkToCenterField);
        // Row 5
        isDrawBoxesFirstField = new ComboBox("isDrawBoxesFirstField", ["TXT_YES"c, "TXT_NO"c]);
        isDrawBoxesFirstField.selectedItemIndex(0).layoutWidth(FILL_PARENT);
        settingsTable.addChild((new TextWidget(null, "Draw all boxes first"d)).alignment(Align.Right | Align.VCenter));
        settingsTable.addChild(isDrawBoxesFirstField);
        // Row 6
        isShowLinkDescrField = new ComboBox("isShowLinkDescrField", ["TXT_YES"c, "TXT_NO"c]);
        isShowLinkDescrField.selectedItemIndex(0).layoutWidth(FILL_PARENT);
        settingsTable.addChild((new TextWidget(null, "Show link descriptions"d)).alignment(Align.Right | Align.VCenter));
        settingsTable.addChild(isShowLinkDescrField);
        settingsTable.margins(Rect(2,2,2,2)).layoutWidth(FILL_PARENT);
        settingsLayout.addChild(settingsTable);
        settingsDock.bodyWidget(settingsLayout.layoutWidth(FILL_PARENT));
        
        DockWindow dw3 = new DockWindow("3");
        dw3.caption.textResource("CAP_PATHS"c);
        dw3.dockAlignment(DockAlignment.Bottom);
        dockLayout.addDockedWindow(dw3);
        
        dockLayout.bodyWidget(mainText);
        
        this.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        dockLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        
        this.addChild(dockLayout);
        
        statusBar = new TextWidget();
        statusBar.text(UIString.fromId("TXT_READY"));
        statusBar.layoutWidth(FILL_PARENT);
        this.addChild(statusBar);

        applySettings();
    }

    private void draw()
    {
        setStatusText(UIString.fromId("TXT_PLEASE_WAIT"));
        mainText.text(to!dstring(workspace.visualize()));
        setStatusText(UIString.fromId("TXT_READY"));
    }

    private void setStatusText(UIString text)
    {
        statusBar.text(text);
    }

    private void applySettings()
    {
        if (!isNumeric(to!string(marginXEdit.text))) {
            // TODO show error message
        } else if (!isNumeric(to!string(marginYEdit.text))) {
            // TODO show error message
        }
        
        if (directionList.selectedItemIndex == 0) workspace.settings.direction = Direction.N;
        else if (directionList.selectedItemIndex == 1) workspace.settings.direction = Direction.NE;
        else if (directionList.selectedItemIndex == 2) workspace.settings.direction = Direction.E;
        else if (directionList.selectedItemIndex == 3) workspace.settings.direction = Direction.SE;
        else if (directionList.selectedItemIndex == 4) workspace.settings.direction = Direction.S;
        else if (directionList.selectedItemIndex == 5) workspace.settings.direction = Direction.SW;
        else if (directionList.selectedItemIndex == 6) workspace.settings.direction = Direction.W;
        else if (directionList.selectedItemIndex == 7) workspace.settings.direction = Direction.NW;

        workspace.settings.boxMarginX(to!long(marginXEdit.text));
        workspace.settings.boxMarginY(to!long(marginYEdit.text));

        workspace.settings.isJoinToCenter(isLinkToCenterField.selectedItemIndex == 0);
        workspace.settings.isCreateAllBoxesFirst(isDrawBoxesFirstField.selectedItemIndex == 0);
        workspace.settings.isShowArrowDescriptions(isShowLinkDescrField.selectedItemIndex == 0);
    }

    private void resetTemporaryNodes()
    {
        currLinkFromNode = null;
        currLinkToNode = null;
        currPathFromNode = null;
        currPathToNode = null;
    }
}

class CustomEditBox : EditBox
{
    WorkspaceContainer workspaceContainer;
    
    this(string id, WorkspaceContainer workspaceContainer)
    {
        super(id, ""d);
        this.workspaceContainer = workspaceContainer;
    }
    
    override protected void onControlClick()
    {
        workspaceContainer.setStatusText(UIString.fromRaw(to!dstring(to!string(this.caretPos.pos) ~ " / " ~ to!string(this.caretPos.line))));
    }

    @property ulong caretX()
    {
        return to!ulong(this.caretPos.pos);
    }

    @property ulong caretY()
    {
        return to!ulong(this.caretPos.line);
    }
}

class CustomMainMenu : MainMenu
{
    this(MenuItem newNodeItem, MenuItem editNodeItem, MenuItem deleteNodeItem, MenuItem linkFromItem,
            MenuItem linkToItem, MenuItem editLinkItem, MenuItem deleteLinkItem,
            MenuItem findPathsFromItem, MenuItem findPathsToItem, MenuItem findShortestPathsFromItem,
            MenuItem findShortestPathsToItem, MenuItem unmarkPathsItem, MenuItem drawItem)
    {
        super();
                
        MenuItem mainMenuItems = new MenuItem();
        MenuItem sep = new MenuItem();
        sep.type = MenuItemType.Separator;
        MenuItem fileItem = new MenuItem(new Action(1, "MENU_FILE"c));
        fileItem.add(new Action(ACTION_FILE_NEW, "MENU_FILE_NEW"c, "document-new", KeyCode.KEY_N, KeyFlag.Control));
        fileItem.add(sep);
        fileItem.add(new Action(ACTION_FILE_OPEN, "MENU_FILE_OPEN"c, "document-open", KeyCode.KEY_O, KeyFlag.Control));
        fileItem.add(new Action(ACTION_FILE_SAVE_DATA, "MENU_FILE_SAVE_DATA"c, "document-save-data", KeyCode.KEY_S, KeyFlag.Control));
        fileItem.add(new Action(ACTION_FILE_SAVE_DATA_AS, "MENU_FILE_SAVE_DATA_AS"c, "document-save-data", KeyCode.KEY_S, KeyFlag.Control));
        fileItem.add(sep);
        fileItem.add(new Action(ACTION_FILE_SAVE_VIS, "MENU_FILE_SAVE_VIS"c, "document-save-vis", KeyCode.KEY_S, KeyFlag.Control));
        fileItem.add(sep);
        fileItem.add(new Action(ACTION_FILE_EXIT, "MENU_FILE_EXIT"c, "document-close"c, KeyCode.KEY_X, KeyFlag.Alt));
        mainMenuItems.add(fileItem);
        MenuItem actionItem = new MenuItem(new Action(2, "MENU_ACTIONS"c));
        actionItem.add(newNodeItem);
        actionItem.add(editNodeItem);
        actionItem.add(deleteNodeItem);
        actionItem.add(sep);
        actionItem.add(linkFromItem);
        actionItem.add(linkToItem);
        actionItem.add(editLinkItem);
        actionItem.add(deleteLinkItem);
        actionItem.add(sep);
        actionItem.add(drawItem);
        mainMenuItems.add(actionItem);
        MenuItem pathsItem = new MenuItem(new Action(4, "MENU_PATHS"c));
        pathsItem.add(findPathsFromItem);
        pathsItem.add(findPathsToItem);
        pathsItem.add(sep);
        pathsItem.add(findShortestPathsFromItem);
        pathsItem.add(findShortestPathsToItem);
        pathsItem.add(sep);
        pathsItem.add(unmarkPathsItem);
        mainMenuItems.add(pathsItem);
        MenuItem helpItem = new MenuItem(new Action(4, "MENU_HELP"c));
        helpItem.add(new Action(ACTION_HELP_ONLINE, "MENU_HELP_ONLINE"));
        helpItem.add(new Action(ACTION_HELP_ABOUT, "MENU_HELP_ABOUT"));
        mainMenuItems.add(helpItem);
        this.menuItems = mainMenuItems;
    }
}

class CustomPopupMenu : MenuItem
{
    this(MenuItem newNodeItem, MenuItem editNodeItem, MenuItem deleteNodeItem, MenuItem linkFromItem,
            MenuItem linkToItem, MenuItem editLinkItem, MenuItem deleteLinkItem,
            MenuItem findPathsFromItem, MenuItem findPathsToItem, MenuItem findShortestPathsFromItem,
            MenuItem findShortestPathsToItem, MenuItem unmarkPathsItem)
    {
        super(null);

        MenuItem sep = new MenuItem();
        sep.type = MenuItemType.Separator;
        
        add(newNodeItem);
        add(editNodeItem);
        add(deleteNodeItem);
        add(sep);
        add(linkFromItem);
        add(linkToItem);
        add(editLinkItem);
        add(deleteLinkItem);
        add(sep);
        add(findPathsFromItem);
        add(findPathsToItem);
        add(findShortestPathsFromItem);
        add(findShortestPathsToItem);
        add(unmarkPathsItem);
    }
}
