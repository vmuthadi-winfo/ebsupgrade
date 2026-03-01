REM HEADER
REM   $Header: ebs_analysis.sql v1.01  $
REM   
REM   ebs_analysis.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@ebs_analysis.sql
REM
REM   
REM   Output should take ~2 minutes or less.
REM   
REM	EBS_analyzer_<SID>_<HOSTNAME>.html
REM
REM
REM     Created: Oct 27th, 2019
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

begin
select to_char(sysdate,'hh24:mi:ss') into :st_time from dual;
end;
/

COLUMN host_name NOPRINT NEW_VALUE hostname
SELECT host_name from v$instance;
COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
SPOOL EBS_analyzer_&&hostname._&&instancename..html


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


alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

prompt <HTML>
prompt <HEAD>
prompt <TITLE>EBS E-Business Applications  Analyzer</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 10pt; font-family: calibri; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">EBS E-Business Applications  Analysis for 
select UPPER(instance_name) from v$instance;
prompt </font></B></TD></TR>
prompt </TABLE><BR>

prompt <font size="-1"><i><b>EBS ANALYZER v0.1 compiled on : 
select sysdate from dual;
prompt </b></i></font><BR><BR>

prompt <BR>
prompt <BR>


prompt This Analyzer performs an overall check of the Oracle E-Business Applications environment.  
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

prompt       <a href="#section2"><b><font size="+1">E-Business Suite Application Services Analysis</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#cpadv1"> - Installed modules and its patch levels </a><br>
prompt         <a href="#cpadv23"> - Concurrent Managers Active and Enabled </a><br>
prompt         <a href="#cpadv064"> - Active Users with Responsibilities </a><br>
prompt         <a href="#cpadv090"> - Applied patches in last 30 days </a><br>
prompt         <a href="#cpadv096"> - Languages installed in application </a><br>
prompt         <a href="#cpadv097"> - Total User Creation by Monthly </a><br>
prompt         <a href="#cpadv098"> - Active User count by Application </a><br>
prompt         <a href="#cpadv099"> - Top 100 Concurrents Programs by No.of Executions </a><br>
prompt         <a href="#cpadv100"> - Top 100 Concurrents Programs by Average time </a><br>
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

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Oracle E-Business Suite Application URL Details</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
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
REM ******* Section 2 : E-Business Suite Application Services Analysis          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">E-Business Suite Application Services Analysis</font></B></U><BR><BR>


REM
REM ******* Installed modules and its patch levels *******
REM


prompt <script type="text/javascript">  function displayRows2sql1(){var row = document.getElementById("s2sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv1"></a>
prompt     <B>Languages installed</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql1" style="display:none">
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> APPLICATION_SHORT_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH_LEVEL </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MEANING</B></TD>

select  
'<TR><TD>'||fa.application_short_name||'</TD>'||chr(10)|| 
'<TD>'||fat.application_name||'</TD>'||chr(10)|| 
'<TD>'||fpi.patch_level||'</TD>'||chr(10)||
'<TD>'||flv.meaning||'</TD></TR>'
from	apps.fnd_application fa,
	apps.fnd_application_tl fat,
	apps.fnd_product_installations fpi,
	apps.fnd_lookup_values flv
where	fa.application_id = fat.application_id
and 	fat.application_id = fpi.application_id
and 	fat.language = 'US'
and 	fpi.status = flv.lookup_code
and 	flv.lookup_type = 'FND_PRODUCT_STATUS'
and 	flv.language = 'US'
and 	flv.meaning != 'Not installed'
order by meaning, application_short_name;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM 
REM ******* Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size) *******
REM


prompt <script type="text/javascript">    function displayRows3sql4(){var row = document.getElementById("s3sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv132"></a>
prompt     <B>Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME "Queue Name", q.USER_CONCURRENT_QUEUE_NAME "User Queue Name",<BR>
prompt          decode(q.manager_type, 'Y', 'N') "Manager Type", a.application_short_name module, q.cache_size cache<BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id and q.enabled_flag = 'Y'<BR>
prompt          and nvl(q.control_code,'X') <> 'E'<BR>
prompt          order by   q.running_processes desc, q.manager_type, q.application_id, q.concurrent_queue_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MANAGER TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MODULE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CACHE SIZE</B></TD>
select  
'<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||q.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||q.manager_type||'</TD>'||chr(10)|| 
'<TD>'||a.application_short_name||'</TD>'||chr(10)|| 
'<TD>'||q.cache_size||'</TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
order by
  q.running_processes desc,
  q.manager_type,
  q.application_id,
  q.concurrent_queue_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Active Users with Responsibilities   *******
REM

prompt <a name="cpadv065"></a><B><U>Active Users with Responsibilities </B></U><BR> 
prompt <BR><BR>


prompt <script type="text/javascript">  function displayRows2sql1(){var row = document.getElementById("s2sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv1"></a>
prompt     <B>Languages installed</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt  SELECT fu.user_name,frv.responsibility_name <BR>
prompt  from	apps.fnd_user fu, <BR>
prompt fnd_user_resp_groups_direct furgd,<BR>
prompt  WHERE fu.user_id                     = furgd.user_id <BR>
prompt AND furgd.responsibility_id          = frv.responsibility_id<BR>
prompt  AND furgd.end_date                  IS NULL AND furgd.start_date                <= sysdate AND NVL(furgd.end_date, sysdate + 1) > sysdate AND fu.start_date                   <= sysdate AND NVL(fu.end_date, sysdate + 1)    > sysdate AND frv.start_date                  <= sysdate AND NVL(frv.end_date, sysdate + 1)   > sysdate; <BR>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> USER_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESPONSIBILITY NAME </B></TD>
SELECT 
'<TR><TD>'||fu.user_name||'</TD>'||chr(10)||
'<TD>'||frv.responsibility_name||'</TD></TR>'
FROM fnd_user fu,
  fnd_user_resp_groups_direct furgd,
  fnd_responsibility_vl frv
WHERE fu.user_id                     = furgd.user_id
AND furgd.responsibility_id          = frv.responsibility_id
AND furgd.end_date                  IS NULL
AND furgd.start_date                <= sysdate
AND NVL(furgd.end_date, sysdate + 1) > sysdate
AND fu.start_date                   <= sysdate
AND NVL(fu.end_date, sysdate + 1)    > sysdate
AND frv.start_date                  <= sysdate
AND NVL(frv.end_date, sysdate + 1)   > sysdate;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM ******* Applied patches in last 90 days *******
REM
prompt <a name="cpadv90"></a><B><U> Applied patches in last 90 days </B></U><BR>
prompt <BR><b>Description:</b><BR> Applied patches in last month in E-business suite .<BR>

prompt <script type="text/javascript"> function displayRows1sql90(){var row = document.getElementById("s1sql90");if prompt (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv90"></a>
prompt     <B> Applied patches </B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql90()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql90" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="45">
prompt       <blockquote><p align="left">
prompt	SELECT DISTINCT <br>
prompt	e.patch_name PATCH_NAME,<br>
prompt	TRUNC(a.last_update_date) LAST_APPLIED_DATE,<br>
prompt	b.applied_flag BUG_APPLIED<br>
prompt	FROM <br>
prompt	ad_bugs a,<br>
prompt	ad_patch_run_bugs b,<br>
prompt	ad_patch_runs c,<br>
prompt	ad_patch_drivers d,<br>
prompt	ad_applied_patches e<br>
prompt	WHERE<br>
prompt	a.bug_id = b.bug_id AND<br>
prompt	b.patch_run_id = c.patch_run_id AND<br>
prompt	c.patch_driver_id = d.patch_driver_id AND<br>
prompt	d.applied_patch_id = e.applied_patch_id AND<br>
prompt	a.last_update_date >= sysdate-90<br>
prompt	ORDER BY 1 DESC;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST UPDATE DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BUG APPLIED</B></TD>
select  distinct 
'<TR><TD>'||e.patch_name||'</TD>'||chr(10)|| 
'<TD>'||TRUNC(a.last_update_date)||'</TD>'||chr(10)|| 
'<TD>'||b.applied_flag||'</TD></TR>'
FROM
ad_bugs a,
ad_patch_run_bugs b,
ad_patch_runs c,
ad_patch_drivers d ,
ad_applied_patches e
WHERE
a.bug_id = b.bug_id AND
b.patch_run_id = c.patch_run_id AND
c.patch_driver_id = d.patch_driver_id AND
d.applied_patch_id = e.applied_patch_id AND
a.last_update_date >= sysdate-90
ORDER BY 1 DESC;
prompt </TABLE><P><P> 
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Languages installed in application *******
REM

prompt <a name="cpadv096"></a><B><U>  Languages installed in application  </B></U><BR>

prompt <script type="text/javascript">  function displayRows2sql96(){var row = document.getElementById("s2sql96");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv096"></a>
prompt     <B>Languages installed</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql96()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql96" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt  select NLS_LANGUAGE,LANGUAGE_CODE ,INSTALLED_FLAG <BR>
prompt from fnd_languages<BR>
prompt  where INSTALLED_FLAG in ('I','B'); </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> NLS_LANGUAGE </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LANG_CODE </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>INSTALLED_FLAG</B></TD>
select  
'<TR><TD>'||NLS_LANGUAGE||'</TD>'||chr(10)|| 
'<TD>'||LANGUAGE_CODE||'</TD>'||chr(10)|| 
'<TD>'||INSTALLED_FLAG||'</TD></TR>'
from fnd_languages
where INSTALLED_FLAG in ('I','B');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Total User Creation by Monthly    **********
REM

prompt <a name="cpadv097"></a><B><U>Total users created - Month wise</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total count of users created by month wise.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Total users created - Month wise</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          select to_char(creation_date,'YYYY-MON'),count(*) from fnd_user <BR>
prompt          where user_id > 1050 and (end_date is null or end_date > sysdate)<BR>
prompt          group by to_char(creation_date,'YYYY-MON');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>YEAR-MON</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>User Count</B></TD> 
select  
'<TR><TD>'||to_char(creation_date,'YYYY-MM')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
FROM fnd_user
WHERE user_id > 1050 and (end_date is null or end_date > sysdate)
group by to_char(creation_date,'YYYY-MM') order by 1 asc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Active User count by Application   **********
REM

prompt <a name="cpadv098"></a><B><U>TActive User count by Module</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total active users based on application module.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Active User count by Application</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          NA<BR>
prompt          </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>User Count</B></TD> 
select  
'<TR><TD>'||Application_Name||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
from ( 
SELECT distinct fu.user_name               User_Name,
       fat.application_name   Application_Name,
       to_char(fu.creation_date,'YYYY-DD') MONYY
  FROM fnd_user_resp_groups_direct        furg,
       applsys.fnd_user                   fu,
       applsys.fnd_application_tl         fat
 WHERE furg.user_id             =  fu.user_id
   AND furg.responsibility_application_id        =  fat.application_id
   AND fat.language             =  'US'
    AND (fu.end_date IS NULL OR fu.end_date >= TRUNC(SYSDATE))
 )
group by Application_Name  order by application_name ;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Top 100 Concurrents Programs by No.of Executions   **********
REM

prompt <a name="cpadv099"></a><B><U>Top 100 Concurrents Programs by No.of Executions</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total active users based on application module.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Top 100 Concurrents Programs by No.of Executions</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          NA<BR>
prompt          </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PRIGRAM NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>No.of Executions</B></TD> 
select  
'<TR><TD>'||PNAME||'</TD>'||chr(10)|| 
'<TD><div align="right">'||TOTAL_EXECUTIONS||'</div></TD></TR>'
from (
select
--b.user_name username,
a.USER_CONCURRENT_PROGRAM_NAME as PNAME,
count(ACTUAL_COMPLETION_DATE) Total_Executions
from
apps.fnd_conc_req_summary_v a --,
--apps.fnd_user b
where
phase_code = 'C' and status_code = 'C' and
a.REQUESTED_START_DATE > sysdate-30 -- and
--a.REQUESTED_BY=b.user_id
group by -- b.user_name,
a.USER_CONCURRENT_PROGRAM_NAME) where rownum <100
order by Total_Executions desc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM  **********   Top 100 Concurrents Programs by Average time   **********
REM

prompt <a name="cpadv100"></a><B><U>Top 100 Concurrents Programs by Average time</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total active users based on application module.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Top 100 Concurrents Programs by Average time</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          NA<BR>
prompt          </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PRIGRAM NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>No.of Executions</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Average Time(Hrs)</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Maximum Time(Hrs)</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Minimum Time(Hrs)</B></TD> 
select  
'<TR><TD>'||PNAME||'</TD>'||chr(10)|| 
'<TD><div align="right">'||TOTAL_EXECUTIONS||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||avg_Hrs_running||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||Max_Hrs_running||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||Min_Hrs_running||'</div></TD></TR>'
from (
select
--b.user_name username,
a.USER_CONCURRENT_PROGRAM_NAME as PNAME,
count(ACTUAL_COMPLETION_DATE) Total_Executions,
round(avg((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) avg_Hrs_running,
round(max((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) Max_Hrs_running,
round(min((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) Min_Hrs_running
from
apps.fnd_conc_req_summary_v a 
where
phase_code = 'C' and status_code = 'C' and
a.REQUESTED_START_DATE > sysdate-30 
group by 
a.USER_CONCURRENT_PROGRAM_NAME) where rownum <100
order by avg_Hrs_running desc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



spool off
set heading on
set feedback on  
set verify on
exit
;
