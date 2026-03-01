REM HEADER
REM   $Header: ebs_custom_reporting_objects.sql v1.01  $
REM   
REM   ebs_custom_reporting_objects.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@ebs_custom_reporting_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
REM   	sqlplus apps/<password>	@ebs_custom_reporting_objects.sql XXWINFO XXW%	
REM
REM   
REM   Output should take ~5 to ~10 minutes or less.
REM   
REM	EBS_CUSTOM_REPORTING_OBJECTS_<SID>_<HOSTNAME>.html
REM
REM
REM     Created: Dec 23rd, 2022
REM
REM
set term off
set arraysize 1
set heading off
set feedback off  
set echo off
set verify off
SET CONCAT ON
SET CONCAT .
SET ESCAPE '\'
REM '
set lines 120
set pages 9999
set serveroutput on size 100000

variable st_time 	varchar2(100);
variable et_time 	varchar2(100);
variable cust_appl_name varchar2(100);
variable cust_appl_prefix varchar2(100);
VARIABLE cust_appl_id NUMBER;

begin
select to_char(sysdate,'hh24:mi:ss') into :st_time from dual;
end;
/

COLUMN host_name NOPRINT NEW_VALUE hostname
SELECT host_name from v$instance;
COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
SPOOL EBS_CUSTOM_REPORTING_OBJECTS_XX..html


VARIABLE GSM		VARCHAR2(1);
VARIABLE ITEM_CNT    	NUMBER;
VARIABLE SID         	VARCHAR2(20);
VARIABLE HOST        	VARCHAR2(30);
VARIABLE APPS_REL    	VARCHAR2(10);
VARIABLE SYSDATE	VARCHAR2(22);
VARIABLE WF_ADMIN_ROLE	VARCHAR2(320);
VARIABLE APPLPTMP VARCHAR2(240);


declare

	admin_email             varchar2(40);
	gsm         		varchar2(1);
	item_cnt    		number;
	sid         		varchar2(20);
	host        		varchar2(30);
	apps_rel    		varchar2(10);
	sysdate			varchar2(22);
	wf_admin_role 		varchar2(320);
    applptmp                varchar2(240);


begin

  select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;

end;
/			 				 




alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS' NLS_LANGUAGE = 'AMERICAN';

BEGIN
SELECT application_id into :cust_appl_id FROM fnd_application_vl
where application_short_name LIKE UPPER('XX%');
END;
/


prompt <HTML>
prompt <HEAD>
prompt <TITLE>EBS E-Business Applications Custom Application Objects Analyser</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 10pt; font-family: calibri; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">EBS E-Business Applications Custom Application Analysis for 
select UPPER(instance_name) from v$instance;
prompt </font></B></TD></TR>
prompt </TABLE><BR>

prompt <font size="-1"><i><b>EBS ANALYZER v0.1 compiled on : 
select sysdate from dual;
prompt </b></i></font><BR><BR>

prompt <BR>
prompt <BR>


prompt This Analyzer performs an overall check of the data available within Oracle E-Business Applications environment.  
prompt The included recommendations are based upon best practices used across many Oracle E-Business Suite Environments.  Please check for regular updates, and feel free to provide any additional feedback or other suggestions.
prompt <BR>

prompt ________________________________________________________________________________________________<BR>

prompt <table width="95%" border="0">
prompt   <tr> 
prompt     <td colspan="4" height="46"> 
prompt       <p><a name="top"><b><font size="+2">Table of Contents</font></b></a> </p>
prompt     </td>
prompt   </tr>
prompt   <tr> 
prompt     <td width="50%"> 
prompt       <p><a href="#section1"><b><font size="+1">E-Business Applications Analysis</font></b></a> 
prompt         <br>
prompt       <blockquote> <a href="#cpadv051"> - E-Business Suite Architecture Layout </a><br>
prompt        <a href="#wfadv111"> - E-Business Suite Version </a><br></blockquote>

prompt       <a href="#section2"><b><font size="+1">E-Business Suite Application Custom Application Analysis</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#cpadv1"> - Custom Reporting Object Details </a><br>
prompt		   <a href="#ddbfolder"> - Discoverer DBFolder </a><br>
prompt		   <a href="#dworksheet"> - Discoverer Worksheets </a><br>
prompt		   <a href="#dworkbook"> - Discoverer Workbook </a><br>
prompt		   <a href="#dreports"> - Discoverer Reports </a><br>
prompt		   <a href="#dreportslu"> - Discoverer Reports Last Used</a><br>
prompt		   <a href="#dreportsus"> - Discoverer Worksbook Usage Statiscs</a><br>
prompt		   <a href="#dreportsrt"> - Discoverer Worksbook Run Time Statiscs</a><br>
prompt		   <a href="#xmltemp"> - XML Templates </a><br>		  
prompt       <br>
prompt       <br>
prompt       <br>



prompt ________________________________________________________________________________________________<BR><BR>

REM **************************************************************************************** 
REM *******Section 1 : E-Business Applications  Overview         
REM ****************************************************************************************

prompt <a name="section1"></a><B><U><font size="+2">E-Business Suite Analysis Overview</font></B></U><BR><BR>




REM
REM ******* Ebusiness Suite Architecture Layout *******
REM

REM
prompt <a name="cpadv051"></a><B><U>E-Business Architecture Layout </B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the overall Architecture of the current EBS Environment  <BR>This provides details if current environment has multi-node or single-node architecture. <BR>
prompt
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows1sql1(){var row = document.getElementById("s1sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>E-Business Architecture Layout</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="60">
prompt       <blockquote><p align="left">
prompt          select node_name,<br>
prompt          decode(support_cp, 'Y','YES','N','NO'),<br>
prompt          decode(support_forms, 'Y','YES','N','NO'), <br>
prompt          decode(support_web, 'Y','YES','N','NO'),<br>
prompt          decode(support_db, 'Y','YES','N','NO') from fnd_nodes<br>
prompt          where node_name<>'AUTHENTICATION';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SERVER NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FORMS SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEB SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE SERVER</B></TD>
select  
'<TR><TD>'||node_name||'</TD>'||chr(10)|| 
'<TD>'||decode(support_cp, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
'<TD>'||decode(support_forms, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
'<TD>'||decode(support_web, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
'<TD>'||decode(support_db, 'Y','YES','N','NO')||'</TD></TR>'
from fnd_nodes where node_name<>'AUTHENTICATION';
prompt </TABLE><P><P>

REM
REM ******* Ebusiness Suite Version *******
REM

prompt <script type="text/javascript">    function displayRows1sql2(){var row = document.getElementById("s1sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv111"></a>
prompt     <B>E-Business Suite Version</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="60">
prompt       <blockquote><p align="left">
prompt          select instance_name, release_name, host_name, <br>
prompt          startup_time, version<br>
prompt          from fnd_product_groups, v$instance;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>E-BUSINESS RELEASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE HOSTNAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTUP TIME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE VERSION</B></TD>
select  
'<TR><TD>'||instance_name||'</TD>'||chr(10)|| 
'<TD>'||release_name||'</TD>'||chr(10)|| 
'<TD>'||host_name||'</TD>'||chr(10)|| 
'<TD>'||startup_time||'</TD>'||chr(10)|| 
'<TD>'||version||'</TD></TR>'
from fnd_product_groups, v$instance;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 2 : E-Business Suite Application URLs          *******
REM ****************************************************************************************


prompt <a name="cpadv09"></a><B><U>E-Business Suite Application URLs</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides various URL and configuration information of EBS.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Oracle E-Business Suite Application URL Details</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT FO.PROFILE_OPTION_NAME URL_SHORTNAME ,FV.PROFILE_OPTION_VALUE URL<BR>
prompt          FROM FND_PROFILE_OPTION_VALUES FV,FND_PROFILE_OPTIONS FO<BR>
prompt          WHERE FO.PROFILE_OPTION_ID=FV.PROFILE_OPTION_ID AND FV.LEVEL_VALUE = 0<BR>
prompt          AND FO.PROFILE_OPTION_NAME IN ('APPS_FRAMEWORK_AGENT','APPS_AUTH_AGENT','FND_APEX_URL','FND_EXTERNAL_ADF_URL','INV_EBI_SERVER_URL','ICX_FORMS_LAUNCHER'</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Value</B></TD> 
select  
'<TR><TD>'||fo.profile_option_name||'</TD>'||chr(10)|| 
'<TD><div align="right">'||fv.profile_option_value||'</div></TD></TR>'
FROM fnd_profile_option_values fv,fnd_profile_options fo
WHERE fo.profile_option_id=fv.profile_option_id AND fv.level_value = 0
 and fo.profile_option_name in ('APPS_FRAMEWORK_AGENT','APPS_AUTH_AGENT','FND_APEX_URL','FND_EXTERNAL_ADF_URL','INV_EBI_SERVER_URL','ICX_FORMS_LAUNCHER');
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 2 : E-Business Suite Custom Application Analysis          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">E-Business Suite Custom Application Analysis </font></B></U><BR><BR>


REM
REM ******* Installed modules and its patch levels *******
REM


prompt <script type="text/javascript">  function displayRows2sql4(){var row = document.getElementById("s2sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv1"></a>
prompt     <B>Languages installed</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt  select 	fa.application_short_name, <BR>
prompt fat.application_name,<BR>
prompt  fpi.patch_level, <BR>
prompt flv.meaning<BR>
prompt  from	apps.fnd_application fa, <BR>
prompt apps.fnd_application_tl fat,<BR>
prompt  apps.fnd_product_installations fpi, <BR>
prompt apps.fnd_lookup_values flv<BR>
prompt  where	fa.application_id = fat.application_id <BR>
prompt and 	fat.application_id = fpi.application_id<BR>
prompt  and 	fat.language = 'US' <BR>
prompt and 	fpi.status = flv.lookup_code<BR>
prompt  and 	flv.lookup_type = 'FND_PRODUCT_STATUS' <BR>
prompt and 	flv.language = 'US'<BR>
prompt  and 	flv.meaning != 'Not installed' <BR>
prompt  order by meaning, application_short_name; </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> APPLICATION_ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION_SHORT_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BASEPATH</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CREATION_DATE</B></TD>
select  
'<TR><TD>'||application_id||'</TD>'||chr(10)|| 
'<TD>'||application_name||'</TD>'||chr(10)|| 
'<TD>'||description||'</TD>'||chr(10)||
'<TD>'||application_short_name||'</TD>'||chr(10)||
'<TD>'||basepath||'</TD>'||chr(10)||
'<TD>'||creation_date||'</TD></TR>'
FROM
    fnd_application_vl
WHERE
    application_short_name LIKE UPPER('XX%');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Discoverer DBFolder          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer DBFolder Details</font></B></U><BR><BR>
REM
REM ******* Discoverer DBFolder Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="ddbfolder"></a>
prompt     <B>Discoverer DBFolder Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Folder Name </B></TD>
	  
SELECT DISTINCT '<TR><TD>'||obj_name||'</TD></TR>'
FROM EUL_US.EUL5_OBJS
WHERE UPPER(obj_name) LIKE UPPER('XX%');		  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Discoverer Worksheets          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Worksheets Details</font></B></U><BR><BR>
REM
REM ******* Discoverer Worksheets Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dworksheet"></a>
prompt     <B>Discoverer Worksheets Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Owner </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Worksheet </B></TD>	  

SELECT DISTINCT '<TR><TD>'||a.qs_doc_owner ||'</TD>'||chr(10)|| 
  '<TD>'||a.qs_doc_name ||'</TD></TR>'
FROM EUL_US.eul5_qpp_stats a
WHERE 1=1
AND UPPER(a.qs_doc_name) LIKE UPPER('XX%');

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Discoverer Workbook          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Workbook Details</font></B></U><BR><BR>
REM
REM ******* Discoverer Workbook Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dworkbook"></a>
prompt     <B>Discoverer Workbook Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Owner </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workbook </B></TD>	
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Worksheet </B></TD>	  

SELECT DISTINCT '<TR><TD>'||a.qs_doc_owner||'</TD>'||chr(10)|| 
  '<TD>'||a.qs_doc_details ||'</TD>'||chr(10)|| 
  '<TD>'||a.qs_doc_name||'</TD></TR>'
FROM EUL_US.eul5_qpp_stats a
WHERE 1=1
AND UPPER(a.qs_doc_details)LIKE UPPER('XX%')	;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Discoverer Reports          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Reports Details</font></B></U><BR><BR>
REM
REM ******* Discoverer Reports Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql8(){var row = document.getElementById("s2sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dreports"></a>
prompt     <B>Discoverer Reports Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Report Name </B></TD>

SELECT DISTINCT '<TR><TD>'||doc_name||'</TD></TR>'
FROM EUL_US.EUL5_DOCUMENTS DOC
WHERE  UPPER(doc_name) LIKE UPPER('XX%');	

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 5 : Discoverer Reports Last Used          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Reports Last Used</font></B></U><BR><BR>
REM
REM ******* Discoverer Last Used *******
REM
prompt <script type="text/javascript">  function displayRows2sq20(){var row = document.getElementById("s2sq20");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dreportslu"></a>
prompt     <B>Discoverer Reports Last Used</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sq20()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sq20" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>


prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workbook</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Owner</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>List </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Times Run </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Last Used</B></TD>


SELECT '<TR><TD>'workbook||'</TD>'||chr(10)|| 
   '<TD>'||owner||'</TD>'||chr(10)||
   '<TD>'RTRIM(XMLAGG(XMLELEMENT(E,username || ' ('||last_used||' - '||times_run||')',chr(13)).EXTRACT('//text()') ORDER BY times_run).GetClobVal(),',') ||'</TD>'||chr(10)||
   '<TD>'||SUM(times_run)||'</TD>'||chr(10)||
   '<TD>'||MAX(last_used)||'</TD>'||chr(10)||
   '<TD>'||doc_name||'</TD></TR>'
FROM(
SELECT qpp.qs_doc_name  workbook
      ,qpp.qs_doc_owner owner
      ,fu.description   username
      ,QPP.QS_DOC_NAME doc_name
      ,MAX (qpp.qs_created_date) last_used 
      ,count(*) times_run
FROM eul_us.eul5_qpp_stats qpp
    ,apps.fnd_user         fu
WHERE trunc(substr(qpp.qs_created_by,2)) * 1 = fu.user_id(+)
 AND qpp.qs_created_date > TO_DATE('30-SEP-2019','DD-MON-YYYY')
GROUP BY qpp.qs_doc_owner
        ,qpp.qs_doc_name
        ,fu.description
        ,qpp.qs_doc_name)
group by workbook,doc_name,owner
ORDER BY 3 DESC;


prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 6 : Discoverer Worksbook Usage Statiscs          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Worksbook Usage Statiscs</font></B></U><BR><BR>
REM
REM ******* Discoverer Worksbook Usage Statiscs *******
REM
prompt <script type="text/javascript">  function displayRows2sq21(){var row = document.getElementById("s2sq21");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dreportsus"></a>
prompt     <B>Discoverer Worksbook Usage Statiscs</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sq21()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sq21" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workbook</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Fastest</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Slowest</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG (s)</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG (m)</B></TD>



SELECT '<TR><TD>'||qpp.qs_doc_name  workbook||'</TD>'||chr(10)|| 
      '<TD>'||round(min(qpp.qs_act_elap_time/60),2)||'</TD>'||chr(10)||  "Fastest"
      '<TD>'||round(max(qpp.qs_act_elap_time/60),2)||'</TD>'||chr(10)||  "Slowest"
      '<TD>'||round(avg(qpp.qs_act_elap_time/60),2)||'</TD>'||chr(10)||  "AVG (s)"
      '<TD>'||round(avg(qpp.qs_act_elap_time)/60,2) ||'</TD>'||chr(10)|| "AVG (m)"
      '<TD>'||count(*) times_run||'</TD></TR>'
FROM eul_us.eul5_qpp_stats qpp
WHERE qpp.qs_created_date > TO_DATE('30-SEP-2019','DD-MON-YYYY')
GROUP BY qpp.qs_doc_name


prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 7 : Discoverer Worksbook Run Time Statiscs          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Discoverer Worksbook Run Time Statiscs</font></B></U><BR><BR>
REM
REM ******* Discoverer Worksbook Run Time Statiscs *******
REM
prompt <script type="text/javascript">  function displayRows2sq22(){var row = document.getElementById("s2sq22");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dreportsrt"></a>
prompt     <B>Discoverer Worksbook Run Time Statiscs</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sq21()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sq21" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Business Area</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Description</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workbook</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Fastest</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Slowest</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG (s)</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG (m)</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Count</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Created Date</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>First Accessed Date</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Last Accessed</B></TD>

select  '<TR><TD>'||ba.ba||'</TD>'||chr(10)||
        '<TD>'||usr.description||'</TD>'||chr(10)||
        '<TD>'||doc.doc_name||'</TD>'||chr(10)||
        '<TD>'||round(min(qs_act_elap_time/60),2)||'</TD>'||chr(10)||
        '<TD>'||round(max(qs_act_elap_time/60),2) ||'</TD>'||chr(10)||
        '<TD>'||round(avg(qs_act_elap_time/60),2) ||'</TD>'||chr(10)||
        '<TD>'||round(avg(qs_act_elap_time)/60,2) ||'</TD>'||chr(10)||
        '<TD>'||count(*) ||'</TD>'||chr(10)||
        '<TD>'||doc.doc_created_date||'</TD>'||chr(10)||
        '<TD>'||min(acc.qs_created_date)||'</TD>'||chr(10)||
        '<TD>'||max(acc.qs_created_date) ||'</TD></TR>'
from    eul_us.eul5_documents doc,
        apps.fnd_user usr,
        eul_us.eul5_qpp_stats acc,
        (select distinct gd_doc_id from eul_us.eul5_access_privs ) privs,
        (
          select distinct doc.doc_id,ba.ba_name ba
          from eul_us.eul5_documents doc
          ,eul_us.eul5_elem_xrefs eex
          ,eul_us.eul5_ba_obj_links bol
          ,eul_us.eul5_objs obj
          ,eul_us.eul5_bas ba
          WHERE doc.doc_id = eex.ex_from_id
          AND eex.ex_to_par_name = obj.obj_name
          AND obj.obj_id = bol.bol_obj_id
          AND bol.bol_ba_id = ba.ba_id
        )ba
where   '#'||usr.user_id=doc.doc_created_by
        And doc.doc_name=acc.qs_doc_name
        And privs.gd_doc_id = doc.doc_id
        And trunc(substr(acc.qs_created_by,2)) * 1 = usr.user_id(+)
        And doc.doc_created_date<acc.qs_created_date
        And doc.doc_id=BA.doc_id
group by ba.ba,
        usr.description,
        doc.doc_name,
        doc.doc_created_date;

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 3 : XML Reports          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">XML Reports Details</font></B></U><BR><BR>
REM
REM ******* XML Reports Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="xmltemp"></a>
prompt     <B>XML Reports Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TEMPLATE CODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TEMPLATE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>

SELECT DISTINCT
    '<TR><TD>'||fav.application_id||'</TD>'||chr(10)|| 
    '<TD>'||xtv.template_code||'</TD>'||chr(10)|| 
    '<TD>'||xtv.template_name||'</TD>'||chr(10)|| 
    '<TD>'||nvl(xtv.description, 'No Description Available')||'</TD>'||chr(10)|| 
    '<TD>'||fav.application_name||'</TD>'||chr(10)|| 
    '<TD>'||xtv.template_type_code||'</TD>'||chr(10)|| 
    '<TD>'||decode(xtv.template_status, 'E', 'Enabled', 'D', 'Disabled')||'</TD></TR>'  
FROM
    apps.xdo_templates_vl   xtv,
    apps.fnd_application_vl fav
WHERE
        fav.application_id = xtv.application_id
    AND ( xtv.application_id IN  (  :cust_appl_id )
          OR upper(xtv.template_code) LIKE upper('XX%'));

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

spool off
set heading on
set feedback on  
set verify on
exit
;
