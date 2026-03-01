REM HEADER
REM   $Header: ebs_custom_application_objects.sql v1.01  $
REM   
REM   ebs_custom_application_objects.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@ebs_custom_application_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
REM   	sqlplus apps/<password>	@ebs_custom_application_objects.sql XXWINFO XXW%	
REM
REM   
REM   Output should take ~5 to ~10 minutes or less.
REM   
REM	EBS_CUSTOM_APPLICATION_OBJECTS_<SID>_<HOSTNAME>.html
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
SPOOL EBS_CUSTOM_APPLICATION_OBJECTS_XX._XX..html


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
SELECT application_id into :cust_appl_id FROM apps.fnd_application_vl
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
prompt       <blockquote> <a href="#cpadv1"> - Custom Application Details </a><br>
prompt		   <a href="#alrdata"> - Alert Details </a><br>
prompt		   <a href="#cphost"> - Concurrent Program-Host </a><br>
prompt		   <a href="#cpjava"> - Concurrent Program-Java </a><br>
prompt		   <a href="#cpjavasp"> - Concurrent Program-Java Stored Procedures </a><br>
prompt		   <a href="#cpreports"> - Concurrent Program-Reports </a><br>
prompt		   <a href="#cpsqll"> - Concurrent Program-Sql Loader </a><br>
prompt		   <a href="#cpsql"> - Concurrent Program-SQLPLUS </a><br>
prompt		   <a href="#cpplsql"> - Concurrent Program-PLSQL </a><br>
prompt		   <a href="#forms"> - Forms </a><br>
prompt		   <a href="#oacforms"> - OAF Custom Pages </a><br>
prompt		   <a href="#oacandp"> - OAF Page Customizations and Personalizations </a><br>
prompt		   <a href="#clookup"> - Lookup Types </a><br>
prompt		   <a href="#cmenu"> - Menus </a><br>
prompt		   <a href="#cmessage"> - Messages </a><br>
prompt		   <a href="#cpersonalization"> - Personalizations </a><br>
prompt		   <a href="#cprofile"> - Profiles </a><br>
prompt		   <a href="#creqgroup"> - Request Groups </a><br>
prompt		   <a href="#creqset"> - Request Sets </a><br>
prompt		   <a href="#cresp"> - Responsibilities </a><br>
prompt		   <a href="#cvalset"> - Value Sets </a><br>
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
    select '<TR><TD>'||node_name||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_cp, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_forms, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_web, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_db, 'Y','YES','N','NO')||'</TD></TR>'
      from apps.fnd_nodes 
     where node_name<>'AUTHENTICATION';
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
    select '<TR><TD>'||instance_name||'</TD>'||chr(10)|| 
               '<TD>'||release_name||'</TD>'||chr(10)|| 
               '<TD>'||host_name||'</TD>'||chr(10)|| 
               '<TD>'||startup_time||'</TD>'||chr(10)|| 
               '<TD>'||version||'</TD></TR>'
      from apps.fnd_product_groups
          ,v$instance;
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
    select '<TR><TD>'||fo.profile_option_name||'</TD>'||chr(10)|| 
               '<TD><div align="right">'||fv.profile_option_value||'</div></TD></TR>'
      FROM apps.fnd_profile_option_values fv
          ,apps.fnd_profile_options fo
     WHERE fo.profile_option_id=fv.profile_option_id 
       AND fv.level_value = 0
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
      SELECT '<TR><TD>'||a.application_id||'</TD>'||chr(10)|| 
                 '<TD>'||a.application_name||'</TD>'||chr(10)|| 
                 '<TD>'||a.description||'</TD>'||chr(10)||
                 '<TD>'||a.application_short_name||'</TD>'||chr(10)||
                 '<TD>'||a.basepath||'</TD>'||chr(10)||
                 '<TD>'||a.creation_date||'</TD>'||chr(10)||
                 '<TD>'||u.user_name||'</TD>'||chr(10)||
              '</TR>'
        FROM apps.fnd_application_vl a
            ,apps.fnd_user           u
       WHERE u.user_id = a.created_by
         and ((u.user_name NOT LIKE 'ORACLE12%'
                 AND  u.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                 AND a.application_id >= 20000) OR a.application_short_name LIKE 'XX%');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Alert Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Alert Details</font></B></U><BR><BR>


REM
REM ******* Alert Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="alrdata"></a>
prompt     <B>Alert Details</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Alert Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Application Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Alert Type </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Status </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Enabled </B></TD>

    SELECT '<TR><TD>'||aa.application_id||'</TD>'||chr(10)||
               '<TD>'||aa.alert_name||'</TD>'||chr(10)|| 
               '<TD>'||fav.application_name||'</TD>'||chr(10)|| 
               '<TD>'||decode(aa.alert_condition_type, 'E', 'Event', 'P', 'Periodic',
                      alert_condition_type)||'</TD>'||chr(10)|| 
               '<TD>'||decode(aa.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled') ||
               '</TD></TR>' 
      FROM apps.alr_alerts         aa
          ,apps.fnd_application_vl fav
          ,fnd_user                usr
     WHERE usr.user_id = fav.created_by
       AND aa.application_id = fav.application_id
       AND (((usr.user_name NOT LIKE 'ORACLE12%'
                 AND  usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                 AND fav.application_id >= 20000) OR fav.application_short_name LIKE 'XX%')
               OR upper(aa.alert_name) LIKE 'XX%');  
              
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-Host Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-Host Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-Host Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cphost"></a>
prompt     <B>Concurrent Program-Host Details</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'H'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');
		  

prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-Java Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-Java Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-Java Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpjava"></a>
prompt     <B>Concurrent Program-Java Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'K'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');

prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-Java Stored Procedures Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-Java Stored Procedures Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-Java Stored Procedures  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql8(){var row = document.getElementById("s2sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpjavasp"></a>
prompt     <B>Concurrent Program-Java Stored Procedures Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'J'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-Reports          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-Reports Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-Reports  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpreports"></a>
prompt     <B>Concurrent Program-Reports Details</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'P'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');
		  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-Sql Loader          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-Sql Loader Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-Sql Loader  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql10(){var row = document.getElementById("s2sql10");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpsqll"></a>
prompt     <B>Concurrent Program-Sql Loader Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql10()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql10" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'L'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');
		  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-SQLPLUS          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-SQLPLUS Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-SQLPLUS  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql11(){var row = document.getElementById("s2sql11");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpsql"></a>
prompt     <B>Concurrent Program-SQLPLUS Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql11()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql11" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'Q'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');
		  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Concurrent Program-PLSQL          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Concurrent Program-PLSQL Details</font></B></U><BR><BR>


REM
REM ******* Concurrent Program-PLSQL  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql12(){var row = document.getElementById("s2sql12");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpplsql"></a>
prompt     <B>Concurrent Program-PLSQL Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql12" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTION FILE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS </B></TD>

    SELECT '<TR><TD>'||fcpt.user_concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fcp.concurrent_program_name||'</TD>'||chr(10)||
               '<TD>'||fee.execution_file_name||'</TD>'||chr(10)||
               '<TD>'||fee.executable_name||'</TD>'||chr(10)||
               '<TD>'||eapp.application_name||'</TD>'||chr(10)||
               '<TD>'||papp.application_name||'</TD>'||chr(10)||
               '<TD>'||decode(fcp.enabled_flag, 'N', 'Disable', 'Y', 'Enable','Enabled')||
               '</TD>
            </TR>' 
      FROM apps.fnd_executables            fee
          ,apps.fnd_concurrent_programs    fcp
          ,apps.fnd_concurrent_programs_tl fcpt
          ,apps.fnd_application_tl         eapp
          ,apps.fnd_application_tl         papp
     WHERE fee.executable_id         = fcp.executable_id
       AND eapp.application_id       = fee.application_id
       AND papp.application_id       = fcp.application_id
       AND fcp.concurrent_program_id = fcpt.concurrent_program_id
       AND fcpt.language             = 'US'
       AND eapp.language             = 'US'
       AND papp.language             = 'US'
       AND fee.execution_method_code = 'I'
       AND (fee.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcp.application_id IN     
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR fcpt.user_concurrent_program_name LIKE 'XX%');

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Forms          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Forms Details</font></B></U><BR><BR>


REM
REM ******* Forms  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql13(){var row = document.getElementById("s2sql13");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="forms"></a>
prompt     <B>Forms Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql13()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql13" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FORM NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER FORM NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME </B></TD>


    SELECT '<TR><TD>'||nvl(fffv.form_name, ' ')||'</TD>'||chr(10)||
               '<TD>'||fffv.user_form_name||'</TD>'||chr(10)||
               '<TD>'||fav.application_name ||'</TD></TR>' 
      FROM apps.fnd_form_vl        fffv
          ,apps.fnd_application_vl fav
     WHERE fffv.application_id = fav.application_id
       AND (fav.application_id IN 
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
            OR upper(fffv.form_name) LIKE 'XX%');	  	  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : OAF Custom Pages          *******
REM ****************************************************************************************
prompt <a name="section2"></a><B><U><font size="+2">OAF Custom Pages Details</font></B></U><BR><BR>
REM
REM ******* OAF Custom Pages  Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql14(){var row = document.getElementById("s2sql14");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="oacforms"></a>
prompt     <B>OAF Custom Pages Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OAF PAGE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OAF PAGE PATH</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ATTRIBUTE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FILE NAME AND PATH</B></TD>

    SELECT DISTINCT
           '<TR><TD>'||jp.path_name||'</TD>'||chr(10)||  
               '<TD>'||jp.the_path||'</TD>'||chr(10)||  
               '<TD>'||jat.att_name||'</TD>'||chr(10)|| 
               '<TD>'||jat.att_value||'</TD></TR>'  
      FROM (SELECT path_name,
                   path_docid,
                   path_type,
                   sys_connect_by_path(path_name, '/') the_path,
                   CONNECT_BY_ISLEAF                   is_leaf,
                   created_by,
                   last_update_date
              FROM apps.jdr_paths
                     CONNECT BY path_owner_docid = PRIOR path_docid
            START WITH ( path_owner_docid = 0 )) jp
          ,apps.jdr_attributes jat
     WHERE 1 = 1
       AND is_leaf = 1
       AND path_type = 'DOCUMENT'
       AND created_by NOT IN ( '1' )
       AND jp.path_docid = jat.att_comp_docid
       AND ( jat.att_name = 'amDefName'
             OR jat.att_name = 'controllerClass'
             OR jat.att_name = 'viewName' )
       AND ( ( upper(path_name) LIKE upper('XX%')
               OR upper(path_name) LIKE upper('XX%')
                )
             OR ( ( upper(the_path) LIKE upper('XX%')
                    OR upper(the_path) LIKE upper('XX%')
                     ) ) )
       AND ( upper(the_path) NOT LIKE '%/CUSTOMIZATIONS/%' )
    ORDER BY 1;	  
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : OAF Page Customizations and Personalizations          *******
REM ****************************************************************************************
prompt <a name="section2"></a><B><U><font size="+2">OAF Page Customizations and Personalizations</font></B></U><BR><BR>
REM
REM ******* OAF Page Customizations and Personalizations *******
REM
prompt <script type="text/javascript">  function displayRows2sql15(){var row = document.getElementById("s2sql15");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="oacforms"></a>
prompt     <B>OAF Page Customizations and Personalizations</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql15()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql15" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OAF PAGE NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OAF PAGE PATH</B></TD>
    SELECT DISTINCT
           '<TR><TD>'||jp.path_name||'</TD>'||chr(10)|| 
           '<TD>'||jp.the_path||'</TD></TR>'
      FROM ( SELECT path_name,
                    path_docid,
                    path_type,
                    sys_connect_by_path(path_name, '/') the_path,
                    CONNECT_BY_ISLEAF                   is_leaf,
                    created_by,
                    last_update_date
               FROM apps.jdr_paths
            CONNECT BY path_owner_docid = PRIOR path_docid
            START WITH ( path_owner_docid = 0 )) JP
     WHERE 1 = 1
       AND jp.the_path LIKE '%customizations%'
       AND jp.is_leaf = 1
       AND jp.path_type = 'DOCUMENT'
       AND jp.created_by NOT IN ( '1' ); 
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Lookup Types         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Lookup Types</font></B></U><BR><BR>


REM
REM ******* Lookup Types *******
REM
prompt <script type="text/javascript">  function displayRows2sql16(){var row = document.getElementById("s2sql16");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="clookup"></a>
prompt     <B>Lookup Types</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql16()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql16" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LOOKUP TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME </B></TD>

	
	SELECT '<TR><TD>'||flt.application_id||'</TD>'||chr(10)|| 
               '<TD>'||flt.lookup_type ||'</TD>'||chr(10)||  
               '<TD>'||ftl.application_name||'</TD></TR>'
      FROM apps.fnd_lookup_types_vl flt
          ,apps.fnd_application_tl  ftl
     WHERE flt.application_id = ftl.application_id
       AND ftl.language  = 'US'
       AND (flt.application_id IN 
                (SELECT application_id
                   FROM apps.fnd_application app
                       ,apps.fnd_user        usr
                  WHERE usr.user_id = app.created_by
                    AND usr.user_name NOT LIKE 'ORACLE12%'
                    AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                    AND app.application_id >= 20000)
          OR upper(flt.lookup_type) LIKE 'XX%' ) ;	  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Menus         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Menus</font></B></U><BR><BR>


REM
REM ******* Menus *******
REM
prompt <script type="text/javascript">  function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cmenu"></a>
prompt     <B>Menus</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MENU NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESPONSIBILITY NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME </B></TD>		  
    SELECT '<TR><TD>'||fapt.application_id||'</TD>'||chr(10)||
               '<TD>'||fmn.menu_name||'</TD>'||chr(10)||
               '<TD>'||fret.responsibility_name||'</TD>'||chr(10)||
               '<TD>'||fapt.application_name||'</TD>
            </TR>' 
      FROM apps.fnd_menus             fmn
          ,apps.fnd_responsibility    fres
          ,apps.fnd_responsibility_tl fret
          ,apps.fnd_application_tl    fapt
     WHERE fmn.menu_id           = fres.menu_id (+)
       AND fres.responsibility_id = fret.responsibility_id (+)
       AND fres.application_id    = fapt.application_id (+)
       AND fapt.language (+)      = 'US'
       AND fret.language (+)      = 'US'       
       AND (fres.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(fmn.menu_name) LIKE 'XX%' );	  

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 3 : Messages         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Messages</font></B></U><BR><BR>


REM
REM ******* Messages *******
REM
prompt <script type="text/javascript">  function displayRows2sql18(){var row = document.getElementById("s2sql18");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cmessage"></a>
prompt     <B>Messages</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql18()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql18" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME </B></TD>		  

    SELECT '<TR><TD>'||fnm.application_id||'</TD>'||chr(10)|| 
               '<TD>'||fnm.message_name||'</TD>'||chr(10)||     
               '<TD>'||ftl.application_name||'</TD></TR>' 
      FROM apps.fnd_new_messages   fnm
          ,apps.fnd_application_tl ftl
     WHERE ftl.application_id = fnm.application_id
       AND ftl.language       = 'US'
       AND (fnm.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(fnm.message_name) LIKE 'XX%' );	  
     
    
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Personalizations         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Personalizations</font></B></U><BR><BR>


REM
REM ******* Personalizations *******
REM
prompt <script type="text/javascript">  function displayRows2sql19(){var row = document.getElementById("s2sql19");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpersonalization"></a>
prompt     <B>Personalizations</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql19()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql19" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FORM NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER FORM NAME </B></TD>		 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>	 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET OBJECT</B></TD>	 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONDITION</B></TD>	 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROPERTY VALUE</B></TD>	 

	  
    SELECT '<TR><TD>'||fav.application_name||'</TD>'||chr(10)|| 
               '<TD>'||ffcr.form_name||'</TD>'||chr(10)||                                           
               '<TD>'||ffv.user_form_name||'</TD>'||chr(10)||   
               '<TD>'||ffcr.description||'</TD>'||chr(10)||   
               '<TD>'||decode(ffcr.enabled, 'Y', 'Enabled', 'N', 'Disabled') ||'</TD>'||chr(10)||   
               '<TD>'||ffca.target_object||'</TD>'||chr(10)||   
               '<TD>'||ffcr.condition||'</TD>'||chr(10)||   
               '<TD>'||ffca.property_value||'</TD>
            </TR>' 
      FROM apps.fnd_application_vl      fav
          ,apps.fnd_form_vl             ffv
          ,apps.fnd_form_custom_rules   ffcr
          ,apps.fnd_form_custom_actions ffca
     WHERE 1 = 1
       AND ffv.form_name      = ffcr.form_name
       AND fav.application_id = ffv.application_id
       AND ffca.rule_id       = ffcr.id ;		  
    
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Profiles         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Profiles</font></B></U><BR><BR>


REM
REM ******* Profiles *******
REM
prompt <script type="text/javascript">  function displayRows2sql20(){var row = document.getElementById("s2sql20");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cprofile"></a>
prompt     <B>Profiles</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql20()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql20" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER PROFILE OPTION NAME </B></TD>		 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE OPTION NAME</B></TD>

    SELECT '<TR><TD>'||fa.application_id||'</TD>'||chr(10)||  
               '<TD>'||fa.application_name||'</TD>'||chr(10)||    
               '<TD>'||user_profile_option_name||'</TD>'||chr(10)||
               '<TD>'||profile_option_name||'</TD></TR>'       
      FROM apps.fnd_profile_options_vl fpo
          ,apps.fnd_application_vl     fa
     WHERE fpo.application_id = fa.application_id
       AND fpo.start_date_active <= sysdate
       AND ( nvl(fpo.end_date_active, sysdate) >= sysdate )
       AND (fa.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(fpo.profile_option_name) LIKE 'XX%' );
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Request Groups         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Request Groups</font></B></U><BR><BR>


REM
REM ******* Request Groups *******
REM
prompt <script type="text/javascript">  function displayRows2sql21(){var row = document.getElementById("s2sql21");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="creqgroup"></a>
prompt     <B>Request Groups</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql21()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql21" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST GROUP NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION </B></TD>		 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME NAME</B></TD>

	  
    SELECT '<TR><TD>'||fav.application_id||'</TD>'||chr(10)||
               '<TD>'||frg.request_group_name||'</TD>'||chr(10)||
               '<TD>'||nvl(frg.description, ' ')||'</TD>'||chr(10)||
               '<TD>'||fav.application_name||'</TD></TR>'      
      FROM apps.fnd_request_groups frg
          ,apps.fnd_application_vl fav
     WHERE frg.application_id = fav.application_id
       AND (fav.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(frg.request_group_name) LIKE 'XX%' );
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Request Sets         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Request Sets</font></B></U><BR><BR>


REM
REM ******* Request Sets *******
REM
prompt <script type="text/javascript">  function displayRows2sql22(){var row = document.getElementById("s2sql22");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="creqset"></a>
prompt     <B>Request Sets</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql22()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql22" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST SET NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER REQUEST SET NAME </B></TD>	
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION </B></TD>	
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME NAME</B></TD>

    SELECT '<TR><TD>'||fav.application_id        ||'</TD>'||chr(10)||  
               '<TD>'||frs.request_set_name      ||'</TD>'||chr(10)||    
               '<TD>'||frst.user_request_set_name||'</TD>'||chr(10)||
               '<TD>'||nvl(frst.description, ' ')||'</TD>'||chr(10)||
               '<TD>'||fav.application_name      ||'</TD></TR>'          
      FROM apps.fnd_application_vl  fav
          ,apps.fnd_request_sets    frs
          ,apps.fnd_request_sets_tl frst
     WHERE frst.request_set_id = frs.request_set_id
        AND frs.application_id = fav.application_id
        AND (fav.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(frs.request_set_name) LIKE 'XX%' );
 
	  
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Responsibilities        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Responsibilities</font></B></U><BR><BR>


REM
REM ******* Responsibilities *******
REM
prompt <script type="text/javascript">  function displayRows2sql23(){var row = document.getElementById("s2sql23");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cresp"></a>
prompt     <B>Responsibilities</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql23()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql23" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESPONSIBILITY NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>

	  
    SELECT '<TR><TD>'||fav.application_id                         ||'</TD>'||chr(10)||
               '<TD>'||frt.responsibility_name                    ||'</TD>'||chr(10)||
               '<TD>'||fav.application_name                       ||'</TD>'||chr(10)||  
               '<TD>'||( CASE WHEN frv.end_date <= sysdate THEN
                                      'Disable'
                              WHEN end_date IS NULL THEN
                                      'Enable'
                              ELSE  'Enable'
                         END )                                     ||'</TD></TR>'                      
      FROM apps.fnd_responsibility_tl frt
          ,apps.fnd_responsibility_vl frv
          ,apps.fnd_application_vl    fav
     WHERE frt.application_id    = fav.application_id
       AND frv.application_id    = fav.application_id
       AND frt.responsibility_id = frv.responsibility_id
       AND (fav.application_id IN 
                    (SELECT application_id
                       FROM apps.fnd_application app
                           ,apps.fnd_user        usr
                      WHERE usr.user_id = app.created_by
                        AND usr.user_name NOT LIKE 'ORACLE12%'
                        AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL')
                        AND app.application_id >= 20000)
              OR upper(frt.responsibility_name) LIKE 'XX%'
              OR upper(frv.responsibility_key) LIKE upper('XX%'));  
     
	  
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Value Sets        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Value Sets</font></B></U><BR><BR>


REM
REM ******* Value Sets *******
REM
prompt <script type="text/javascript">  function displayRows2sql24(){var row = document.getElementById("s2sql24");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cvalset"></a>
prompt     <B>Value Sets</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql23()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql24" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE SET NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALIDATION TYPE</B></TD>
    SELECT '<TR><TD>'||Value_Set_Name||'</TD>'||chr(10)||
               '<TD>'||Validation_Type||'</TD></TR>'   
      FROM (
            SELECT ( flex_value_set_name || ' ' || '('  || 
                       decode(validation_type, 'D', 'Dependent', 'I', 'Independent',
                                               'N', 'None', 'P', 'Pair', 'U', 'Special', 'F', 'Table', 'X', 'Translatable Independent',
                            'Y', 'Translatable Dependent', validation_type)|| ')' )                                               Value_Set_Name,
                     decode(validation_type, 'D', 'Dependent', 'I', 'Independent',
                       'N', 'None', 'P', 'Pair', 'U',
                       'Special', 'F', 'Table', 'X', 'Translatable Independent',
                       'Y', 'Translatable Dependent', validation_type) Validation_Type
              FROM apps.fnd_flex_value_sets
             WHERE upper(flex_value_set_name) LIKE 'XX%');
    
	  
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

spool off
set heading on
set feedback on  
set verify on
exit
;
