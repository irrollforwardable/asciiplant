module asciiplant.gui;

import asciiplant.core;
import dlangui;

mixin APP_ENTRY_POINT;

extern (C) int UIAppMain(string[] args) {
	embeddedResourceList.addResources(embedResourcesFromList!("resources.list")());
	Platform.instance.uiLanguage = "en";

    Window window = Platform.instance.createWindow("Asciiplant", null);

    VerticalLayout mainLayout = new VerticalLayout();

    // Main menu
    MenuItem mainMenuItems = new MenuItem();
    MenuItem sep = new MenuItem();
    sep.type = MenuItemType.Separator;
    MenuItem fileItem = new MenuItem(new Action(1, "MENU_FILE"c));
    fileItem.add(new Action(11, "MENU_FILE_NEW"c, "document-new", KeyCode.KEY_N, KeyFlag.Control));
    fileItem.add(sep);
    fileItem.add(new Action(12, "MENU_FILE_OPEN"c, "document-open", KeyCode.KEY_O, KeyFlag.Control));
    fileItem.add(new Action(13, "MENU_FILE_SAVE_DATA"c, "document-save-data", KeyCode.KEY_S, KeyFlag.Control));
    fileItem.add(new Action(13, "MENU_FILE_SAVE_VIS"c, "document-save-vis", KeyCode.KEY_S, KeyFlag.Control));
    fileItem.add(sep);
    fileItem.add(new Action(14, "MENU_FILE_EXIT"c, "document-close"c, KeyCode.KEY_X, KeyFlag.Alt));
    mainMenuItems.add(fileItem);
    MenuItem actionItem = new MenuItem(new Action(2, "MENU_ACTIONS"c));
    actionItem.add(new Action(21, "MENU_ACTIONS_NEWNODE"c, "node-new"));
    actionItem.add(new Action(22, "MENU_ACTIONS_DELETENODE"c, "node-remove"));
    actionItem.add(sep);
    actionItem.add(new Action(23, "MENU_ACTIONS_NEWLINK"c, "link-new"));
    actionItem.add(new Action(24, "MENU_ACTIONS_DELETELINK"c, "link-remove"));
    actionItem.add(sep);
    actionItem.add(new Action(25, "MENU_ACTIONS_FINDPATHS"c, "find-paths"));
    actionItem.add(new Action(26, "MENU_ACTIONS_SHORTESTPATHS"c, "find-short-paths"));
    actionItem.add(new Action(27, "MENU_ACTIONS_UNMARK"c, "unmark-paths"));
    actionItem.add(sep);
    actionItem.add(new Action(28, "MENU_ACTIONS_DRAW"c, "draw", KeyCode.KEY_D, KeyFlag.Control));
    mainMenuItems.add(actionItem);
    MenuItem helpItem = new MenuItem(new Action(4, "MENU_HELP"c));
    helpItem.add(new Action(41, "MENU_HELP_ONLINE"));
    helpItem.add(new Action(41, "MENU_HELP_ABOUT"));
    mainMenuItems.add(helpItem);
    MainMenu mainMenu = new MainMenu(mainMenuItems);

    // Dock
	DockHost dockLayout = new DockHost();

	DockWindow dataDock = new DockWindow("1");
	dataDock.caption.textResource("CAP_DATA"c);
	dataDock.dockAlignment(DockAlignment.Left);
	dockLayout.addDockedWindow(dataDock);
	VerticalLayout dataLayout = new VerticalLayout();
	dataLayout.margins(Rect(2,2,2,2)).layoutWidth(FILL_PARENT);
	TreeWidget dataTree = new TreeWidget("dataTree");
	dataTree.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
	dataTree.items.newChild("nodesGroup", "Nodes"d, null);
	dataTree.items.newChild("linksGroup", "Links"d, null);
	dataLayout.addChild(dataTree);
	dataDock.bodyWidget(dataLayout);

	DockWindow settingsDock = new DockWindow("2");
	settingsDock.caption.textResource("CAP_SETTINGS"c);
	settingsDock.dockAlignment(DockAlignment.Right);
	dockLayout.addDockedWindow(settingsDock);
	VerticalLayout settingsLayout = new VerticalLayout();
	TableLayout settingsTable = new TableLayout("settings_layout");
	settingsTable.colCount = 2;
	// Row 1
	settingsTable.addChild((new TextWidget(null, "Direction"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new ComboBox("directionField", ["DIR_N"c, "DIR_NE"c, "DIR_E"c, "DIR_SE"c, "DIR_S"c, "DIR_SW"c, "DIR_W"c, "DIR_NW"c])).selectedItemIndex(2).layoutWidth(FILL_PARENT));
	// Row 2
	settingsTable.addChild((new TextWidget(null, "Horizontal margin"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new EditLine("marginXField", "0"d)).layoutWidth(FILL_PARENT));
	// Row 3
	settingsTable.addChild((new TextWidget(null, "Vertical margin"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new EditLine("marginYField", "0"d)).layoutWidth(FILL_PARENT));
	// Row 4
	settingsTable.addChild((new TextWidget(null, "Link to box center"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new ComboBox("isLinkToCenterField", ["TXT_YES"c, "TXT_NO"c])).selectedItemIndex(0).layoutWidth(FILL_PARENT));
	// Row 5
	settingsTable.addChild((new TextWidget(null, "Draw all boxes first"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new ComboBox("isDrawBOxesFirstField", ["TXT_YES"c, "TXT_NO"c])).selectedItemIndex(0).layoutWidth(FILL_PARENT));
	// Row 6
	settingsTable.addChild((new TextWidget(null, "Show link descriptions"d)).alignment(Align.Right | Align.VCenter));
	settingsTable.addChild((new ComboBox("isShowLinkDescrField", ["TXT_YES"c, "TXT_NO"c])).selectedItemIndex(0).layoutWidth(FILL_PARENT));
	settingsTable.margins(Rect(2,2,2,2)).layoutWidth(FILL_PARENT);
	settingsLayout.addChild(settingsTable);
	settingsDock.bodyWidget(settingsLayout.layoutWidth(FILL_PARENT));

	DockWindow dw3 = new DockWindow("3");
	dw3.caption.textResource("CAP_PATHS"c);
	dw3.dockAlignment(DockAlignment.Bottom);
	dockLayout.addDockedWindow(dw3);

	EditBox mainText = new EditBox("ebMain", ""d);
	dockLayout.bodyWidget(mainText);

	mainLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
	dockLayout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);


	mainLayout.addChild(mainMenu);
	mainLayout.addChild(dockLayout);

	window.mainWidget = mainLayout;
    window.show();
    return Platform.instance.enterMessageLoop();
}
