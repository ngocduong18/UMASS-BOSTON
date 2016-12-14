<%--<%@ Page Language="C#" MasterPageFile="Layout.Master" AutoEventWireup="true" CodeBehind="Search.aspx.cs" Inherits="Microsoft.Dynamics.Nav.WebHelp.Search" %>--%>
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Search.aspx.cs" Inherits="Microsoft.Dynamics.Nav.WebHelp.Search" %>
<%@ Import Namespace="Microsoft.Dynamics.Nav.WebHelp" %>

<%--<asp:Content ID="SearchResultContent" runat="server" ContentPlaceHolderID="HelpContentPlaceHolder">--%>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Search results</title>
    <link href="/css/msdnTheme.css" rel="stylesheet" type="text/css" />
    <base target="_parent"/>
</head>
    <body>
        <div>
            <div id="ResultsMessageDiv">
                <span class="ResultMessage">
                    <asp:Literal ID="ResultMessage" runat="server" Text="Test"/>
                 </span>
            </div>
            <asp:Repeater Id="Repeater" runat="server">
                <ItemTemplate>
                    <div class="SearchResult">
                        <div class="result">
                            <a id="A1" 
                                class="resultTitleLink" 
                                href="/main.aspx?lang=<%#Context.Request.QueryString["lang"]%>&content=<%#((SearchResult)Container.DataItem).File %>"><%#((SearchResult)Container.DataItem).Title%>
                            </a>
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>    
        </div>
     </body>
 </html>

<%--</asp:Content>--%>