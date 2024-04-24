<%option explicit%>
<%server.scripttimeout=10*60 '10minutes%>
<!--#include file="modFunctions.inc" -->
<html>
<head>
<script>
function downloadCSV(tbl,filename)
{
	//loop through table rows & cols
	var obj = document.getElementById(tbl);
	var row;
	var col;
	var csv='';
	for (var i = 0; row = obj.rows[i]; i++)
	{
	   //iterate through rows
	   //rows would be accessed using the "row" variable assigned in the for loop
	   for (var j = 0; col = row.cells[j]; j++)
	   {
	     //iterate through columns
	     //columns would be accessed using the "col" variable assigned in the for loop
	     var str = col.innerText;
	     str = str.replace("#", encodeURIComponent("#"));
	     csv+='"'+str+'";';
	   }
	   csv+='\n';
	}
	filename = filename;
	if (!csv.match(/^data:text\/csv/i))
	{
	csv = 'data:text/csv;charset=utf-8,' + encodeURI('\uFEFF'+csv); //force the file to be UTF8
	}
	var data = csv;
	var link = document.createElement('a');
	link.setAttribute('href', data);
	link.setAttribute('download', filename);
	document.body.appendChild(link); //needed for FF
	link.click();
}
</script>
</head>
<body style='font-family:verdana;font-size:8pt;'>
<%
Dim tmp
Dim tmp2
Dim url
dim id
dim prj
'dim arr
dim issuetype
dim event_
dim sum_
dim desc_
dim i
dim j

dim days
dim tot_days
dim vali
dim invali

dim arr
dim a
dim arr2
dim a2
dim arrP
dim aP

dim xml
dim objXML
set objXML = createobject("MSXML.DOMDocument")
Dim item_
Dim field_in_item_
dim nodelist

dim label
dim hist_
dim comp
dim bln
dim bln2

dim duedate
dim target_duedate
dim sprint
dim sprintenddate

dim yearmonth
yearmonth = request.querystring("yearmonth")
dim settodone

dim fso
dim f

arrP = split("STSPES,STSCNT,MOEBIUS,RES", ",")
'arr = split("STSPES", ",")
'arr = split("STSCNT,STSPES", ",")
arrP = split(request.querystring("project"), ",")
'response.write request.querystring("project") & "<br>"
'response.write ubound(arr) & "<br>"

dim dt
dim from_
dim to_

yearmonth = request.querystring("yearmonth")
if (yearmonth = "") then yearmonth = right("0000" & year(date),4) & right("00" & Month(date),2)

response.write "<b>In progress throughput</b><br>"
response.write "<table style='font-family:verdana;font-size:8pt;border-collapse:collapse;' border='1' id='table'>"
response.write "<tr>"
response.write "<td>" & "segment" & "</td>"
response.write "<td>" & "pkey" & "-" & "issuenum" & "</td>"
response.write "<td>" & "issuetype" & "</td>"
response.write "<td>" & "component" & "</td>"
response.write "<td>" & "summary" & "</td>"
response.write "<td>" & "state"   & "</td>"
response.write "<td>" & "resolution"   & "</td>"
response.write "<td>" & "created"   & "</td>"
response.write "<td>" & "updated"   & "</td>"
response.write "<td>" & "resolutiondate"   & "</td>"
response.write "<td>" & "state change overview"   & "</td>"
response.write "<td>" & "date no more in backlog/to do/open" & "</td>"
response.write "<td>" & "date set to done" & "</td>"
response.write "<td>" & "date set to cancelled" & "</td>"
response.write "<td>" & "item duedate"   & "</td>"
response.write "<td>" & "item target duedate"   & "</td>"
response.write "<td>" & "duedate via linked sprint(s)"   & "</td>"
response.write "</tr>"

dt = dateserial(mid(yearmonth,1,4), mid(yearmonth,5,2), 1)
'format into 2018/06/30
from_ = right("0000" & year(dt),4) & "/" & right("00" & month(dt),2) & "/" & right("00" & day(dt),2)
dt = dateadd("m", 1, dt)
dt = dateadd("d", -1, dt)
to_ = right("0000" & year(dt),4) & "/" & right("00" & month(dt),2) & "/" & right("00" & day(dt),2)

dim jql
jql = ""
jql = jql & " project = ""STS"" "
'jql = jql & " AND issuetype in (""Activity - Archive Validation"", ""Activity - Feasibility"", ""Activity - Manual Production"", ""Activity - Other"", ""Activity - Quality Analysis"", ""Activity - SQR Measurement"", ""Activity - Source Acquisition"", ""Activity - Source Acquisition - Field"", ""Activity - Source Analysis"", ""Activity - Source Preparation"")"
'jql = jql & " AND ""Assigned Unit"" in (""SO MOMA"",""SO SSO"",""SO APA"",""SO AME"",""SO PMO"",""SO GDT"",""SO EAP"", ""SO ECA"", ""SO SAMEA"",""SO EECA"", ""SO AFR"", ""SO WCE"", ""SO STS"", ""SO SAM"", ""SO PDV"", ""SO OCE"", ""SO NEA"", ""SO NAM"", ""SO LAM"")"
jql = jql & " AND not ((status = Done and resolution = Cancelled) or (status = cancelled)) "
'jql = jql & " AND  (resolution != Cancelled or status != cancelled) "
jql = jql & " AND ("
jql = jql & " status changed to ""done"" during (""" & from_ & """, """ & to_ & """)"
'jql = jql & " OR status changed to ""closed"" during (""" & from_ & """"", """ & to_ & """)"
'jql = jql & " OR status changed to ""planned"" during (""" & from_ & """"", """ & to_ & """)"
jql = jql & " )"

'response.write jql
'response.end

xml = getJiraItems(jql)
'response.write xml

	objXML.LoadXML xml

	xml = ""
	xml = xml & "<item_result>" & vbcrlf
	'now rebuild the XML using addiotnal filters
	Set nodelist = objXML.getElementsByTagName("item_result/*")
	i = 1
	For Each item_ In nodelist
		bln = true
		For Each field_in_item_ In item_.ChildNodes
			'check if correct issuetype
			if field_in_item_.BaseName = "issuetype" then
			if instr("||Epic||Initiative||", "||" & field_in_item_.Text & "||") > 0 then
				bln = false
			end if
			end if
			'check if correct components
			if field_in_item_.BaseName = "components" then
			arr = split(field_in_item_.Text, "||")
			for a = lbound(arr) to ubound(arr)
			if arr(a) <> "" then
				if instr(lcase("||Innovation platforms||STS Support||SO Regions||Events organization||Hosting Sharepoint sites||R&D||STS internal processes||STS Newsletter||TD platform||"),lcase("||" & arr(a) & "||")) > 0 then
					bln = false
				end if
			end if
			next
			end if
			if false then 'this condition is done by getJiraItems.aspx
			'check if done in this month
			if field_in_item_.BaseName = "transitions_history" then
			    bln2 = False
			    arr = Split(field_in_item_.Text, "@@")
			    For a = LBound(arr) To UBound(arr)
			    If arr(a) <> "" Then
				arr2 = Split(arr(a), "||")
				'For a2 = LBound(arr2) To UBound(arr2)
				'If arr2(a2) <> "" Then
				    If arr2(2) = "Done" Then
				    If Mid(arr2(0), 1, 6) = yearmonth Then
					bln2 = True
				    End If
				    End If
				'End If
				'Next
			    End If
			    Next
			    If bln2 = True Then ' it is set to done in this month
				'do nothing
			    Else
				'not a good item
				bln = False
			    End If
			end if
			end if 'set to done in this month
		Next
		if bln = true then
		xml = xml & "<item>" & vbcrlf
		For Each field_in_item_ In item_.ChildNodes
			xml = xml & "<" & field_in_item_.BaseName & ">" & xmlsafe("" & field_in_item_.Text) & "</" & field_in_item_.BaseName & ">" & vbcrlf
		Next
		xml = xml & "</item>" & vbcrlf
		end if

		i = i + 1
	Next
	xml = xml & "</item_result>" & vbcrlf
	'response.write (replace(xml, "<" , "["))
	objXML.LoadXML xml

	'ok now we have a good set of xml to go with
	i = 0
	j = 0

	Set nodelist = objXML.getElementsByTagName("item_result/*")
	For Each item_ In nodelist
		bln = true
		if bln = true then
			'tmp = countInProgress(getFieldValue(item_,"created"), getFieldValue(item_,"transitions_history"))
			'j = j + tmp
			response.write "<tr>"
			response.write "<td>" & "STS" & "</td>"
			response.write "<td>" & getFieldValue(item_,"key") & "</td>"
			response.write "<td>" & getFieldValue(item_,"issuetype") & "</td>"
			response.write "<td>" & getFieldValue(item_,"components") & "</td>"
			response.write "<td>" & getFieldValue(item_,"summary") & "</td>"
			response.write "<td>" & getFieldValue(item_,"status") & "</td>"
			response.write "<td>" & getFieldValue(item_,"resolution") & "</td>"
			'response.write "<td>" & getFieldValue(item_,"components") & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"created")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"updated")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"resolutiondate")) & "</td>"
			response.write "<td>" & replace(getFieldValue(item_,"transitions_history"), "@@", "<br>") & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getNoMoreBacklog(getFieldValue(item_,"transitions_history"))) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getSettoDone(getFieldValue(item_,"transitions_history"))) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getSettoCancelled(getFieldValue(item_,"transitions_history"))) & "</td>"
			'response.write "<td>" & "" & "</td>" 'validation tracking to in validation occurences
			'response.write "<td>" & "" & "</td>" 'in validation to anything but done/Validation Tracking occurences
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"duedate")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"target_duedate")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"sprintcompletedate")) & "</td>"
			'response.write "<td>" & tmp & "</td>"

			'For Each field_in_item_ In item_.ChildNodes
			'response.write "<td>" & field_in_item_.text & "</td>"
			'next
			response.write "</tr>"
			i = i + 1
		end if
	next

'14JUN2019 - disable MOEBIUS (mail Mireille)
if false then

'RUN MOEBIUS HERE

jql = ""
jql = jql & " project = ""MOEBIUS"" "
'jql = jql & " AND issuetype in (""Activity - Archive Validation"", ""Activity - Feasibility"", ""Activity - Manual Production"", ""Activity - Other"", ""Activity - Quality Analysis"", ""Activity - SQR Measurement"", ""Activity - Source Acquisition"", ""Activity - Source Acquisition - Field"", ""Activity - Source Analysis"", ""Activity - Source Preparation"")"
'jql = jql & " AND ""Assigned Unit"" in (""SO MOMA"",""SO SSO"",""SO APA"",""SO AME"",""SO PMO"",""SO GDT"",""SO EAP"", ""SO ECA"", ""SO SAMEA"",""SO EECA"", ""SO AFR"", ""SO WCE"", ""SO STS"", ""SO SAM"", ""SO PDV"", ""SO OCE"", ""SO NEA"", ""SO NAM"", ""SO LAM"")"
jql = jql & " AND not ((status = Done and resolution = Cancelled) or (status = cancelled)) "
jql = jql & " AND ("
jql = jql & " status changed to ""done"" during (""" & from_ & """, """ & to_ & """)"
'jql = jql & " OR status changed to ""closed"" during (""" & from_ & """"", """ & to_ & """)"
'jql = jql & " OR status changed to ""planned"" during (""" & from_ & """"", """ & to_ & """)"
jql = jql & " )"

'response.write jql
'response.end

xml = getJiraItemsMoebius(jql)
	objXML.LoadXML xml

	xml = ""
	xml = xml & "<item_result>" & vbcrlf
	'now rebuild the XML using addiotnal filters
	Set nodelist = objXML.getElementsByTagName("item_result/*")
	i = 1
	For Each item_ In nodelist
		bln = true
		For Each field_in_item_ In item_.ChildNodes
			'check if correct labels (exclude entries with label incident
			if field_in_item_.BaseName = "labels" then
			arr = split(field_in_item_.Text, "||")
			for a = lbound(arr) to ubound(arr)
			if arr(a) <> "" then
				if instr(lcase("||incident||"),lcase("||" & arr(a) & "||")) > 0 then
					bln = false
				end if
			end if
			next
			end if
		Next
		if bln = true then
		xml = xml & "<item>" & vbcrlf
		For Each field_in_item_ In item_.ChildNodes
			xml = xml & "<" & field_in_item_.BaseName & ">" & xmlsafe("" & field_in_item_.Text) & "</" & field_in_item_.BaseName & ">" & vbcrlf
		Next
		xml = xml & "</item>" & vbcrlf
		end if

		i = i + 1
	Next
	xml = xml & "</item_result>" & vbcrlf
	'response.write (replace(xml, "<" , "["))
	objXML.LoadXML xml

	'ok now we have a good set of xml to go with
	i = 0
	j = 0

	Set nodelist = objXML.getElementsByTagName("item_result/*")
	For Each item_ In nodelist
		bln = true
		if bln = true then
			'tmp = countInProgress(getFieldValue(item_,"created"), getFieldValue(item_,"transitions_history"))
			'j = j + tmp
			response.write "<tr>"
			response.write "<td>" & "SSO" & "</td>"
			response.write "<td>" & getFieldValue(item_,"key") & "</td>"
			response.write "<td>" & getFieldValue(item_,"issuetype") & "</td>"
			response.write "<td>" & getFieldValue(item_,"labels") & "</td>"
			response.write "<td>" & getFieldValue(item_,"summary") & "</td>"
			response.write "<td>" & getFieldValue(item_,"status") & "</td>"
			response.write "<td>" & getFieldValue(item_,"resolution") & "</td>"
			'response.write "<td>" & getFieldValue(item_,"components") & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"created")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"updated")) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"resolutiondate")) & "</td>"
			response.write "<td>" & replace(getFieldValue(item_,"transitions_history"), "@@", "<br>") & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getNoMoreBacklogMoebius(getFieldValue(item_,"transitions_history"))) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getSettoDoneMoebius(getFieldValue(item_,"transitions_history"))) & "</td>"
			response.write "<td>" & toDD_MM_YYYY(getSettoCancelledMoebius(getFieldValue(item_,"transitions_history"))) & "</td>"
			'response.write "<td>" & "" & "</td>" 'validation tracking to in validation occurences
			'response.write "<td>" & "" & "</td>" 'in validation to anything but done/Validation Tracking occurences
			response.write "<td>" & toDD_MM_YYYY(getFieldValue(item_,"duedate")) & "</td>"
			'response.write "<td>" & tmp & "</td>"
			response.write "<td>" & "" & "</td>" 'target duedate : N/A for MOEBIUS
			response.write "<td>" & "" & "</td>" 'duedate via sprint : N/A for MOEBIUS

			'For Each field_in_item_ In item_.ChildNodes
			'response.write "<td>" & field_in_item_.text & "</td>"
			'next
			response.write "</tr>"
			i = i + 1
		end if
	next
end if 'moebius = false

	response.write "</table>"
	response.write "<a href='#' onclick='downloadCSV(""table"",""output.csv"");'>CSV</a><br>"

'end if 'prj loop
'next 'prj loop

'response.write tmp
%>
</body>
</html>
<%




function getSettoDone(allstates)
getSettoDone = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(2) = "Done" then
	getSettoDone = arr2(0)
	end if
end if
next
if getSettoDone = "00000000" then getSettoDone = ""
end function

function getSettoCancelled(allstates)
getSettoCancelled = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(2) = "Cancelled" then
	getSettoCancelled = arr2(0)
	end if
end if
next
if getSettoCancelled = "00000000" then getSettoCancelled = ""
end function

function getStarted(allstates)
getStarted = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Backlog" then
	getStarted = arr2(0)
	end if
end if
next
if getStarted = "00000000" then getStarted = ""
end function

function getNoMoreBacklog(allstates) 'function returns the date the item was no more on the backlog
getNoMoreBacklog = "00000000"
dim arr
dim arr2
dim a

'date||fromstate||tostate
'arr2(0)||arr2(1)||arr2(2)

'from 'backlog' to any state
arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Backlog" then
	getNoMoreBacklog = arr2(0)
	end if
end if
next
if getNoMoreBacklog = "00000000" then
	'depending on the issuetype we need to look further
	'from 'to do' to any state
	for a = lbound(arr) to ubound(arr)
	if arr(a) <> "" then
		arr2 = split(arr(a), "||")
		if arr2(1) = "To Do" then
		getNoMoreBacklog = arr2(0)
		end if
	end if
	next
end if
if getNoMoreBacklog = "00000000" then
	'depending on the issuetype we need to look further
	'from 'Open' to any state
	for a = lbound(arr) to ubound(arr)
	if arr(a) <> "" then
		arr2 = split(arr(a), "||")
		if arr2(1) = "Open" then
		getNoMoreBacklog = arr2(0)
		end if
	end if
	next
end if
if getNoMoreBacklog = "00000000" then getNoMoreBacklog = ""
end function

function donethismonth(allstates, ym)
donethismonth = false
'allstates = date||from||to@@...
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	'response.write ym & " - " & arr2(0) & "-" & arr2(1) & "-" & arr2(2) & "-" & "<br>"
	if arr2(2) = "Done" then
	if mid(arr2(0), 1, 6) = ym then
		donethismonth = true
	end if
	end if
end if
next
end function

Function getJiraItems(jql)
'response.write "https://soreporting.azurewebsites.net/src_reporting/getJiraitems.aspx?project=" & project & "&yearmonth=" & yearmonth & "&rnd=" & rnd & ""
randomize timer
'On Error Resume Next
Dim xmlhttp
Set xmlhttp = CreateObject("MSXML2.XMLHTTP")
xmlhttp.Open "GET", "https://soreporting.azurewebsites.net/src_reporting/getJiraitems.aspx?jql=" & jql & "&rnd=" & rnd & "", False
xmlhttp.send
getJiraItems = xmlhttp.responseText
Set xmlhttp = Nothing
End Function

Function getJiraItemsMoebius(jql)
'response.write "https://soreporting.azurewebsites.net/src_reporting/getJiraitemsMoebius.aspx?project=" & project & "&yearmonth=" & yearmonth & "&rnd=" & rnd & ""
randomize timer
'On Error Resume Next
Dim xmlhttp
Set xmlhttp = CreateObject("MSXML2.XMLHTTP")
xmlhttp.Open "GET", "https://soreporting.azurewebsites.net/src_reporting/getJiraitemsMoebius.aspx?jql=" & jql & "&rnd=" & rnd & "", False
xmlhttp.send
getJiraItemsMoebius = xmlhttp.responseText
Set xmlhttp = Nothing
End Function


function itemRejected(allstates)
'in = 20180226||Open||Breakdown@@20180226||Breakdown||Breakdown Done@@20180302||Breakdown Done||Development@@20180302||Development||Development Done@@20180305||Development Done||Validation@@20180305||Validation||Done
dim arr
dim arr2
dim a
itemRejected = false
arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Validation" and arr2(2) <> "Done" then
	itemRejected = true
	end if
end if
next
end function

Function CountinProgress(created, allstates)
'loop through all transitions, if an item is 'in progress (all but Done, Cancelled, Backlog)' then count the # of days
Dim arr
Dim arr2
Dim a
Dim dt
Dim prevdate

'allstates = created & "||" & "<new>" & "||" & "Open" & "@@"
CountinProgress = 0
arr = Split(allstates, "@@")
prevdate = DateSerial(Mid(created, 1, 4), Mid(created, 5, 2), Mid(created, 7, 2))
For a = LBound(arr) To UBound(arr)
If arr(a) <> "" Then
    arr2 = Split(arr(a), "||")
    'did we move to an not in progres state?
    If arr2(2) <> "Done" And arr2(2) <> "Cancelled" And arr2(2) <> "Backlog" Then
        dt = DateSerial(Mid(arr2(0), 1, 4), Mid(arr2(0), 5, 2), Mid(arr2(0), 7, 2))
        CountinProgress = CountinProgress + DateDiff("d", prevdate, dt)
    End If
    prevdate = DateSerial(Mid(arr2(0), 1, 4), Mid(arr2(0), 5, 2), Mid(arr2(0), 7, 2))
    'If a = LBound(arr) Then dt1 = DateSerial(Mid(arr2(0), 1, 4), Mid(arr2(0), 5, 2), Mid(arr2(0), 7, 2))
    'If a = UBound(arr) - 1 Then dt2 = DateSerial(Mid(arr2(0), 1, 4), Mid(arr2(0), 5, 2), Mid(arr2(0), 7, 2))
    'End If

End If
Next
'CountinProgress = DateDiff("d", dt1, dt2)
'If CountinProgress = 0 Then CountinProgress = 1
End Function



function getSettoDoneMoebius(allstates)
getSettoDoneMoebius = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(2) = "Done" then
	getSettoDoneMoebius = arr2(0)
	end if
end if
next
if getSettoDoneMoebius = "00000000" then getSettoDoneMoebius = ""
end function

function getSettoCancelledMoebius(allstates)
getSettoCancelledMoebius = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(2) = "Cancelled" then
	getSettoCancelledMoebius = arr2(0)
	end if
end if
next
if getSettoCancelledMoebius = "00000000" then getSettoCancelledMoebius = ""
end function

function getStartedMoebius(allstates)
getStartedMoebius = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Backlog" then
	getStartedMoebius = arr2(0)
	end if
end if
next
if getStartedMoebius = "00000000" then getStartedMoebius = ""
end function

function getNoMoreBacklogMoebius(allstates)
getNoMoreBacklogMoebius = "00000000"
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Open Backlog" then
	getNoMoreBacklogMoebius = arr2(0)
	end if
end if
next
if false then
	if getNoMoreBacklogMoebius = "00000000" then
		'depending on the issuetype we need to look further
		for a = lbound(arr) to ubound(arr)
		if arr(a) <> "" then
			arr2 = split(arr(a), "||")
			if arr2(1) = "To Do" then
			getNoMoreBacklogMoebius = arr2(0)
			end if
		end if
		next
	end if
	if getNoMoreBacklogMoebius = "00000000" then
		'depending on the issuetype we need to look further
		for a = lbound(arr) to ubound(arr)
		if arr(a) <> "" then
			arr2 = split(arr(a), "||")
			if arr2(1) = "Open" then
			getNoMoreBacklogMoebius = arr2(0)
			end if
		end if
		next
	end if
end if
if getNoMoreBacklogMoebius = "00000000" then getNoMoreBacklogMoebius = ""
end function

function donethismonthMoebius(allstates, ym)
donethismonthMoebius = false
'allstates = date||from||to@@...
dim arr
dim arr2
dim a

arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	'response.write ym & " - " & arr2(0) & "-" & arr2(1) & "-" & arr2(2) & "-" & "<br>"
	if arr2(2) = "Done" then
	if mid(arr2(0), 1, 6) = ym then
		donethismonthMoebius = true
	end if
	end if
end if
next
end function

function itemRejectedMoebius(allstates)
'in = 20180226||Open||Breakdown@@20180226||Breakdown||Breakdown Done@@20180302||Breakdown Done||Development@@20180302||Development||Development Done@@20180305||Development Done||Validation@@20180305||Validation||Done
dim arr
dim arr2
dim a
itemRejectedMoebius = false
arr = split(allstates, "@@")
for a = lbound(arr) to ubound(arr)
if arr(a) <> "" then
	arr2 = split(arr(a), "||")
	if arr2(1) = "Validation" and arr2(2) <> "Done" then
	itemRejectedMoebius = true
	end if
end if
next
end function


%>