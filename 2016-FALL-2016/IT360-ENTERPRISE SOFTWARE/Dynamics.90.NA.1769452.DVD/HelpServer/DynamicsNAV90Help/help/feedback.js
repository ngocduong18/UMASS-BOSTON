// Microsoft Dynamics NAV Documentation Feedback Script

var sProduct = 'Microsoft Dynamics NAV';
var sVersion = '2016';
// var sClassicFolderName = '\\Classic\\' //Set to parent folder containing the CSide docs
var privacyStatementURL = 'http://go.microsoft.com/fwlink/?LinkID=617571';

// *****Start: Partner Section************************
var sPartner = "MSFT";//change to your company name
var sRecipient = "mailto:nav-olh@microsoft.com";//append your company's email address. Please leave the Microsoft address as well.
// ******End: Partner Section***********************

// *****Start: Localization Section************************
//---Note to localization: Do not change <A> and </A> tags.---

var L_fbLocale_Text = getLocaleText(); //This is the locale of the content; use the short string values at http://msdn2.microsoft.com/en-us/library/0h88fahh.aspx
var L_fbLink_Text = 'Documentation Feedback';//--- This is the link text appearing at the bottom of each topic ---

//--- This is the text appearing in the feedback window ---
var L_fbTitle_Text = 'Documentation Feedback';
var L_fbParagraph_Text = "Was this information helpful?";
var L_fbValue1_Text = "Yes, this information was helpful.";
var L_fbValue2_Text = "This Help topic contains a technical error.";
var L_fbValue3_Text = "I could not find what I was looking for.";
var L_fbValue4_Text = "The language or terminology was incorrect.";
var L_fbEnterFeedbackHere_Text = 'To submit your feedback,'; //The text: Click here will be appended here!
var L_fbViewPrivacyStatement_Text = 'To see how your personal information will be used, see <a href="' + privacyStatementURL + '" target="_blank">Microsoft Dynamics NAV ' + sVersion + ' Privacy Statement</a>.';
var L_fbCancel_Text = 'Cancel';


//--- This is the text appearing in the feedback email body ---
var L_fbTypeHere_Text = 'Microsoft Dynamics NAV ' + sVersion + ' Privacy Statement ' + encodeURIComponent(privacyStatementURL);

var L_fbSubmit_Text = 'click here';//This text is appended to "To add comments and send an email message with your feedback" above

//--- This text is appended to the text in the feedback email body, which depends on users selection ---
	var L_fbQuestion1_Text = "";
	var L_fbQuestion2_Text = "";
	var L_fbQuestion3_Text = "";
	var L_fbQuestionDefault_Text = "";

// ******End: Localization Section***********************


function FeedBackLink()
{
document.write('<b><a href="javascript:ShowFeedback()">' +L_fbLink_Text + '</a></b><br />');
}


function EMailStream(obj)
{
var stream;

stream = '<DIV ID="feedbackarea">'
	+ '<b>' + L_fbTitle_Text + '</b><br /><br />'
	+ '<P>' + L_fbParagraph_Text + '</P>'
	+ '<FORM METHOD="post" ENCTYPE="text/plain" NAME="formRating">'
	+ '<P><\P>'
	+ '<INPUT TYPE="radio" value="1" NAME="fbRating">' + L_fbValue1_Text + '<BR>'
	+ '<INPUT TYPE="radio" value="2" NAME="fbRating">' + L_fbValue2_Text + '<BR>'
	+ '<INPUT TYPE="radio" value="3" NAME="fbRating">' + L_fbValue3_Text + '<BR>'
	+ '<INPUT TYPE="radio" value="4" NAME="fbRating">' + L_fbValue4_Text + '<BR>'
	+ '</FORM>'
	+ '<P>' + L_fbViewPrivacyStatement_Text + '</P>'
	+ '<P>' + L_fbEnterFeedbackHere_Text + '&nbsp;'
	+ '<SPAN ONCLICK="feedbackarea.style.display=\'none\';document.getElementById(\'fbb\').style.display=\'block\';' + obj.id + '.innerHTML=\'\'">'+ submitFeedback() + '</SPAN></P>'
	+ '<P STYLE="width:100%;position:relative;float:left;clear:left;margin-bottom:-0.7em;margin-top:0em;" align=left><A HREF="#Feedback" ONCLICK=fbReload()>' + L_fbCancel_Text
	+ '</A>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</P>'
	+ '<br><br>'
	+ '<hr>'
	+ '</div>';

obj.innerHTML = stream;

// Scroll to the bottom, after a delay
window.setTimeout('scrollToBottom()',50);

}

function ShowFeedback()
{EMailStream(fb);document.getElementById('fbb').style.display='none';};

function submitFeedback()
{

  var sTitle = ParseTitle(document.title);
  var sHTM = ParseFileName(window.location.href);

  var sSubject =  '[' + sProduct + '] ' + '[' + sVersion + '] ' + '[' + L_fbLocale_Text + '] ' + '[' + sPartner + '] ' + 
  	  '[' + sHTM + '] ' + '[' + sTitle + '] ' + '[' + '\' + GetRating() + \'' + '-Class]';

  var sEntireMailMessage = sRecipient + '?subject=' + sSubject
	+ '&body=' + L_fbTypeHere_Text + '\' + GetQuestion() + \'';
  
  var sHREF = '<A HREF=\"' + sRecipient + '" ONCLICK=\"this.href=\''
	+ sEntireMailMessage + '\';\">'+L_fbSubmit_Text+'</A>' + '.';
  
  return sHREF;
}

//---Parses document title.---
function ParseTitle(theTitle)
{
	theTitle = theTitle.replace(/\"/g,"--");
  	theTitle = theTitle.replace(/'/g,"-");
	if (theTitle == "") {theTitle = "Documentation Feedback";}
	if (theTitle.length > 60) {theTitle = theTitle.slice(0,57) + "...";}
	return theTitle;
}

//---Parses document filename.---
function ParseFileName(Filename)
{
  	var intPos = Filename.lastIndexOf("\\");
  	var intLen = Filename.length;
  	var newFileName = Filename.substr(intPos + 1, intLen  - intPos);
  	
  	// Look for the last forward slash, and any pound symbol
  	var x = newFileName.lastIndexOf("/") + 1;
  	var y = newFileName.lastIndexOf("#");
  	
  	if(y == (-1))
  	{
  		// There is no pound symbol (#)
  		newFileName = newFileName.slice(x);
  	}
  	else
  	{
  		newFileName = newFileName.slice(x,y);
  	}
  	
  	return(newFileName);
}

function GetRating()
{
    sRating = "0";
	for(var x = 0;x < 3;x++)
  	{
      		if(document.formRating.fbRating[x].checked) { sRating = x + 1;}
  	}
	return sRating;
}

function GetQuestion()
{
	var rating = GetRating();
	var question;

	if(rating == "1")
	{
		question = L_fbQuestion1_Text;
	}
	else if(rating == "2")
	{
		question = L_fbQuestion2_Text;
	}
	else if(rating == "3")
	{
		question = L_fbQuestion3_Text;
	}
	else
	{
		question = L_fbQuestionDefault_Text;
	}

	return question;
}

//---Reloads window.---
function fbReload()
{
	window.location.reload(true);
}

//---Scrolls to the bottom of the window.---
function scrollToBottom()
{
	window.scrollBy(0,20000);
}

function getLocaleText() {
    var urlParts = window.location.href.split('/');
    var localeTextIndex = urlParts.indexOf('help') + 1;
    var localeText = urlParts[localeTextIndex];

    if (localeText) {
        return localeText === "en" ? "W1" : localeText;
    } else {
        return "W1";
    }
}