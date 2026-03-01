# Oracle E-Business Suite 12.2.15 & Database 19c/23ai Upgrade Analyzer

This tool suite performs an overall automated check of the Oracle E-Business Suite Database and Application environment to assess upgrade impacts when moving to the latest continuous innovation releases (EBS 12.2.15) and modern Oracle Databases (19c or 23ai) on Linux 9.

## Tool Components
The suite is comprised of three parts:
1. **`create_analyzer_user.sql`**: A setup SQL script for the DBA to create a dedicated, least-privileged database user (`EBS_ANALYZER`), avoiding the need for `SYSDBA` credentials during extraction.
2. **`ebs_upgrade_analyzer_collector.sh`**: A Bash shell script that runs on the Database or Application node to securely extract all Oracle metrics into a single flat file.
3. **`generate_upgrade_report.py`**: A Python rendering engine designed to be run on *any* workstation. It ingests the data collected by the shell script and generates a formatted HTML Impact Report dashboard. 

---

## 1. Creating the Least-Privilege Extraction User

Instead of requiring `SYSDBA` access to run the collector tool, you should first provision a dedicated assessment user. This user only gets `SELECT` grants for required dictionary and application tables.

1. Connect to your database as `SYSDBA`:
   ```bash
   sqlplus / as sysdba
   ```
2. Run the user generation script (you will be prompted to supply a password):
   ```sql
   @create_analyzer_user.sql
   ```

---

## 2. Executing the Collector Script (Source Server)

The shell script natively parses vital data spanning DB Configurations, EBS Integrations, Topology logic, and massive CEMLI (Custom Extension) counts—translating thousands of custom objects into a clean aggregated profile.

### Prerequisites 
- **Execution Node**: You can run this shell script on either the **Oracle Database Tier** or **Applications Tier**. Running on the Apps tier allows the tool to natively parse your Autoconfig XML files to understand Load-balancing. 
- **Database Context**: Ensure that you can reach `sqlplus` from the command line.

### Execution Steps
1. Make the shell script executable:
   ```bash
   chmod +x ebs_upgrade_analyzer_collector.sh
   ```
2. Run the script:
   ```bash
   ./ebs_upgrade_analyzer_collector.sh
   ```
3. **Authentication**: The script will interactively ask you for:
   - Analyzer Database Username (e.g., `EBS_ANALYZER`)
   - Password (hidden)
   - TNS Connection string (e.g., `localhost:1521/PRODDB` or `EBSDB`)
4. The script will securely connect, extract, and write the outputs.
5. Locate the newly generated structured output file named dynamically: `ebs_upgrade_analyzer_data_server01_20260227_101530.txt`.

---

## 3. Generating the HTML Impact Report (Workstation)

You should transfer the generated text file to a workstation or a central analysis server where Python is installed. The generation does not require any connection to the database.

### Prerequisites
- **Python Setup**: Python 3.6 or higher must be installed. No external libraries (`pip install`) are required outside of standard Python.

### Execution Steps
1. Run the Python generating engine and pass the text file as the primary argument:
   ```bash
   python generate_upgrade_report.py ebs_upgrade_analyzer_data_server01_20260227_101530.txt
   ```
2. Upon completion, it will output a beautiful, highly formatted executive dashboard: `EBS_Upgrade_Impact_Analysis_YYYYMMDD.html`.
3. Open the generated HTML file in any modern web browser to review the interactive Dashboard and Application Customization (CEMLI) impacts.

---

## Technical Mapping & Oracle Support

The generated report translates technical debt into actionable upgrade impact. For example, it counts custom Java and spawned C executables and flags them for Linux 9 re-compilation. It assesses OAF Personalizations which often conflict during Weblogic domain migrations.

For a deeper, official assessment, cross-reference the findings with the following Oracle Support Documents:

*   **MOS Note 1581549.1:** Oracle E-Business Suite Release 12.2 Information Center (Upgrade)
*   **MOS Note 2552181.1:** Interoperability Notes: EBS 12.2 with Database 19c
*   **MOS Note 3042045.1:** Current status of Oracle Database 23ai Certification with E-Business Suite 
*   **MOS Note 1392100.1:** Using the EBS Upgrade Analyzer (11i/12.1 to 12.2)
*   **MOS Note 2769561.1:** Oracle Installation and Upgrade Notes for Oracle Linux 9
