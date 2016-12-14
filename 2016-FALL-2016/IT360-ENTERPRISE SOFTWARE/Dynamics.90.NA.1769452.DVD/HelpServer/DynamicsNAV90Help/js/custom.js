function iframeLoaded() {
    injectCssInIFrame();
    resizeHelpContentIFrame();
    patchContentLinks();
}

function patchContentLinks() {
    var frameContents = $("#mainContentIFrame").contents();
    var elements = $("a", frameContents);


    var regex = new RegExp("(\./)?[a-zA-Z0-9_]+\\.htm");
    var filteredElements = elements.filter(function () {
        var href = $(this).attr("href");
        return regex.test(href) && !(href.toLowerCase().indexOf("http") === 0);
    });

    var lang = getLanguage();
    filteredElements.each(function () {
        if ($(this).attr("href").indexOf("/main.aspx?lang=") == 0) {
            return;
        }

        var href = $(this).attr("href").replace("./", "");
        var newUrl = "/main.aspx?lang=" + lang + "&content=" + href;
        $(this).attr("href", newUrl);
        $(this).attr("target", "_parent");
    });

    var externalLinks = elements.filter(function() {
        var href = $(this).attr("href");
        return href.toLowerCase().indexOf("http") === 0;
    });

    externalLinks.each(function() {
        $(this).attr("target", "_externalContent");
    });
}

function getLanguage() {
    return getUrlVars()["lang"];
}

function getUrlVars() {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for (var i = 0; i < hashes.length; i++) {
        hash = hashes[i].split('=');
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
    }
    return vars;
}
function resizeHelpContentIFrame() {
    var iFrame = $("#mainContentIFrame");

    var newHeight = iFrame[0].contentWindow.document.body.scrollHeight;
    var newWidth = iFrame[0].contentWindow.document.body.scrollWidth;
    iFrame.contents().find("body").css("margin-left", "0px");
    iFrame.height(newHeight);
    iFrame.width(newWidth);
}

function injectCssInIFrame() {
    var iFrameHead = $("#mainContentIFrame").contents().find("head");
    iFrameHead.append(
    $('<link/>', { href: '/css/injected.css', rel: 'stylesheet' }));
}

function init() {
    $(".TocLeftPane").resizable({ handles: "e" });
    $("#mainContentIFrame").ready(iframeLoaded);
}