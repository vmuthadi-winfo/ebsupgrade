-- ==============================================================================
-- Script Name: create_analyzer_user.sql
-- Description: Creates a dedicated, least-privileged database user to run the 
--              EBS Upgrade Analyzer extraction safely, without requiring SYSDBA.
-- Usage: Execute this script once as SYSDBA before running the collector.
--        sqlplus "/ as sysdba" @create_analyzer_user.sql
-- ==============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET VERIFY OFF
PROMPT ==========================================================
PROMPT Creating EBS_ANALYZER Database User
PROMPT ==========================================================
PROMPT 

ACCEPT AnalyzerPassword PROMPT 'Enter a strong password for the new EBS_ANALYZER user: ' HIDE

DECLARE
   user_exists INT;
BEGIN
   SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = 'EBS_ANALYZER';
   IF user_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP USER EBS_ANALYZER CASCADE';
   END IF;
END;
/

CREATE USER EBS_ANALYZER IDENTIFIED BY "&AnalyzerPassword" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP;

-- Base connect privileges
GRANT CREATE SESSION TO EBS_ANALYZER;

-- Required to read v$parameter, v$instance, v$database, v$osstat, dba_objects, dba_users, etc.
GRANT SELECT ANY DICTIONARY TO EBS_ANALYZER;
GRANT SELECT_CATALOG_ROLE TO EBS_ANALYZER;

-- Required to read application specific metadata from the APPS schema 
-- (Equivalent to SELECT ANY TABLE, constrained to APPS if strictly required, but SELECT ANY TABLE is easier for cross-schema EBS implementations)
GRANT SELECT ANY TABLE TO EBS_ANALYZER;

-- Specific grants on dynamic performance views that sometimes fail with generic roles
GRANT SELECT ON v_$instance TO EBS_ANALYZER;
GRANT SELECT ON v_$database TO EBS_ANALYZER;
GRANT SELECT ON v_$parameter TO EBS_ANALYZER;
GRANT SELECT ON v_$osstat TO EBS_ANALYZER;

PROMPT 
PROMPT User EBS_ANALYZER successfully created and granted least privileges.
PROMPT You can now run the shell collector using this user.
PROMPT ==========================================================

EXIT;
