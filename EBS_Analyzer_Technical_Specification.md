# Oracle EBS & Database Upgrade Analyzer
## Full Technical Specification & Data Collection Catalog

### 1. Overview & Purpose
The Oracle EBS Upgrade Analyzer is a comprehensive, non-intrusive automation tool designed to deeply inspect existing Oracle E-Business Suite instances (11i, 12.1.3, 12.2) and their underlying Oracle Databases (11g, 12c, 19c). 

The tool performs a deterministic extraction of the application's configuration, topology, integrations, and historic technical debt. This raw metadata is then processed by an offline AI Scoring Engine to output an actionable, mathematically derived Upgrade Impact Report for transitioning to Continuous Innovation release 12.2.15 and Database 19c/23ai on Linux 9.

---

### 2. Solution Architecture & Components
The solution operates using a decoupled, air-gapped architecture to ensure maximum security:

1.  **`create_analyzer_user.sql`**: A DBA-executed setup script that provisions a least-privileged, read-only database user (`EBS_ANALYZER`).
2.  **`ebs_upgrade_analyzer_collector.sh`**: A bash-executable data collection agent deployed to the source application/database node. It dynamically discovers the EBS context and executes targeted OS and SQL inspection commands, generating a localized flat-file (`.txt`).
3.  **`generate_upgrade_report.py`**: A vendor-agnostic Python UI Engine. This process runs entirely offline (on an architect's workstation or CI/CD pipeline server), ingesting the `.txt` payload and rendering the dynamic HTML Executive Dashboard. 
4.  **`.github/workflows/ebs_analyzer_pipeline.yml`**: A pre-built Continuous Integration pipeline enabling DevOps engineers to remotely orchestrate the extraction and HTML deployment securely.

---

### 3. Data Privacy, PHI/PII Security & Compliance
Zero business data or intellectual property is exfiltrated during execution.
*   **No PII/PHI Transmitted:** The tool strictly extracts metadata counters (e.g., `count(*)` of `FND_USER`). It explicitly ignores transactional schemas (AP, GL, HR). No usernames, employee IDs, passwords, or financial figures are captured.
*   **No Source Code Exfiltration:** Identifies the volume and type of customizations (CEMLIs), but never extracts PL/SQL body text, Java source code, or proprietary configurations.
*   **Least Privilege:** Runs exclusively under the isolated `EBS_ANALYZER` read-only schema.

---

### 4. Exhaustive Data Collection Catalog (Organized)
The following is the exhaustive dictionary of the precise configurations, parameters, and metadata the shell script is authorized to evaluate.

#### A. Operating System & Hardware Topology
*   **Host Discovery:** Captures generic OS distributions via `/etc/system-release` and Hostname.
*   **Hardware Compute:** Parses total allocated CPU Cores (`/proc/cpuinfo`) and Server Memory boundaries (`free -g`).
*   **Storage Mounts:** Aggregates filesystem capacities via `df -hP`.
*   **OS Limits:** Extracts User Process Linux limits (`ulimit -n`, `ulimit -u`) required for WebLogic capacity planning.
*   **EBS Active Context:** Dynamically hooks into the active Oracle `FNDLIBR` process to locate the active Oracle Application Context File (`SID_hostname.xml`).

#### B. Oracle Database Analytics
*   **Core Versions & Storage:** Target version, DB Uptime (`v$instance`), and total physical allocated Database sizes (`dba_data_files`).
*   **Architectural Overlays:** Logs Archive Mode, Flashback status, and Data Guard definitions (`v$database`).
*   **Initialization Parameters (`v$parameter`):** Explicitly extracts only:
    *   `processes`, `sessions`, `open_cursors`, `cpu_count` (For 19c Memory Sizing targets)
    *   `sga_max_size`, `sga_target`, `pga_aggregate_target`, `memory_target`
    *   `utl_file_dir` (Identifying 19c hard-deprecations)
    *   `compatible`, `cluster_database` (RAC awareness)

#### C. Customizations & Technical Debt (CEMLI Context)
Executes complex `GROUP BY` aggregations on the `APPS` dictionary matching client prefixes (`XX%` or `CUST%`).
*   **Database Objects:** Aggregates totals of Custom Tables, Packages, Triggers, Views, and custom Schemas (`dba_users`).
*   **Hygiene Status:** Tracks the absolute volume of Invalidized compilations (`dba_objects where status='INVALID'`).
*   **EBR Readiness:** Identifies the presence (or absence) of Edition-Based Redefinition tracking proxies (`object_name like 'AD_ZD%'`).
*   **Concurrent Programs:** Categorizes every bespoke concurrent program by its explicit Execution Engine (e.g., PL/SQL vs. C vs. Java vs. Host Shell) revealing binaries that will break on Linux 9.
*   **UI Extensions:** Sums custom Oracle Forms (`fnd_form`) and OAF MDS Personalizations (`jdr_paths`).

#### D. Rogue File System Deployments (OS Sweeps)
Executes localized `find` algorithms isolating explicit paths: `$OA_HTML`, `$OA_MEDIA`, and `$JAVA_TOP`.
*   **Java Classes:** Captures total volumes of standalone `.class` logic payloads dropped outside standard ADOP procedures.
*   **Images & HTML:** Identifies unstructured `*b64*` or custom `xx*.jpeg` images overriding Oracle Core web deployments.

#### E. Enterprise Integrations & Workflows
*   **Database Links (`dba_db_links`):** Network mappings showing the total volume of database links feeding inbound/outbound external systems.
*   **Directory Interfaces (`dba_directories`):** Maps OS/DB data-file drop points.
*   **Workflow Mailer (`fnd_svc_comp_param_vals`):** Extracts `OUTBOUND_SERVER` (SMTP), `INBOUND_SERVER` (IMAP), and SSL Trust Store mappings.
*   **Custom Workflows:** Counts distinct Oracle Workflow Builder types (`wf_item_types`).
*   **XML Publisher (XDO):** Computes total volume of custom document deliveries, grouped geometrically by format (PDF, Excel, eText).
*   **Application Connections (`fnd_profile_option_values`):** Queries FND profiles to detect active system wirings for APEX, SOA, OSB, OBIEE, ECC, and Endeca integrations.

#### F. Security & Native TechStack Context
*   **Topology Definition:** Evaluates `FND_NODES` to classify which hostnames are running Web, Forms, Admin, and Concurrent processing.
*   **Tech Stack Tooling:** Parses the context file for 10g OC4J deployments (`s_atg_version`), HTTP Server logic (`s_ohs_version`), and JDK bindings (`s_jdktarget`).
*   **SSO & External Identity:** Identifies the presence of PingFederate, Oracle Access Manager (OAM), or custom session timeouts (`ICX_SESSION_TIMEOUT`).
*   **SSL Certificates:** Traces the raw OS paths mapping to active Java Keystores, Truststores, and OHS HTTPS Wallets.

#### G. System Workload Analytics
*   **Current Functional Capacity:** Generates counts of actively authorized user accounts (`fnd_user`) and active TCP Forms sessions (`v$session`).
*   **Heavy Workloads:** Identifies the exact Top 50 longest-running/highly-demanded DB Concurrent Programs spanning the last 30 days (`fnd_conc_req_summary_v`).
*   **Processing Thrash:** Evaluates actively configured OPP (Output Post Processor) runtime capacities (`fnd_concurrent_queues`).

---

### 5. AI Evaluation Engine & Target Formulations
The captured dictionary parameters and OS definitions are injected into a deterministic AI engine encapsulated in the Python execution tool. 

The resulting HTML Dashboard outputs the following derived analytics:
1.  **7-Factor Upgrade Complexity Model:** Generates an algorithmic `0-35` effort score targeting functional blast radius, CEMLI limits, DB constraints, and integrations sprawl, resulting in a distinct t-shirt size category (Small, Medium, Large, Very Large) for project planning.
2.  **Explicit Rule Violations:** An actionable assessment scanning the inputs and identifying critical transition failure points (e.g. Incompatible `.class` footprints, Desupported `utl_file_dir`).
3.  **Target Node & Memory Tuning Specifications:** Extrapolating the 11g inputs against modern Oracle Linux 9 / 19c benchmarks to generate the exact CPU limits, target WebLogic Managed Server bounds (e.g. `oacore` counts), and DB HugePage Memory allocations necessary to survive the transition. 
