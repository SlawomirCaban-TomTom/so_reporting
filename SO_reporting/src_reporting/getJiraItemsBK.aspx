<%@ Page Language="VB" Explicit="True" Debug="true"%>

<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Web.Services" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.OleDb" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data.Linq" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="DocumentFormat.OpenXml" %>
<%@ Import Namespace="DocumentFormat.OpenXml.Packaging" %>
<%@ Import Namespace="DocumentFormat.OpenXml.Spreadsheet" %>
<%@ Import Namespace="DocumentFormat.OpenXml.Wordprocessing" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>

<script language=vb runat=server>
Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs)
System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12

Dim webClient As New System.Net.WebClient
'webClient.Headers.Add("Content-Type", "application/x-www-form-urlencoded")
webClient.Headers.Add("Content-Type", "application/json; charset=utf-8")
'webClient.Headers.Add("Authorization", "Basic " & "c3ZjX3N0c19qaXJhX3VzZXI6RjIzcnQjNDV0eSM0")
webClient.Headers.Add("Authorization", "Bearer " & "NjEwNTg3NTc5NjU0Ot6RDMksA3OJYGutuCZaMVZs6e1i")
Dim result As String 
'result = webClient.DownloadString("https://soreporting.azurewebsites.net/getsuppipeitem.asp?id=1")
Dim url As String
dim prj as string

dim jql as String
jql = request.querystring("jql")
'if jql = "" then jql = "project=""STS"""
if jql = "" then jql = "issuekey=""STS-714"""

'	jql = ""
'	jql = jql & " project = ""STS"" "
'	'jql = jql & " AND issuetype in (""Activity - Archive Validation"", ""Activity - Feasibility"", ""Activity - Manual Production"", ""Activity - Other"", ""Activity - Quality Analysis"", ""Activity - SQR Measurement"", ""Activity - Source Acquisition"", ""Activity - Source Acquisition - Field"", ""Activity - Source Analysis"", ""Activity - Source Preparation"")"
'	'jql = jql & " AND ""Assigned Unit"" in (""SO EECA"", ""SO AFR"", ""SO WCE"", ""SO STS"", ""SO SAM"", ""SO PDV"", ""SO OCE"", ""SO NEA"", ""SO NAM"", ""SO LAM"")"
'	jql = jql & " AND ("
'	jql = jql & " status changed to done during (""" & from_ & """, """ & to_ & """)"
'	'jql = jql & " OR status changed to closed during (""" & from_ & """"", """ & to_ & """)"
'	'jql = jql & " OR status changed to planned during (""" & from_ & """"", """ & to_ & """)"
'	jql = jql & " )"

'url = "https://jira.tomtomgroup.com/rest/api/2/search?jql=project=""" & prj & """ and component=""RSO Global Alignment""&fields=summary,issuetype,status,created,updated,duedate,resolutiondate,customfield_11860,fixVersions,components,customfield_19662&maxResults=-1"
'url = "https://jira.tomtomgroup.com/rest/api/2/search?jql=project=""" & prj & """&fields=summary,issuetype,status,created,updated,duedate,resolutiondate,customfield_11860,fixVersions,components,customfield_19662&maxResults=-1"
url = "https://jira.tomtomgroup.com/rest/api/2/search?jql=" & Server.UrlEncode(jql) & "&fields=summary,issuetype,status,created,updated,duedate,resolutiondate,customfield_11860,fixVersions,components,customfield_19662&maxResults=-1"
'response.write (url)

result = webClient.DownloadString(url)
dim tmp as string
dim arr
dim a
'response.Write (now)

'response.write (result)
'responsE.end

Dim MySerializer As JavaScriptSerializer = New JavaScriptSerializer()
MySerializer.MaxJsonLength = 86753090
Dim parentJson As Dictionary(Of String, Object) = MySerializer.Deserialize(Of Dictionary(Of String, Object))(result)
'Dim issuesJson As Dictionary(Of String, Object) 

dim jira_key as string
dim xml as string
xml = ""
'xml = xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbcrlf
xml = xml & "<item_result>" & vbcrlf
For Each pair In parentJson
	if (pair.Key.tostring = "issues" ) then
		jira_key = ""
		'here we have a list of issues - issues is an arraylist
		For each issue in pair.value 
		xml = xml & "<item>"
		for each field_in_issue in issue
			if (field_in_issue.key.tostring = "key") then
				jira_key = field_in_issue.value.tostring
				xml = xml & "<key>" & jira_key & "</key>"
			end if

			if (field_in_issue.Key.tostring = "fields" ) then
				for each field in field_in_issue.value 'loop though the fields within ONE issue
					
					if (field.key.tostring = "summary") then
					if (field.value is nothing) then
						xml = xml & "<summary>" & "" & "</summary>" & vbcrlf
					else
						xml = xml & "<summary>" & xmlsafe("" & field.value.tostring) & "</summary>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "issuetype") then
					if (field.value is nothing) then
						xml = xml & "<issuetype>" & "" & "</issuetype>" & vbcrlf
					else
						'xml = xml & "<issuetype>" & xmlsafe("" & field.value.tostring) & "</issuetype>" & vbcrlf
						for each field_in_issuetype in field.value
						if (field_in_issuetype.key.tostring = "name") then
							xml = xml & "<issuetype>" & xmlsafe("" & field_in_issuetype.value.tostring) & "</issuetype>" & vbcrlf
						end if
						next
					end if
					end if

					if (field.key.tostring = "duedate") then
					if (field.value is nothing) then
						xml = xml & "<duedate>" & "" & "</duedate>" & vbcrlf
					else
						xml = xml & "<duedate>" & xmlsafe(toDD_MM_YYYY("" & field.value.tostring)) & "</duedate>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "customfield_19662") then
					if (field.value is nothing) then
						xml = xml & "<target_duedate>" & "" & "</target_duedate>" & vbcrlf
					else
						xml = xml & "<target_duedate>" & xmlsafe(toDD_MM_YYYY("" & field.value.tostring)) & "</target_duedate>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "status") then
					if (field.value is nothing) then
						xml = xml & "<status>" & "" & "</status>" & vbcrlf
					else
						'xml = xml & "<issuetype>" & xmlsafe("" & field.value.tostring) & "</issuetype>" & vbcrlf
						for each field_in_status in field.value
						if (field_in_status.key.tostring = "name") then
							xml = xml & "<status>" & xmlsafe("" & field_in_status.value.tostring) & "</status>" & vbcrlf
						end if
						next
					end if
					end if

					if (field.key.tostring = "created") then
					if (field.value is nothing) then
						xml = xml & "<created>" & "" & "</created>" & vbcrlf
					else
						xml = xml & "<created>" & xmlsafe(toDD_MM_YYYY("" & field.value.tostring)) & "</created>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "updated") then
					if (field.value is nothing) then
						xml = xml & "<updated>" & "" & "</updated>" & vbcrlf
					else
						xml = xml & "<updated>" & xmlsafe(toDD_MM_YYYY("" & field.value.tostring)) & "</updated>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "resolutiondate") then
					if (field.value is nothing) then
						xml = xml & "<resolutiondate>" & "" & "</resolutiondate>" & vbcrlf
					else
						xml = xml & "<resolutiondate>" & xmlsafe(toDD_MM_YYYY("" & field.value.tostring)) & "</resolutiondate>" & vbcrlf
					end if
					end if

					if (field.key.tostring = "components") then
					if (field.value is nothing) then
						xml = xml & "<components>" & "" & "</components>" & vbcrlf
					else
						tmp = "||"
						for each comp_item in field.value
						for each field_in_comp_item in comp_item
						if (field_in_comp_item.key.tostring = "name") then
							tmp = tmp & trim(field_in_comp_item.value.tostring) & "||"
						end if
						next
						next
						if tmp = "||" then tmp = ""
						xml = xml & "<components>" & xmlsafe(tmp) & "</components>" & vbcrlf
					end if
					end if
					
					'sprintinfo - customfield_11860
					'sprintenddate - take latest completeddate - customfield_11860
					if (field.key.tostring = "customfield_11860") then
					if (field.value is nothing) then
						xml = xml & "<sprintinfo>" & "" & "</sprintinfo>" & vbcrlf
						xml = xml & "<sprintcompletedate>" & "" & "</sprintcompletedate>" & vbcrlf

					else
						tmp = "||"
						for each sprintinfo_item in field.value
						'for each field_in_sprintinfo_item in sprintinfo_item
						'if (field_in_comp_item.key.tostring = "name") then
							tmp = tmp & trim(sprintinfo_item) & "||"
						'end if
						'next
						next
						if tmp = "||" then tmp = ""
						xml = xml & "<sprintinfo>" & xmlsafe(tmp) & "</sprintinfo>" & vbcrlf
						'xml = xml & "<sprintcompletedate>" & xmlsafe(toDD_MM_YYYY("" & getSprintLatestCompletedDate(tmp))) & "</sprintcompletedate>" & vbcrlf
						xml = xml & "<sprintcompletedate>" & xmlsafe(tmp) & "</sprintcompletedate>" & vbcrlf
					end if
					end if
				next 'loop through all the fields
				
				'history
				tmp = parseHist_(jira_key)
				if tmp = "" then
					xml = xml & "<transitions_history>" & "" & "</transitions_history>" & vbcrlf
				else
					xml = xml & "<transitions_history>" & tmp & "</transitions_history>" & vbcrlf
				end if
'					statedate = "00000000000000"
'					'look for the latest timestamp the item got the current state
'					arr = split(tmp, "@@")
'					for a = lbound(arr) to ubound(arr)
'					if arr(a) <> "" then
'						arr2 = split(arr(a), "||")
'						'Arr(a) = date||from||tostring
'						if arr2(2) = state_ then
'						if arr2(0) > statedate then
'							statedate = arr2(0)
'						end if
'						end if
'					end if
'					next
'					if statedate = "00000000000000" then statedate = ""
'					xml = xml & "<transitions_history>" & xmlsafe("" & statedate) & "</transitions_history>" & vbcrlf

			end if
		next
		xml = xml & "</item>"
		next
	end if	
Next

xml = xml & "</item_result>" & vbcrlf

Server.ScriptTimeout = 60*60
Response.ContentType = "text/xml"
Response.CharSet = "UTF-8"
response.write (xml)
'response.Write (now)
end sub

function getSprintLatestCompletedDate(s)
'multiple sprint may be attached, take the latest one
'IN : ["com.atlassian.greenhopper.service.sprint.Sprint@790ac54f[id=11467,rapidViewId=3248,state=CLOSED,name=SDP Sprint 1,startDate=2017-11-13T06:12:41.559Z,endDate=2017-11-27T06:12:00.000Z,completeDate=2017-11-29T09:20:45.503Z,sequence=11467]","com.atlassian.greenhopper.service.sprint.Sprint@728aac4a[id=12185,rapidViewId=3248,state=CLOSED,name=SDP Sprint 2,startDate=2018-02-12T12:02:27.361Z,endDate=2018-02-26T12:02:00.000Z,completeDate=2018-02-23T11:26:35.645Z,sequence=12185]"]
Dim arr
Dim arr2
Dim arr3
Dim a
Dim a2
Dim tmp
getSprintLatestCompletedDate = "00000000"
arr = Split(s, "||")
For a = LBound(arr) To UBound(arr)
If arr(a) <> "" Then
    arr2 = Split(arr(a), ",")
    For a2 = LBound(arr2) To UBound(arr2)
    If arr2(a2) <> "" Then
        arr3 = Split(arr2(a2), "=")
        If arr3(0) = "completeDate" Then
            If "" & arr3(1) <> "" And "" & arr3(1) <> "<null>" Then
            tmp = Mid(arr3(1), 1, 4) & Mid(arr3(1), 6, 2) & Mid(arr3(1), 9, 2)
            'response.write s & "##" & tmp & "<br>"
    
            'since we might have multiple sprints check if this one is the latest
            If tmp > getSprintLatestCompletedDate Then getSprintLatestCompletedDate = tmp
        End If
        End If
    End If
    Next
End If
Next
'if nothing found then return empty
If getSprintLatestCompletedDate = "00000000" Then getSprintLatestCompletedDate = ""
end function

function xmlsafe(s)
xmlsafe = s
xmlsafe = replace(xmlsafe, "&", "&amp;")
xmlsafe = replace(xmlsafe, "<", "&lt;")
xmlsafe = replace(xmlsafe, ">", "&gt;")
xmlsafe = replace(xmlsafe, chr(11), "")
end function

function parseHist_(jira_key)
dim url as string
Dim webClient As New System.Net.WebClient
Dim result As String 

url = "https://jira.tomtomgroup.com/rest/api/2/issue/" & jira_key & "?expand=changelog"
webClient.Headers.Add("Content-Type", "application/json; charset=utf-8")
'webClient.Headers.Add("Authorization", "Basic " & "c3ZjX3N0c19qaXJhX3VzZXI6RjIzcnQjNDV0eSM0")
webClient.Headers.Add("Authorization", "Bearer " & "NjEwNTg3NTc5NjU0Ot6RDMksA3OJYGutuCZaMVZs6e1i")
result = webClient.DownloadString(url)

parseHist_ = ""
Dim MySerializer As JavaScriptSerializer = New JavaScriptSerializer()
MySerializer.MaxJsonLength = 86753090
Dim parentJson As Dictionary(Of String, Object) = MySerializer.Deserialize(Of Dictionary(Of String, Object))(result)
dim bln as boolean
dim created as string

For Each pair In parentJson
	if (pair.Key.tostring = "changelog" ) then 'changelog is a dictionary [], loop through the pairs directly (key+value)
		for each field in pair.value 'dictionary loop
			if (field.key.tostring = "histories") then 'histories is an array {}, loop through the items, within the items loop through as a dictionary
				for each histitem in field.value 'array loop
				for each p in histitem 'dictionary loop
					if (p.Key.tostring = "created") then
						created = toDD_MM_YYYY(p.Value.tostring)
					end if
					if (p.key.tostring = "items") then 'items is an array, loop through the items, within the items loop through as a dictionary
						for each itemitem in p.value 'array loop
						bln = false 'use a toggle to start capturing status info
						for each p_item in itemitem 'dictionary loop							
							if (p_item.Value is nothing) then
							else
								if (p_item.key.tostring = "field" and p_item.value.tostring = "status") then
									bln = true
									parseHist_ = parseHist_ & created & "||"
								end if
								if (p_item.key.tostring = "fromString" and bln) then
									parseHist_ = parseHist_ & p_item.value.tostring & "||"	
								end if
								if (p_item.key.tostring = "toString" and bln) then
									parseHist_ = parseHist_ & p_item.value.tostring & "@@"	
								end if
							end if
					'		
						next
						next
					end if
				next 'dictionary loop
				next 'array loop
			end if
		next
	end if
next
end function

function toYYYYMMDD(s)
'2018-05-29T12:27:48.000+0000 comes in
'20180529 goes out
toYYYYMMDD = mid(s, 1, 4) & mid(s, 6, 2) & mid(s, 9, 2)
end function

function toDD_MM_YYYY(s)
'2018-05-29T12:27:48.000+0000 comes in
'26/05/2018 goes out
toDD_MM_YYYY = mid(s, 9, 2) & "/" & mid(s, 6, 2) &"/" & mid(s, 1, 4)
end function
</script>
