REM HEADER
REM   $Header: ebs_custom_database_objects.sql v1.01  $
REM   
REM   ebs_custom_database_objects.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@ebs_custom_database_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
REM   	sqlplus apps/<password>	@ebs_custom_database_objects.sql XXWINFO XX%	
REM
REM   
REM   Output should take ~5 to ~10 minutes or less.
REM   
REM	EBS_CUSTOM_DATABASE_OBJECTS_<SID>_<HOSTNAME>.html
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
SPOOL ebs_custom_database_objects_XX..html


VARIABLE GSM		    VARCHAR2(1);
VARIABLE ITEM_CNT    	NUMBER;
VARIABLE SID         	VARCHAR2(20);
VARIABLE HOST        	VARCHAR2(30);
VARIABLE APPS_REL    	VARCHAR2(10);
VARIABLE SYSDATE	    VARCHAR2(22);
VARIABLE WF_ADMIN_ROLE	VARCHAR2(320);
VARIABLE APPLPTMP       VARCHAR2(240);


declare

	admin_email         varchar2(40);
	gsm         		varchar2(1);
	item_cnt    		number;
	sid         		varchar2(20);
	host        		varchar2(30);
	apps_rel    		varchar2(10);
	sysdate			    varchar2(22);
	wf_admin_role 		varchar2(320);
    applptmp            varchar2(240);

begin

  select wf_core.translate('WF_ADMIN_ROLE') 
    into :wf_admin_role 
    from dual;

end;
/			 				 


alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS' NLS_LANGUAGE = 'AMERICAN';

BEGIN
   SELECT application_id 
     into :cust_appl_id 
     FROM apps.fnd_application_vl
   where application_short_name LIKE 'XX%';
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
select UPPER(instance_name) 
  from v$instance;
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
prompt       <blockquote> <a href="#dblink"> - Database Links </a><br>
prompt		   <a href="#func"> - Functions </a><br>
prompt		   <a href="#index"> - Indexes </a><br>
prompt		   <a href="#lobject"> - Large Objects </a><br>
prompt		   <a href="#mview"> - Materialized Views </a><br>
prompt		   <a href="#package"> - Packages </a><br>		
prompt		   <a href="#procedure"> - Procedures </a><br>	
prompt		   <a href="#queue"> - Queues </a><br>		
prompt		   <a href="#sequence"> - Sequences </a><br>	
prompt		   <a href="#synonym"> - Synonyms </a><br>		
prompt		   <a href="#table"> - Tables </a><br>	
prompt		   <a href="#trigger"> - Triggers </a><br>		
prompt		   <a href="#types"> - Types </a><br>	
prompt		   <a href="#view"> - Views </a><br>		
prompt		   <a href="#workflow"> - Workflows </a><br>	
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
prompt          SELECT node_name,<br>
prompt                 DECODE(support_cp, 'Y','YES','N','NO'),<br>
prompt                 DECODE(support_forms, 'Y','YES','N','NO'), <br>
prompt                 DECODE(support_web, 'Y','YES','N','NO'),<br>
prompt                 DECODE(support_db, 'Y','YES','N','NO') 
prompt           FROM fnd_nodes<br>
prompt          WHERE node_name<>'AUTHENTICATION';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SERVER NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FORMS SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEB SERVER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE SERVER</B></TD>
    SELECT '<TR><TD>'||node_name||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_cp, 'Y','YES','N','NO')   ||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_forms, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_web, 'Y','YES','N','NO')  ||'</TD>'||chr(10)|| 
               '<TD>'||decode(support_db, 'Y','YES','N','NO')   ||'</TD>
            </TR>'
      FROM apps.fnd_nodes 
     WHERE node_name <>'AUTHENTICATION';
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
prompt          select instance_name
prompt                ,release_name
prompt                ,host_name <br>
prompt                ,startup_time
prompt                ,version<br>
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
prompt          SELECT fo.profile_option_name url_shortname
prompt                ,fv.profile_option_value url<BR>
prompt            FROM fnd_profile_option_values fv
prompt                ,fnd_profile_options fo<BR>
prompt           WHERE Fo.profile_option_id=fv.profile_option_id 
prompt             AND fv.level_value = 0<BR>
prompt             AND fo.profile_option_name IN ('APPS_FRAMEWORK_AGENT'
prompt                                           ,'APPS_AUTH_AGENT'
prompt                                           ,'FND_APEX_URL'
prompt                                           ,'FND_EXTERNAL_ADF_URL'
prompt                                           ,'INV_EBI_SERVER_URL'
prompt                                           ,'ICX_FORMS_LAUNCHER'</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Value</B></TD> 
      SELECT  '<TR><TD>'||fo.profile_option_name||'</TD>'||chr(10)|| 
                  '<TD><div align="right">'||fv.profile_option_value||'</div></TD></TR>'
        FROM apps.fnd_profile_option_values fv
            ,apps.fnd_profile_options fo
       WHERE fo.profile_option_id=fv.profile_option_id AND fv.level_value = 0
         AND fo.profile_option_name in ('APPS_FRAMEWORK_AGENT'
                                       ,'APPS_AUTH_AGENT'
                                       ,'FND_APEX_URL'
                                       ,'FND_EXTERNAL_ADF_URL'
                                       ,'INV_EBI_SERVER_URL'
                                       ,'ICX_FORMS_LAUNCHER');
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
prompt       <blockquote><p align="left"></p>
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
REM ******* Section 3 : Database Links          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Database Links</font></B></U><BR><BR>
REM
REM ******* Database Links *******
REM
prompt <script type="text/javascript">  function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="dblink"></a>
prompt     <B>Database Links</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Database Link</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>User Name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Created On</B></TD>
	  
    SELECT '<TR><TD>'||db_link ||'</TD>'||chr(10)|| 
               '<TD>'||username ||'</TD>'||chr(10)|| 
               '<TD>'||created ||'</TD></TR>' 
     FROM dba_db_links;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Functions         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Functions</font></B></U><BR><BR>
REM
REM ******* Functions *******
REM
prompt <script type="text/javascript">  function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="func"></a>
prompt     <B>Functions</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'FUNCTION'
        AND owner     != 'APPS_MRC'
        AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Indexes         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Indexes</font></B></U><BR><BR>
REM
REM ******* Indexes *******
REM
prompt <script type="text/javascript">  function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="index"></a>
prompt     <B>Indexes</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'INDEX'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Large Objects         *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Large Objects</font></B></U><BR><BR>
REM
REM ******* Large Objects *******
REM
prompt <script type="text/javascript">  function displayRows2sql8(){var row = document.getElementById("s2sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="lobject"></a>
prompt     <B>Large Objects</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'LOB'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Materialized Views        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Materialized Views</font></B></U><BR><BR>
REM
REM ******* Materialized Views *******
REM
prompt <script type="text/javascript">  function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="mview"></a>
prompt     <B>Materialized Views</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'MATERIALIZED VIEW'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Packages        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Packages</font></B></U><BR><BR>
REM
REM ******* Packages *******
REM
prompt <script type="text/javascript">  function displayRows2sql10(){var row = document.getElementById("s2sql10");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="package"></a>
prompt     <B>Packages</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql10()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql10" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'PACKAGE'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : PROCEDURE        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">PROCEDURE</font></B></U><BR><BR>
REM
REM ******* PROCEDURE *******
REM
prompt <script type="text/javascript">  function displayRows2sql11(){var row = document.getElementById("s2sql11");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="procedure"></a>
prompt     <B>PROCEDURE</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'PROCEDURE'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Queues        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Queues</font></B></U><BR><BR>
REM
REM ******* Queues *******
REM
prompt <script type="text/javascript">  function displayRows2sql12(){var row = document.getElementById("s2sql12");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="queue"></a>
prompt     <B>Queues</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql12" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
           '<TD>'||object_type||'</TD>'||chr(10)|| 
           '<TD>'||owner||'</TD>'||chr(10)|| 
           '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'QUEUE'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Sequences        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Sequences</font></B></U><BR><BR>
REM
REM ******* Sequences *******
REM
prompt <script type="text/javascript">  function displayRows2sql13(){var row = document.getElementById("s2sql13");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="sequence"></a>
prompt     <B>Sequences</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'SEQUENCE'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Synonyms        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Synonyms</font></B></U><BR><BR>
REM
REM ******* Synonyms *******
REM
prompt <script type="text/javascript">  function displayRows2sql14(){var row = document.getElementById("s2sql14");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="synonym"></a>
prompt     <B>Synonyms</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'SYNONYM'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Tables        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Tables</font></B></U><BR><BR>
REM
REM ******* Tables *******
REM
prompt <script type="text/javascript">  function displayRows2sql15(){var row = document.getElementById("s2sql15");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="table"></a>
prompt     <B>Tables</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'TABLE'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Triggers        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Triggers</font></B></U><BR><BR>
REM
REM ******* Triggers *******
REM
prompt <script type="text/javascript">  function displayRows2sql16(){var row = document.getElementById("s2sql16");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="trigger"></a>
prompt     <B>Triggers</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'TRIGGER'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 3 : Types        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Types</font></B></U><BR><BR>
REM
REM ******* Types *******
REM
prompt <script type="text/javascript">  function displayRows2sql18(){var row = document.getElementById("s2sql18");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="types"></a>
prompt     <B>Types</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'TYPES'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Views        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Views</font></B></U><BR><BR>
REM
REM ******* Views *******
REM
prompt <script type="text/javascript">  function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="view"></a>
prompt     <B>Views</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>	  

    SELECT '<TR><TD>'||object_name||'</TD>'||chr(10)|| 
               '<TD>'||object_type||'</TD>'||chr(10)|| 
               '<TD>'||owner||'</TD>'||chr(10)|| 
               '<TD>'||status||'</TD></TR>'
      FROM all_objects
     WHERE object_type = 'VIEW'
       AND owner      != 'APPS_MRC'
       AND upper(object_name) LIKE 'XX%';
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 3 : Workflow        *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Workflow</font></B></U><BR><BR>
REM
REM ******* Workflow *******
REM
prompt <script type="text/javascript">  function displayRows2sql19(){var row = document.getElementById("s2sql19");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="workflow"></a>
prompt     <B>Workflow</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WORKFLOW NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCESS NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY NAME</B></TD>	  

	
    SELECT '<TR><TD>'||wav.item_type||'</TD>'||chr(10)|| 
               '<TD>'||witt.display_name||'</TD>'||chr(10)|| 
               '<TD>'||wav.name||'</TD>'||chr(10)|| 
               '<TD>'||wav.display_name||'</TD>'||chr(10)|| 
               '<TD>'||wav.function||'</TD></TR>'
      FROM apps.wf_activities_vl wav
          ,apps.wf_item_types_tl witt
     WHERE 1 = 1
       AND witt.name = wav.item_type
       AND witt.language = 'US'
       AND (upper(witt.name) LIKE 'XX%' or upper(wav.function) LIKE 'XX%' or upper(wav.message) LIKE 'XX%'
                  or upper(wav.result_type) LIKE 'XX%');	
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
spool off
set heading on
set feedback on  
set verify on
exit
;
