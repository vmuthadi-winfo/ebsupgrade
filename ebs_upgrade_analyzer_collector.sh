#!/bin/bash
# ==============================================================================
# Script Name: ebs_upgrade_analyzer_collector.sh
# Description: Gathers database & app server data for EBS 12.2.15 / DB 19c/23ai upgrade assessment
#              Includes Deep-Dive into EBS Profiles, Topology, Context Files & Integrations
#              Now executes as LEAST-PRIVILEGED USER and extracts CEMLI summaries natively.
# Usage: ./ebs_upgrade_analyzer_collector.sh
# ==============================================================================

HOST_NAME=$(hostname)
DATE_STAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="ebs_upgrade_analyzer_data_${HOST_NAME}_${DATE_STAMP}.txt"
LOG_FILE="ebs_upgrade_analyzer_${HOST_NAME}_${DATE_STAMP}.log"

echo "=========================================================" | tee -a "$LOG_FILE"
echo " EBS & Database Upgrade Deep-Dive Analyzer " | tee -a "$LOG_FILE"
echo "=========================================================" | tee -a "$LOG_FILE"

# Support Non-Interactive CI/CD pipeline runs
if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_TNS" ]; then
    echo "Interactive Shell Mode"
    echo -n "Enter the Analyzer Database Username [e.g. EBS_ANALYZER]: "
    read -r DB_USER
    echo -n "Enter the Analyzer Database Password: "
    read -rs DB_PASS
    echo
    echo -n "Enter the TNS Connection String [e.g. PRODDB or localhost:1521/PRODDB]: "
    read -r DB_TNS
else
    echo "Pipeline Mode: Credentials detected via environment variables."
fi

echo "Starting collection at: $(date)" | tee -a "$LOG_FILE"
echo "Output will be written to: $OUTPUT_FILE" | tee -a "$LOG_FILE"

> $OUTPUT_FILE

echo "1. Collecting OS, Hardware & Storage Info" | tee -a "$LOG_FILE"
echo "[SECTION_START:OS_SERVER_INFO]" >> $OUTPUT_FILE
echo "HOSTNAME|$(hostname)" >> $OUTPUT_FILE
echo "OS_RELEASE|$(cat /etc/system-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')" >> $OUTPUT_FILE
echo "KERNEL|$(uname -r)" >> $OUTPUT_FILE
echo "TOTAL_CPU_CORES|$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)" >> $OUTPUT_FILE
echo "TOTAL_MEMORY_GB|$(free -g | awk '/^Mem:/{print $2}')" >> $OUTPUT_FILE
echo "[SECTION_END:OS_SERVER_INFO]" >> $OUTPUT_FILE

echo "[SECTION_START:OS_STORAGE_MOUNTS]" >> $OUTPUT_FILE
df -hP | awk 'NR>1 {print $1"|"$2"|"$3"|"$4"|"$5"|"$6}' >> $OUTPUT_FILE
echo "[SECTION_END:OS_STORAGE_MOUNTS]" >> $OUTPUT_FILE

echo "[SECTION_START:OS_ULIMIT]" >> $OUTPUT_FILE
echo "OPEN_FILES|$(ulimit -n)" >> $OUTPUT_FILE
echo "MAX_USER_PROCESSES|$(ulimit -u)" >> $OUTPUT_FILE
echo "[SECTION_END:OS_ULIMIT]" >> $OUTPUT_FILE

echo "2. Check Application Tier Rogue Files (OS Search)" | tee -a "$LOG_FILE"

echo "[SECTION_START:APP_CUSTOM_FILES]" >> $OUTPUT_FILE
if [ -n "$OA_HTML" ] && [ -d "$OA_HTML" ]; then
    echo "ROGUE_OA_HTML_B64|$(find $OA_HTML -iname '*b64*' 2>/dev/null | wc -l)" >> $OUTPUT_FILE
    echo "ROGUE_OA_HTML_XX_FILES|$(find $OA_HTML -iname 'xx*' -o -iname 'XX*' 2>/dev/null | wc -l)" >> $OUTPUT_FILE
fi
if [ -n "$OA_MEDIA" ] && [ -d "$OA_MEDIA" ]; then
    echo "ROGUE_OA_MEDIA_XX_IMAGES|$(find $OA_MEDIA -iname 'xx*' -o -iname 'XX*' 2>/dev/null | wc -l)" >> $OUTPUT_FILE
fi
if [ -n "$JAVA_TOP" ] && [ -d "$JAVA_TOP" ]; then
    echo "ROGUE_JAVA_TOP_XX_CLASSES|$(find $JAVA_TOP -iname 'xx*.class' -o -iname 'XX*.class' 2>/dev/null | wc -l)" >> $OUTPUT_FILE
fi
echo "[SECTION_END:APP_CUSTOM_FILES]" >> $OUTPUT_FILE

echo "3. Creating SQL Payload for Deep-Dive Extraction" | tee -a "$LOG_FILE"

cat << 'EOF' > run_db_collect.sql
set term off
set arraysize 200
set heading off
set feedback off  
set echo off
set verify off
set lines 2000
set pages 0
set trimspool on
set colsep '|'

prompt [SECTION_START:DB_VERSION]
select instance_name ||'|'|| version ||'|'|| host_name ||'|'|| startup_time from v$instance;
prompt [SECTION_END:DB_VERSION]

prompt [SECTION_START:DB_SIZE]
select round(sum(bytes)/1024/1024/1024, 2) as size_gb from dba_data_files;
prompt [SECTION_END:DB_SIZE]

prompt [SECTION_START:DB_CONFIG]
select log_mode ||'|'|| flashback_on ||'|'|| database_role from v$database;
prompt [SECTION_END:DB_CONFIG]

prompt [SECTION_START:DB_PARAMETERS]
select name ||'|'|| value from v$parameter 
where name in ('processes', 'sessions', 'open_cursors', 'utl_file_dir', 'sga_max_size', 'sga_target', 'pga_aggregate_target', 'memory_target', 'compatible', 'cluster_database', 'cpu_count');
prompt [SECTION_END:DB_PARAMETERS]

prompt [SECTION_START:EBS_NODES]
select node_name ||'|'|| decode(support_cp, 'Y','YES','N','NO') ||'|'|| decode(support_forms, 'Y','YES','N','NO') ||'|'|| decode(support_web, 'Y','YES','N','NO') ||'|'|| decode(support_db, 'Y','YES','N','NO') ||'|'|| status
from apps.fnd_nodes
where node_name <> 'AUTHENTICATION';
prompt [SECTION_END:EBS_NODES]

prompt [SECTION_START:ALL_NODES_CONTEXT]
select n.node_name ||'|'||
       REGEXP_SUBSTR(c.text, '<s_webentryhost[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_webentrydomain[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_active_webport[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_adminserver[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_shared_file_system[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_atg_version[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_tools_version[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_ohs_version[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_jdktarget[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_custom_file_top[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_adkeystore[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_truststore[^>]*>([^<]+)', 1, 1, 'i', 1) ||'|'||
       REGEXP_SUBSTR(c.text, '<s_web_ssl_directory[^>]*>([^<]+)', 1, 1, 'i', 1)
from apps.fnd_nodes n,
     (select node_name, text from apps.fnd_oam_context_files 
      where (node_name, last_update_date) in 
          (select node_name, max(last_update_date) 
           from apps.fnd_oam_context_files 
           where status not in ('H') 
           group by node_name)
     ) c
where n.node_name = c.node_name
and n.node_name <> 'AUTHENTICATION';
prompt [SECTION_END:ALL_NODES_CONTEXT]

prompt [SECTION_START:EBS_INTEGRATIONS_PROFILES]
SELECT fo.profile_option_name ||'|'|| fv.profile_option_value
FROM apps.fnd_profile_option_values fv, apps.fnd_profile_options fo
WHERE fo.profile_option_id = fv.profile_option_id 
AND fv.level_value = 0
AND (
    fo.profile_option_name LIKE '%APEX%' OR
    fo.profile_option_name LIKE '%SSO%' OR
    fo.profile_option_name LIKE '%OAM%' OR
    fo.profile_option_name LIKE '%ECC%' OR
    fo.profile_option_name LIKE '%ENDECA%' OR
    fo.profile_option_name LIKE '%SOA%' OR
    fo.profile_option_name LIKE '%OBIEE%' OR
    fo.profile_option_name LIKE '%VERTEX%' OR
    fo.profile_option_name LIKE '%AVALARA%' OR
    fo.profile_option_name LIKE '%KBACE%' OR
    fo.profile_option_name LIKE '%MARKVIEW%' OR
    fo.profile_option_name LIKE '%GRC%' OR
    fo.profile_option_name IN (
        'APPS_FRAMEWORK_AGENT', 
        'APPS_AUTH_AGENT', 
        'APPS_SERVLET_AGENT',
        'ICX_FORMS_LAUNCHER', 
        'ICX_SESSION_TIMEOUT',
        'FND_SSO_COOKIE_DOMAIN',
        'APPS_SSO_COOKIE_DOMAIN',
        'APPS_SSO_PROFILE',
        'FND_DIAGNOSTICS',
        'GUEST_USER_PWD',
        'APPLICATIONS_HOME_PAGE',
        'ICX_DISCOVERER_LAUNCHER',
        'ICX_DISCOVERER_VIEWER_LAUNCHER',
        'FND_WEB_SERVER',
        'FND_APEX_URL',
        'FND_EXTERNAL_ADF_URL',
        'INV_EBI_SERVER_URL'
    )
);
prompt [SECTION_END:EBS_INTEGRATIONS_PROFILES]

prompt [SECTION_START:EBS_VERSION]
select release_name from apps.fnd_product_groups;
prompt [SECTION_END:EBS_VERSION]

prompt [SECTION_START:EBS_MODULES]
select fa.application_short_name ||'|'|| fat.application_name ||'|'|| fpi.patch_level ||'|'|| flv.meaning
from apps.fnd_application fa, apps.fnd_application_tl fat, apps.fnd_product_installations fpi, apps.fnd_lookup_values flv
where fa.application_id = fat.application_id and fat.application_id = fpi.application_id
and fat.language = 'US' and fpi.status = flv.lookup_code and flv.lookup_type = 'FND_PRODUCT_STATUS' and flv.language = 'US' and flv.meaning != 'Not installed';
prompt [SECTION_END:EBS_MODULES]

prompt [SECTION_START:EBS_LANGUAGES]
select NLS_LANGUAGE ||'|'|| LANGUAGE_CODE ||'|'|| INSTALLED_FLAG from apps.fnd_languages where INSTALLED_FLAG in ('I','B');
prompt [SECTION_END:EBS_LANGUAGES]

prompt [SECTION_START:EBS_CONCURRENT_MANAGERS]
select q.CONCURRENT_QUEUE_NAME ||'|'|| q.USER_CONCURRENT_QUEUE_NAME ||'|'|| decode(q.manager_type, 'Y', 'N', 'Y') ||'|'|| a.application_short_name ||'|'|| q.cache_size ||'|'|| q.target_processes ||'|'|| q.running_processes
from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a
where i.application_id = q.application_id and a.application_id = q.application_id and q.enabled_flag = 'Y' and nvl(q.control_code,'X') <> 'E'
and rownum <= 100;
prompt [SECTION_END:EBS_CONCURRENT_MANAGERS]

prompt [SECTION_START:WF_ADMIN_ROLE]
select apps.wf_core.translate('WF_ADMIN_ROLE') from dual;
prompt [SECTION_END:WF_ADMIN_ROLE]

prompt [SECTION_START:EBS_LOCALIZATIONS]
select fa.application_short_name ||'|'|| fat.application_name ||'|'|| fpi.status
from apps.fnd_product_installations fpi, apps.fnd_application fa, apps.fnd_application_tl fat
where fpi.application_id = fa.application_id and fa.application_id = fat.application_id and fat.language = 'US'
and (fa.application_short_name like 'JL%' or fa.application_short_name like 'JG%' or fa.application_short_name like 'JA%' or fa.application_short_name like 'JE%')
and fpi.status in ('I', 'S');
prompt [SECTION_END:EBS_LOCALIZATIONS]

prompt [SECTION_START:TOP_50_CONC_PROGS_BY_EXEC]
select * from (select fcp.concurrent_program_name ||'|'|| count(*) from apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs fcp
where fcr.concurrent_program_id = fcp.concurrent_program_id and fcr.program_application_id = fcp.application_id
and fcr.actual_start_date >= trunc(sysdate)-30 group by fcp.concurrent_program_name order by count(*) desc) where rownum <= 50;
prompt [SECTION_END:TOP_50_CONC_PROGS_BY_EXEC]

prompt [SECTION_START:TOP_50_CONC_PROGS_BY_TIME]
select * from (select fcp.concurrent_program_name ||'|'|| round(avg((fcr.actual_completion_date - fcr.actual_start_date)*24*60), 2)
from apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs fcp
where fcr.concurrent_program_id = fcp.concurrent_program_id and fcr.program_application_id = fcp.application_id
and fcr.actual_start_date >= trunc(sysdate)-30 and fcr.actual_completion_date is not null
group by fcp.concurrent_program_name order by avg((fcr.actual_completion_date - fcr.actual_start_date)*24*60) desc) where rownum <= 50;
prompt [SECTION_END:TOP_50_CONC_PROGS_BY_TIME]

prompt [SECTION_START:CONC_MANAGER_QUEUE_STATUS]
SELECT q.concurrent_queue_id||'|'||q.concurrent_queue_name||'|'||q.user_concurrent_queue_name||'|'||q.target_node||'|'||q.max_processes||'|'||q.running_processes||'|'||running.run||'|'||pending.pend||'|'||
Decode(q.control_code, 'D', 'Deactivating', 'E', 'Deactivated', 'N', 'Node unavai', 'A', 'Activating', 'X', 'Terminated', 'T', 'Terminating', 'V', 'Verifying', 'O', 'Suspending', 'P', 'Suspended', 'Q', 'Resuming', 'R', 'Restarting')
FROM (SELECT concurrent_queue_name, COUNT(phase_code) run FROM apps.fnd_concurrent_worker_requests WHERE phase_code = 'R' AND hold_flag != 'Y' AND requested_start_date <= SYSDATE GROUP BY concurrent_queue_name) running,
(SELECT concurrent_queue_name, COUNT(phase_code) pend FROM apps.fnd_concurrent_worker_requests WHERE phase_code = 'P' AND hold_flag != 'Y' AND requested_start_date <= SYSDATE GROUP BY concurrent_queue_name) pending,
apps.fnd_concurrent_queues_vl q
WHERE q.concurrent_queue_name = running.concurrent_queue_name(+) AND q.concurrent_queue_name = pending.concurrent_queue_name(+) AND q.enabled_flag = 'Y'
ORDER BY Decode(q.application_id, 0, Decode(q.concurrent_queue_id, 1, 1,4, 2)), Sign(q.max_processes) DESC, q.concurrent_queue_name, q.application_id;
prompt [SECTION_END:CONC_MANAGER_QUEUE_STATUS]

prompt [SECTION_START:DAILY_CONC_REQS_LAST_MONTH]
select to_char(actual_start_date, 'YYYY-MM-DD') ||'|'|| count(*) from apps.fnd_concurrent_requests 
where actual_start_date >= trunc(sysdate)-30 group by to_char(actual_start_date, 'YYYY-MM-DD') order by 1 desc;
prompt [SECTION_END:DAILY_CONC_REQS_LAST_MONTH]

prompt [SECTION_START:USERS_CREATED_MONTHLY]
select to_char(creation_date, 'YYYY-MM') ||'|'|| count(*) from apps.fnd_user group by to_char(creation_date, 'YYYY-MM') order by 1 desc;
prompt [SECTION_END:USERS_CREATED_MONTHLY]

prompt [SECTION_START:DB_SIZE_USAGE_FREE]
select round(sum(used.bytes) / 1024 / 1024 / 1024 ) ||'|'|| round(free.p/1024/1024/1024)
from (select bytes from v$datafile union all select bytes from v$tempfile union all select bytes from v$log) used,
(select sum(bytes) as p from dba_free_space) free group by free.p;
prompt [SECTION_END:DB_SIZE_USAGE_FREE]

prompt [SECTION_START:EBS_CUSTOM_SCHEMAS]
select username ||'|'|| created from dba_users where username like 'XX%' or username like 'CUST%';
prompt [SECTION_END:EBS_CUSTOM_SCHEMAS]

prompt [SECTION_START:EBS_CUSTOM_OBJECTS]
select owner ||'|'|| object_type ||'|'|| count(*) from dba_objects where owner like 'XX%' or owner like 'CUST%' group by owner, object_type;
prompt [SECTION_END:EBS_CUSTOM_OBJECTS]

prompt [SECTION_START:EBS_ACTIVE_USERS]
select 'SYSTEM_TOTAL' ||'|'|| count(*) from apps.fnd_user where (end_date is null or end_date > sysdate) and start_date <= sysdate;
prompt [SECTION_END:EBS_ACTIVE_USERS]

prompt [SECTION_START:ACTIVE_USERS_BY_MODULE]
select fa.application_short_name ||'|'|| count(distinct fu.user_id)
from apps.fnd_user fu, apps.fnd_user_resp_groups_direct furg, apps.fnd_application fa
where fu.user_id = furg.user_id and furg.responsibility_application_id = fa.application_id
and (fu.end_date is null or fu.end_date > sysdate) and (furg.end_date is null or furg.end_date > sysdate)
group by fa.application_short_name order by 2 desc;
prompt [SECTION_END:ACTIVE_USERS_BY_MODULE]

prompt [SECTION_START:ACTIVE_USERS_BY_RESP]
select fr.responsibility_key ||'|'|| count(distinct fu.user_id)
from apps.fnd_user fu, apps.fnd_user_resp_groups_direct furg, apps.fnd_responsibility fr
where fu.user_id = furg.user_id and furg.responsibility_id = fr.responsibility_id
and fu.user_id >= 1000
and (fu.end_date is null or fu.end_date > sysdate) and (furg.end_date is null or furg.end_date > sysdate)
group by fr.responsibility_key order by 2 desc;
prompt [SECTION_END:ACTIVE_USERS_BY_RESP]

prompt [SECTION_START:OPP_SIZING]
select target_processes ||'|'|| running_processes from apps.fnd_concurrent_queues where concurrent_queue_name = 'FNDCPOPP';
prompt [SECTION_END:OPP_SIZING]

prompt [SECTION_START:FORMS_SESSIONS]
select count(*) from v$session where upper(module) like '%FORM%' or upper(program) like '%FRM%';
prompt [SECTION_END:FORMS_SESSIONS]

prompt [SECTION_START:DBA_DB_LINKS]
select count(*), host from dba_db_links group by host;
prompt [SECTION_END:DBA_DB_LINKS]

prompt [SECTION_START:DBA_DIRECTORIES]
select count(*) from dba_directories;
prompt [SECTION_END:DBA_DIRECTORIES]

prompt [SECTION_START:DBA_INVALID_OBJECTS_LIST]
select owner ||'|'|| object_name ||'|'|| object_type ||'|'|| status ||'|'|| to_char(last_ddl_time, 'YYYY-MM-DD')
from dba_objects where status = 'INVALID' and owner not in ('SYS','SYSTEM') order by owner, object_type;
prompt [SECTION_END:DBA_INVALID_OBJECTS_LIST]

prompt [SECTION_START:ADOP_AD_ZD_SCHEMAS]
select count(distinct owner) from dba_objects where object_name like 'AD_ZD%';
prompt [SECTION_END:ADOP_AD_ZD_SCHEMAS]

prompt [SECTION_START:WORKFLOW_MAILER_DETAILED]
select p.parameter_name ||'|'|| v.parameter_value ||'|'|| c.component_name
from apps.fnd_svc_comp_param_vals v, apps.fnd_svc_comp_params_b p, apps.fnd_svc_components c
where c.component_id = v.component_id and p.parameter_id = v.parameter_id and c.component_name like '%Mailer%';
prompt [SECTION_END:WORKFLOW_MAILER_DETAILED]

prompt [SECTION_START:FND_SMTP_PROFILES]
select fp.profile_option_name ||'|'|| fv.profile_option_value 
from apps.fnd_profile_option_values fv, apps.fnd_profile_options fp
where fv.profile_option_id = fp.profile_option_id and fp.profile_option_name like '%SMTP%';
prompt [SECTION_END:FND_SMTP_PROFILES]

prompt [SECTION_START:CUSTOM_WORKFLOWS]
select name ||'|'|| count(*) from apps.wf_item_types where name like 'XX%' group by name;
prompt [SECTION_END:CUSTOM_WORKFLOWS]

prompt [SECTION_START:XML_PUBLISHER_DELIVERY]
select 'XDO_TEMPLATES' ||'|'|| default_output_type ||'|'|| count(*) from apps.xdo_templates_b where template_code like 'XX%' group by default_output_type;
prompt [SECTION_END:XML_PUBLISHER_DELIVERY]


prompt [SECTION_START:CEMLI_CONCURRENT_PROGRAMS]
select fee.execution_method_code ||'|'|| decode(fee.execution_method_code, 'H', 'Host', 'J', 'Java SP', 'K', 'Java', 'P', 'Oracle Reports', 'E', 'Perl', 'Q', 'SQL*Plus', 'A', 'Spawned', 'I', 'PL/SQL', 'L', 'SQL*Loader', fee.execution_method_code) ||'|'|| count(*)
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp
where fee.executable_id = fcp.executable_id
and (fcp.concurrent_program_name like 'XX%' or fee.executable_name like 'XX%')
group by fee.execution_method_code;
prompt [SECTION_END:CEMLI_CONCURRENT_PROGRAMS]

prompt [SECTION_START:CEMLI_FORMS_AND_PAGES]
select 'CUSTOM_FORMS' ||'|'|| count(*) from apps.fnd_form where form_name like 'XX%';
prompt [SECTION_END:CEMLI_FORMS_AND_PAGES]

prompt [SECTION_START:CEMLI_OAF_PERSONALIZATIONS]
select 'OAF_PERSONALIZATIONS' ||'|'|| count(*) from apps.jdr_paths 
where path_type = 'DOCUMENT' and (path_name like '/oracle/apps/%/customizations/%' or path_name like '%/XX%');
prompt [SECTION_END:CEMLI_OAF_PERSONALIZATIONS]

prompt [SECTION_START:AD_TXK_PATCH_LEVEL]
select 'AD' ||'|'|| bug_number ||'|'|| creation_date from apps.ad_bugs where bug_number like '346%' or bug_number like '356%' or bug_number like '366%' and rownum <= 1
union all
select 'TXK' ||'|'|| bug_number ||'|'|| creation_date from apps.ad_bugs where bug_number like '345%' or bug_number like '355%' or bug_number like '365%' and rownum <= 1;
prompt [SECTION_END:AD_TXK_PATCH_LEVEL]

prompt [SECTION_START:RECENT_PATCHES]
select patch_name ||'|'|| trunc(creation_date) from apps.ad_applied_patches where creation_date > sysdate - 180 and rownum <= 50 order by creation_date desc;
prompt [SECTION_END:RECENT_PATCHES]

prompt [SECTION_START:DB_INIT_PARAMS_FULL]
select name ||'|'|| value ||'|'|| isdefault ||'|'|| ismodified 
from v$system_parameter order by name;
prompt [SECTION_END:DB_INIT_PARAMS_FULL]

prompt [SECTION_START:DB_INTERNAL_STATE]
select 'NLS_CHARACTERSET' ||'|'|| value from v$nls_parameters where parameter = 'NLS_CHARACTERSET'
union all
select 'DBA_TABLESPACES' ||'|'|| count(*) from dba_tablespaces
union all
select 'REDO_LOG_GROUPS' ||'|'|| count(*) from v$log
union all
select 'ARCHIVELOG_MODE' ||'|'|| log_mode from v$database;
prompt [SECTION_END:DB_INTERNAL_STATE]

prompt [SECTION_START:DB_FEATURE_USAGE]
select name ||'|'|| currently_used ||'|'|| first_usage_date ||'|'|| last_usage_date 
from dba_feature_usage_statistics where currently_used = 'TRUE' and rownum <= 50 order by last_usage_date desc;
prompt [SECTION_END:DB_FEATURE_USAGE]

prompt [SECTION_START:CUSTOM_FND_OBJECTS]
select 'MENUS' ||'|'|| count(*) from apps.fnd_menus where menu_name like 'XX%'
union all
select 'RESPONSIBILITIES' ||'|'|| count(*) from apps.fnd_responsibility where responsibility_key like 'XX%'
union all
select 'FUNCTIONS' ||'|'|| count(*) from apps.fnd_form_functions where function_name like 'XX%'
union all
select 'LOOKUPS' ||'|'|| count(distinct lookup_type) from apps.fnd_lookup_values where lookup_type like 'XX%'
union all
select 'VALUE_SETS' ||'|'|| count(*) from apps.fnd_flex_value_sets where flex_value_set_name like 'XX%'
union all
select 'DFFS' ||'|'|| count(*) from apps.fnd_descriptive_flexs where descriptive_flexfield_name like 'XX%';
prompt [SECTION_END:CUSTOM_FND_OBJECTS]

prompt [SECTION_START:INFRA_OBJECTS]
select 'SCHEDULER_JOBS' ||'|'|| count(*) from dba_scheduler_jobs where owner not in ('SYS','SYSTEM')
union all
select 'MATERIALIZED_VIEWS' ||'|'|| count(*) from dba_mviews where owner not in ('SYS','SYSTEM')
union all
select 'PARTITIONED_TABLES' ||'|'|| count(*) from dba_part_tables where owner not in ('SYS','SYSTEM');
prompt [SECTION_END:INFRA_OBJECTS]

prompt [SECTION_START:WORKLOAD_STATISTICS]
select 'AVG_DAILY_CONC_REQS_30D' ||'|'|| round(count(*)/30) from apps.fnd_concurrent_requests where requested_start_date > sysdate-30
union all
select 'FND_ATTACHED_DOCS' ||'|'|| count(*) from apps.fnd_attached_documents
union all
select 'AUDIT_TABLE_ROWS' ||'|'|| sum(num_rows) from dba_tables where table_name in ('FND_LOG_MESSAGES', 'FND_CONCURRENT_REQUESTS');
prompt [SECTION_END:WORKLOAD_STATISTICS]

prompt [SECTION_START:ORACLE_ALERTS_LIST]
select fa.application_short_name ||'|'|| a.alert_name ||'|'|| a.description ||'|'|| a.alert_condition_type ||'|'|| a.oracle_id
from apps.alr_alerts a, apps.fnd_application fa 
where a.application_id = fa.application_id and a.enabled_flag = 'Y';
prompt [SECTION_END:ORACLE_ALERTS_LIST]

prompt [SECTION_START:DB_DATAGUARD]
select dest_name ||'|'|| status ||'|'|| target ||'|'|| destination
from v$archive_dest where status = 'VALID' and target = 'STANDBY';
prompt [SECTION_END:DB_DATAGUARD]

prompt [SECTION_START:DB_BACKUP_SUMMARY]
select status ||'|'|| trunc(end_time) ||'|'|| round((output_bytes_display/1024/1024/1024),2)
from v$rman_backup_job_details where start_time > sysdate - 7 order by end_time desc;
prompt [SECTION_END:DB_BACKUP_SUMMARY]

prompt [SECTION_START:TOP_10_TABLES]
select owner ||'.'|| segment_name ||'|'|| segment_type ||'|'|| round(bytes/1024/1024/1024, 2)
from (select owner, segment_name, segment_type, bytes from dba_segments order by bytes desc)
where rownum <= 10;
prompt [SECTION_END:TOP_10_TABLES]

prompt [SECTION_START:DB_USER_PROFILES]
select profile ||'|'|| resource_name ||'|'|| limit 
from dba_profiles where resource_type = 'PASSWORD';
prompt [SECTION_END:DB_USER_PROFILES]

prompt [SECTION_START:DB_ROLE_PRIVS]
select grantee ||'|'|| granted_role ||'|'|| admin_option 
from dba_role_privs where grantee in ('APPS', 'APPLSYS');
prompt [SECTION_END:DB_ROLE_PRIVS]

prompt [SECTION_START:EBS_DMZ_EXTERNAL_NODES]
select fv.profile_option_value ||'|'|| fp.profile_option_name
from apps.fnd_profile_option_values fv, apps.fnd_profile_options fp
where fv.profile_option_id = fp.profile_option_id and fp.profile_option_name in ('NODE_TRUST_LEVEL', 'RESP_TRUST_LEVEL');
prompt [SECTION_END:EBS_DMZ_EXTERNAL_NODES]

prompt [SECTION_START:EBS_PCP_MANAGERS]
select q.user_concurrent_queue_name ||'|'|| n1.node_name ||'|'|| nvl(n2.node_name, 'NO_FAILOVER_DEFINED')
from apps.fnd_concurrent_queues_vl q, apps.fnd_nodes n1, apps.fnd_nodes n2
where q.node_name = n1.node_name(+)
and q.node_name2 = n2.node_name(+)
and (n1.node_name is not null or n2.node_name is not null);
prompt [SECTION_END:EBS_PCP_MANAGERS]

prompt [SECTION_START:EBS_USERS_SCHEMA_CONNECT]
select fu.user_name ||'|'|| fou.oracle_username ||'|'|| drp.granted_role
from apps.fnd_user fu, apps.fnd_oracle_userid fou, apps.fnd_data_group_units fdgu, dba_role_privs drp
where fu.user_id = fou.oracle_id and fou.oracle_id = fdgu.oracle_id
and fou.oracle_username = drp.grantee
and drp.granted_role in ('CONNECT', 'RESOURCE', 'DBA')
and rownum <= 500;
prompt [SECTION_END:EBS_USERS_SCHEMA_CONNECT]

prompt [SECTION_START:SCHEDULED_CONCURRENT_JOBS]
select fcr.request_id ||'|'|| fcp.concurrent_program_name ||'|'|| fu.user_name ||'|'|| fcr.phase_code ||'|'|| fcr.status_code ||'|'|| to_char(fcr.requested_start_date, 'YYYY-MM-DD HH24:MI')
from apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs fcp, apps.fnd_user fu
where fcr.concurrent_program_id = fcp.concurrent_program_id
and fcr.requested_by = fu.user_id
and fcr.phase_code in ('P', 'R') 
and rownum <= 1000 order by fcr.requested_start_date asc;
prompt [SECTION_END:SCHEDULED_CONCURRENT_JOBS]

prompt [SECTION_START:EBS_FUNC_DATA_VOLUMES]
SELECT 'Transaction' category, 'Purchasing' module, 'Purchase Orders' object_type, 
       (SELECT COUNT(1) FROM apps.po_headers_all) total_volume, 
       (SELECT COUNT(1) FROM apps.po_headers_all WHERE closed_code ='OPEN') open_volume FROM dual UNION ALL
SELECT 'Transaction', 'Purchasing', 'Requisitions', (SELECT COUNT(1) FROM apps.po_requisition_headers_all), 0 FROM dual UNION ALL
SELECT 'Master Data', 'Purchasing', 'Suppliers', (SELECT COUNT(1) FROM apps.ap_suppliers), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Payables', 'Invoices', (SELECT COUNT(1) FROM apps.ap_invoices_all), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Payables', 'Expense Reports', (SELECT COUNT(1) FROM apps.ap_expense_report_headers_all), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Payables', 'Payments', (SELECT COUNT(1) FROM apps.ap_checks_all), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Projects', 'Projects Executing', (SELECT COUNT(1) FROM apps.pa_projects_all WHERE template_flag='N'), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Receivables', 'Invoices', (SELECT COUNT(1) FROM apps.ra_customer_trx_all), 0 FROM dual UNION ALL
SELECT 'Transaction', 'Receivables', 'Cash Receipts', (SELECT COUNT(1) FROM apps.ar_cash_receipts_all), 0 FROM dual UNION ALL
SELECT 'Master Data', 'Receivables', 'Customers', (SELECT COUNT(1) FROM apps.hz_cust_accounts), 0 FROM dual UNION ALL
SELECT 'Master Data', 'Human Resources', 'Employees', (SELECT COUNT(1) FROM apps.per_all_people_f), 0 FROM dual UNION ALL
SELECT 'Master Data', 'General Ledger', 'Ledgers', (SELECT COUNT(1) FROM apps.gl_ledgers), 0 FROM dual UNION ALL
SELECT 'Transaction', 'General Ledger', 'GL Lines', (SELECT COUNT(1) FROM apps.gl_je_lines), 0 FROM dual UNION ALL
SELECT 'Transaction', 'General Ledger', 'GL Accounts', (SELECT COUNT(1) FROM apps.gl_code_combinations), 0 FROM dual;
prompt [SECTION_END:EBS_FUNC_DATA_VOLUMES]


exit;
EOF

echo "4. Executing Database Deep-Dive via user: $DB_USER" | tee -a $LOG_FILE
sqlplus -s /nolog <<EOF >> $OUTPUT_FILE 2>>$LOG_FILE
connect $DB_USER/"$DB_PASS"@$DB_TNS
@run_db_collect.sql
exit;
EOF

if [ $? -eq 0 ]; then
    echo "DB Collection Executed Successfully." | tee -a $LOG_FILE
else
    echo "ERROR: DB Collection failed. Are privileges correct?" | tee -a $LOG_FILE
fi

rm run_db_collect.sql
sed -i '/^$/d' $OUTPUT_FILE

echo "Collection Complete. Output: $OUTPUT_FILE" | tee -a $LOG_FILE
