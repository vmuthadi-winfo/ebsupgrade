set term off
set arraysize 200
set heading on
set feedback off  
set echo off
set verify off
set lines 2000
set pages 0
set trimspool on
set colsep '|'

COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
SPOOL ebs_upgrade_analyzer_data.txt

prompt [SECTION_START:DB_VERSION]
select instance_name ||'|'|| version ||'|'|| host_name ||'|'|| startup_time
from v$instance;
prompt [SECTION_END:DB_VERSION]

prompt [SECTION_START:DB_SIZE]
select round(sum(bytes)/1024/1024/1024, 2) as size_gb
from dba_data_files;
prompt [SECTION_END:DB_SIZE]

prompt [SECTION_START:DB_CONFIG]
select log_mode ||'|'|| flashback_on ||'|'|| database_role 
from v$database;
prompt [SECTION_END:DB_CONFIG]

prompt [SECTION_START:DB_PARAMETERS]
select name ||'|'|| value
from v$parameter 
where name in ('processes', 'sessions', 'open_cursors', 'utl_file_dir', 'sga_max_size', 'sga_target', 'pga_aggregate_target', 'memory_target', 'compatible', 'cluster_database');
prompt [SECTION_END:DB_PARAMETERS]

prompt [SECTION_START:DB_OS_STAT]
select stat_name ||'|'|| value
from v$osstat
where stat_name in ('NUM_CPUS', 'NUM_CPU_CORES', 'PHYSICAL_MEMORY_BYTES');
prompt [SECTION_END:DB_OS_STAT]

prompt [SECTION_START:DB_REGISTRY]
select comp_id ||'|'|| comp_name ||'|'|| version ||'|'|| status
from dba_registry;
prompt [SECTION_END:DB_REGISTRY]

prompt [SECTION_START:DB_LINKS]
select owner ||'|'|| db_link ||'|'|| host
from dba_db_links;
prompt [SECTION_END:DB_LINKS]

prompt [SECTION_START:DB_DIRECTORIES]
select owner ||'|'|| directory_name ||'|'|| directory_path
from dba_directories;
prompt [SECTION_END:DB_DIRECTORIES]

prompt [SECTION_START:EBS_VERSION]
select release_name from apps.fnd_product_groups;
prompt [SECTION_END:EBS_VERSION]

prompt [SECTION_START:EBS_MODULES]
select fa.application_short_name ||'|'|| fat.application_name ||'|'|| fpi.patch_level ||'|'|| flv.meaning
from apps.fnd_application fa, apps.fnd_application_tl fat, apps.fnd_product_installations fpi, apps.fnd_lookup_values flv
where fa.application_id = fat.application_id
and fat.application_id = fpi.application_id
and fat.language = 'US'
and fpi.status = flv.lookup_code
and flv.lookup_type = 'FND_PRODUCT_STATUS'
and flv.language = 'US'
and flv.meaning != 'Not installed';
prompt [SECTION_END:EBS_MODULES]

prompt [SECTION_START:EBS_CUSTOM_SCHEMAS]
select username ||'|'|| created
from dba_users
where username like 'XX%' or username like 'CUST%';
prompt [SECTION_END:EBS_CUSTOM_SCHEMAS]

prompt [SECTION_START:EBS_CUSTOM_OBJECTS]
select owner ||'|'|| object_type ||'|'|| count(*) 
from dba_objects 
where owner like 'XX%' or owner like 'CUST%'
group by owner, object_type;
prompt [SECTION_END:EBS_CUSTOM_OBJECTS]

prompt [SECTION_START:EBS_ACTIVE_USERS]
select count(*)
from apps.fnd_user
where (end_date is null or end_date > sysdate) and start_date <= sysdate;
prompt [SECTION_END:EBS_ACTIVE_USERS]

prompt [SECTION_START:EBS_PATCHES_LAST_90_DAYS]
select e.patch_name ||'|'|| TRUNC(a.last_update_date) ||'|'|| b.applied_flag
from apps.ad_bugs a, apps.ad_patch_run_bugs b, apps.ad_patch_runs c, apps.ad_patch_drivers d, apps.ad_applied_patches e
where a.bug_id = b.bug_id and b.patch_run_id = c.patch_run_id 
and c.patch_driver_id = d.patch_driver_id and d.applied_patch_id = e.applied_patch_id 
and a.last_update_date >= sysdate-90
and rownum <= 100
order by a.last_update_date desc;
prompt [SECTION_END:EBS_PATCHES_LAST_90_DAYS]

spool off
set heading on
set feedback on  
set trimspool off
exit;
