#!/bin/bash
# ==============================================================================
# Script Name: ebs_upgrade_analyzer_collector.sh
# Description: Gathers database & app server data for EBS 12.2.15 / DB 19c/23ai upgrade assessment
#              Includes Deep-Dive into EBS Profiles, Topology, Context Files & Integrations
#              Now executes as LEAST-PRIVILEGED USER and extracts CEMLI summaries natively.
# Usage: ./ebs_upgrade_analyzer_collector.sh
#
# Copyright (c) 2024-2026 Winfo Solutions. All Rights Reserved.
# This tool is Winfo Solutions Proprietary and Confidential.
# Unauthorized copying, distribution, or use of this file is strictly prohibited.
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

: > "$OUTPUT_FILE"

echo "1. Collecting OS, Hardware & Storage Info" | tee -a "$LOG_FILE"

echo "[SECTION_START:OS_SERVER_INFO]" >> $OUTPUT_FILE
echo "HOSTNAME|$(hostname)" >> $OUTPUT_FILE
echo "OS_RELEASE|$(cat /etc/system-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')" >> $OUTPUT_FILE
echo "KERNEL|$(uname -r)" >> $OUTPUT_FILE
echo "TOTAL_CPU_CORES|$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)" >> $OUTPUT_FILE
echo "TOTAL_MEMORY_GB|$(free -g | awk '/^Mem:/{print $2}')" >> $OUTPUT_FILE
echo "[SECTION_END:OS_SERVER_INFO]" >> $OUTPUT_FILE

{
echo "[SECTION_START:OS_STORAGE_MOUNTS]"
df -hP | awk 'NR>1 {print $1"|"$2"|"$3"|"$4"|"$5"|"$6}'
echo "[SECTION_END:OS_STORAGE_MOUNTS]"

echo "[SECTION_START:OS_ULIMIT]"
echo "OPEN_FILES|$(ulimit -n)"
echo "MAX_USER_PROCESSES|$(ulimit -u)"
echo "[SECTION_END:OS_ULIMIT]"
} >> "$OUTPUT_FILE"

echo "2. Check Application Tier Rogue Files (OS Search)" | tee -a "$LOG_FILE"

{
echo "[SECTION_START:APP_CUSTOM_FILES]"
if [ -n "$OA_HTML" ] && [ -d "$OA_HTML" ]; then
    echo "ROGUE_OA_HTML_B64|$(find "$OA_HTML" -iname '*b64*' 2>/dev/null | wc -l)"
    echo "ROGUE_OA_HTML_XX_FILES|$(find "$OA_HTML" \( -iname 'xx*' -o -iname 'XX*' \) 2>/dev/null | wc -l)"
fi
if [ -n "$OA_MEDIA" ] && [ -d "$OA_MEDIA" ]; then
    echo "ROGUE_OA_MEDIA_XX_IMAGES|$(find "$OA_MEDIA" \( -iname 'xx*' -o -iname 'XX*' \) 2>/dev/null | wc -l)"
fi
if [ -n "$JAVA_TOP" ] && [ -d "$JAVA_TOP" ]; then
    echo "ROGUE_JAVA_TOP_XX_CLASSES|$(find "$JAVA_TOP" \( -iname 'xx*.class' -o -iname 'XX*.class' \) 2>/dev/null | wc -l)"
fi
echo "[SECTION_END:APP_CUSTOM_FILES]"
} >> "$OUTPUT_FILE"

echo "3. Creating SQL Payload for Deep-Dive Extraction" | tee -a "$LOG_FILE"

cat << 'EOF' > run_db_collect.sql
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

-- RAC Database Detection and Information Collection
prompt [SECTION_START:RAC_STATUS]
select 'CLUSTER_DATABASE' ||'|'|| value from v$parameter where name = 'cluster_database';
select 'INSTANCE_COUNT' ||'|'|| count(*) from gv$instance;
select 'CLUSTER_NAME' ||'|'|| nvl((select value from v$parameter where name = 'cluster_database_instances'), 'N/A') from dual;
prompt [SECTION_END:RAC_STATUS]

prompt [SECTION_START:RAC_INSTANCES]
select inst_id ||'|'|| instance_name ||'|'|| host_name ||'|'|| version ||'|'|| status ||'|'|| to_char(startup_time, 'YYYY-MM-DD HH24:MI:SS') ||'|'|| database_status ||'|'|| instance_role
from gv$instance order by inst_id;
prompt [SECTION_END:RAC_INSTANCES]

prompt [SECTION_START:RAC_INSTANCE_PARAMETERS]
select inst_id ||'|'|| name ||'|'|| value ||'|'|| isdefault
from gv$parameter
where name in ('instance_name', 'instance_number', 'thread', 'undo_tablespace', 'cluster_database', 
               'cluster_database_instances', 'cluster_interconnects', 'remote_listener', 'local_listener',
               'sga_target', 'sga_max_size', 'pga_aggregate_target', 'memory_target', 'memory_max_target',
               'db_cache_size', 'shared_pool_size', 'large_pool_size', 'java_pool_size', 'streams_pool_size',
               'processes', 'sessions', 'cpu_count', 'parallel_max_servers', 'log_archive_dest_1', 'log_archive_dest_2')
order by inst_id, name;
prompt [SECTION_END:RAC_INSTANCE_PARAMETERS]

prompt [SECTION_START:RAC_INTERCONNECT]
select inst_id ||'|'|| name ||'|'|| ip_address ||'|'|| is_public ||'|'|| source
from gv$cluster_interconnects order by inst_id;
prompt [SECTION_END:RAC_INTERCONNECT]

prompt [SECTION_START:RAC_SERVICES]
select inst_id ||'|'|| name ||'|'|| network_name ||'|'|| enabled ||'|'|| nvl(aq_ha_notifications, 'N/A') ||'|'|| nvl(clb_goal, 'N/A') ||'|'|| nvl(goal, 'N/A')
from gv$services order by name, inst_id;
prompt [SECTION_END:RAC_SERVICES]

prompt [SECTION_START:RAC_DATABASE_INFO]
select 'DB_UNIQUE_NAME' ||'|'|| db_unique_name from v$database
union all
select 'PLATFORM_NAME' ||'|'|| platform_name from v$database
union all
select 'CREATED' ||'|'|| to_char(created, 'YYYY-MM-DD HH24:MI:SS') from v$database
union all
select 'OPEN_MODE' ||'|'|| open_mode from v$database
union all
select 'PROTECTION_MODE' ||'|'|| protection_mode from v$database
union all
select 'DATABASE_ROLE' ||'|'|| database_role from v$database;
prompt [SECTION_END:RAC_DATABASE_INFO]

prompt [SECTION_START:RAC_ASM_DISKGROUPS]
select name ||'|'|| state ||'|'|| type ||'|'|| total_mb ||'|'|| free_mb ||'|'|| round((free_mb/total_mb)*100, 2) as pct_free
from v$asm_diskgroup where total_mb > 0;
prompt [SECTION_END:RAC_ASM_DISKGROUPS]

prompt [SECTION_START:RAC_GV_SYSSTAT]
select inst_id ||'|'|| name ||'|'|| value 
from gv$sysstat 
where name in ('gc cr blocks received', 'gc current blocks received', 'gc cr blocks served', 'gc current blocks served', 
               'global cache gets', 'global cache get time', 'gc cr block receive time', 'gc current block receive time')
order by inst_id, name;
prompt [SECTION_END:RAC_GV_SYSSTAT]

prompt [SECTION_START:RAC_THREAD_REDO]
select thread# ||'|'|| group# ||'|'|| members ||'|'|| round(bytes/1024/1024, 0) ||'|'|| status ||'|'|| archived
from v$log order by thread#, group#;
prompt [SECTION_END:RAC_THREAD_REDO]

prompt [SECTION_START:RAC_SCAN_LISTENERS]
select 'SCAN_LISTENER' ||'|'|| value from v$parameter where name = 'remote_listener'
union all
select 'LOCAL_LISTENER' ||'|'|| value from v$parameter where name = 'local_listener';
prompt [SECTION_END:RAC_SCAN_LISTENERS]

prompt [SECTION_START:EBS_NODES]
select node_name ||'|'|| decode(support_cp, 'Y','YES','N','NO') ||'|'|| decode(support_forms, 'Y','YES','N','NO') ||'|'|| decode(support_web, 'Y','YES','N','NO') ||'|'|| decode(support_db, 'Y','YES','N','NO') ||'|'|| status
from apps.fnd_nodes
where node_name <> 'AUTHENTICATION';
prompt [SECTION_END:EBS_NODES]

prompt [SECTION_START:CTX_DIRECTORIES]
select node_name ||'|appl_top|'|| EXTRACTVALUE(XMLType(TEXT),'(//APPL_TOP)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|common_top|'|| EXTRACTVALUE(XMLType(TEXT),'(//COMMON_TOP)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|instance_top|'|| EXTRACTVALUE(XMLType(TEXT),'(//INST_TOP)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name);
    
prompt [SECTION_END:CTX_DIRECTORIES]

prompt [SECTION_START:CTX_PORTS_SECURITY]
select node_name ||'|port_pool|'|| EXTRACTVALUE(XMLType(TEXT),'(//PORT_POOL)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|sslterminator|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_shared_file_system)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|webport|'|| EXTRACTVALUE(XMLType(TEXT),'(//webport)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|webssl_port|'|| EXTRACTVALUE(XMLType(TEXT),'(//webssl_port)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|Active_Port|'|| EXTRACTVALUE(XMLType(TEXT),'(//activewebport)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name);
prompt [SECTION_END:CTX_PORTS_SECURITY]

prompt [SECTION_START:CTX_DB_NETWORKING]
select node_name ||'|db_name|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_dbSid)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|db_host|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_dbhost)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|db_port|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_dbport)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|jdbc_url|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_apps_jdbc_connect_descriptor)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|dbc_file|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_apps_jdbc_alias)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name);
prompt [SECTION_END:CTX_DB_NETWORKING]

prompt [SECTION_START:CTX_JVM_SERVICES]
select node_name ||'|oacore_nprocs|'|| EXTRACTVALUE(XMLType(TEXT),'(//oacore_nprocs)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|forms_nprocs|'|| EXTRACTVALUE(XMLType(TEXT),'(//forms_nprocs)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|oafm_nprocs|'|| EXTRACTVALUE(XMLType(TEXT),'(//oafm_nprocs)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name)
union all
select node_name ||'|oacore_jvm_options|'|| EXTRACTVALUE(XMLType(TEXT),'(//oacore_jvm_start_options)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' and ctx_type = 'A' group by node_name);
prompt [SECTION_END:CTX_JVM_SERVICES]

prompt [SECTION_START:EBS_INTEGRATIONS_PROFILES]
SELECT fo.profile_option_name ||'|'|| NVL(fv.profile_option_value, 'NOT_DEFINED')
FROM apps.fnd_profile_options fo, apps.fnd_profile_option_values fv
WHERE fo.profile_option_id = fv.profile_option_id(+)
AND fv.level_value(+) = 0
AND (
    fo.profile_option_name LIKE '%APEX%' OR
    fo.profile_option_name LIKE '%SOA%' OR
    fo.profile_option_name LIKE '%ISG%' OR
    fo.profile_option_name LIKE '%REST%' OR
    fo.profile_option_name LIKE '%OBIEE%' OR
    fo.profile_option_name LIKE '%OAC%' OR
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
        'APPS_SSO_PROFILE',
        'FND_SSO_COOKIE_DOMAIN',
        'APPS_SSO_COOKIE_DOMAIN',
        'APPS_SSO_AUTO_REDIRECT',
        'APPS_OAM_APPL_SERVER_URL',
        'FND_DIAGNOSTICS',
        'GUEST_USER_PWD',
        'APPLICATIONS_HOME_PAGE',
        'ICX_DISCOVERER_LAUNCHER',
        'ICX_DISCOVERER_VIEWER_LAUNCHER',
        'FND_WEB_SERVER',
        'FND_APEX_URL',
        'FND_EXTERNAL_ADF_URL',
        'INV_EBI_SERVER_URL',
        'OAM_DIAG_COMMUNITY_URL',
        'ECC_URL',
        'ECC_EBS_AUTH_COOKIE'
    )
);
prompt [SECTION_END:EBS_INTEGRATIONS_PROFILES]

prompt [SECTION_START:EBS_URL_PROFILES]
SELECT fo.profile_option_name ||'|'|| NVL(fv.profile_option_value, 'NOT_DEFINED')
FROM apps.fnd_profile_option_values fv, apps.fnd_profile_options fo
WHERE fo.profile_option_id = fv.profile_option_id AND fv.level_value = 0
AND fo.profile_option_name IN ('APPS_FRAMEWORK_AGENT','APPS_AUTH_AGENT','FND_APEX_URL','FND_EXTERNAL_ADF_URL','INV_EBI_SERVER_URL','ICX_FORMS_LAUNCHER');
prompt [SECTION_END:EBS_URL_PROFILES]

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

prompt [SECTION_START:PROFILE_OPTIONS_CHANGED_48H]
SELECT fpo.profile_option_name ||'|'|| fpot.user_profile_option_name ||'|'|| 
       decode(fpov.level_id, 10001, 'Site', 10002, 'Application', 10003, 'Responsibility', 10004, 'User', 'Other') ||'|'||
       fpov.profile_option_value ||'|'|| to_char(fpov.last_update_date, 'YYYY-MM-DD HH24:MI:SS') ||'|'|| fu.user_name
FROM apps.fnd_profile_option_values fpov, apps.fnd_profile_options fpo, 
     apps.fnd_profile_options_tl fpot, apps.fnd_user fu
WHERE fpov.profile_option_id = fpo.profile_option_id
AND fpo.profile_option_name = fpot.profile_option_name AND fpot.language = 'US'
AND fpov.last_updated_by = fu.user_id
AND fpov.last_update_date >= sysdate - 2
ORDER BY fpov.last_update_date DESC;
prompt [SECTION_END:PROFILE_OPTIONS_CHANGED_48H]

prompt [SECTION_START:APPLIED_PATCHES_30_DAYS]
SELECT DISTINCT e.patch_name ||'|'|| e.patch_type ||'|'|| to_char(a.last_update_date, 'YYYY-MM-DD') ||'|'|| b.applied_flag
FROM apps.ad_bugs a, apps.ad_patch_run_bugs b, apps.ad_patch_runs c, 
     apps.ad_patch_drivers d, apps.ad_applied_patches e
WHERE a.bug_id = b.bug_id AND b.patch_run_id = c.patch_run_id
AND c.patch_driver_id = d.patch_driver_id AND d.applied_patch_id = e.applied_patch_id
AND a.last_update_date >= sysdate - 30
ORDER BY a.last_update_date DESC;
prompt [SECTION_END:APPLIED_PATCHES_30_DAYS]

prompt [SECTION_START:EBS_LOCALIZATIONS]
select fa.application_short_name ||'|'|| fat.application_name ||'|'|| fpi.status
from apps.fnd_product_installations fpi, apps.fnd_application fa, apps.fnd_application_tl fat
where fpi.application_id = fa.application_id and fa.application_id = fat.application_id and fat.language = 'US'
and (fa.application_short_name like 'JL%' or fa.application_short_name like 'JG%' or fa.application_short_name like 'JA%' or fa.application_short_name like 'JE%')
and fpi.status in ('I', 'S');
prompt [SECTION_END:EBS_LOCALIZATIONS]

prompt [SECTION_START:TOP_50_CONC_PROGS_BY_EXEC]
select * from (select fcp.user_concurrent_program_name ||'|'|| count(*) from apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs_vl fcp
where fcr.concurrent_program_id = fcp.concurrent_program_id and fcr.program_application_id = fcp.application_id
and fcr.actual_start_date >= trunc(sysdate)-30 group by fcp.user_concurrent_program_name order by count(*) desc) where rownum <= 50;
prompt [SECTION_END:TOP_50_CONC_PROGS_BY_EXEC]

prompt [SECTION_START:TOP_50_CONC_PROGS_BY_TIME]
select * from (select fcp.user_concurrent_program_name ||'|'|| round(avg((fcr.actual_completion_date - fcr.actual_start_date)*24*60), 2)
from apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs_vl fcp
where fcr.concurrent_program_id = fcp.concurrent_program_id and fcr.program_application_id = fcp.application_id
and fcr.actual_start_date >= trunc(sysdate)-30 and fcr.actual_completion_date is not null
group by fcp.user_concurrent_program_name order by avg((fcr.actual_completion_date - fcr.actual_start_date)*24*60) desc) where rownum <= 50;
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
select username ||'|'|| created from dba_users where username like 'XX%' or username like 'XX%';
prompt [SECTION_END:EBS_CUSTOM_SCHEMAS]

prompt [SECTION_START:EBS_CUSTOM_OBJECTS]
select owner ||'|'|| object_type ||'|'|| count(*) from dba_objects where owner like 'XX%' or owner like 'XX%' group by owner, object_type;
prompt [SECTION_END:EBS_CUSTOM_OBJECTS]

prompt [SECTION_START:EBS_ACTIVE_USERS]
select 'SYSTEM_TOTAL' ||'|'|| count(*) from apps.fnd_user where (end_date is null or end_date > sysdate) and start_date <= sysdate;
prompt [SECTION_END:EBS_ACTIVE_USERS]

prompt [SECTION_START:ACTIVE_USERS_BY_MODULE]
select fa.application_short_name ||'|'|| count(distinct fu.user_id)
from apps.fnd_user fu, apps.fnd_user_resp_groups_direct furg, apps.fnd_application fa
where fu.user_id = furg.user_id and furg.responsibility_application_id = fa.application_id
and (fu.end_date is null or fu.end_date > sysdate) and (furg.end_date is null or furg.end_date > sysdate)
group by fa.application_short_name order by count(distinct fu.user_id) desc;
prompt [SECTION_END:ACTIVE_USERS_BY_MODULE]

prompt [SECTION_START:ACTIVE_USERS_BY_RESP]
select fr.responsibility_key ||'|'|| count(distinct fu.user_id)
from apps.fnd_user fu, apps.fnd_user_resp_groups_direct furg, apps.fnd_responsibility fr
where fu.user_id = furg.user_id and furg.responsibility_id = fr.responsibility_id
and fu.user_id >= 1000
and (fu.end_date is null or fu.end_date > sysdate) and (furg.end_date is null or furg.end_date > sysdate)
group by fr.responsibility_key order by count(distinct fu.user_id) desc;
prompt [SECTION_END:ACTIVE_USERS_BY_RESP]

prompt [SECTION_START:OPP_SIZING]
select target_processes ||'|'|| running_processes from apps.fnd_concurrent_queues where concurrent_queue_name = 'FNDCPOPP';
prompt [SECTION_END:OPP_SIZING]

prompt [SECTION_START:FORMS_SESSIONS]
select count(*) from v$session where upper(module) like '%FORM%' or upper(program) like '%FRM%';
prompt [SECTION_END:FORMS_SESSIONS]

prompt [SECTION_START:DBA_DB_LINKS]
select count(*) ||'|'|| host from dba_db_links group by host;
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
select name ||'|'|| name from apps.wf_item_types where name like 'XX%';
prompt [SECTION_END:CUSTOM_WORKFLOWS]

prompt [SECTION_START:XML_PUBLISHER_DELIVERY]
select 'XDO_TEMPLATES' ||'|'|| default_output_type ||'|'|| count(*) from apps.xdo_templates_b where template_code like 'XX%' group by default_output_type;
prompt [SECTION_END:XML_PUBLISHER_DELIVERY]


prompt [SECTION_START:CEMLI_CONCURRENT_PROGRAMS]
select fa.application_short_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.executable_name ||'|'|| decode(fee.execution_method_code, 'H', 'Host', 'J', 'Java SP', 'K', 'Java', 'P', 'Oracle Reports', 'E', 'Perl', 'Q', 'SQL*Plus', 'A', 'Spawned', 'I', 'PL/SQL', 'L', 'SQL*Loader', fee.execution_method_code)
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_application fa
where fee.executable_id = fcp.executable_id
and fcp.application_id = fa.application_id
and (fa.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(fcp.concurrent_program_name) LIKE 'XX%' OR upper(fee.executable_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_CONCURRENT_PROGRAMS]

prompt [SECTION_START:CEMLI_FORMS_AND_PAGES]
select fa.application_short_name ||'|'|| ff.form_name ||'|'|| ff.user_form_name
from apps.fnd_form_vl ff, apps.fnd_application_vl fa
where ff.application_id = fa.application_id
and (fa.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(ff.form_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_FORMS_AND_PAGES]

prompt [SECTION_START:CEMLI_OAF_PAGES]
SELECT DISTINCT jp.path_name ||'|'|| jp.the_path ||'|'|| jat.att_name ||'|'|| jat.att_value
FROM (SELECT path_name, path_docid, path_type, sys_connect_by_path(path_name, '/') the_path,
             CONNECT_BY_ISLEAF is_leaf, created_by, last_update_date
      FROM apps.jdr_paths CONNECT BY path_owner_docid = PRIOR path_docid
      START WITH path_owner_docid = 0) jp, apps.jdr_attributes jat
WHERE is_leaf = 1 AND path_type = 'DOCUMENT' AND created_by NOT IN ('1')
AND jp.path_docid = jat.att_comp_docid
AND (jat.att_name = 'amDefName' OR jat.att_name = 'controllerClass' OR jat.att_name = 'viewName')
AND (upper(path_name) LIKE 'XX%' OR upper(the_path) LIKE '%XX%')
AND upper(the_path) NOT LIKE '%/CUSTOMIZATIONS/%'
ORDER BY 1;
prompt [SECTION_END:CEMLI_OAF_PAGES]

prompt [SECTION_START:CEMLI_OAF_PERSONALIZATIONS]
SELECT DISTINCT jp.path_name ||'|'|| jp.the_path ||'|'|| TO_CHAR(jp.last_update_date, 'YYYY-MM-DD HH24:MI:SS')
FROM (SELECT path_name, path_docid, path_type, sys_connect_by_path(path_name, '/') the_path,
             CONNECT_BY_ISLEAF is_leaf, created_by, last_update_date
      FROM apps.jdr_paths CONNECT BY path_owner_docid = PRIOR path_docid
      START WITH path_owner_docid = 0) jp
WHERE (LOWER(jp.the_path) LIKE '%customizations%' OR LOWER(jp.the_path) LIKE '%site%' OR LOWER(jp.the_path) LIKE '%/perz/%')
AND jp.is_leaf = 1 
AND jp.path_type = 'DOCUMENT' 
AND jp.created_by NOT IN ('1', '-1')
ORDER BY jp.last_update_date DESC;
prompt [SECTION_END:CEMLI_OAF_PERSONALIZATIONS]

prompt [SECTION_START:CEMLI_LOOKUPS]
SELECT flt.application_id ||'|'|| flt.lookup_type ||'|'|| ftl.application_name ||'|'|| flt.meaning
FROM apps.fnd_lookup_types_vl flt, apps.fnd_application_tl ftl
WHERE flt.application_id = ftl.application_id AND ftl.language = 'US'
AND (flt.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(flt.lookup_type) LIKE 'XX%');
prompt [SECTION_END:CEMLI_LOOKUPS]

prompt [SECTION_START:CEMLI_MENUS]
SELECT fm.menu_id ||'|'|| fm.menu_name ||'|'|| fm.user_menu_name ||'|'|| fa.application_name
FROM apps.fnd_menus_vl fm, apps.fnd_application_tl fa
WHERE fm.application_id = fa.application_id(+) AND fa.language(+) = 'US'
AND (fm.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(fm.menu_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_MENUS]

prompt [SECTION_START:CEMLI_MESSAGES]
SELECT fnm.application_id ||'|'|| fnm.message_name ||'|'|| fa.application_name ||'|'|| fnm.message_text
FROM apps.fnd_new_messages fnm, apps.fnd_application_tl fa
WHERE fnm.application_id = fa.application_id AND fa.language = 'US' AND fnm.language_code = 'US'
AND (fnm.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(fnm.message_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_MESSAGES]

prompt [SECTION_START:CEMLI_PROFILES]
SELECT fpo.profile_option_id ||'|'|| fpo.profile_option_name ||'|'|| fpot.user_profile_option_name ||'|'|| fa.application_name
FROM apps.fnd_profile_options fpo, apps.fnd_profile_options_tl fpot, apps.fnd_application_tl fa
WHERE fpo.profile_option_name = fpot.profile_option_name AND fpot.language = 'US'
AND fpo.application_id = fa.application_id AND fa.language = 'US'
AND (fpo.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(fpo.profile_option_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_PROFILES]

prompt [SECTION_START:CEMLI_REQUEST_GROUPS]
SELECT frg.request_group_id ||'|'|| frg.request_group_name ||'|'|| fa.application_name ||'|'|| frg.description
FROM apps.fnd_request_groups frg, apps.fnd_application_tl fa
WHERE frg.application_id = fa.application_id AND fa.language = 'US'
AND (frg.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(frg.request_group_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_REQUEST_GROUPS]

prompt [SECTION_START:CEMLI_REQUEST_SETS]
SELECT frs.request_set_id ||'|'|| frs.request_set_name ||'|'|| frs.user_request_set_name ||'|'|| fa.application_name
FROM apps.fnd_request_sets_vl frs, apps.fnd_application_tl fa
WHERE frs.application_id = fa.application_id AND fa.language = 'US'
AND (frs.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(frs.request_set_name) LIKE 'XX%');
prompt [SECTION_END:CEMLI_REQUEST_SETS]

prompt [SECTION_START:CEMLI_VALUE_SETS]
SELECT fvs.flex_value_set_id ||'|'|| fvs.flex_value_set_name ||'|'|| fvs.description ||'|'|| fvs.validation_type
FROM apps.fnd_flex_value_sets fvs
WHERE fvs.created_by NOT IN (SELECT user_id FROM apps.fnd_user WHERE user_name LIKE 'ORACLE12%' 
     OR user_name IN ('INITIAL SETUP','AUTOINSTALL'))
OR upper(fvs.flex_value_set_name) LIKE 'XX%';
prompt [SECTION_END:CEMLI_VALUE_SETS]

prompt [SECTION_START:DB_INIT_PARAMS_FULL]
select name ||'|'|| value ||'|'|| isdefault ||'|'|| ismodified 
from v$system_parameter where isdefault='FALSE' order by name;
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
select 'MENUS' ||'|'|| user_menu_name from apps.fnd_menus_vl where menu_name like 'XX%'
union all
select 'RESPONSIBILITIES' ||'|'|| responsibility_name from apps.fnd_responsibility_vl where responsibility_key like 'XX%'
union all
select 'FUNCTIONS' ||'|'|| user_function_name from apps.fnd_form_functions_vl where function_name like 'XX%'
union all
select 'LOOKUPS' ||'|'|| meaning from apps.fnd_lookup_types_vl where lookup_type like 'XX%'
union all
select 'VALUE_SETS' ||'|'|| description from apps.fnd_flex_value_sets where flex_value_set_name like 'XX%'
union all
select 'DFFS' ||'|'|| title from apps.fnd_descriptive_flexs_vl where descriptive_flexfield_name like 'XX%';
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
select 'FND_ATTACHED_DOCS' ||'|'|| count(*) from apps.fnd_attached_documents;
prompt [SECTION_END:WORKLOAD_STATISTICS]

prompt [SECTION_START:ORACLE_ALERTS_LIST]
select fa.application_short_name ||'|'|| a.alert_name ||'|'|| a.description ||'|'|| a.alert_condition_type
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
select fv.profile_option_value ||'|'|| fp.profile_option_name ||'|'|| nvl(n.node_name, nvl(r.responsibility_name, fv.level_value))
from apps.fnd_profile_option_values fv, apps.fnd_profile_options fp, apps.fnd_nodes n, apps.fnd_responsibility_vl r
where fv.profile_option_id = fp.profile_option_id 
and fp.profile_option_name in ('NODE_TRUST_LEVEL', 'RESP_TRUST_LEVEL')
and fv.level_value = n.node_id(+)
and fv.level_value = r.responsibility_id(+);
prompt [SECTION_END:EBS_DMZ_EXTERNAL_NODES]

prompt [SECTION_START:EBS_APEX_ORDS_VERSION]
select comp_name ||'|'|| version ||'|'|| status from dba_registry where comp_id in ('APEX', 'ORDS');
prompt [SECTION_END:EBS_APEX_ORDS_VERSION]

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
and fou.oracle_id >= 20000
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

prompt [SECTION_START:CEMLI_AME_RULES]
select 'AME_CUSTOM_RULES' ||'|'|| count(*) from apps.ame_rules where rule_key like 'XX%' or created_by > 1;
prompt [SECTION_END:CEMLI_AME_RULES]

-- Enhanced Data Collection for Upgrade Analysis

prompt [SECTION_START:AD_TXK_VERSIONS]
select 'AD' ||'|'|| (select coalesce(patch_level,'UNKNOWN') from apps.fnd_product_installations where application_id = 0)
from dual;
select 'TXK' ||'|'|| (select coalesce(patch_level,'UNKNOWN') from apps.fnd_product_installations where application_id = 535)
from dual;
select 'FND' ||'|'|| (select coalesce(patch_level,'UNKNOWN') from apps.fnd_product_installations where application_id = 0)
from dual;
prompt [SECTION_END:AD_TXK_VERSIONS]

prompt [SECTION_START:TECH_STACK_VERSIONS]
-- Extract WebLogic Server version from context files
select 'WLS_VERSION' ||'|'|| EXTRACTVALUE(XMLType(TEXT),'(/oa_context/WLS_HOME/@version)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A' 
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' group by node_name)
and rownum = 1;
-- Extract OHS version from context files  
select 'OHS_VERSION' ||'|'|| EXTRACTVALUE(XMLType(TEXT),'(/oa_context/OHS_HOME/@version)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' group by node_name)
and rownum = 1;
-- Extract Forms version from context files
select 'FORMS_VERSION' ||'|'|| EXTRACTVALUE(XMLType(TEXT),'(/oa_context/FORMS_HOME/@version)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' group by node_name)
and rownum = 1;
-- Extract Oracle Home base versions
select 'ORACLE_HOME' ||'|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_10205_oracle_home)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' group by node_name)
and rownum = 1;
-- Extract JDK version
select 'JDK_VERSION' ||'|'|| EXTRACTVALUE(XMLType(TEXT),'(//s_jdk_top)[1]')
from apps.fnd_oam_context_files
where status = 'S' and ctx_type = 'A'
and (node_name, last_update_date) in 
    (select node_name, max(last_update_date) from apps.fnd_oam_context_files where status = 'S' group by node_name)
and rownum = 1;
prompt [SECTION_END:TECH_STACK_VERSIONS]

prompt [SECTION_START:DB_CHARACTER_SET]
select parameter ||'|'|| value from nls_database_parameters where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET','NLS_LANGUAGE','NLS_TERRITORY','NLS_DATE_FORMAT');
prompt [SECTION_END:DB_CHARACTER_SET]

prompt [SECTION_START:DB_TABLESPACES]
select tablespace_name ||'|'|| round(sum(bytes)/1024/1024/1024,2) ||'|'|| status
from dba_data_files group by tablespace_name, status order by sum(bytes) desc;
prompt [SECTION_END:DB_TABLESPACES]

prompt [SECTION_START:DB_REDO_LOGS]
select group# ||'|'|| members ||'|'|| round(bytes/1024/1024,0) ||'|'|| status from v$log;
prompt [SECTION_END:DB_REDO_LOGS]

prompt [SECTION_START:DB_ARCHIVE_MODE]
select log_mode ||'|'|| force_logging ||'|'|| supplemental_log_data_min from v$database;
prompt [SECTION_END:DB_ARCHIVE_MODE]

prompt [SECTION_START:DB_FEATURES_USED]
select * from (select name ||'|'|| detected_usages ||'|'|| currently_used from dba_feature_usage_statistics where detected_usages > 0 order by detected_usages desc) where rownum <= 30;
prompt [SECTION_END:DB_FEATURES_USED]

prompt [SECTION_START:INVALID_OBJECTS_DETAIL]
select owner ||'|'|| object_type ||'|'|| count(*) from dba_objects where status = 'INVALID' and owner not in ('SYS','SYSTEM','WMSYS','XDB','CTXSYS','MDSYS','OLAPSYS','ORDDATA','ORDSYS') group by owner, object_type order by count(*) desc;
prompt [SECTION_END:INVALID_OBJECTS_DETAIL]

prompt [SECTION_START:AD_REGISTERED_SCHEMAS]
select oracle_username ||'|'|| read_only_flag from apps.fnd_oracle_userid 
where oracle_username like 'XX%' or oracle_username like 'CUSTOM%'
order by oracle_username;
prompt [SECTION_END:AD_REGISTERED_SCHEMAS]

prompt [SECTION_START:ONLINE_PATCHING_STATUS]
select fs_clone_status ||'|'|| adop_valid from apps.fnd_appl_tops where rownum = 1;
prompt [SECTION_END:ONLINE_PATCHING_STATUS]

prompt [SECTION_START:AD_APPLIED_PATCHES_RECENT]
select patch_name ||'|'|| patch_type ||'|'|| to_char(creation_date,'YYYY-MM-DD') from apps.ad_applied_patches where creation_date >= sysdate - 180 order by creation_date desc;
prompt [SECTION_END:AD_APPLIED_PATCHES_RECENT]

prompt [SECTION_START:EBS_RESPONSIBILITIES]
select count(*) ||'|'|| decode(end_date, null, 'ACTIVE', 'INACTIVE') from apps.fnd_responsibility where responsibility_key like 'XX%' or responsibility_key like 'XX%' group by decode(end_date, null, 'ACTIVE', 'INACTIVE');
prompt [SECTION_END:EBS_RESPONSIBILITIES]

prompt [SECTION_START:CUSTOM_MENUS]
select user_menu_name from apps.fnd_menus_vl where menu_name like 'XX%' or menu_name like 'CUST%';
prompt [SECTION_END:CUSTOM_MENUS]

prompt [SECTION_START:CUSTOM_FUNCTIONS]
select user_function_name from apps.fnd_form_functions_vl where function_name like 'XX%' or function_name like 'CUST%';
prompt [SECTION_END:CUSTOM_FUNCTIONS]

prompt [SECTION_START:CUSTOM_LOOKUPS]
select meaning from apps.fnd_lookup_types_vl where lookup_type like 'XX%' or lookup_type like 'CUST%';
prompt [SECTION_END:CUSTOM_LOOKUPS]

prompt [SECTION_START:CUSTOM_VALUE_SETS]
select description from apps.fnd_flex_value_sets where flex_value_set_name like 'XX%' or flex_value_set_name like 'CUST%';
prompt [SECTION_END:CUSTOM_VALUE_SETS]

prompt [SECTION_START:CUSTOM_DFF]
select title from apps.fnd_descriptive_flexs_vl where descriptive_flexfield_name like 'XX%' or title like '%Custom%';
prompt [SECTION_END:CUSTOM_DFF]

prompt [SECTION_START:SCHEDULER_JOBS]
select owner ||'|'|| job_name ||'|'|| state from dba_scheduler_jobs where owner not in ('SYS','SYSTEM','EXFSYS') and rownum <= 50 order by owner;
prompt [SECTION_END:SCHEDULER_JOBS]

prompt [SECTION_START:DB_LINKS_DETAIL]
select owner ||'|'|| db_link ||'|'|| host from dba_db_links order by owner, db_link;
prompt [SECTION_END:DB_LINKS_DETAIL]

prompt [SECTION_START:LOB_SIZES]
select owner ||'|'|| table_name ||'|'|| column_name ||'|'|| segment_name from dba_lobs where owner in ('APPS','APPLSYS') and rownum <= 20;
prompt [SECTION_END:LOB_SIZES]

prompt [SECTION_START:MATERIALIZED_VIEWS]
select owner ||'|'|| mview_name ||'|'|| refresh_mode ||'|'|| last_refresh_date from dba_mviews where owner not in ('SYS','SYSTEM') and rownum <= 30;
prompt [SECTION_END:MATERIALIZED_VIEWS]

prompt [SECTION_START:PARTITIONED_TABLES]
select owner ||'|'|| table_name ||'|'|| partitioning_type ||'|'|| partition_count from dba_part_tables where owner in ('APPS','AP','AR','GL','PO','INV','HR','PA') and rownum <= 30;
prompt [SECTION_END:PARTITIONED_TABLES]

prompt [SECTION_START:EBS_TIMEZONES]
select timezone_code ||'|'|| enabled_flag from apps.fnd_timezones_b where enabled_flag = 'Y';
prompt [SECTION_END:EBS_TIMEZONES]

prompt [SECTION_START:EBS_TERRITORIES]
select a.territory_code ||'|'|| count(*) as orgs 
from apps.hr_all_organization_units o, apps.fnd_territories a 
where o.location_id is not null and rownum <= 10 
group by a.territory_code;
prompt [SECTION_END:EBS_TERRITORIES]

prompt [SECTION_START:CONCURRENT_REQUESTS_STATS]
select status_code ||'|'|| phase_code ||'|'|| count(*) from apps.fnd_concurrent_requests where requested_start_date > sysdate - 30 group by status_code, phase_code;
prompt [SECTION_END:CONCURRENT_REQUESTS_STATS]

prompt [SECTION_START:ATTACHMENTS_COUNT]
select 'ATTACHMENTS' ||'|'|| count(*) from apps.fnd_attached_documents;
prompt [SECTION_END:ATTACHMENTS_COUNT]

prompt [SECTION_START:ACTIVE_USERS_WITH_RESPONSIBILITIES]
select fu.user_name ||'|'|| frv.responsibility_name
from apps.fnd_user fu, apps.fnd_user_resp_groups_direct furgd, apps.fnd_responsibility_vl frv
where fu.user_id = furgd.user_id
and furgd.responsibility_id = frv.responsibility_id
and furgd.end_date is null
and furgd.start_date <= sysdate
and nvl(furgd.end_date, sysdate + 1) > sysdate
and fu.start_date <= sysdate
and nvl(fu.end_date, sysdate + 1) > sysdate
and frv.start_date <= sysdate
and nvl(frv.end_date, sysdate + 1) > sysdate
and rownum <= 1000;
prompt [SECTION_END:ACTIVE_USERS_WITH_RESPONSIBILITIES]

prompt [SECTION_START:APPLIED_PATCHES_90_DAYS]
select distinct e.patch_name ||'|'|| trunc(a.last_update_date) ||'|'|| b.applied_flag
from apps.ad_bugs a, apps.ad_patch_run_bugs b, apps.ad_patch_runs c, apps.ad_patch_drivers d, apps.ad_applied_patches e
where a.bug_id = b.bug_id
and b.patch_run_id = c.patch_run_id
and c.patch_driver_id = d.patch_driver_id
and d.applied_patch_id = e.applied_patch_id
and a.last_update_date >= sysdate - 90
order by 1 desc;
prompt [SECTION_END:APPLIED_PATCHES_90_DAYS]

prompt [SECTION_START:TOP_100_CONC_PROGS_BY_EXEC]
select * from (
select a.user_concurrent_program_name ||'|'|| count(actual_completion_date)
from apps.fnd_conc_req_summary_v a
where phase_code = 'C' and status_code = 'C'
and a.requested_start_date > sysdate - 30
group by a.user_concurrent_program_name
order by count(actual_completion_date) desc)
where rownum <= 100;
prompt [SECTION_END:TOP_100_CONC_PROGS_BY_EXEC]

prompt [SECTION_START:TOP_100_CONC_PROGS_BY_AVG_TIME]
select * from (
select a.user_concurrent_program_name ||'|'|| count(actual_completion_date) ||'|'||
round(avg((nvl(actual_completion_date, sysdate) - a.requested_start_date) * 24), 2) ||'|'||
round(max((nvl(actual_completion_date, sysdate) - a.requested_start_date) * 24), 2) ||'|'||
round(min((nvl(actual_completion_date, sysdate) - a.requested_start_date) * 24), 2)
from apps.fnd_conc_req_summary_v a
where phase_code = 'C' and status_code = 'C'
and a.requested_start_date > sysdate - 30
group by a.user_concurrent_program_name
order by avg((nvl(actual_completion_date, sysdate) - a.requested_start_date) * 24) desc)
where rownum <= 100;
prompt [SECTION_END:TOP_100_CONC_PROGS_BY_AVG_TIME]

prompt [SECTION_START:FLAGGED_FILES_FOR_UPGRADE]
select * from (
select af.app_short_name ||'|'|| af.subdir ||'|'|| af.filename ||'|'|| afv.version ||'|'|| afv.translation_level ||'|'|| to_char(afv.creation_date, 'YYYY-MM-DD')
from apps.ad_files af, apps.ad_file_versions afv
where af.file_id = afv.file_id
and (af.filename like 'XX%' or af.filename like 'xx%' or af.subdir like '%/custom%' or af.subdir like '%/XX%')
order by afv.creation_date desc)
where rownum <= 500;
prompt [SECTION_END:FLAGGED_FILES_FOR_UPGRADE]

prompt [SECTION_START:CUSTOM_TOP_FILES]
select name ||'|'|| appl_top_id ||'|'|| nvl(server_type_admin_flag, 'N/A')
from apps.ad_appl_tops
where name like 'XX%' or name like 'CUSTOM%';
prompt [SECTION_END:CUSTOM_TOP_FILES]

prompt [SECTION_START:AD_FILES_BY_TYPE]
select substr(af.filename, instr(af.filename, '.', -1) + 1) ||'|'|| count(*)
from apps.ad_files af
where af.filename like 'XX%' or af.filename like 'xx%'
group by substr(af.filename, instr(af.filename, '.', -1) + 1)
order by count(*) desc;
prompt [SECTION_END:AD_FILES_BY_TYPE]

prompt [SECTION_START:PATCHED_FILES_RECENT]
select * from (
select af.app_short_name ||'|'|| af.filename ||'|'|| aap.patch_name ||'|'|| to_char(aap.creation_date, 'YYYY-MM-DD')
from apps.ad_files af, apps.ad_applied_patches aap, apps.ad_patch_drivers apd, apps.ad_patch_runs apr, apps.ad_patch_run_bugs aprb
where aap.applied_patch_id = apd.applied_patch_id
and apd.patch_driver_id = apr.patch_driver_id
and apr.patch_run_id = aprb.patch_run_id
and aap.creation_date >= sysdate - 90
and af.app_short_name is not null
order by aap.creation_date desc)
where rownum <= 200;
prompt [SECTION_END:PATCHED_FILES_RECENT]

-- CEMLI Extract: Custom Application Objects
-- Filter for non-Oracle-seeded applications (created by non-system users OR XX-prefixed)

prompt [SECTION_START:CEMLI_CUSTOM_APPLICATIONS]
select a.application_id ||'|'|| a.application_name ||'|'|| a.application_short_name ||'|'|| a.basepath ||'|'|| to_char(a.creation_date, 'YYYY-MM-DD')
from apps.fnd_application_vl a, apps.fnd_user u
where u.user_id = a.created_by
and (
    (u.user_name not like 'ORACLE%' 
     and u.user_name not in ('INITIAL SETUP','AUTOINSTALL','SYSADMIN') 
     and a.application_id >= 20000) 
    or a.application_short_name like 'XX%'
)
and rownum <= 100;
prompt [SECTION_END:CEMLI_CUSTOM_APPLICATIONS]

prompt [SECTION_START:CEMLI_CUSTOM_ALERTS]
select aa.alert_name ||'|'|| fav.application_name ||'|'|| decode(aa.alert_condition_type, 'E', 'Event', 'P', 'Periodic', aa.alert_condition_type) ||'|'|| decode(aa.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled', 'Enabled')
from apps.alr_alerts aa, apps.fnd_application_vl fav
where aa.application_id = fav.application_id
and (fav.application_short_name like 'XX%' or upper(aa.alert_name) like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CUSTOM_ALERTS]

prompt [SECTION_START:CEMLI_CONC_PROG_HOST]
select fcpt.user_concurrent_program_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.execution_file_name ||'|'|| fee.executable_name ||'|'|| decode(fcp.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled')
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_concurrent_programs_tl fcpt
where fee.executable_id = fcp.executable_id
and fcp.concurrent_program_id = fcpt.concurrent_program_id
and fcpt.language = 'US'
and fee.execution_method_code = 'H'
and (fee.executable_name like 'XX%' or fcp.concurrent_program_name like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CONC_PROG_HOST]

prompt [SECTION_START:CEMLI_CONC_PROG_JAVA]
select fcpt.user_concurrent_program_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.execution_file_name ||'|'|| fee.executable_name ||'|'|| decode(fcp.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled')
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_concurrent_programs_tl fcpt
where fee.executable_id = fcp.executable_id
and fcp.concurrent_program_id = fcpt.concurrent_program_id
and fcpt.language = 'US'
and fee.execution_method_code in ('J', 'K')
and (fee.executable_name like 'XX%' or fcp.concurrent_program_name like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CONC_PROG_JAVA]

prompt [SECTION_START:CEMLI_CONC_PROG_REPORTS]
select fcpt.user_concurrent_program_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.execution_file_name ||'|'|| fee.executable_name ||'|'|| decode(fcp.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled')
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_concurrent_programs_tl fcpt
where fee.executable_id = fcp.executable_id
and fcp.concurrent_program_id = fcpt.concurrent_program_id
and fcpt.language = 'US'
and fee.execution_method_code = 'P'
and (fee.executable_name like 'XX%' or fcp.concurrent_program_name like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CONC_PROG_REPORTS]

prompt [SECTION_START:CEMLI_CONC_PROG_SQLLOADER]
select fcpt.user_concurrent_program_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.execution_file_name ||'|'|| fee.executable_name ||'|'|| decode(fcp.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled')
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_concurrent_programs_tl fcpt
where fee.executable_id = fcp.executable_id
and fcp.concurrent_program_id = fcpt.concurrent_program_id
and fcpt.language = 'US'
and fee.execution_method_code = 'L'
and (fee.executable_name like 'XX%' or fcp.concurrent_program_name like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CONC_PROG_SQLLOADER]

prompt [SECTION_START:CEMLI_CONC_PROG_SQLPLUS]
select fcpt.user_concurrent_program_name ||'|'|| fcp.concurrent_program_name ||'|'|| fee.execution_file_name ||'|'|| fee.executable_name ||'|'|| decode(fcp.enabled_flag, 'N', 'Disabled', 'Y', 'Enabled')
from apps.fnd_executables fee, apps.fnd_concurrent_programs fcp, apps.fnd_concurrent_programs_tl fcpt
where fee.executable_id = fcp.executable_id
and fcp.concurrent_program_id = fcpt.concurrent_program_id
and fcpt.language = 'US'
and fee.execution_method_code = 'Q'
and (fee.executable_name like 'XX%' or fcp.concurrent_program_name like 'XX%')
and rownum <= 200;
prompt [SECTION_END:CEMLI_CONC_PROG_SQLPLUS]

-- CEMLI Extract: Custom Database Objects (Comprehensive)

prompt [SECTION_START:CEMLI_DB_FUNCTIONS]
select object_name ||'|'|| object_type ||'|'|| owner ||'|'|| status ||'|'|| to_char(created, 'YYYY-MM-DD') ||'|'|| to_char(last_ddl_time, 'YYYY-MM-DD')
from all_objects
where object_type = 'FUNCTION'
and owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(object_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_FUNCTIONS]

prompt [SECTION_START:CEMLI_DB_INDEXES]
select ai.index_name ||'|'|| ai.index_type ||'|'|| ai.owner ||'|'|| ai.status ||'|'|| ai.table_name ||'|'|| ai.uniqueness
from all_indexes ai
where ai.owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(ai.index_name) like 'XX%' OR ai.owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_INDEXES]

prompt [SECTION_START:CEMLI_DB_LOBS]
select al.table_name ||'|'|| al.column_name ||'|'|| al.owner ||'|'|| al.segment_name ||'|'|| al.tablespace_name ||'|'|| al.chunk
from all_lobs al
where al.owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(al.table_name) like 'XX%' OR al.owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_LOBS]

prompt [SECTION_START:CEMLI_DB_PACKAGES]
select object_name ||'|'|| object_type ||'|'|| owner ||'|'|| status ||'|'|| to_char(created, 'YYYY-MM-DD') ||'|'|| to_char(last_ddl_time, 'YYYY-MM-DD')
from all_objects
where object_type in ('PACKAGE', 'PACKAGE BODY')
and owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(object_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_PACKAGES]

prompt [SECTION_START:CEMLI_DB_PROCEDURES]
select object_name ||'|'|| object_type ||'|'|| owner ||'|'|| status ||'|'|| to_char(created, 'YYYY-MM-DD') ||'|'|| to_char(last_ddl_time, 'YYYY-MM-DD')
from all_objects
where object_type = 'PROCEDURE'
and owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(object_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_PROCEDURES]

prompt [SECTION_START:CEMLI_DB_SEQUENCES]
select sequence_name ||'|'|| sequence_owner ||'|'|| min_value ||'|'|| max_value ||'|'|| increment_by ||'|'|| last_number
from all_sequences
where sequence_owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(sequence_name) like 'XX%' OR sequence_owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_SEQUENCES]

prompt [SECTION_START:CEMLI_DB_SYNONYMS]
select synonym_name ||'|'|| owner ||'|'|| table_owner ||'|'|| table_name ||'|'|| db_link
from all_synonyms
where owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100','PUBLIC')
and (upper(synonym_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_SYNONYMS]

prompt [SECTION_START:CEMLI_DB_TABLES]
select at.table_name ||'|'|| at.owner ||'|'|| at.tablespace_name ||'|'|| at.num_rows ||'|'|| at.partitioned ||'|'|| to_char(ao.created, 'YYYY-MM-DD')
from all_tables at, all_objects ao
where at.owner = ao.owner and at.table_name = ao.object_name and ao.object_type = 'TABLE'
and at.owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(at.table_name) like 'XX%' OR at.owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_TABLES]

prompt [SECTION_START:CEMLI_DB_TRIGGERS]
select trigger_name ||'|'|| owner ||'|'|| table_owner ||'|'|| table_name ||'|'|| triggering_event ||'|'|| status
from all_triggers
where owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(trigger_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_TRIGGERS]

prompt [SECTION_START:CEMLI_DB_TYPES]
select object_name ||'|'|| object_type ||'|'|| owner ||'|'|| status ||'|'|| to_char(created, 'YYYY-MM-DD') ||'|'|| to_char(last_ddl_time, 'YYYY-MM-DD')
from all_objects
where object_type in ('TYPE', 'TYPE BODY')
and owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(object_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_TYPES]

prompt [SECTION_START:CEMLI_DB_VIEWS]
select av.view_name ||'|'|| av.owner ||'|'|| ao.status ||'|'|| to_char(ao.created, 'YYYY-MM-DD') ||'|'|| to_char(ao.last_ddl_time, 'YYYY-MM-DD')
from all_views av, all_objects ao
where av.owner = ao.owner and av.view_name = ao.object_name and ao.object_type = 'VIEW'
and av.owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(av.view_name) like 'XX%' OR av.owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_VIEWS]

prompt [SECTION_START:CEMLI_DB_MVIEWS]
select mview_name ||'|'|| owner ||'|'|| container_name ||'|'|| refresh_mode ||'|'|| refresh_method ||'|'|| staleness
from all_mviews
where owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(mview_name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_MVIEWS]

prompt [SECTION_START:CEMLI_DB_QUEUES]
select name ||'|'|| owner ||'|'|| queue_table ||'|'|| queue_type ||'|'|| enqueue_enabled ||'|'|| dequeue_enabled
from all_queues
where owner not in ('SYS','SYSTEM','APPS_MRC','CTXSYS','MDSYS','XDB','WMSYS','ORDSYS','ORDDATA','APEX_050100')
and (upper(name) like 'XX%' OR owner like 'XX%');
prompt [SECTION_END:CEMLI_DB_QUEUES]

prompt [SECTION_START:CEMLI_WORKFLOWS]
select wit.item_type ||'|'|| wit.display_name ||'|'|| wit.persistence_type ||'|'|| wit.persistence_days ||'|'|| 
       (select count(*) from apps.wf_activities wa where wa.item_type = wit.item_type) activity_count
from apps.wf_item_types_vl wit
where upper(wit.item_type) like 'XX%'
or wit.item_type in (select distinct item_type from apps.wf_process_activities where process_name like 'XX%');
prompt [SECTION_END:CEMLI_WORKFLOWS]

-- CEMLI Extract: Custom Reporting Objects

prompt [SECTION_START:CEMLI_XML_TEMPLATES]
SELECT DISTINCT xtv.application_id ||'|'|| xtv.template_code ||'|'|| xtv.template_name ||'|'|| 
       nvl(xtv.description, 'No Description') ||'|'|| fav.application_name ||'|'|| 
       xtv.template_type_code ||'|'|| decode(xtv.template_status, 'E', 'Enabled', 'D', 'Disabled', xtv.template_status)
FROM apps.xdo_templates_vl xtv, apps.fnd_application_vl fav
WHERE fav.application_id = xtv.application_id
AND (xtv.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(xtv.template_code) LIKE 'XX%');
prompt [SECTION_END:CEMLI_XML_TEMPLATES]

prompt [SECTION_START:CEMLI_DATA_DEFINITIONS]
SELECT DISTINCT xdd.application_id ||'|'|| xdd.data_source_code ||'|'|| xdd.data_source_name ||'|'|| 
       nvl(xdd.description, 'No Description') ||'|'|| fav.application_name ||'|'|| 
       decode(xdd.data_source_status, 'E', 'Enabled', 'D', 'Disabled', xdd.data_source_status) ||'|'|| to_char(xdd.creation_date, 'YYYY-MM-DD')
FROM apps.xdo_ds_definitions_vl xdd, apps.fnd_application_vl fav
WHERE fav.application_id = xdd.application_id
AND (xdd.application_id IN (SELECT app.application_id FROM apps.fnd_application app, apps.fnd_user usr
     WHERE usr.user_id = app.created_by AND usr.user_name NOT LIKE 'ORACLE12%'
     AND usr.user_name NOT IN ('INITIAL SETUP','AUTOINSTALL') AND app.application_id >= 20000)
     OR upper(xdd.data_source_code) LIKE 'XX%');
prompt [SECTION_END:CEMLI_DATA_DEFINITIONS]

-- Data Reconciliator: Business Group and Organization Structure

prompt [SECTION_START:DATA_BUSINESS_GROUPS]
select otl.name ||'|'|| o.organization_id ||'|'|| to_char(o.date_from, 'YYYY-MM-DD') ||'|'|| nvl(to_char(o.date_to, 'YYYY-MM-DD'), 'Active') ||'|'|| nvl(o3.org_information9, 'N/A') ||'|'|| nvl(o3.org_information10, 'N/A')
from apps.hr_all_organization_units o, apps.hr_all_organization_units_tl otl, apps.hr_organization_information o3, apps.hr_organization_information o4
where o.organization_id = otl.organization_id
and o.organization_id = o3.organization_id
and o.organization_id = o4.organization_id
and o3.org_information_context = 'Business Group Information'
and o4.org_information_context = 'CLASS'
and o4.org_information1 = 'HR_BG'
and o4.org_information2 = 'Y'
and otl.language = 'US';
prompt [SECTION_END:DATA_BUSINESS_GROUPS]

prompt [SECTION_START:DATA_SET_OF_BOOKS]
select sob.set_of_books_id ||'|'|| sob.name ||'|'|| sob.short_name ||'|'|| sob.currency_code ||'|'|| sob.accounted_period_type ||'|'|| nvl(sob.latest_opened_period_name, 'N/A') ||'|'|| fc.name
from apps.gl_sets_of_books sob, apps.fnd_currencies_vl fc
where sob.currency_code = fc.currency_code;
prompt [SECTION_END:DATA_SET_OF_BOOKS]

prompt [SECTION_START:DATA_LEGAL_ENTITIES]
select xep.legal_entity_id ||'|'|| xep.name ||'|'|| xep.legal_entity_identifier ||'|'|| nvl(hla.country, 'N/A') ||'|'|| nvl(hla.address_line_1, 'N/A') ||'|'|| to_char(xep.effective_from, 'YYYY-MM-DD') ||'|'|| nvl(to_char(xep.effective_to, 'YYYY-MM-DD'), 'Active')
from apps.xle_entity_profiles xep, apps.hr_locations_all hla
where xep.registered_address_id = hla.location_id(+);
prompt [SECTION_END:DATA_LEGAL_ENTITIES]

prompt [SECTION_START:DATA_OPERATING_UNITS]
select hou.organization_id ||'|'|| hou.name ||'|'|| hou.short_code ||'|'|| hout.name ||'|'|| to_char(hou.date_from, 'YYYY-MM-DD') ||'|'|| nvl(to_char(hou.date_to, 'YYYY-MM-DD'), 'Active')
from apps.hr_operating_units hou, apps.hr_all_organization_units_tl hout
where hou.business_group_id = hout.organization_id(+) and hout.language(+) = 'US';
prompt [SECTION_END:DATA_OPERATING_UNITS]

prompt [SECTION_START:DATA_INVENTORY_ORGS]
select mp.organization_id ||'|'|| mp.organization_code ||'|'|| ood.organization_name ||'|'|| ood.operating_unit ||'|'|| nvl(mp.master_organization_id, 0) ||'|'|| nvl(to_char(ood.disable_date, 'YYYY-MM-DD'), 'Active')
from apps.mtl_parameters mp, apps.org_organization_definitions ood
where mp.organization_id = ood.organization_id;
prompt [SECTION_END:DATA_INVENTORY_ORGS]

-- Data Reconciliator: Module-Specific Data Volumes

prompt [SECTION_START:DATA_AP_VOLUMES]
select 'AP_INVOICES' ||'|'|| count(*) from apps.ap_invoices_all union all
select 'AP_SUPPLIERS' ||'|'|| count(*) from apps.ap_suppliers union all
select 'AP_SUPPLIER_SITES' ||'|'|| count(*) from apps.ap_supplier_sites_all union all
select 'AP_PAYMENTS' ||'|'|| count(*) from apps.ap_checks_all union all
select 'AP_INVOICE_LINES' ||'|'|| count(*) from apps.ap_invoice_lines_all union all
select 'AP_INVOICE_DISTRIBUTIONS' ||'|'|| count(*) from apps.ap_invoice_distributions_all union all
select 'AP_PAYMENT_SCHEDULES' ||'|'|| count(*) from apps.ap_payment_schedules_all union all
select 'AP_HOLDS' ||'|'|| count(*) from apps.ap_holds_all;
prompt [SECTION_END:DATA_AP_VOLUMES]

prompt [SECTION_START:DATA_AR_VOLUMES]
select 'AR_CUSTOMERS' ||'|'|| count(*) from apps.hz_cust_accounts union all
select 'AR_CUSTOMER_SITES' ||'|'|| count(*) from apps.hz_cust_acct_sites_all union all
select 'AR_INVOICES' ||'|'|| count(*) from apps.ra_customer_trx_all union all
select 'AR_RECEIPTS' ||'|'|| count(*) from apps.ar_cash_receipts_all union all
select 'AR_INVOICE_LINES' ||'|'|| count(*) from apps.ra_customer_trx_lines_all union all
select 'AR_INVOICE_DISTRIBUTIONS' ||'|'|| count(*) from apps.ra_cust_trx_line_gl_dist_all union all
select 'AR_RECEIVABLE_APPS' ||'|'|| count(*) from apps.ar_receivable_applications_all union all
select 'AR_PAYMENT_SCHEDULES' ||'|'|| count(*) from apps.ar_payment_schedules_all;
prompt [SECTION_END:DATA_AR_VOLUMES]

prompt [SECTION_START:DATA_GL_VOLUMES]
select 'GL_LEDGERS' ||'|'|| count(*) from apps.gl_ledgers union all
select 'GL_PERIODS' ||'|'|| count(*) from apps.gl_periods union all
select 'GL_JOURNALS' ||'|'|| count(*) from apps.gl_je_headers union all
select 'GL_JOURNAL_LINES' ||'|'|| count(*) from apps.gl_je_lines union all
select 'GL_ACCOUNTS' ||'|'|| count(*) from apps.gl_code_combinations union all
select 'GL_BALANCES' ||'|'|| count(*) from apps.gl_balances union all
select 'GL_DAILY_RATES' ||'|'|| count(*) from apps.gl_daily_rates;
prompt [SECTION_END:DATA_GL_VOLUMES]

prompt [SECTION_START:DATA_PO_VOLUMES]
select 'PO_HEADERS' ||'|'|| count(*) from apps.po_headers_all union all
select 'PO_LINES' ||'|'|| count(*) from apps.po_lines_all union all
select 'PO_LINE_LOCATIONS' ||'|'|| count(*) from apps.po_line_locations_all union all
select 'PO_DISTRIBUTIONS' ||'|'|| count(*) from apps.po_distributions_all union all
select 'PO_REQUISITIONS' ||'|'|| count(*) from apps.po_requisition_headers_all union all
select 'PO_REQUISITION_LINES' ||'|'|| count(*) from apps.po_requisition_lines_all union all
select 'PO_RECEIPTS' ||'|'|| count(*) from apps.rcv_shipment_headers union all
select 'PO_RECEIPT_LINES' ||'|'|| count(*) from apps.rcv_shipment_lines union all
select 'PO_RCV_TRANSACTIONS' ||'|'|| count(*) from apps.rcv_transactions;
prompt [SECTION_END:DATA_PO_VOLUMES]

prompt [SECTION_START:DATA_OM_VOLUMES]
select 'OM_ORDERS' ||'|'|| count(*) from apps.oe_order_headers_all union all
select 'OM_ORDER_LINES' ||'|'|| count(*) from apps.oe_order_lines_all union all
select 'OM_ORDER_HOLDS' ||'|'|| count(*) from apps.oe_order_holds_all union all
select 'OM_PRICE_ADJUSTMENTS' ||'|'|| count(*) from apps.oe_price_adjustments union all
select 'OM_DELIVERIES' ||'|'|| count(*) from apps.wsh_delivery_details union all
select 'OM_DELIVERY_ASSIGNMENTS' ||'|'|| count(*) from apps.wsh_delivery_assignments union all
select 'OM_NEW_DELIVERIES' ||'|'|| count(*) from apps.wsh_new_deliveries;
prompt [SECTION_END:DATA_OM_VOLUMES]

prompt [SECTION_START:DATA_INV_VOLUMES]
select 'INV_ITEMS' ||'|'|| count(*) from apps.mtl_system_items_b union all
select 'INV_ITEM_CATEGORIES' ||'|'|| count(*) from apps.mtl_item_categories union all
select 'INV_ONHAND' ||'|'|| count(*) from apps.mtl_onhand_quantities_detail union all
select 'INV_TRANSACTIONS' ||'|'|| count(*) from apps.mtl_material_transactions union all
select 'INV_RESERVATIONS' ||'|'|| count(*) from apps.mtl_reservations union all
select 'INV_LOT_NUMBERS' ||'|'|| count(*) from apps.mtl_lot_numbers union all
select 'INV_SERIAL_NUMBERS' ||'|'|| count(*) from apps.mtl_serial_numbers;
prompt [SECTION_END:DATA_INV_VOLUMES]

prompt [SECTION_START:DATA_HR_VOLUMES]
select 'HR_EMPLOYEES' ||'|'|| count(*) from apps.per_all_people_f union all
select 'HR_ASSIGNMENTS' ||'|'|| count(*) from apps.per_all_assignments_f union all
select 'HR_POSITIONS' ||'|'|| count(*) from apps.hr_all_positions_f union all
select 'HR_ORGANIZATIONS' ||'|'|| count(*) from apps.hr_all_organization_units union all
select 'HR_JOBS' ||'|'|| count(*) from apps.per_jobs union all
select 'HR_GRADES' ||'|'|| count(*) from apps.per_grades union all
select 'HR_PAY_PROPOSALS' ||'|'|| count(*) from apps.per_pay_proposals;
prompt [SECTION_END:DATA_HR_VOLUMES]

prompt [SECTION_START:DATA_FA_VOLUMES]
select 'FA_ASSET_BOOKS' ||'|'|| count(*) from apps.fa_book_controls union all
select 'FA_ASSETS' ||'|'|| count(*) from apps.fa_additions_b union all
select 'FA_ASSET_BOOKS_DETAIL' ||'|'|| count(*) from apps.fa_books union all
select 'FA_ASSET_CATEGORIES' ||'|'|| count(*) from apps.fa_categories_b union all
select 'FA_DEPRN_PERIODS' ||'|'|| count(*) from apps.fa_deprn_periods union all
select 'FA_DEPRN_SUMMARY' ||'|'|| count(*) from apps.fa_deprn_summary union all
select 'FA_ADJUSTMENTS' ||'|'|| count(*) from apps.fa_adjustments;
prompt [SECTION_END:DATA_FA_VOLUMES]

prompt [SECTION_START:DATA_CM_VOLUMES]
select 'CM_COST_TYPES' ||'|'|| count(*) from apps.cst_cost_types union all
select 'CM_ITEM_COSTS' ||'|'|| count(*) from apps.cst_item_costs union all
select 'CM_ITEM_COST_DETAILS' ||'|'|| count(*) from apps.cst_item_cost_details union all
select 'CM_COST_GROUPS' ||'|'|| count(*) from apps.cst_cost_groups union all
select 'CM_TRANSACTIONS' ||'|'|| count(*) from apps.mtl_cst_actual_cost_details;
prompt [SECTION_END:DATA_CM_VOLUMES]

prompt [SECTION_START:DATA_OPM_VOLUMES]
select 'OPM_BATCHES' ||'|'|| count(*) from apps.gme_batch_header union all
select 'OPM_BATCH_STEPS' ||'|'|| count(*) from apps.gme_batch_steps union all
select 'OPM_MATERIAL_DETAILS' ||'|'|| count(*) from apps.gme_material_details union all
select 'OPM_RECIPES' ||'|'|| count(*) from apps.gmd_recipes_b union all
select 'OPM_FORMULAS' ||'|'|| count(*) from apps.fm_form_mst_b union all
select 'OPM_ROUTINGS' ||'|'|| count(*) from apps.gmd_routings_b;
prompt [SECTION_END:DATA_OPM_VOLUMES]

prompt [SECTION_START:DATA_PRICING_VOLUMES]
select 'QP_LIST_HEADERS' ||'|'|| count(*) from apps.qp_list_headers_b union all
select 'QP_LIST_LINES' ||'|'|| count(*) from apps.qp_list_lines union all
select 'QP_PRICING_ATTRIBUTES' ||'|'|| count(*) from apps.qp_pricing_attributes union all
select 'QP_QUALIFIERS' ||'|'|| count(*) from apps.qp_qualifiers union all
select 'QP_PRICE_FORMULAS' ||'|'|| count(*) from apps.qp_price_formulas_b union all
select 'QP_MODIFIERS' ||'|'|| count(*) from apps.qp_list_headers_b where list_type_code = 'DLT';
prompt [SECTION_END:DATA_PRICING_VOLUMES]


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

rm -f run_db_collect.sql
sed -i '/^$/d' "$OUTPUT_FILE"

echo "Collection Complete. Output: $OUTPUT_FILE" | tee -a "$LOG_FILE"
