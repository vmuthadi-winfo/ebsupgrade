

1. ebs_custom_application_objects.sql
   sqlplus apps/<password>	@ebs_custom_application_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
   
   e.g. sqlplus apps/<password>	@ebs_custom_application_objects.sql XXWINFO XXW%
   
2. ebs_custom_database_objects.sql
   sqlplus apps/<password>	@ebs_custom_database_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
   
   e.g. sqlplus apps/<password>	@ebs_custom_database_objects.sql XXWINFO XX%
   
3. ebs_custom_reporting_objects.sql

   sqlplus apps/<password>	@ebs_custom_reporting_objects.sql <CUST_APPL_SHORT_NAME> <CUST_APPL_NAMING_CONVENTION>%
   
   e.g. sqlplus apps/<password>	@ebs_custom_reporting_objects.sql XXWINFO XXW%
   
4. ebs_data_collection.sql
   sqlplus apps/<password>	@ebs_analysis.sql
   
5. ebs_data_reconciliator.sql

   sqlplus apps/<password>	@ebs_data_reconciliator.sql