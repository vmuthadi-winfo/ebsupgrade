REM HEADER
REM   $Header: ebs_data_collection.sql v1.01  $
REM   
REM   ebs_data_collection.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM       sqlplus apps/<password>    @ebs_data_collection.sql
REM
REM   
REM   Output should take ~2 minutes or less.
REM   
REM    EBS_analyzer_<SID>_<HOSTNAME>.html
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

variable st_time     varchar2(100);
variable et_time     varchar2(100);

begin
select to_char(sysdate,'hh24:mi:ss') into :st_time from dual;
end;
/

COLUMN host_name NOPRINT NEW_VALUE hostname
SELECT host_name from v$instance;
COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
SPOOL EBS_analyzer_XX..html


VARIABLE GSM             VARCHAR2(1);
VARIABLE ITEM_CNT        NUMBER;
VARIABLE SID             VARCHAR2(20);
VARIABLE HOST            VARCHAR2(30);
VARIABLE APPS_REL        VARCHAR2(10);
VARIABLE SYSDATE         VARCHAR2(22);
VARIABLE WF_ADMIN_ROLE   VARCHAR2(320);
VARIABLE APPLPTMP        VARCHAR2(240);


declare

    admin_email         varchar2(40);
    gsm                 varchar2(1);
    item_cnt            number;
    sid                 varchar2(20);
    host                varchar2(30);
    apps_rel            varchar2(10);
    sysdate             varchar2(22);
    wf_admin_role       varchar2(320);
    applptmp            varchar2(240);


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
prompt         <a href="#cpadv065"> - Concurrent Manager Status </a><br>
prompt         <a href="#cpadv091"> - Volume of Daily Concurrent Requests for Last Month  </a><br>
prompt         <a href="#cpadv064"> - Profile options changes in last 48 hours </a><br>
prompt         <a href="#cpadv090"> - Applied patches in last 30 days </a><br>
prompt         <a href="#cpadv096"> - Languages installed in application </a><br>
prompt         <a href="#cpadv097"> - Total User Creation by Monthly </a><br>
prompt         <a href="#cpadv098"> - Active User count by Application </a><br>
prompt         <a href="#cpadv099"> - Top 100 Concurrents Programs by No.of Executions </a><br>
prompt         <a href="#cpadv100"> - Top 100 Concurrents Programs by Average time </a><br>
prompt       <br>
prompt       <br>
prompt       <br>

prompt       <a href="#section3"><b><font size="+1">E-Business Applications Database Details</font></b></a> 
prompt       <br>
prompt        <a href="#cpadv11"> - Invalid Objects in Database group by owner </a><br>
prompt         <a href="#cpadv3"> - Gather Schema Statistics last run </a><br>
prompt         <a href="#cpadv50"> - Database size  </a><br>
prompt         <a href="#cpadv51"> - Database User Details  </a><br>
prompt     </p>
prompt     </td>
prompt     </tr>
prompt </table>

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

prompt <script type="text/javascript">    function displayRows1sql1(){var row = document.getElementById("s1sql1");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    select  '<TR><TD>'||node_name||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_cp, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_forms, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_web, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_db, 'Y','YES','N','NO')||'</TD></TR>'
      from apps.fnd_nodes 
     where node_name <>'AUTHENTICATION';
prompt </TABLE><P><P>

REM
REM ******* Ebusiness Suite Version *******
REM

prompt <script type="text/javascript">    function displayRows1sql2(){var row = document.getElementById("s1sql2");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    select '<TR><TD>'||instance_name   ||'</TD>'||chr(10)|| 
               '<TD>'||release_name    ||'</TD>'||chr(10)|| 
               '<TD>'||host_name       ||'</TD>'||chr(10)|| 
               '<TD>'||startup_time    ||'</TD>'||chr(10)|| 
               '<TD>'||version         ||'</TD></TR>'
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

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    select  '<TR><TD>'||fo.profile_option_name||'</TD>'||chr(10)|| 
                '<TD><div align="right">'||fv.profile_option_value||'</div></TD></TR>'
      FROM apps.fnd_profile_option_values fv
          ,apps.fnd_profile_options fo
     WHERE fo.profile_option_id=fv.profile_option_id
       AND fv.level_value = 0
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

prompt <script type="text/javascript">  function displayRows2sql1(){var row = document.getElementById("s2sql1");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
prompt  select     fa.application_short_name, <BR>
prompt fat.application_name,<BR>
prompt  fpi.patch_level, <BR>
prompt flv.meaning<BR>
prompt  from    apps.fnd_application fa, <BR>
prompt apps.fnd_application_tl fat,<BR>
prompt  apps.fnd_product_installations fpi, <BR>
prompt apps.fnd_lookup_values flv<BR>
prompt  where    fa.application_id = fat.application_id <BR>
prompt and     fat.application_id = fpi.application_id<BR>
prompt  and     fat.language = 'US' <BR>
prompt and     fpi.status = flv.lookup_code<BR>
prompt  and     flv.lookup_type = 'FND_PRODUCT_STATUS' <BR>
prompt and     flv.language = 'US'<BR>
prompt  and     flv.meaning != 'Not installed' <BR>
prompt  order by meaning, application_short_name; </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> APPLICATION_SHORT_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION_NAME </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH_LEVEL </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MEANING</B></TD>

    SELECT '<TR><TD>'||fa.application_short_name  ||'</TD>'||chr(10)|| 
               '<TD>'||fat.application_name       ||'</TD>'||chr(10)|| 
               '<TD>'||fpi.patch_level            ||'</TD>'||chr(10)||
               '<TD>'||flv.meaning                ||'</TD>
            </TR>'
      FROM apps.fnd_application           fa
          ,apps.fnd_application_tl        fat
          ,apps.fnd_product_installations fpi
          ,apps.fnd_lookup_values         flv
     WHERE fa.application_id  = fat.application_id
       AND fat.application_id = fpi.application_id
       AND fat.language       = 'US'
       AND fpi.status         = flv.lookup_code
       AND flv.lookup_type    = 'FND_PRODUCT_STATUS'
       AND flv.language       = 'US'
       AND flv.meaning       != 'Not installed'
    order by meaning, application_short_name;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM 
REM ******* Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size) *******
REM


prompt <script type="text/javascript">    function displayRows3sql4(){var row = document.getElementById("s3sql4");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    select '<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
               '<TD>'||q.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
               '<TD>'||q.manager_type||'</TD>'||chr(10)|| 
               '<TD>'||a.application_short_name||'</TD>'||chr(10)|| 
               '<TD>'||q.cache_size||'</TD></TR>'
      from apps.fnd_concurrent_queues_vl  q
          ,apps.fnd_product_installations i
          ,apps.fnd_application_vl        a
     where i.application_id = q.application_id
      and a.application_id = q.application_id
      and q.enabled_flag = 'Y'
      and nvl(q.control_code,'X') <> 'E'
    order by q.running_processes desc,
             q.manager_type,
             q.application_id,
             q.concurrent_queue_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Concurrent Manager Status   *******
REM

prompt <a name="cpadv065"></a><B><U>Concurrent Manager Status </B></U><BR>
prompt <BR><b>Description:</b><BR> Provides the status of the Concurrent Managers <BR>
prompt <BR><b>Action:</b><BR> When the Concurrent Manager is up and running, the number should be same for max_processes and running_processes.  
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Concurrent Manager Status</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt SELECT q.concurrent_queue_id,<BR>
prompt q.concurrent_queue_name,<BR>
prompt q.user_concurrent_queue_name,<BR>
prompt q.target_node,<BR>
q.max_processes,<BR>
prompt q.running_processes,<BR>
prompt running.run running,<BR>
promptpending.pend,<BR>
prompt Decode(q.control_code, 'D', 'Deactivating','E', 'Deactivated','N', 'Node unavai','A', 'Activating','X', 'Terminated','T', 'Terminating','V', 'Verifying','O', 'Suspending','P', 'Suspended','Q', 'Resuming','R', 'Restarting') status<BR>
prompt FROM (SELECT concurrent_queue_name,<BR>
prompt COUNT(phase_code) run<BR>
prompt FROM fnd_concurrent_worker_requests<BR>
prompt WHERE phase_code = 'R'<BR>
prompt AND hold_flag != 'Y'<BR>
prompt AND requested_start_date <= SYSDATE<BR>
prompt GROUP BY concurrent_queue_name) running,<BR>
prompt (SELECT concurrent_queue_name,<BR>
prompt COUNT(phase_code) pend<BR>
prompt FROM fnd_concurrent_worker_requests<BR>
prompt WHERE phase_code = 'P'<BR>
prompt AND hold_flag != 'Y'<BR>
prompt AND requested_start_date <= SYSDATE<BR>
prompt GROUP BY concurrent_queue_name) pending,<BR>
prompt apps.fnd_concurrent_queues_vl q<BR>
prompt WHERE q.concurrent_queue_name = running.concurrent_queue_name(+)<BR>
prompt AND q.concurrent_queue_name = pending.concurrent_queue_name(+)<BR>
prompt AND q.enabled_flag = 'Y'<BR>
prompt ORDER BY Decode(q.application_id, 0, Decode(q.concurrent_queue_id, 1, 1,4, 2)),<BR>
prompt Sign(q.max_processes) DESC,<BR>
prompt q.concurrent_queue_name,<BR>
prompt q.application_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>concurrent_queue_id</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>concurrent_queue_name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>user_concurrent_queue_name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>target_node</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>max_processes</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>running_processes</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>running</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>pending</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>status</B></TD>
    SELECT '<TR><TD>'||q.concurrent_queue_id            ||'</TD>'||chr(10)||
               '<TD>'||q.concurrent_queue_name          ||'</TD>'||chr(10)||
               '<TD>'||q.user_concurrent_queue_name     ||'</TD>'||chr(10)||
               '<TD>'||q.target_node                    ||'</TD>'||chr(10)||
               '<TD>'||q.max_processes                  ||'</TD>'||chr(10)||
               '<TD>'||q.running_processes              ||'</TD>'||chr(10)||
               '<TD>'||running.run                      ||'</TD>'||chr(10)||
               '<TD>'||pending.pend                     ||'</TD>'||chr(10)||
               '<TD>'||Decode(q.control_code, 'D', 'Deactivating',
                                    'E', 'Deactivated',
                                    'N', 'Node unavai',
                                    'A', 'Activating',
                                    'X', 'Terminated',
                                    'T', 'Terminating',
                                    'V', 'Verifying',
                                    'O', 'Suspending',
                                    'P', 'Suspended',
                                    'Q', 'Resuming',
                                    'R', 'Restarting')||'</TD></TR>'
      FROM (SELECT concurrent_queue_name,
                   COUNT(phase_code) run
              FROM fnd_concurrent_worker_requests
             WHERE phase_code = 'R'
               AND hold_flag != 'Y'
               AND requested_start_date <= SYSDATE
          GROUP BY concurrent_queue_name) running
         ,(SELECT concurrent_queue_name,
                  COUNT(phase_code) pend
             FROM fnd_concurrent_worker_requests
            WHERE phase_code = 'P'
              AND hold_flag != 'Y'
              AND requested_start_date <= SYSDATE
         GROUP BY concurrent_queue_name) pending
        ,apps.fnd_concurrent_queues_vl q
     WHERE q.concurrent_queue_name = running.concurrent_queue_name(+)
       AND q.concurrent_queue_name = pending.concurrent_queue_name(+)
       AND q.enabled_flag = 'Y'
    ORDER BY Decode(q.application_id, 0, Decode(q.concurrent_queue_id, 1, 1,4, 2)),
             Sign(q.max_processes) DESC,
             q.concurrent_queue_name,
             q.application_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM
REM  **********   Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count) **********
REM

prompt <a name="cpadv091"></a><B><U>Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section documents the number of Concurrent Requests run on the instance for the Last Month.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT trunc(REQUESTED_START_DATE), count(*)<BR>
prompt          FROM FND_CONCURRENT_REQUESTS<BR>
prompt          WHERE REQUESTED_START_DATE BETWEEN sysdate-90 AND sysdate<BR>
prompt          group by (trunc(REQUESTED_START_DATE));</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Requested Start Date</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Request Count</B></TD> 
      SELECT '<TR><TD>'||trunc(REQUESTED_START_DATE)||'</TD>'||chr(10)|| 
                 '<TD><div align="right">'||count(*)||'</div></TD></TR>'
        FROM apps.fnd_concurrent_requests
       WHERE requested_start_date BETWEEN SYSDATE-90 AND SYSDATE
      group by (trunc(requested_start_date));
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Profile options changes in last 48 hours *******
REM

prompt <a name="cpadv064"></a><B><U><font size="+2">Profile options changes in last 48 hours</font></B></U><BR><BR>


prompt <a name="cpadv064"></a><B><U>Profile options changes in last 48 hours</B></U><BR>
prompt <BR><b>Description:</b><BR> This section looks to identify Profile options changes in last 48 hours. 
prompt
prompt <BR><BR>


prompt <script type="text/javascript">    function displayRows6sql1(){var row = document.getElementById("s6sql1");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv064"></a>
prompt     <B>Profile options changes in last 48 hours</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="850">
prompt       <blockquote><p align="left">
prompt         select n.user_profile_option_name ,<br> 
prompt         decode(v.level_id,<br>
prompt         10001, 'Site',<br>
prompt         10002, 'Application',<br>
prompt         10003, 'Responsibility',<br>
prompt         10004, 'User',<br>
prompt         10005, 'Server',<br>
prompt         10006, 'Org',<br>
prompt         10007, decode(to_char(v.level_value2), '-1', 'Responsibility',<br>
prompt         decode(to_char(v.level_value), '-1', 'Server','Server+Resp')),'UnDef') ,<br>
prompt         p.last_update_date,<br>
prompt         usr.user_name<br>
prompt         from fnd_profile_options p,<br>
prompt         fnd_profile_option_values v,<br>
prompt         fnd_profile_options_tl n,<br>
prompt         fnd_user usr,<br>
prompt         fnd_application app,<br>
prompt         fnd_responsibility rsp,<br>
prompt         fnd_nodes svr,<br>
prompt         hr_operating_units org<br>
prompt         where p.profile_option_id = v.profile_option_id (+) <br>
prompt         and p.profile_option_name = n.profile_option_name <br>
prompt         and upper(p.profile_option_name) in <br>
prompt        ( select profile_option_name from fnd_profile_options_tl) <br>
prompt         and usr.user_id (+) = v.level_value <br>
prompt         and rsp.application_id (+) = v.level_value_application_id <br>
prompt         and rsp.responsibility_id (+) = v.level_value <br>
prompt         and app.application_id (+) = v.level_value <br>
prompt         and svr.node_id (+) = v.level_value <br>
prompt         and org.organization_id (+) = v.level_value <br>
prompt         and trunc(p.last_update_date) >= trunc(sysdate-2) <br>
prompt         order by n.user_profile_option_name;</p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LEVEL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST UPDATED ON</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>UPDATED BY</B></TD>
     SELECT '<TR><TD>'||n.user_profile_option_name||'</TD>'||chr(10)|| 
                '<TD>'||decode(v.level_id,
                               10001, 'Site',
                               10002, 'Application',
                               10003, 'Responsibility',
                               10004, 'User',
                               10005, 'Server',
                               10006, 'Org',
                               10007, 
                        decode(to_char(v.level_value2), '-1', 'Responsibility',
                        decode(to_char(v.level_value), '-1', 'Server','Server+Resp')),'UnDef')||'</TD>'||chr(10)||
                '<TD>'||p.last_update_date||'</TD>'||chr(10)||
                '<TD>'||usr.user_name||'</TD></TR>' 
       FROM apps.fnd_profile_options       p
           ,apps.fnd_profile_option_values v
           ,apps.fnd_profile_options_tl    n
           ,apps.fnd_user                  usr
           ,apps.fnd_application           app
           ,apps.fnd_responsibility        rsp
           ,apps.fnd_nodes                 svr
           ,apps.hr_operating_units        org
      WHERE p.profile_option_id        = v.profile_option_id (+)
        AND p.profile_option_name      = n.profile_option_name
        AND upper(p.profile_option_name) in ( 
                          select profile_option_name
                            from fnd_profile_options_tl)
        AND usr.user_id (+)            = v.level_value
        AND rsp.application_id (+)     = v.level_value_application_id
        AND rsp.responsibility_id (+)  = v.level_value
        AND app.application_id (+)     = v.level_value
        AND svr.node_id (+)            = v.level_value
        AND org.organization_id (+)    = v.level_value
        AND trunc(p.last_update_date) >= trunc(sysdate-2)
         ORDER BY n.user_profile_option_name;
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
prompt    SELECT DISTINCT <br>
prompt    e.patch_name PATCH_NAME,<br>
prompt    TRUNC(a.last_update_date) LAST_APPLIED_DATE,<br>
prompt    b.applied_flag BUG_APPLIED<br>
prompt    FROM <br>
prompt    ad_bugs a,<br>
prompt    ad_patch_run_bugs b,<br>
prompt    ad_patch_runs c,<br>
prompt    ad_patch_drivers d,<br>
prompt    ad_applied_patches e<br>
prompt    WHERE<br>
prompt    a.bug_id = b.bug_id AND<br>
prompt    b.patch_run_id = c.patch_run_id AND<br>
prompt    c.patch_driver_id = d.patch_driver_id AND<br>
prompt    d.applied_patch_id = e.applied_patch_id AND<br>
prompt    a.last_update_date >= sysdate-90<br>
prompt    ORDER BY 1 DESC;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST UPDATE DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BUG APPLIED</B></TD>
    SELECT  DISTINCT 
             '<TR><TD>'||e.patch_name||'</TD>'||chr(10)|| 
                 '<TD>'||TRUNC(a.last_update_date)||'</TD>'||chr(10)|| 
                 '<TD>'||b.applied_flag||'</TD></TR>'
      FROM apps.ad_bugs            a
          ,apps.ad_patch_run_bugs  b
          ,apps.ad_patch_runs      c
          ,apps.ad_patch_drivers   d
          ,apps.ad_applied_patches e
     WHERE a.bug_id           = b.bug_id 
       AND b.patch_run_id     = c.patch_run_id
       AND c.patch_driver_id  = d.patch_driver_id
       AND d.applied_patch_id = e.applied_patch_id
       AND a.last_update_date >= sysdate-90
    ORDER BY 1 DESC;
prompt </TABLE><P><P> 
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Languages installed in application *******
REM

prompt <a name="cpadv096"></a><B><U>  Languages installed in application  </B></U><BR>

prompt <script type="text/javascript">  function displayRows2sql96(){var row = document.getElementById("s2sql96");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    SELECT '<TR><TD>'||nls_language     ||'</TD>'||chr(10)|| 
               '<TD>'||language_code    ||'</TD>'||chr(10)|| 
               '<TD>'||installed_flag   ||'</TD></TR>'
      FROM apps.fnd_languages
     WHERE installed_flag in ('I','B');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Total User Creation by Monthly    **********
REM

prompt <a name="cpadv097"></a><B><U>Total users created - Month wise</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total count of users created by month wise.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    SELECT  '<TR><TD>'||to_char(creation_date,'YYYY-MM')||'</TD>'||chr(10)|| 
                '<TD><div align="right">'||count(*)||'</div></TD></TR>'
      FROM apps.fnd_user
     WHERE user_id > 1050 and (end_date is null or end_date > sysdate)
     group by to_char(creation_date,'YYYY-MM') order by 1 asc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Active User count by Application   **********
REM

prompt <a name="cpadv098"></a><B><U>Active User count by Module</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total active users based on application module.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    SELECT '<TR><TD>'||fat.application_name||'</TD>'||chr(10)|| 
               '<TD><div align="right">'||
                     (SELECT COUNT(fu.user_id)
                        FROM applsys.fnd_user fu
                       WHERE (fu.end_date IS NULL OR fu.end_date >= TRUNC(SYSDATE))
                         AND EXISTS (SELECT 'x'
                                       FROM fnd_user_resp_groups_direct  furg
                                      WHERE furg.user_id             =  fu.user_id
                                        AND furg.responsibility_application_id        =  fat.application_id))||'</div></TD></TR>'
      FROM apps.fnd_application_vl         fat
          ,apps.fnd_product_installations  fpi
      WHERE 1 = 1
       AND fat.application_id = fpi.application_id 
       AND fpi.status IN ('I','S');
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM  **********   Top 100 Concurrents Programs by No.of Executions   **********
REM

prompt <a name="cpadv099"></a><B><U>Top 100 Concurrents Programs by No.of Executions</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides total active users based on application module.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    select '<TR><TD>'||PNAME||'</TD>'||chr(10)|| 
               '<TD><div align="right">'||TOTAL_EXECUTIONS||'</div></TD></TR>'
      from (
            select a.user_concurrent_program_name as pname,
                   count(actual_completion_date) Total_Executions
              from apps.fnd_conc_req_summary_v a
             where phase_code   = 'C' 
               and status_code  = 'C' 
               and a.requested_start_date > sysdate-30 -- and
            group by a.user_concurrent_program_name) where rownum <100
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

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    SELECT '<TR><TD>'||PNAME||'</TD>'||chr(10)|| 
               '<TD><div align="right">'||total_executions||'</div></TD>'||chr(10)|| 
               '<TD><div align="right">'||avg_hrs_running ||'</div></TD>'||chr(10)|| 
               '<TD><div align="right">'||max_hrs_running ||'</div></TD>'||chr(10)|| 
               '<TD><div align="right">'||min_hrs_running ||'</div></TD></TR>'
     FROM (SELECT a.user_concurrent_program_name as PNAME
                 ,count(ACTUAL_COMPLETION_DATE) Total_Executions
                 ,round(avg((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) avg_Hrs_running
                 ,round(max((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) Max_Hrs_running
                 ,round(min((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2) Min_Hrs_running
             FROM apps.fnd_conc_req_summary_v a 
            WHERE phase_code     = 'C' 
              AND status_code    = 'C' 
              AND a.requested_start_date > sysdate-30 
            group by a.user_concurrent_program_name) 
            where rownum <100
            order by avg_Hrs_running desc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 3 : E-Business Applications Database  Analysis          *******
REM ****************************************************************************************

prompt <a name="section3"></a><B><U><font size="+2">E-Business Applications Database Analysis</font></B></U><BR><BR>

REM
REM ******* INVALID objects in DATABASE *******
REM

prompt <a name="cpadv11"></a><B><U>Invalid Objects in Database</B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the Invalid Objects in Database group by owner.<BR>
prompt

prompt <script type="text/javascript">    function displayRows1sql3(){var row = document.getElementById("s1sql3");if (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv11"></a>
prompt     <B>Invalid Objects in Database</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select owner,object_name<br>
prompt          from all_objects<br>
prompt           where status = 'INVALID' order by owner;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT OWNER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OBJECT NAME</B></TD>
    SELECT '<TR><TD>'||owner||'</TD>'||chr(10)||
               '<TD>'||object_name||'</TD></TR>'
      FROM all_objects
     WHERE status = 'INVALID' 
     ORDER BY owner;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM ******* Database size *******
REM
prompt <a name="cpadv50"></a><B><U> Database size </B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the database size utilization and the free space available<BR>
prompt
REM prompt <BR><b>Action:</b><BR> Database size.<BR>
prompt <BR>
prompt <script type="text/javascript"> function displayRows1sql50(){var row = document.getElementById("s1sql50");if (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv50"></a>
prompt     <B> Database size </B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql50()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql50" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="45">
prompt       <blockquote><p align="left">
prompt  select round(sum(used.bytes) / 1024 / 1024 / 1024 )  "Database Size in GB" <br>
prompt ,round(sum(used.bytes)/1024/1024/1024) - round(free.p/1024/1024/1024) "Used space in GB" <br>
prompt  , round(free.p/1024/1024/1024) "Free space in GB" <br>
prompt  from    (select bytes from v$datafile  union all <br>
prompt  select bytes  from  v$tempfile  union  all <br>
prompt  select  bytes  from  v$log) used , (select sum(bytes) as p <br>
prompt  from dba_free_space) free group by free.p;<br>
prompt         </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Database Size in GB</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Free space in GB </B></TD>

    select '<TR><TD>'||round(sum(used.bytes) / 1024 / 1024 / 1024 )||'</TD>'||chr(10)||
              '<TD>'||round(free.p/1024/1024/1024)||'</TD></TR>'
      from (select bytes 
              from v$datafile  
            union all
            select bytes  
              from  v$tempfile  
            union  all
            select  bytes  
              from  v$log) used 
          ,(select sum(bytes) as p
              from dba_free_space) free 
    group by free.p;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Database Configuration Details  *******
REM

prompt <a name="cpadv51"></a><B><U>Database Configuration Details </B></U><BR>

prompt <script type="text/javascript">    function displayRows1sql5(){var row = document.getElementById("s1sql5");if (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv5"></a>
prompt     <B>Database Summary</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select PLATFORM_NAME,CREATED,LOG_MODE,FORCE_LOGGING,FLASHBACK_ON,GUARD_STATUS from v$database; <br>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PLATFORM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CREATED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LOG_MODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FORCE_LOGGING</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FLASHBACK_ON</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>GUARD_STATUS</B></TD>

    select '<TR><TD>'||PLATFORM_NAME||'</TD>'||chr(10)||
               '<TD>'||CREATED||'</TD>'||chr(10)||
               '<TD>'||LOG_MODE||'</TD>'||chr(10)||
               '<TD>'||FORCE_LOGGING||'</TD>'||chr(10)||
               '<TD>'||FLASHBACK_ON||'</TD>'||chr(10)||
               '<TD>'||GUARD_STATUS||'</TD></TR>'
      from v$database;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Database Parameters  *******
REM

prompt <a name="cpadv51"></a><B><U>Database Parameters </B></U><BR>

prompt <script type="text/javascript">    function displayRows1sql5(){var row = document.getElementById("s1sql5");if (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv5"></a>
prompt     <B>Database parameter details</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select NAME,VALUE from v\$parameter
where NAME in ('sga_target','shared_pool_size','job_queue_processes','cpu_count','open_cursors','pga_aggregate_target','sessions','processes','instance_type','db_block_size','compatible','db_recovery_file_dest_size') <br>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>

    select '<TR><TD>'||NAME||'</TD>'||chr(10)||
               '<TD>'||VALUE||'</TD></TR>'
      from v$parameter
     where NAME in ('sga_target','shared_pool_size','job_queue_processes','cpu_count','open_cursors','pga_aggregate_target','sessions','processes','instance_type','db_block_size','compatible','db_recovery_file_dest_size');
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Database Objects Count  *******
REM

prompt <a name="cpadv51"></a><B><U>Database Objects Count </B></U><BR>

REM
REM ******* Database Active User Details  *******
REM

prompt <a name="cpadv51"></a><B><U>Database  Active User Details </B></U><BR>

prompt <script type="text/javascript">    function displayRows1sql5(){var row = document.getElementById("s1sql5");if (row.style.display == '')  row.style.display = 'none';     else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="cpadv5"></a>
prompt     <B>Database Active User Details e</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select USERNAME,DEFAULT_TABLESPACE from dba_users where account_status in ('OPEN'); <br>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USERNAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEFAULT_TABLESPACE</B></TD>

    select '<TR><TD>'||USERNAME||'</TD>'||chr(10)||
               '<TD>'||DEFAULT_TABLESPACE||'</TD></TR>'
      from all_users;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


spool off
set heading on
set feedback on  
set verify on
exit
;
