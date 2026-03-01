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

echo "=========================================================" | tee -a $LOG_FILE
echo " EBS & Database Upgrade Deep-Dive Analyzer " | tee -a $LOG_FILE
echo "=========================================================" | tee -a $LOG_FILE

# Prompt for least privileged user credentials
echo -n "Enter the Analyzer Database Username [e.g. EBS_ANALYZER]: "
read DB_USER
echo -n "Enter the Analyzer Database Password: "
read -s DB_PASS
echo
echo -n "Enter the TNS Connection String [e.g. PRODDB or localhost:1521/PRODDB]: "
read DB_TNS

echo "Starting collection at: $(date)" | tee -a $LOG_FILE
echo "Output will be written to: $OUTPUT_FILE" | tee -a $LOG_FILE

> $OUTPUT_FILE

echo "1. Collecting OS, Hardware & Storage Info" | tee -a $LOG_FILE
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

echo "2. Check Application Tier Context (if sourced)" | tee -a $LOG_FILE
echo "[SECTION_START:APP_CONTEXT_INFO]" >> $OUTPUT_FILE
if [ -n "$CONTEXT_FILE" ] && [ -f "$CONTEXT_FILE" ]; then
    echo "CONTEXT_FILE_FOUND|YES" >> $OUTPUT_FILE
    echo "CONTEXT_FILE_PATH|$CONTEXT_FILE" >> $OUTPUT_FILE
    echo "WEB_ENTRY_HOST|$(cat $CONTEXT_FILE | grep -i 's_webentryhost' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "WEB_ENTRY_DOMAIN|$(cat $CONTEXT_FILE | grep -i 's_webentrydomain' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "ACTIVE_WEB_PORT|$(cat $CONTEXT_FILE | grep -i 's_active_webport' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "ADMIN_SERVER|$(cat $CONTEXT_FILE | grep -i 's_adminserver' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "FORMS_SERVER|$(cat $CONTEXT_FILE | grep -i 's_forms_server' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "CP_SERVER|$(cat $CONTEXT_FILE | grep -i 's_cpServer' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "SHARED_APPL_TOP|$(cat $CONTEXT_FILE | grep -i 's_shared_file_system' | cut -d'>' -f2 | cut -d'<' -f1)" >> $OUTPUT_FILE
    echo "ORACLE_HOME|$ORACLE_HOME" >> $OUTPUT_FILE
else
    echo "CONTEXT_FILE_FOUND|NO" >> $OUTPUT_FILE
fi
echo "[SECTION_END:APP_CONTEXT_INFO]" >> $OUTPUT_FILE

echo "3. Creating SQL Payload for Deep-Dive Extraction" | tee -a $LOG_FILE

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
    fo.profile_option_name IN ('APPS_FRAMEWORK_AGENT', 'APPS_AUTH_AGENT', 'ICX_FORMS_LAUNCHER')
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

prompt [SECTION_START:EBS_TOP_PROGRAMS]
select * from (
select a.USER_CONCURRENT_PROGRAM_NAME ||'|'|| count(ACTUAL_COMPLETION_DATE) ||'|'|| round(avg((nvl(ACTUAL_COMPLETION_DATE,sysdate)-a.REQUESTED_START_DATE)*24),2)
from apps.fnd_conc_req_summary_v a 
where phase_code = 'C' and status_code = 'C' and a.REQUESTED_START_DATE > sysdate-30 
group by a.USER_CONCURRENT_PROGRAM_NAME
order by 2 desc) where rownum <= 50;
prompt [SECTION_END:EBS_TOP_PROGRAMS]

prompt [SECTION_START:EBS_CUSTOM_SCHEMAS]
select username ||'|'|| created from dba_users where username like 'XX%' or username like 'CUST%';
prompt [SECTION_END:EBS_CUSTOM_SCHEMAS]

prompt [SECTION_START:EBS_CUSTOM_OBJECTS]
select owner ||'|'|| object_type ||'|'|| count(*) from dba_objects where owner like 'XX%' or owner like 'CUST%' group by owner, object_type;
prompt [SECTION_END:EBS_CUSTOM_OBJECTS]

prompt [SECTION_START:EBS_ACTIVE_USERS]
select count(*) from apps.fnd_user where (end_date is null or end_date > sysdate) and start_date <= sysdate;
prompt [SECTION_END:EBS_ACTIVE_USERS]

prompt [SECTION_START:OPP_SIZING]
select target_processes ||'|'|| running_processes from apps.fnd_concurrent_queues where concurrent_queue_name = 'FNDCPOPP';
prompt [SECTION_END:OPP_SIZING]

prompt [SECTION_START:FORMS_SESSIONS]
select count(*) from v$session where upper(module) like '%FORM%' or upper(program) like '%FRM%';
prompt [SECTION_END:FORMS_SESSIONS]

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
select 'OAF_PERSONALIZATIONS' ||'|'|| count(*) from apps.jdr_paths where path_docid is not null and path_name like '%custom%';
prompt [SECTION_END:CEMLI_OAF_PERSONALIZATIONS]

prompt [SECTION_START:CEMLI_ALERTS]
select 'CUSTOM_ALERTS' ||'|'|| count(*) from apps.alr_alerts where alert_name like 'XX%';
prompt [SECTION_END:CEMLI_ALERTS]


exit;
EOF

echo "4. Executing Database Deep-Dive via user: $DB_USER" | tee -a $LOG_FILE
if sqlplus -s "$DB_USER/$DB_PASS@$DB_TNS" @run_db_collect.sql >> $OUTPUT_FILE 2>>$LOG_FILE; then
    echo "DB Collection Successful." | tee -a $LOG_FILE
else
    echo "ERROR: Failed connecting using $DB_USER. Are privileges correct?" | tee -a $LOG_FILE
fi

rm run_db_collect.sql
sed -i '/^$/d' $OUTPUT_FILE

echo "Collection Complete. Output: $OUTPUT_FILE" | tee -a $LOG_FILE
