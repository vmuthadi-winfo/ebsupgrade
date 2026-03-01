# Oracle E-Business Suite 12.2.15 & Database 19c/23ai Upgrade Analyzer

This tool suite performs an overall automated check of the Oracle E-Business Suite Database and Application environment to assess upgrade impacts when moving to the latest continuous innovation releases (EBS 12.2.15) and modern Oracle Databases (19c or 23ai) on Linux 9.

## Tool Components
The suite is comprised of three parts:
1. **`create_analyzer_user.sql`**: A setup SQL script for the DBA to create a dedicated, least-privileged database user (`EBS_ANALYZER`).
2. **`ebs_upgrade_analyzer_collector.sh`**: A Bash shell script that runs on the Database or Application node to securely extract all Oracle metrics into a single flat file.
3. **`generate_upgrade_report.py`**: A Python rendering engine designed to be run on *any* workstation. It ingests the data collected by the shell script and generates a formatted HTML Impact Report dashboard. 

---

## 🔥 New AI-Driven Complexity Scoring Engine
Based strictly on analytical inputs, the tool now generates an explicit, deterministic 35-point **Complexity Score** categorizing your upgrade effort into sizes (Small / Medium / Large / Very Large).

The Assessment engine evaluates the environment against 7 explicit factors:
*   **CD-1 Infrastructure Change:** E.g., End of life OS detected vs. Target Linux 9.
*   **CD-2 Database Transition:** 12c footprint to Multitenant sizes.
*   **CD-3 EBR Readiness:** Validates Edition Based Redefinition seed schemas against custom schemas.
*   **CD-4 Customization Sprawl (CEMLIs):** Measures OAF/Forms footprint gravity.
*   **CD-5 Integrations Impact:** Flags DB Links (`DBA_DB_LINKS`), active SOA, and APEX listener constraints.
*   **CD-6 Advanced Security:** Validates PingFederate / SSOGEN and session mapping configurations.
*   **CD-7 Functional Blast Radius:** Derives user concurrency against actively registered Application Modules.

---

## 1. Creating the Least-Privilege Extraction User

Instead of requiring `SYSDBA` access, first provision a dedicated assessment user.

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
4. Detect the dynamically generated flat file: `ebs_upgrade_analyzer_data_server01_YYYYMMDD_HHMMSS.txt`.

*(Note: The shell script is CI/CD Pipeline ready and natively supports Environment Variables (`$DB_USER`, `$DB_PASS`) to run silently without human-prompting!)*

---

## 3. Generating the HTML Impact Report (Workstation)

You should transfer the generated text file to a workstation or a central analysis server where Python is installed. 

### Execution Steps
1. Run the Python generating engine:
   ```bash
   python generate_upgrade_report.py ebs_upgrade_analyzer_data_...txt
   ```
2. Open the generated file `EBS_Upgrade_Impact_Analysis_YYYYMMDD.html` in any web browser.

---

## 4. GitHub Actions Pipeline (Automated Deployments)

A `.github/workflows/ebs_analyzer_pipeline.yml` pipeline has been curated for remote deployments.
If you have a Self-Hosted GitHub Action runner authorized to SSH into your `applmgr` and `oracle` nodes, you can trigger this pipeline to manually extract both Application & DB configs, consolidate the data, and attach the rendered `HTML` Document as an artifact to your GitHub repo implicitly.
