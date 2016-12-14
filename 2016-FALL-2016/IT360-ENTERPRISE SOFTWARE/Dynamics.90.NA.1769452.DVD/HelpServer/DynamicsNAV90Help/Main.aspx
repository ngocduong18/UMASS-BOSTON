<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Main.aspx.cs" Inherits="Microsoft.Dynamics.Nav.WebHelp.Main" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Microsoft Dynamics NAV 2016 Help</title>
    <meta http-equiv="X-UA-Compatible" content="IE=9; IE=10" />
    <link href="/css/msdnTheme.css" rel="stylesheet" type="text/css" />
    <link rel="shortcut icon" href="images/NAV_blue_286.ico" type="image/x-icon" />
    <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.2/themes/smoothness/jquery-ui.css" />
    <script src="http://ajax.aspnetcdn.com/ajax/jQuery/jquery-2.1.0.min.js"></script>
    <script src="http://ajax.aspnetcdn.com/ajax/jquery.ui/1.10.2/jquery-ui.min.js"></script>
    <script type="text/javascript" src="/js/custom.js"></script>
</head>
<body class="library" onload="init()">
    <div id="page">
        <div class="FF ltr" id="ux-header">
            <h1 class="title">
                <asp:Label runat="server" Text="Dynamics NAV 2016" ID="ProductName"/></h1>
            <div class="ux-mtps-internav">
                <div class="SearchBox">
                    <form name="HeaderSearchForm" id="HeaderSearchForm" action="/Search.aspx" method="get" target="mainContentIFrame">
                        <input name="lang" id="lang" value="<%=Context.Request.QueryString["lang"] %>" type="hidden" />
                        <input name="query" title="Search" id="HeaderSearchTextBox" style="color: rgb(170, 170, 170); font-style: italic;" type="text" maxlength="200" autocomplete="off" />
                        <button title="Search" class="header-search-button" id="HeaderSearchButton" type="submit" value=""></button>
                    </form>
                </div>
                <div class="TocNavigation">
                    <div class="toclevel1">
                        <asp:HyperLink ID="GettingStartedLink" runat="server"
                            Text="<%$Resources:WebHelpResources, NavMenu_GettingStarted %>"
                            ToolTip="<%$Resources:WebHelpResources, NavMenu_GettingStarted %>" />
                        <asp:HyperLink runat="server"
                            Text="<%$Resources:WebHelpResources, NavMenu_Community%>"
                            ToolTip="<%$Resources:WebHelpResources, NavMenu_Community %>"
                            NavigateUrl="http://community.dynamics.com/nav/default.aspx"
                            Target="_blank" />
                        <asp:HyperLink runat="server"
                            Text="MSDN"
                            ToolTip="MSDN"
                            NavigateUrl="http://go.microsoft.com/fwlink/?LinkID=623003"
                            Target="_blank" />
                    </div>
                </div>
            </div>
        </div>

        <div id="body">
            <div class="TocLeftPane" id="leftNav">
                <div class="toclevel0" style="padding-left: 0px;" data-toclevel="0">
                    <form id="TocForm" runat="server">
                        <asp:XmlDataSource 
                            ID="XmlTocDataSource" 
                            runat="server"/>
                        <asp:TreeView
                            ID="TocTreeView" 
                            ExpandDepth="1"
                            ExpandImageUrl="~/help/local/expall.gif"
                            CollapseImageUrl="~/help/local/collall.gif"
                            runat="server"
                            DataSourceID="XmlTocDataSource" 
                            Target="mainContentIFrame"
                            NodeWrap="True">
                            <DataBindings>
                                <asp:TreeNodeBinding DataMember="Node" TextField="DisplayName" ValueField="Page" ToolTipField="DisplayName" />
                            </DataBindings>
                        </asp:TreeView>
                    </form>
                </div>
            </div>
            <div class="content" id="content" style="margin-left: 300px;">
                <div class="topic">
                    <h1 class="title"></h1>
                </div>
                <div id="mainSection">
                    <div id="mainBody">
                        <iframe name="mainContentIFrame"
                                frameborder="0" 
                                id="mainContentIFrame" 
                                scrolling="no" 
                                src="<%=ResolveUrl("~/help/" + Context.Request.QueryString["lang"] + "/" + Context.Request.QueryString["content"])%>"/>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>

    