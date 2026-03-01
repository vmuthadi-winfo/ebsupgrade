REM HEADER
REM   $Header: ebs_data_reconciliator.sql v1.01  $
REM   
REM   ebs_data_reconciliator.sql
REM     
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM       sqlplus apps/<password>    @ebs_data_reconciliator.sql
REM
REM   
REM   Output should take ~5 to ~10 minutes or less.
REM   
REM    EBS_DATA_RECONCILIATOR_<SID>_<HOSTNAME>.html
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
SPOOL EBS_DATA_RECONCILIATOR_XX..html


VARIABLE GSM            VARCHAR2(1);
VARIABLE ITEM_CNT        NUMBER;
VARIABLE SID             VARCHAR2(20);
VARIABLE HOST            VARCHAR2(30);
VARIABLE APPS_REL        VARCHAR2(10);
VARIABLE SYSDATE        VARCHAR2(22);
VARIABLE WF_ADMIN_ROLE    VARCHAR2(320);
VARIABLE APPLPTMP       VARCHAR2(240);


declare

    admin_email         varchar2(40);
    gsm                 varchar2(1);
    item_cnt            number;
    sid                 varchar2(20);
    host                varchar2(30);
    apps_rel            varchar2(10);
    sysdate                varchar2(22);
    wf_admin_role         varchar2(320);
    applptmp            varchar2(240);


begin

  select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;

end;
/                              


alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

ALTER SESSION SET NLS_LANGUAGE = 'AMERICAN';

prompt <HTML>
prompt <HEAD>
prompt <TITLE>EBS E-Business Applications Data Analyser</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 10pt; font-family: calibri; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">EBS E-Business Applications Data Analysis for 
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

prompt       <a href="#section2"><b><font size="+1">E-Business Suite Application Services Analysis</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#cpadv1"> - Installed modules and its patch levels </a><br>
prompt           <a href="#bgdata"> - Business Group </a><br>
prompt           <a href="#sobdata"> - Set of Books </a><br>
prompt           <a href="#ledata"> - Legal Entitites </a><br>
prompt           <a href="#oudata"> - Operating Units </a><br>
prompt           <a href="#invorgsdata"> - Inventory Organizations </a><br>
prompt         <a href="#apmdata"> - AP Module Details </a><br>
prompt         <a href="#armdata"> - AR Module Details </a><br>
prompt         <a href="#cmmdata"> - CM Module Details </a><br>
prompt         <a href="#famdata"> - FA Module Details </a><br>
prompt         <a href="#glmdata"> - GL Module Details </a><br>
prompt         <a href="#opmmdata"> - OPM Module Details </a><br>
prompt         <a href="#ommdata"> - OM Module Details </a><br>
prompt         <a href="#qpmdata"> - Pricing Module Details </a><br>
prompt         <a href="#pomdata"> - Pruchasing Module Details </a><br>
prompt         <a href="#cped"> - Concurrent Program Execution Details </a><br>
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
                '<TD>'||decode(support_cp, 'Y','YES','N','NO')   ||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_forms, 'Y','YES','N','NO')||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_web, 'Y','YES','N','NO')  ||'</TD>'||chr(10)|| 
                '<TD>'||decode(support_db, 'Y','YES','N','NO')   ||'</TD></TR>'
     from fnd_nodes 
    where node_name<>'AUTHENTICATION';
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
    select '<TR><TD>'||instance_name||'</TD>' ||chr(10)|| 
               '<TD>'||release_name||'</TD>'  ||chr(10)|| 
               '<TD>'||host_name||'</TD>'     ||chr(10)|| 
               '<TD>'||startup_time||'</TD>'  ||chr(10)|| 
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

prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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
    SELECT '<TR><TD>'||fo.profile_option_name||'</TD>'||chr(10)|| 
               '<TD><div align="right">'||fv.profile_option_value||'</div></TD></TR>'
      FROM apps.fnd_profile_option_values fv
          ,apps.fnd_profile_options fo
     WHERE fo.profile_option_id=fv.profile_option_id 
       AND fv.level_value = 0
       AND fo.profile_option_name in ('APPS_FRAMEWORK_AGENT','APPS_AUTH_AGENT','FND_APEX_URL','FND_EXTERNAL_ADF_URL','INV_EBI_SERVER_URL','ICX_FORMS_LAUNCHER');
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 2 : E-Business Suite Application Services Analysis          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">E-Business Suite Application Services Analysis</font></B></U><BR><BR>


REM
REM ******* Installed modules and its patch levels *******
REM


prompt <script type="text/javascript">  function displayRows2sql4(){var row = document.getElementById("s2sql4");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
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

    select '<TR><TD>'||fa.application_short_name ||'</TD>'||chr(10)|| 
               '<TD>'||fat.application_name      ||'</TD>'||chr(10)|| 
               '<TD>'||fpi.patch_level           ||'</TD>'||chr(10)||
               '<TD>'||flv.meaning               ||'</TD></TR>'
      from apps.fnd_application           fa
          ,apps.fnd_application_tl        fat
          ,apps.fnd_product_installations fpi
          ,apps.fnd_lookup_values         flv
     where fa.application_id   = fat.application_id
       and fat.application_id  = fpi.application_id
       and fat.language        = 'US'
       and fpi.status          = flv.lookup_code
       and flv.lookup_type     = 'FND_PRODUCT_STATUS'
       and flv.language        = 'US'
       and flv.meaning        != 'Not installed'
    order by meaning
            ,application_short_name;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Business Group Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Business Group Details</font></B></U><BR><BR>


REM
REM ******* Business Group Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="bgdata"></a>
prompt     <B>Business Group Details</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Business Group Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Date From </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Date To </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Short Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Legislation Code </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Currency Code </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Enabled </B></TD>
    
    SELECT '<TR><TD>'|| otl.name		         ||'</TD>'||chr(10)||
               '<TD>'||o.date_from 		     ||'</TD>'||chr(10)||
               '<TD>'||o.date_to		     ||'</TD>'||chr(10)||
               '<TD>'||o3.org_information1   ||'</TD>'||chr(10)||
               '<TD>'||o3.org_information9   ||'</TD>'||chr(10)||
               '<TD>'||o3.org_information10  ||'</TD>'||chr(10)||
               '<TD>'||o4.org_information2   ||'</TD>
           </TR>'
     FROM apps.hr_all_organization_units    o
         ,apps.hr_all_organization_units_tl otl
         ,apps.hr_organization_information  o2
         ,apps.hr_organization_information  o3
         ,apps.hr_organization_information  o4
    WHERE o.organization_id          = otl.organization_id
      AND o.organization_id          = o2.organization_id (+)
      AND o.organization_id          = o3.organization_id
      AND o.organization_id          = o4.organization_id
      AND o3.org_information_context = 'Business Group Information'
      AND o2.org_information_context (+) = 'Work Day Information'
      AND o4.org_information_context = 'CLASS'
      AND o4.org_information1        = 'HR_BG'
      AND o4.org_information2        = 'Y'
      AND otl.language               = 'US'
      AND o4.org_information2        = 'Y';

prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Set Of Books Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Set Of Books Details</font></B></U><BR><BR>


REM
REM ******* Set Of Books Details  *******
REM
prompt <script type="text/javascript">  function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="sobdata"></a>
prompt     <B>Set Of Books Details</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Description </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Short Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Currency Code </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Accounted Period Type </B></TD>

prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Latest Opened Period Name</B></TD>

prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Latest Encumbrance Year </B></TD>

    SELECT '<TR><TD>'||NAME                     ||'</TD>'||chr(10)||
               '<TD>'||description              ||'</TD>'||chr(10)|| 
               '<TD>'||short_name               ||'</TD>'||chr(10)||
               '<TD>'||currency_code            ||'</TD>'||chr(10)|| 
               '<TD>'||accounted_period_type    ||'</TD>'||chr(10)|| 
               '<TD>'||latest_opened_period_name||'</TD>'||chr(10)|| 
               '<TD>'||latest_encumbrance_year  ||'</TD></TR>'
      FROM apps.gl_sets_of_books;

prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : Legal Entity Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Legal Entity Details</font></B></U><BR><BR>


REM
REM ******* Legal Entity Details  *******
REM
prompt <script type="text/javascript">  function displayRows2sql7(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="ledata"></a>
prompt     <B>Legal Entity Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"> </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Legal Entity Identifier </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Country </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Effective From </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Effective To </B></TD>



    SELECT '<TR><TD>'||NAME                   ||'</TD>'||chr(10)||
               '<TD>'||legal_entity_identifier||'</TD>'||chr(10)||
               '<TD>'||country                ||'</TD>'||chr(10)||
               '<TD>'||effective_from         ||'</TD>'||chr(10)||
               '<TD>'||effective_to           ||'</TD>'||chr(10)||
               '</TR>'
      FROM apps.xle_firstparty_information_v;

prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 3 : Operating Unit Entity Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Operating Unit Details</font></B></U><BR><BR>


REM
REM ******* Operating Unit Details  *******
REM
prompt <script type="text/javascript">  function displayRows2sql8(){var row = document.getElementById("s2sql18");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="oudata"></a>
prompt     <B>Operating Unit Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql18" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Name </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Date From </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Date To </B></TD>

    SELECT '<TR><TD>'||NAME         ||'</TD>'||chr(10)||
               '<TD>'||DATE_FROM    ||'</TD>'||chr(10)||
               '<TD>'||DATE_TO      ||'</TD></TR>'
     FROM apps.hr_operating_units
    WHERE organization_id IN
          (SELECT operating_unit
             FROM apps.org_organization_definitions
            WHERE disable_date IS NULL)
      AND (TRUNC(date_to) >=trunc(sysdate) or date_to is null);
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 3 : Inventory Organization Details          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">Inventory Organization Details</font></B></U><BR><BR>


REM
REM ******* Inventory Organization Details  *******
REM
prompt <script type="text/javascript">  function displayRows2sql9(){var row = document.getElementById("s2sql19");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="invorgsdata"></a>
prompt     <B>Inventory Organization Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql19" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Organization Name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Organization Code</B></TD>
     
    SELECT '<TR><TD>'||ood.organization_name||'</TD>'||chr(10)||
               '<TD>'||ood.organization_code||'</TD></TR>'
      FROM apps.org_organization_definitions ood
          ,apps.mtl_parameters mp
     WHERE ood.disable_date IS NULL
       AND mp.organization_id = ood.organization_id
    ORDER BY ood.organization_code;
 
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : AP Module Data          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">AP Module Data</font></B></U><BR><BR>


REM
REM ******* AP Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql14(){var row = document.getElementById("s2sql14");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="apmdata"></a>
prompt     <B>AP Module Data Analysis</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

    SELECT '<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
               '<TD>'||"CountR12"   ||'</TD></TR>'
      FROM (
         SELECT 'Total Number of Open Invoices'   Description
                ,COUNT(DISTINCT aia.invoice_id)   CountR12 
                ,8                                order_by                
           FROM apps.ap_invoices_all          aia
               ,apps.ap_payment_schedules_all aps 
          WHERE 1 = 1 
            AND aia.invoice_id               = aps.invoice_id 
            AND aps.amount_remaining         <> 0
            AND aia.invoice_type_lookup_code = 'STANDARD'
            AND aia.cancelled_date IS NULL
         UNION
         SELECT 'Total Number of Closed Invoices' Description
                ,COUNT(DISTINCT aia.invoice_id)   CountR12
                ,9                                order_by                
           FROM apps.ap_invoices_all          aia
               ,apps.ap_payment_schedules_all aps 
          WHERE 1 = 1 
            AND aia.invoice_id               = aps.invoice_id 
            AND aps.amount_remaining         = 0
            AND aia.invoice_type_lookup_code = 'STANDARD'
            AND aia.cancelled_date IS NULL
         UNION
         SELECT 'No of Payment Terms'             Description
                ,COUNT (*)                        CountR12  
                ,6                                order_by                
           FROM apps.ap_terms
          WHERE enabled_flag ='Y'
            AND TRUNC(SYSDATE) BETWEEN start_date_active AND NVL(end_date_active,SYSDATE+1)
         UNION
         SELECT 'No of Tax Codes'                 Description
               ,COUNT (*)                         CountR12
                ,7                                order_by               
           FROM apps.ap_tax_codes_all
          WHERE NVL(inactive_date,SYSDATE) >= TRUNC(SYSDATE)
         UNION
         SELECT 'No of Suppliers'                 Description
                ,COUNT(*)                         CountR12 
                ,1                                order_by
           FROM apps.po_vendors
          WHERE vendor_type_lookup_code = 'VENDOR'
            AND enabled_flag = 'Y'
            AND SYSDATE BETWEEN NVL(start_date_active,SYSDATE-1) AND NVL(end_date_active,SYSDATE+1)
         UNION
         SELECT 'No of Supplier Sites'            Description
                ,COUNT(*)                         CountR12 
                ,2                                order_by                
           FROM apps.po_vendor_sites_all pos
               ,apps.po_vendors          pov
          WHERE pos.vendor_id  = pov.vendor_id
            AND pov.enabled_flag = 'Y'
            AND SYSDATE BETWEEN NVL(pov.start_date_active,SYSDATE-1) AND NVL(pov.end_date_active,SYSDATE+1)
            AND NVL(pos.inactive_date,SYSDATE) >= TRUNC(SYSDATE)
         UNION
         SELECT 'No of Branches'             Description
               ,COUNT(*)                     CountR12
               ,4                            order_by
           FROM apps.ap_bank_branches
          WHERE NVL(end_date,SYSDATE+1) >SYSDATE
         UNION
         SELECT 'No of  Bank Accounts'            Description
                ,COUNT(*)                         CountR12
                ,5                                order_by                
          FROM apps.ap_bank_accounts_all
         WHERE bank_branch_id IN (
                SELECT bank_branch_id
                  FROM apps.ap_bank_branches
                 WHERE NVL(end_date,SYSDATE+1) >SYSDATE))
    ORDER BY order_by;
    
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 3 : AR Module Data          *******
REM ****************************************************************************************

prompt <a name="section212"></a><B><U><font size="+2">AR Module Data</font></B></U><BR><BR>
REM
REM ******* AR Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="armdata"></a>
prompt     <B>AR Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

    SELECT '<TR><TD>'||Description||'</TD>'||chr(10)|| 
               '<TD>'||CountR12   ||'</TD></TR>'
      FROM (SELECT 'Number of  Active Customers'     Description
                   ,count(*)                         CountR12 
                   ,1                                order_by
              FROM apps.hz_parties 
             WHERE  status='A'
            UNION
            SELECT 'Number of  Inactive Customers'     Description
                   ,count(*)                           CountR12 
                   ,2                                  order_by
              FROM apps.hz_parties 
             WHERE status='I'
            UNION
            SELECT 'Number of Active Customer Sites'      Description
                   ,count(*)                              CountR12
                   ,3                                  order_by               
              FROM apps.hz_party_sites     hpsa
                  ,apps.hz_party_site_uses hpsua 
             WHERE hpsa.party_site_id = hpsua.party_site_id 
               AND hpsa.status='A'
            UNION
            SELECT 'Number of Inctive Customer Sites'     Description
                   ,count(*)                              CountR12
                   ,4                                     order_by               
              FROM apps.hz_party_sites     hpsa
                  ,apps.hz_party_site_uses hpsua 
             WHERE hpsa.party_site_id = hpsua.party_site_id 
               AND hpsa.status='I'
            UNION
            SELECT 'Number of  Payment Terms'             Description
                   ,count(*)                              CountR12
                   ,5                                     order_by               
              FROM apps.ra_terms
             WHERE TRUNC(SYSDATE) BETWEEN start_date_active AND NVL(end_date_active,TRUNC(SYSDATE))
            UNION
            SELECT 'Number of Transaction Types'          Description
                   ,count(*)                              CountR12
                   ,6                                     order_by               
              FROM ra_cust_trx_types_all
             WHERE status ='A'
            UNION
            SELECT 'Number of Transaction Types'         Description
                   ,count(DISTINCT rcta.customer_trx_id)  CountR12
                   ,7                                  order_by               
              FROM apps.ra_customer_trx_all       rcta
                  ,apps.ar_payment_schedules_all  apsa
                  ,apps.ra_cust_trx_types_all rctt
             WHERE apsa.customer_trx_id = rcta.customer_trx_id
               AND  rctt.cust_trx_type_id = rcta.cust_trx_type_id
               AND rcta.complete_flag = 'Y'
               AND apsa.class IN ('INV','DM')
               AND apsa.status = 'OP'
               AND rctt.org_id = rcta.org_id)
    ORDER BY order_by;
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 4 : Cash Management Module Data          *******
REM ****************************************************************************************

prompt <a name="section213"></a><B><U><font size="+2">Cash Management Module Data</font></B></U><BR><BR>
REM
REM ******* Cash Management Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cmmdata"></a>
prompt     <B>Cash Management Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Data Entity Description </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

    SELECT '<TR><TD>'||Description||'</TD>'||chr(10)|| 
               '<TD>'||CountR12||'</TD></TR>'
      FROM ( SELECT 'Number of Open Transactions awaiting Clearing in Cash management' Description
                    ,COUNT(*) CountR12 
               FROM apps.ce_available_transactions_tmp
             UNION
             SELECT 'Bank Statements-Lines' Description
                  ,count(*) CountR12 
               FROM apps.ce_statement_lines
             UNION
             SELECT 'Bank Statements-Headers' Description
                    ,count(*) CountR12 
               FROM apps.ce_statement_headers);
           
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM ******* Section 4 : Fixed Assets Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">Fixed Assets Module Data</font></B></U><BR><BR>
REM
REM ******* Fixed Assets Management Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql8(){var row = document.getElementById("s2sql8");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="famdata"></a>
prompt     <B>Fixed Assets Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

    SELECT '<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
               '<TD>'||"CountR12"||'</TD></TR>'
      from (
            SELECT 'Fixed Assests'"Module", 'Number of Assets with type as CAPITALIZED'"Description", COUNT(*) "CountR12" 
              FROM fa_additions_b 
             WHERE asset_type IN ('CAPITALIZED') GROUP BY asset_type
            UNION
            SELECT 'Fixed Assests'"Module", 'Number of Assets with type as CIP'"Description", COUNT(*) "CountR12" 
              FROM fa_additions_b 
             WHERE asset_type IN ('CIP')
            UNION
            SELECT 'Fixed Assests'"Module", 'Total Number of Book Controls'"Description", count(*) "CountR12" 
              FROM fa_book_controls);
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM ******* Section 4 : GL Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">GL Module Data</font></B></U><BR><BR>
REM
REM ******* Fixed Assets Management Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="glmdata"></a>
prompt     <B>GL Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

SELECT 
'<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
'<TD>'||"CountR12"||'</TD></TR>'
from (
SELECT 'Total No of Journal Batches'"Description" , Count(je_batch_id) "CountR12" FROM gl_je_batches
UNION
SELECT 'Total Number of Journal Headers'"Description" , Count(je_header_id) "CountR12" from gl_je_headers
UNION
SELECT 'Total Number of Journal Lines'"Description" , Count(*) "CountR12" from gl_je_lines
UNION
SELECT 'Number of records in General Ledger Daily Exchange Rates table'"Description" , count(*) "CountR12" FROM gl_daily_rates
UNION
SELECT 'Number of records in General Ledger Translation Rates table'"Description", count(*) "CountR12" FROM gl_translation_rates
UNION
SELECT 'Total Number of Enabled Currencies'"Description" , count(*) "CountR12" from fnd_currencies where enabled_flag='Y'
UNION
SELECT 'Total Number of Disabled Currencies'"Description" , count(*) "CountR12" from fnd_currencies where enabled_flag='N'
UNION
SELECT 'Total No of EAM Work Orders with status other than Closed'"Description" , count(we.wip_entity_id) "CountR12" FROM wip_entities we,wip_discrete_jobs wdj  WHERE we.wip_entity_id=wdj.wip_entity_id AND wdj.organization_id=we.organization_id AND we.entity_type in (6,7) AND wdj.status_type not in (12,15)
UNION
SELECT 'EAM Work Orders with status as  Closed'"Description", count(we.wip_entity_id) "CountR12" FROM wip_entities we,wip_discrete_jobs wdj  WHERE we.wip_entity_id=wdj.wip_entity_id AND we.entity_type in (6,7) AND wdj.status_type in  (12,15) AND months_between(sysdate,we.creation_date)<10);
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 4 : OPM Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">OPM Module Data</font></B></U><BR><BR>
REM
REM ******* Fixed Assets Management Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql10(){var row = document.getElementById("s2sql10");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="opmmdata"></a>
prompt     <B>OPM Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

SELECT 
'<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
'<TD>'||"CountR12"||'</TD></TR>'
from (
SELECT 'No. of Expired Lots'"Description", COUNT (*) "CountR12"  FROM  apps.ic_lots_mst WHERE lot_no <> 'DEFAULTLOT' AND TRUNC(EXPIRE_DATE) <= TRUNC(SYSDATE)  AND EXPIRE_DATE IS NOT NULL
UNION
SELECT 'No. of pending transactions  for all whses'"Description", COUNT (*)   "CountR12"  FROM apps.ic_tran_pnd    WHERE completed_ind = 0
UNION
SELECT 'Count of categories' "Description", COUNT (*)   "CountR12"  FROM apps.mtl_categories_b
UNION
SELECT 'No of OPM companies'"Description", COUNT(DISTINCT co_code) "CountR12" FROM apps.sy_orgn_mst_b
UNION
SELECT 'No of Legal Entities'"Description",  COUNT(*) "CountR12" FROM apps.hr_legal_entities
UNION
SELECT 'No of Plants'"Description", COUNT(*) "CountR12" FROM apps.sy_orgn_mst_b WHERE  plant_ind=1
UNION
SELECT 'No of Warehouses'"Description", COUNT(*) "CountR12" FROM apps.ic_whse_mst
UNION
SELECT 'No of Labs'"Description", COUNT(*)  "CountR12" FROM apps.sy_orgn_mst_b WHERE plant_ind=2
UNION
SELECT 'No. of warehouses as Inventory Orgs'"Description",  count(*)  "CountR12" FROM apps.ic_whse_mst iwm,mtl_parameters mtl WHERE iwm.mtl_organization_id=mtl.organization_id
UNION
SELECT 'No. of stock locators'"Description", count(*) "CountR12" FROM apps.ic_loct_mst WHERE inventory_location_id IS NOT NULL
UNION
SELECT 'No. of Active Items'"Description", COUNT(*) "CountR12" FROM apps.ic_item_mst_b  WHERE inactive_ind = 0
UNION
SELECT 'No. of Lots Respective to Items'"Description", COUNT(*) "CountR12" FROM apps.ic_lots_mst WHERE lot_no <> 'DEFAULTLOT'
UNION
SELECT 'No. of Expired Lots'"Description", COUNT(*) "CountR12" FROM apps.ic_lots_mst WHERE lot_no <> 'DEFAULTLOT' AND TRUNC(EXPIRE_DATE) <= TRUNC(SYSDATE) AND EXPIRE_DATE IS NOT NULL
UNION
SELECT 'No. of pending transactions for all whses'"Description", COUNT(*)  "CountR12" FROM apps.ic_tran_pnd WHERE completed_ind=0
UNION
SELECT 'No. of completed transactions for all whses'"Description", SUM(cnt) "CountR12" FROM (SELECT COUNT(*) cnt FROM apps.ic_tran_pnd WHERE completed_ind = 1 UNION SELECT COUNT(*) cnt FROM ic_tran_cmp)
UNION
SELECT 'Count of Lot No'"Description", COUNT(lot_no) "CountR12" FROM apps.ic_lots_mst WHERE lot_no!='DEFAULTLOT'
UNION
SELECT 'Count of Sublot No'"Description", COUNT(sublot_no) "CountR12" FROM apps.ic_lots_mst WHERE lot_no!='DEFAULTLOT'
UNION
SELECT 'Count of categories'"Description", COUNT(*) "CountR12" FROM apps.mtl_categories_b
UNION
SELECT 'Count of Item'"Description", COUNT(DISTINCT inventory_item_id) "CountR12" FROM apps.mtl_system_items_b
UNION
SELECT 'Count Assigned Categories of Items'"Description", COUNT(category_id) "CountR12"  FROM apps.mtl_item_categories
UNION
SELECT 'No. of  Reason Codes'"Description", COUNT(*) "CountR12" FROM apps.sy_reas_cds_b
UNION
SELECT 'No. of  Status Codes'"Description", COUNT(*) "CountR12"  FROM apps.IC_LOTS_STS
UNION
SELECT 'No. of  CREI Transactions'"Description", COUNT(*) "CountR12" FROM apps.IC_TRAN_CMP WHERE doc_type='CREI'
UNION
SELECT 'No. of  ADJI Transactions'"Description", COUNT(*) "CountR12" FROM apps.IC_TRAN_CMP WHERE doc_type='ADJI'
UNION
SELECT 'No. of  TRNI Transactions'"Description", COUNT(*) "CountR12" FROM apps.IC_TRAN_CMP WHERE doc_type='TRNI'
UNION
SELECT 'No. of  Inventory Transfers'"Description", COUNT(*) "CountR12" FROM apps.ic_xfer_mst
UNION
SELECT 'No. of  OMSO Transactions'"Description", COUNT(*) "CountR12" FROM apps.IC_TRAN_PND WHERE doc_type='OMSO'
UNION
SELECT 'No. of  PORC Transactions'"Description", COUNT(*) "CountR12" FROM apps.IC_TRAN_PND WHERE doc_type='PORC'
UNION
SELECT 'No. of Active Formulas'"Description", COUNT(*) "CountR12" FROM apps.fm_form_mst_b WHERE inactive_ind=0
UNION
SELECT 'No. of Active Routings'"Description", COUNT(*) "CountR12" FROM apps.gmd_routings_b WHERE inactive_ind=0
UNION
SELECT 'No. of Active Operations'"Description", COUNT(*) "CountR12" FROM apps.gmd_operations_b WHERE inactive_ind=0
UNION
SELECT 'No. of  Recipes'"Description", COUNT(*) "CountR12" FROM apps.gmd_recipes_b
UNION
SELECT 'Count of Recipe Validity Rules'"Description", COUNT(*) "CountR12" from apps.gmd_recipe_validity_rules
UNION
SELECT 'No. of  Pending Batches'"Description", COUNT(*) "CountR12" FROM apps.gme_batch_header WHERE batch_status=1
UNION
SELECT 'No. of  WIP Batches'"Description", COUNT(*) "CountR12" FROM apps.gme_batch_header WHERE batch_status=2
UNION
SELECT 'No. of  Completed Batches'"Description", COUNT(*) "CountR12" FROM apps.gme_batch_header WHERE batch_status=3
UNION
SELECT 'No. of  Closed Batches'"Description", COUNT(*) "CountR12" FROM apps.gme_batch_header WHERE batch_status=4
UNION
SELECT 'No. of Cost Component Classes'"Description", COUNT(*) "CountR12" FROM apps.cm_cmpt_mst_b
UNION
SELECT 'No. of  Cost Analysis Codes'"Description", COUNT(*) "CountR12" FROM apps.CM_ALYS_MST
UNION
SELECT 'No. of Cost Component Groups'"Description", COUNT(*) "CountR12" FROM apps.CM_CMPT_GRP
UNION
SELECT 'No. of  open cost calendar(may have more than one cldr) periods'"Description", COUNT(*) "CountR12" FROM apps.CM_CLDR_DTL WHERE period_status=0
UNION
SELECT 'No. of  Resources with no cost'"Description", COUNT(*) "CountR12" FROM apps.cm_rsrc_dtl WHERE nominal_cost=0);
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>





REM **************************************************************************************** 
REM ******* Section 4 : OM Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">OM Module Data</font></B></U><BR><BR>
REM
REM ******* OM Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql11(){var row = document.getElementById("s2sql11");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="ommdata"></a>
prompt     <B>OM Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

SELECT 
'<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
'<TD>'||"CountR12"||'</TD></TR>'
from (
SELECT 'No of ship Methods Defined in the System'"Description", count(*) "CountR12" from apps.FND_LOOKUP_VALUES where lookup_type like 'SHIP_METHOD'
UNION
SELECT 'Total No of Sales Orders'"Description", count(order_number) "CountR12" from apps.oe_order_headers_all
UNION
SELECT 'Total No of Sales Orders with Header Status as Booked'"Description", count(*) "CountR12" from apps.oe_order_headers_all WHERE flow_status_code='BOOKED'
UNION
SELECT 'Total No of Sales Orders with Header Status as Entered'"Description", count(*) "CountR12" from apps.oe_order_headers_all WHERE flow_status_code='ENTERED'
UNION
SELECT 'Total No of Closed Sales Orders'"Description", count(*) "CountR12" from apps.oe_order_headers_all WHERE flow_status_code='CLOSED'
UNION
SELECT 'Total No of  Deliveries whose Shipping Line status as STAGED/PICK CONFIRMED'"Description", count(*) "CountR12" from apps.wsh_delivery_details where released_status='Y'
UNION
SELECT 'Total No of  Deliveries are there whose Shipping Line status as RELEASED TO WAREHOUSE'"Description", count(*) "CountR12" from wsh_delivery_details where released_status='S'
UNION
SELECT 'Total No of  Deliveries whose Shipping Line status as READY TO RELEASE'"Description", count(*) "CountR12" from apps.wsh_delivery_details where released_status='R'
UNION
SELECT 'Total No of Customers'"Description", count(customer_id) "CountR12" from apps.ra_customers
UNION
SELECT 'Total No of  Active Customers'"Description", count(customer_id) "CountR12" from apps.ra_customers where status='A'
UNION
SELECT 'Total No of Order Types defined in the System'"Description", count(name) "CountR12" from apps.oe_transaction_types_tl);
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 4 : Pricing Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">Pricing Module Data</font></B></U><BR><BR>
REM
REM ******* Pricing Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql12(){var row = document.getElementById("s2sql12");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="qpmdata"></a>
prompt     <B>Pricing Module Data Analysis</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

SELECT 
'<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
'<TD>'||"CountR12"||'</TD></TR>'
from (
SELECT distinct 'Total No of Active Price Lists'"Description", count(T.Name) "CountR12" from apps.QP_LIST_HEADERS_B B,QP_LIST_HEADERS_TL T where B.LIST_HEADER_ID=T.LIST_HEADER_ID and b.active_flag='Y' and (b.end_date_active is null or trunc(b.end_date_active) >= trunc(Sysdate))
UNION
SELECT DISTINCT 'Total No of Price Lists' "Description", count(name) "CountR12" from apps.QP_LIST_HEADERS_TL
UNION
SELECT 'Total No of Qualifiers'"Description", count(qualifier_id) "CountR12" from apps.qp_qualifiers
UNION
SELECT DISTINCT 'Total No of Active Qualifiers'"Description", count(*) "CountR12" from apps.qp_qualifiers where end_date_active is null or trunc(end_date_active) >=trunc(Sysdate)
UNION
SELECT 'Total No of  non-USD currency price'"Description", count(*) "CountR12" from apps.QP_LIST_HEADERS_B where currency_code != 'USD');

prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 4 : Purchasing Module Data          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">Purchasing Module Data</font></B></U><BR><BR>
REM
REM ******* Purchasing Module Data *******
REM
prompt <script type="text/javascript">  function displayRows2sql13(){var row = document.getElementById("s2sql13");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="pomdata"></a>
prompt     <B>Purchasing Module Data Analysis</B></font></TD>
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
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATA ENTITY DESCRIPTION </B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B> Record Count </B></TD>

SELECT 
'<TR><TD>'||"Description"||'</TD>'||chr(10)|| 
'<TD>'||"CountR12"||'</TD></TR>'
from (
SELECT 'Total No of Standard Purchase Orders'"Description",count(*) "CountR12" from apps.po_headers_all where type_lookup_code = 'STANDARD' group by type_lookup_code
UNION
SELECT 'Total No of Standard Purchase Orders with Approved Status'"Description", count(*) "CountR12" from apps.po_headers_all Where authorization_status='APPROVED'
UNION
SELECT 'Total No of Standard Purchase Orders with Closed Status'"Description", count(*) "CountR12" from apps.po_headers_all Where authorization_status='CLOSED'
UNION
SELECT 'Total No of  Purchase Order with Status other than APPROVED'"Description", count(*) "CountR12" from apps.po_headers_all Where authorization_status not in ('CLOSED','APPROVED')
UNION
SELECT 'Total No of  Blanket Purchase Orders'"Description", count(po_header_id) "CountR12" from apps.po_headers_all where type_lookup_code='BLANKET'
UNION
SELECT 'Total No of  Contract Purchase Orders'"Description", count(po_header_id) "CountR12" from apps.po_headers_all where type_lookup_code='CONTRACT'
UNION
SELECT 'Total No of  Planned Purchase Orders'"Description", count(po_header_id) "CountR12" from apps.po_headers_all where type_lookup_code='PLANNED'
UNION
SELECT 'Total No of  Blanket Releases'"Description", count(1) "CountR12" from apps.po_releases_all where release_type='BLANKET'
UNION
SELECT 'Total No of  foreign currency Standard Purchase Orders'"Description", COUNT(po_header_id) "CountR12" from apps.po_headers_all where type_lookup_code='STANDARD' AND currency_code != 'USD'
UNION
SELECT 'Total No of  Purchase Order Lines whose corresponding shipment lines are not in CLOSED FOR RECEIVING status'"Description", count(*) "CountR12" from apps.po_headers_all poh,apps.po_line_locations_all poll where poh.po_header_id = poll.po_header_id and poll.closed_code in ('CLOSED FOR RECEIVING') 
UNION
SELECT 'Total No of  Active Buyers'"Description", count(agent_id) "CountR12" FROM  apps.po_agents WHERE TRUNC(end_date_active) > TRUNC(SYSDATE) or end_date_active is null
UNION
SELECT 'Total No of  Inactive Buyers'"Description", count(agent_id) "CountR12"  FROM  apps.po_agents WHERE end_date_active is not null or trunc(end_date_active) < trunc(sysdate)
);
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM **************************************************************************************** 
REM ******* Section 4 : Concurrent Program Execution Details          *******
REM ****************************************************************************************

prompt <a name="section214"></a><B><U><font size="+2">Concurrent Program Execution Details</font></B></U><BR><BR>
REM
REM ******* Concurrent Program Execution Details *******
REM
prompt <script type="text/javascript">  function displayRows2sql14(){var row = document.getElementById("s2sql14");if (row.style.display == '')  row.style.display = 'none';    else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="cped"></a>
prompt     <B>Concurrent Program Execution Details</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left"></p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER CONCURRENT PROGRAM NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EXECUTABLE FILE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT PROGRAM ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEEK1</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEEK2</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEEK3</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEEK4</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEEK5</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ZERO TO FIVE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FIVE TO TWENTY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TWENTY TO SIXTY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ONE TO TWO HOURS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TWO TO FOUR HOURS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FOUR TO SIX HOURS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MORE THAN SIX HOURS</B></TD>
SELECT '<TR><TD>'||fat.application_name||'</TD>'||chr(10)|| 
      '<TD>'||fct.user_concurrent_program_name||'</TD>'||chr(10)|| 
      '<TD>'||DECODE(fne.execution_file_name,'FND_REQUEST_SET.FNDRSSUB','',fcp.concurrent_program_name) ||'</TD>'||chr(10)|| 
      '<TD>'||DECODE(fne.execution_file_name,'JCP4XDODataEngine','BI Publisher','FND_REQUEST_SET.FNDRSSUB','Request Set',lke.meaning)
           ||'</TD>'||chr(10)|| 
      '<TD>'||DECODE(fne.execution_file_name,'JCP4XDODataEngine',fcp.concurrent_program_name,'FND_REQUEST_SET.FNDRSSUB','',fne.execution_file_name)||'</TD>'||chr(10)|| 
      '<TD>'||cpr.concurrent_program_id||'</TD>'||chr(10)|| 
      '<TD>'||cpr.week1||'</TD>'||chr(10)|| 
      '<TD>'||cpr.week2||'</TD>'||chr(10)|| 
      '<TD>'||cpr.week3||'</TD>'||chr(10)|| 
      '<TD>'||cpr.week4||'</TD>'||chr(10)|| 
      '<TD>'||cpr.week5||'</TD>'||chr(10)|| 
      '<TD>'||cpr.zero_to_five||'</TD>'||chr(10)|| 
      '<TD>'||cpr.five_to_twenty||'</TD>'||chr(10)|| 
      '<TD>'||cpr.twenty_to_sixty||'</TD>'||chr(10)|| 
      '<TD>'||cpr.one_to_two_hrs||'</TD>'||chr(10)|| 
      '<TD>'||cpr.two_to_four_hrs||'</TD>'||chr(10)|| 
      '<TD>'||cpr.four_to_six_hrs||'</TD>'||chr(10)|| 
      '<TD>'||cpr.more_than_six_hrs||'</TD></TR>'      
FROM 
(SELECT fcr.concurrent_program_id
      ,SUM(DECODE(to_char(fcr.actual_start_date,'W'),'1',1,0)) week1
      ,SUM(DECODE(to_char(fcr.actual_start_date,'W'),'2',1,0)) week2
      ,SUM(DECODE(to_char(fcr.actual_start_date,'W'),'3',1,0)) week3
      ,SUM(DECODE(to_char(fcr.actual_start_date,'W'),'4',1,0)) week4
      ,SUM(DECODE(to_char(fcr.actual_start_date,'W'),'5',1,0)) week5
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 0 AND 5
                THEN 1
                ELSE 0
                END) zero_to_five
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 5 AND 20
                THEN 1
                ELSE 0
                END) five_to_twenty
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 20 AND 60
                THEN 1
                ELSE 0
                END) twenty_to_sixty
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 60 AND 120
                THEN 1
                ELSE 0
                END) one_to_two_hrs
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 120 AND 240
                THEN 1
                ELSE 0
                END) two_to_four_hrs
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   BETWEEN 240 AND 360
                THEN 1
                ELSE 0
                END) four_to_six_hrs
      ,SUM(CASE WHEN (fcr.actual_completion_date - fcr.actual_start_date)*24*60
                   > 360
                THEN 1
                ELSE 0
                END) more_than_six_hrs
  FROM fnd_concurrent_requests    fcr
  GROUP BY fcr.concurrent_program_id ) cpr
, fnd_concurrent_programs    fcp
      ,fnd_concurrent_programs_tl fct
      ,fnd_executables            fne
      ,fnd_lookup_values          lke
      ,fnd_application_tl         fat
WHERE  1 =1
   AND cpr.concurrent_program_id = fct.concurrent_program_id
   AND fcp.concurrent_program_id = fct.concurrent_program_id
   AND fct.language              = 'US'
   AND fne.executable_id         = fcp.executable_id
   AND lke.lookup_type           = 'CP_EXECUTION_METHOD_CODE' 
   AND lke.language              = 'US'
   AND lke.lookup_code           = fne.execution_method_code
   AND fat.application_id        = fct.application_id;
   
   
  
prompt </TABLE><P><P>
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


spool off
set heading on
set feedback on  
set verify on
exit
;
