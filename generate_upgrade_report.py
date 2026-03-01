import sys
import os
from datetime import datetime

def parse_data(file_path):
    data = {}
    current_section = None
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            if line.startswith('[SECTION_START:'):
                current_section = line.split(':')[1].replace(']', '')
                data[current_section] = []
            elif line.startswith('[SECTION_END:'):
                current_section = None
            elif current_section:
                data[current_section].append(line.split('|'))
    return data

def safe_get(data, section, default_row=None):
    if default_row is None:
        default_row = [['N/A']]
    val = data.get(section, [])
    return val if val else default_row

def render_table(rows, headers):
    if not rows:
        return "<p style='color:#777; font-size:14px; font-style:italic;'>No data found for this section.</p>"
    html = '<table><thead><tr>'
    for header in headers:
        html += f'<th>{header}</th>'
    html += '</tr></thead><tbody>'
    for row in rows:
        html += '<tr>'
        for i in range(len(headers)):
            val = row[i] if i < len(row) else ''
            html += f'<td>{val}</td>'
        html += '</tr>'
    html += '</tbody></table>'
    return html

def determine_integrations(profiles):
    integ = {
        'SSO': {'status': 'Disabled', 'desc': 'No Oracle Access Manager or external SSO agents mapping detected. Standard FND login assumed.', 'color': '--border-grey', 'roadmap': 'Standard FND User migration.'},
        'APEX': {'status': 'Disabled', 'desc': 'No APEX listener links found in profiles.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'ECC': {'status': 'Disabled', 'desc': 'Enterprise Command Center not found in fnd profiles.', 'color': '--border-grey', 'roadmap': 'Consider deploying ECC V12 for modern EBS 12.2.14+ reporting.'},
        'SOA_ISG': {'status': 'Disabled', 'desc': 'Integrated SOA Gateway (ISG) or SOA Suite ties are not mapped.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'OBIEE': {'status': 'Disabled', 'desc': 'OAC/OBIEE analytical URL links not found.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'ENDECA': {'status': 'Disabled', 'desc': 'Information Discovery (Endeca) is not wired.', 'color': '--border-grey', 'roadmap': 'Replace with ECC if needed.'}
    }
    
    fwk_agent = ""
    servlet_agent = ""

    for row in profiles:
        if len(row) < 2: continue
        name, value = row[0].upper(), row[1]
        if not value.strip(): continue

        if name == 'APPS_FRAMEWORK_AGENT': fwk_agent = value
        if name == 'APPS_SERVLET_AGENT': servlet_agent = value
        
        if 'APEX' in name:
            integ['APEX'] = {'status': 'Active', 'desc': f'Active via {name}. Custom code and APEX Listeners require testing across 19c/23ai.', 'color': '--warning-amber', 'roadmap': 'APEX 23.x must be deployed on the target database, and ORDS configured on a standalone Weblogic/Tomcat server.'}
        if 'ECC' in name:
            integ['ECC'] = {'status': 'Active', 'desc': 'Command Center profiles found.', 'color': '--primary-blue', 'roadmap': 'Requires upgrading the ECC standalone server to V10+ (V12 Recommended) to certify with EBS 12.2.14/15.'}
        if 'SOA' in name or 'REST' in name or 'ISG' in name:
            integ['SOA_ISG'] = {'status': 'Active', 'desc': 'SOA/ISG/REST detected. Integrated SOA Gateway has major architectural shifts in 12.2.', 'color': '--warning-amber', 'roadmap': 'REST services must be migrated to the new EBS Weblogic ISG deployment mechanism. SOAP endpoints must be re-generated.'}
        if 'OBIEE' in name or 'OAC' in name:
            integ['OBIEE'] = {'status': 'Active', 'desc': 'OBIEE / OAC URL Profiles defined.', 'color': '--primary-blue', 'roadmap': 'No DB structural impact, but EBS Auth integration to OAS/OAC must be tested against new WLS cookies.'}
        if 'ENDECA' in name:
            integ['ENDECA'] = {'status': 'Active', 'desc': 'Endeca extensions detected.', 'color': '--danger-red', 'roadmap': 'Oracle Endeca Information Discovery is functionally replaced by ECC in 12.2. Migration effort to ECC recommended.'}
        if 'SSO' in name or 'OAM' in name or name == 'FND_SSO_COOKIE_DOMAIN' or name == 'APPS_SSO_PROFILE':
            integ['SSO'] = {'status': 'Active', 'desc': 'SSO/OAM configurations detected.', 'color': '--warning-amber', 'roadmap': 'Requires deploying Oracle Access Gate 12.2.1.4+ on Weblogic 14c (or OHS 12c Webgates) certified against the new Linux 9 OS.'}
            
    # Check if agents differ indicating external SSO
    if servlet_agent and fwk_agent and servlet_agent != fwk_agent:
         integ['SSO'] = {'status': 'Active', 'desc': 'Potential SSO / Access Gate detected via disjointed Servlet & Framework Agents.', 'color': '--warning-amber', 'roadmap': 'Verify SSO Trust architecture prior to upgrading.'}

    return integ

def run_prebuilt_rules(data, db_version, ebs_version, db_params, os_info, db_size):
    challenges = []
    
    # OS Check
    os_name = os_info.get('OS_RELEASE', '').lower()
    if 'linux' not in os_name:
        challenges.append("<b>Critical Platform Shift</b>: Target architecture for EBS 12.2.15/DB 19c+ requires Oracle Linux 8/9 or RedHat 8/9. A cross-platform migration (e.g. Solaris/AIX/Windows to Linux) using Transportable Tablespaces (TTS) or Logical Export/Import will be required.")
    elif '7' in os_name or '6' in os_name:
         challenges.append("<b>OS Deprecation</b>: Current Linux OS is End-of-Life. The Upgrade to EBS 12.2.15 on Weblogic and Database 19c/23ai demands Oracle Linux 8 or 9. OHS, Forms, and WebLogic binaries must be explicitly recompiled on the target OS.")

    # Init Params UTL_FILE
    has_utl = any(row[0].lower() == 'utl_file_dir' for row in db_params if len(row) > 0)
    if has_utl:
         challenges.append("<b>UTL_FILE_DIR Desupported</b>: Oracle Database 19c totally desupports this initialization parameter. All custom PL/SQL utilizing this must be refactored to use standard Database Directory objects managed by the APPS schema (via `txkCreateDirObject.sql`).")

    # DB Links and Invalid Objects
    db_links = sum(int(row[0]) for row in safe_get(data, 'DBA_DB_LINKS', []) if row)
    invalid_objs = safe_get(data, 'DBA_INVALID_OBJECTS', [['0']])[0][0]
    if int(invalid_objs) > 100:
        challenges.append(f"<b>Database Hygiene</b>: The source database has {invalid_objs} invalid objects. The 12.2 Edition-based Redefinition pre-reqs demand a clean compilation state before enablement.")
    if db_links > 15:
        challenges.append(f"<b>Integration Sprawl</b>: Detected {db_links} active Database Links. High integration coupling will drastically extend testing cycles during the Multitenant database platform migration.")

    # DB Versions
    if '11' in db_version or '12.1' in db_version:
        challenges.append("<b>Database Container Migration</b>: The Database upgrade to 19c+ mandates converting the non-CDB architecture to the Multitenant (CDB/PDB) architecture required by modern Oracle releases.")

    # Character Set
    challenges.append("<b>AL32UTF8 Mandate</b>: If the Database is not already AL32UTF8, the EBS 12.2 upgrade highly recommends transitioning to Unicode to support modern middle-tier functionality.")

    # Memory Size
    if float(db_size) > 2000:
        challenges.append(f"<b>Downtime Constraints</b>: The database is quite large ({db_size} GB). Depending on OS-endianness, the migration/upgrade of the Database file structures might breach typical weekend downtime cutovers without utilizing specialized Data Guard or Oracle GoldenGate syncs.")

    return challenges

def build_roadmap():
    return """
    <div class="roadmap-timeline">
        <div class="rm-step">
            <div class="rm-badge">Ph 1</div>
            <div>
                <strong>Infrastructure & Technical Stack </strong><br>
                Deploy Oracle Linux 9 / RHEL 9. Install Oracle Database 19c (19.x) binary in Multitenant architecture (CDB).
            </div>
        </div>
        <div class="rm-step">
            <div class="rm-badge">Ph 2</div>
            <div>
                <strong>Database Upgrade & Migration</strong><br>
                Migrate the EBS Database into the 19c PDB. Convert <code>UTL_FILE_DIR</code> logic. Migrate character sets to AL32UTF8 (if needed).
            </div>
        </div>
        <div class="rm-step">
            <div class="rm-badge">Ph 3</div>
            <div>
                <strong>Application Upgrade (12.2.0 Base)</strong><br>
                Rapid Install the 12.2 File System via DB upgrade mode. This lays down the dual-file system and Weblogic Server (WLS 10.3.6). Enable Online Patching (EBR).
            </div>
        </div>
        <div class="rm-step">
            <div class="rm-badge">Ph 4</div>
            <div>
                <strong>CEMLI Remediation (Customizations)</strong><br>
                Apply Online Patching logical columns to all custom tables. Re-compile Java/C executables natively on Linux 9. Remediate custom PL/SQL to Edition-based standards.
            </div>
        </div>
        <div class="rm-step">
            <div class="rm-badge">Ph 5</div>
            <div>
                <strong>Continuous Innovation (12.2.14 / 12.2.15)</strong><br>
                Apply the latest AD/TXK Delta packs in the run edition. Apply the 12.2.15 Release Update Pack (RUP). Re-integrate SSO, OAC, and ISG endpoints.
            </div>
        </div>
    </div>
    """

def calculate_complexity_score(data, db_params, active_users, custom_objs, custom_schemas_cnt, db_size, os_info, ebs_version, profiles):
    # CD-1: Infrastructure
    cd1_score = 0
    os_name = os_info.get('OS_RELEASE', '').lower()
    if 'linux' not in os_name: cd1_score = 5
    elif '7' in os_name or '6' in os_name: cd1_score = 3

    # CD-2: Database Upgrade
    cd2_score = 0
    db_version_info = safe_get(data, 'DB_VERSION', [['Unknown', '12', 'Unknown', 'Unknown']])[0]
    db_ver = db_version_info[1] if len(db_version_info) > 1 else '12'
    if '11' in db_ver or '12' in db_ver: cd2_score = 3
    if float(db_size) > 1000: cd2_score += 2
    if cd2_score > 5: cd2_score = 5

    # CD-3: EBR Readiness
    cd3_score = 0
    adzd_schemas = int(safe_get(data, 'ADOP_AD_ZD_SCHEMAS', [['0']])[0][0])
    if custom_schemas_cnt > 10 and adzd_schemas == 0: cd3_score = 5
    elif custom_schemas_cnt > 0: cd3_score = 3

    # CD-4: Customization Footprint (CEMLI)
    cd4_score = 0
    if custom_objs > 5000: cd4_score = 5
    elif custom_objs > 1000: cd4_score = 3

    # CD-5: Integrations
    cd5_score = 0
    db_links_count = sum(int(row[0]) for row in safe_get(data, 'DBA_DB_LINKS', []) if row)
    if db_links_count > 20: cd5_score = 5
    elif db_links_count > 5: cd5_score = 3
    
    # Check for SOA/APEX in profiles for +2
    for row in profiles:
        if len(row) > 0 and ('SOA' in row[0].upper() or 'APEX' in row[0].upper()):
            cd5_score = min(cd5_score + 2, 5)

    # CD-6: Security & SSO
    cd6_score = 0
    for row in profiles:
        if len(row) > 0 and ('SSO' in row[0].upper() or 'OAM' in row[0].upper()):
            cd6_score = 5
            break

    # CD-7: Functional Blast Radius
    cd7_score = 0
    users = 0
    try: users = int(active_users)
    except: pass
    if users > 1500: cd7_score = 5
    elif users > 400: cd7_score = 3

    total_score = cd1_score + cd2_score + cd3_score + cd4_score + cd5_score + cd6_score + cd7_score
    
    # Complexity Normalization mapping
    size_box = "Small"
    size_color = "--success-green"
    if total_score >= 25: 
        size_box = "Very Large"
        size_color = "--danger-red"
    elif total_score >= 17:
        size_box = "Large"
        size_color = "--warning-amber"
    elif total_score >= 9:
        size_box = "Medium"
        size_color = "--primary-blue"
        
    return {
        'total': total_score,
        'size': size_box,
        'color': size_color,
        'factors': {
            'CD-1 Infrastructure': cd1_score,
            'CD-2 Database': cd2_score,
            'CD-3 EBR Readiness': cd3_score,
            'CD-4 CEMLI Footprint': cd4_score,
            'CD-5 Integrations': cd5_score,
            'CD-6 Security/SSO': cd6_score,
            'CD-7 Functional Impact': cd7_score
        }
    }

def generate_sizing_analytics(db_params, active_users, opp_data, forms_data):
    cpu_count = 8 # Default minimum
    for row in db_params:
        if row[0].lower() == 'cpu_count' and row[1].isdigit():
            cpu_count = int(row[1])
            break
            
    # Calculate recommended Weblogic OAF Managed Servers (assume 1 server per 200 users, min 2)
    try:
        users = int(active_users)
    except:
        users = 500
    wls_servers = max(users // 200, 2)
    if users < 100: wls_servers = 1
    
    # Calculate Custom Forms 
    try:
        forms_sessions = int(forms_data[0][0])
    except:
        forms_sessions = 50
    forms_servers = max(forms_sessions // 150, 1)

    # Calculate OPP
    try:
        opp_target = int(opp_data[0][0])
    except:
        opp_target = 1
    opp_memory = max(opp_target * 2, 2) # 2 GB per OPP JVM usually
    
    # Database Memory
    db_mem = 16 # Default GB
    for row in db_params:
        if 'sga' in row[0].lower() and row[1].isdigit():
            # If size in bytes, convert to GB
            val = int(row[1])
            if val > 1024*1024*1024:
                db_mem = val // (1024*1024*1024)
            else:
                db_mem = val // 1024 # if in MB
            break

    recom_mem = max(int(db_mem * 1.2), 16)
    min_cores = max(cpu_count, 4)
    
    html = f"""
    <div class="grid-summary">
        <div class="metric-card" style="border-left-color: var(--primary-blue)">
            <div class="metric-title">Database Core Analytics</div>
            <div class="metric-value">{min_cores} Cores Minimum</div>
            <div style="font-size:13px; color:#64748b;">Includes 19c buffer cache overhead. (Source: {cpu_count} CPU)</div>
        </div>
        <div class="metric-card" style="border-left-color: var(--warning-amber)">
            <div class="metric-title">Database target Memory</div>
            <div class="metric-value">{recom_mem} GB SGA/PGA</div>
            <div style="font-size:13px; color:#64748b;">Target 20% growth over existing limits to support PDB dictionaries.</div>
        </div>
        <div class="metric-card" style="border-left-color: var(--success-green)">
            <div class="metric-title">EBS 12.2 OAF Load-Balancing</div>
            <div class="metric-value">{wls_servers} WLS oacore JVMs</div>
            <div style="font-size:13px; color:#64748b;">Based on {users} Active Users (2GB memory per instance)</div>
        </div>
        <div class="metric-card" style="border-left-color: var(--primary-blue)">
            <div class="metric-title">Forms &amp; Output Processing</div>
            <div class="metric-value">{forms_servers} Forms | {opp_target} OPP</div>
            <div style="font-size:13px; color:#64748b;">Forms: {forms_sessions} Peak Sessions. OPP JVM Heap: {opp_memory}GB.</div>
        </div>
    </div>
    """
    return html

def build_html(data):
    db_version_info = safe_get(data, 'DB_VERSION', [['Unknown', 'Unknown', 'Unknown', 'Unknown']])[0]
    db_size = safe_get(data, 'DB_SIZE', [['0']])[0][0]
    ebs_version = safe_get(data, 'EBS_VERSION', [['Unknown']])[0][0]
    active_users = safe_get(data, 'EBS_ACTIVE_USERS', [['0']])[0][0]
    
    os_info = {row[0]: row[1] if len(row)>1 else '' for row in safe_get(data, 'OS_SERVER_INFO', [])}
    app_context = {row[0]: row[1] if len(row)>1 else '' for row in safe_get(data, 'APP_CONTEXT_INFO', [])}
    db_params = safe_get(data, 'DB_PARAMETERS', [])
    
    custom_schemas = len(safe_get(data, 'EBS_CUSTOM_SCHEMAS', []))
    custom_objs = sum(int(row[2]) for row in safe_get(data, 'EBS_CUSTOM_OBJECTS', []) if len(row) > 2 and row[2].isdigit())
    
    nodes = safe_get(data, 'EBS_NODES', [])
    profiles = safe_get(data, 'EBS_INTEGRATIONS_PROFILES', [])
    integrations = determine_integrations(profiles)
    rules_challenges = run_prebuilt_rules(data, db_version_info[1] if len(db_version_info)>1 else '', ebs_version, db_params, os_info, db_size)
    
    # Process New Extracts
    invalid_objs = safe_get(data, 'DBA_INVALID_OBJECTS', [['0']])[0][0]
    db_links = sum(int(row[0]) for row in safe_get(data, 'DBA_DB_LINKS', []) if row)
    directories = safe_get(data, 'DBA_DIRECTORIES', [['0']])[0][0]
    
    # CEMLI counts from extracted data
    forms_data_raw = safe_get(data, 'CEMLI_FORMS_AND_PAGES', [])
    forms_count = forms_data_raw[0][1] if forms_data_raw and len(forms_data_raw[0]) > 1 else '0'
    
    oaf_data_raw = safe_get(data, 'CEMLI_OAF_PERSONALIZATIONS', [])
    oaf_count = oaf_data_raw[0][1] if oaf_data_raw and len(oaf_data_raw[0]) > 1 else '0'
    
    cemli_cp = safe_get(data, 'CEMLI_CONCURRENT_PROGRAMS', [])
    
    # Generate sizing analytics
    opp_data = safe_get(data, 'OPP_SIZING', [])
    forms_sessions_data = safe_get(data, 'FORMS_SESSIONS', [])
    sizing_analytics = generate_sizing_analytics(db_params, active_users, opp_data, forms_sessions_data)
    
    # Calculate Complexity
    complexity_payload = calculate_complexity_score(data, db_params, active_users, custom_objs, custom_schemas, db_size, os_info, ebs_version, profiles)
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EBS Deep-Dive Upgrade Assessment</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {{ --bg-color:#f4f7f6; --text-color:#333; --card-bg:#fff; --primary-blue:#0A3A6B; --light-blue:#ECF4F9; --accent-orange:#FF7B00; --danger-red:#D93025; --warning-amber:#F29900; --success-green:#188038; --border-grey:#e0e0e0; }}
        body {{ font-family:'Inter', sans-serif; background-color:var(--bg-color); color:var(--text-color); margin:0; padding:0; line-height:1.6; scroll-behavior: smooth; }}
        .header {{ background-color:var(--primary-blue); color:white; padding:20px 40px; display:flex; justify-content:space-between; align-items:center; position: sticky; top: 0; z-index: 100; box-shadow: 0 2px 10px rgba(0,0,0,0.2);}}
        .header h1 {{ margin:0; font-size:24px; font-weight:600; letter-spacing:-0.5px;}}
        .nav-sidebar {{ width: 250px; position: fixed; left: 0; top: 70px; height: calc(100vh - 70px); background: #fff; border-right: 1px solid var(--border-grey); padding: 20px 0; overflow-y: auto; }}
        .nav-sidebar a {{ display: block; padding: 12px 25px; color: #555; text-decoration: none; font-size: 14px; font-weight: 500; border-left: 4px solid transparent; transition: all 0.2s; }}
        .nav-sidebar a:hover {{ background: var(--light-blue); color: var(--primary-blue); border-left-color: var(--primary-blue); }}
        
        .main-content {{ margin-left: 250px; padding: 30px; max-width: 1400px; }}
        
        .grid-summary {{ display:grid; grid-template-columns:repeat(auto-fit, minmax(280px, 1fr)); gap:20px; margin-bottom:30px; }}
        .metric-card {{ background:var(--card-bg); border-radius:8px; padding:25px; border-left:5px solid var(--primary-blue); box-shadow:0 4px 12px rgba(0,0,0,0.05); position: relative; overflow: hidden; }}
        .metric-card::after {{ content: ''; position: absolute; right: -20px; bottom: -20px; width: 100px; height: 100px; border-radius: 50%; opacity: 0.05; background: currentColor; }}
        .metric-card.danger {{ border-left-color:var(--danger-red); }} .metric-card.danger::after {{ background: var(--danger-red); }}
        .metric-card.success {{ border-left-color:var(--success-green); }} .metric-card.success::after {{ background: var(--success-green); }}
        .metric-card.warning {{ border-left-color:var(--warning-amber); }} .metric-card.warning::after {{ background: var(--warning-amber); }}
        .metric-title {{ font-size:13px; color:#777; font-weight:700; text-transform:uppercase; letter-spacing:0.8px; margin-bottom: 5px; }}
        .metric-value {{ font-size:32px; font-weight:700; color:var(--text-color); margin:5px 0 15px 0; }}
        
        .c-engine-section {{ background:#1E293B; border-radius:12px; padding:35px; color:#fff; box-shadow:0 10px 30px rgba(0,0,0,0.15); margin-bottom:40px; display: flex; align-items: center; justify-content: space-between; gap: 40px; }}
        .c-engine-left {{ flex: 1; }}
        .c-engine-right {{ text-align: right; background: rgba(0,0,0,0.2); padding: 25px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.1); min-width: 250px; }}
        .c-engine-score {{ font-size: 58px; font-weight: 800; line-height: 1; margin: 10px 0; color: #38BDF8; }}
        .c-size-badge {{ display: inline-block; padding: 8px 15px; font-size: 14px; font-weight: 700; border-radius: 30px; text-transform: uppercase; letter-spacing: 1px; margin-top: 10px; background: rgba(255,255,255,0.1); color: #fff; }}
        
        .cd-bars {{ margin-top: 25px; }}
        .cd-row {{ display: flex; align-items: center; margin-bottom: 12px; font-size: 13px; color: #CBD5E1; font-weight: 500; }}
        .cd-label {{ width: 180px; }}
        .cd-track {{ flex: 1; background: #334155; height: 12px; border-radius: 6px; overflow: hidden; margin: 0 15px; }}
        .cd-fill {{ height: 100%; border-radius: 6px; transition: width 1s; }}
        .cd-val {{ width: 30px; text-align: right; font-weight: 700; color: #fff; }}

        
        .section {{ background:var(--card-bg); border-radius:12px; padding:35px; margin-bottom:40px; box-shadow:0 4px 15px rgba(0,0,0,0.03); border: 1px solid rgba(0,0,0,0.05); }}
        .section-header {{ display: flex; align-items: center; border-bottom:2px solid var(--light-blue); padding-bottom:15px; margin-bottom: 25px; }}
        .section-header h2 {{ color:var(--primary-blue); margin: 0; font-size: 22px; }}
        .section h3 {{ color:var(--primary-blue); margin-top:35px; font-size: 18px; display: flex; align-items: center; }}
        
        table {{ width:100%; border-collapse:collapse; margin-top:15px; font-size:14px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.02); }}
        th, td {{ border-bottom:1px solid var(--border-grey); padding:14px 20px; text-align:left; }}
        th {{ background-color:#F8FAFC; color:#475569; font-weight:600; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; }}
        tr:hover td {{ background-color: #F8FAFC; }}
        
        .challenges-box {{ background-color: #FEF2F2; border-left: 5px solid var(--danger-red); padding: 25px; border-radius: 8px; margin: 25px 0; }}
        .challenges-box ul {{ margin: 0; padding-left: 20px; }}
        .challenges-box li {{ margin-bottom: 12px; font-size: 15px; color: #7F1D1D; }}
        .challenges-box li:last-child {{ margin-bottom: 0; }}
        
        .roadmap-timeline {{ margin: 30px 0; position: relative; padding-left: 30px; }}
        .roadmap-timeline::before {{ content: ''; position: absolute; left: 15px; top: 0; bottom: 0; width: 3px; background: var(--light-blue); }}
        .rm-step {{ position: relative; margin-bottom: 30px; padding: 20px; background: #fff; border: 1px solid var(--light-blue); border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.02); margin-left: 20px; }}
        .rm-badge {{ position: absolute; left: -52px; top: 20px; width: 40px; height: 40px; background: var(--primary-blue); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 13px; z-index: 2; border: 4px solid var(--bg-color); }}
        .rm-step strong {{ font-size: 16px; color: var(--primary-blue); display: block; margin-bottom: 8px; }}
        
        .grid-integrations {{ display:grid; grid-template-columns:repeat(auto-fit, minmax(360px, 1fr)); gap:20px; margin-top:25px; }}
        .integ-card {{ background:#fff; padding:25px; border-radius:10px; border:1px solid var(--border-grey); border-top: 5px solid #ccc; box-shadow: 0 4px 10px rgba(0,0,0,0.03); transition: transform 0.2s; }}
        .integ-card:hover {{ transform: translateY(-3px); box-shadow: 0 6px 15px rgba(0,0,0,0.08); }}
        .integ-title {{ font-size:18px; font-weight:700; color:var(--text-color); margin-bottom:15px; display:flex; justify-content:space-between; align-items: center; }}
        .integ-status {{ font-size:12px; padding:4px 10px; border-radius:20px; color:#fff; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }}
        
        .cemli-grid {{ display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap:20px; margin: 30px 0; }}
        .cemli-item {{ text-align:center; padding: 25px; background: #FFF; border: 1px solid var(--border-grey); border-radius: 10px; }}
        .cemli-num {{ font-size:36px; font-weight:800; color:var(--danger-red); margin-bottom: 10px; }}
        .cemli-label {{ font-size:13px; color:#64748B; font-weight: 600; text-transform:uppercase; letter-spacing: 0.5px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>Oracle EBS & Database Upgrade Analysis</h1>
        <div style="font-size:14px; opacity:0.9; font-weight: 500;">Collection Timestamp: {datetime.now().strftime("%Y-%m-%d %H:%M")}</div>
    </div>

    <div class="nav-sidebar">
        <a href="#executive">1. Executive Summary</a>
        <a href="#issues">2. Issues & Challenges</a>
        <a href="#roadmap">3. Upgrade Roadmap</a>
        <a href="#cemli">4. CEMLI / Customization Impact</a>
        <a href="#topology">5. System Topology</a>
        <a href="#integrations">6. Enterprise Integrations</a>
        <a href="#workload">7. Database Workloads</a>
        <a href="#sizing">8. Target Sizing & Capacity</a>
        <a href="#techstack">9. App TechStack & Security</a>
        <a href="#workflow">10. Workflow & Mailer Footprint</a>
    </div>

    <div class="main-content">
        <!-- Dashboard Summary -->
        <div id="executive" class="section" style="padding: 0; background: transparent; box-shadow: none; border: none; margin-bottom: 20px;">
            
            <div class="c-engine-section">
                <div class="c-engine-left">
                    <h2 style="margin:0 0 10px 0; font-size: 24px; color: #F8FAFC;">AI Upgrade Complexity Engine</h2>
                    <p style="margin:0; color:#94A3B8; font-size:15px; max-width: 600px;">The assessment engine processed {len(data.keys())} configuration metrics to mathematically compute the technical effort required for this transition to Oracle EBS 12.2 / 19c.</p>
                    
                    <div class="cd-bars">
                        {''.join(f'''<div class="cd-row">
                            <div class="cd-label">{k}</div>
                            <div class="cd-track"><div class="cd-fill" style="width: {(v/5)*100}%; background: {'#10B981' if v<=2 else '#F59E0B' if v==3 else '#EF4444'};"></div></div>
                            <div class="cd-val">{v}/5</div>
                        </div>''' for k, v in complexity_payload['factors'].items())}
                    </div>
                </div>
                <div class="c-engine-right">
                    <div style="font-size: 13px; color: #94A3B8; text-transform: uppercase; font-weight: 700; letter-spacing: 1px;">Calculated Effort Score</div>
                    <div class="c-engine-score">{complexity_payload['total']}</div>
                    <div style="font-size: 13px; color: #64748B;">/ 35 Max Points</div>
                    <div class="c-size-badge" style="border: 1px solid var({complexity_payload['color']}); color: var({complexity_payload['color']});">Blast Radius: {complexity_payload['size']}</div>
                </div>
            </div>

            <div class="grid-summary">
                <div class="metric-card">
                    <div class="metric-title">Source Application</div>
                    <div class="metric-value">{ebs_version}</div>
                    <div style="font-size:13px; color:#64748b;">Target: <b>EBS 12.2.15 (Innovation)</b></div>
                </div>
                <div class="metric-card">
                    <div class="metric-title">Database Engine</div>
                    <div class="metric-value">{db_version_info[1] if len(db_version_info)>1 else 'Unknown'}</div>
                    <div style="font-size:13px; color:#64748b;">Target: <b>Oracle 19c / 23ai (PDB)</b></div>
                </div>
                <div class="metric-card danger">
                    <div class="metric-title">Custom Objects (EBR Risk)</div>
                    <div class="metric-value">{custom_objs:,}</div>
                    <div style="font-size:13px; color:#64748b;">Spread across {custom_schemas} bespoke schemas</div>
                </div>
                <div class="metric-card warning">
                    <div class="metric-title">Detected Nodes</div>
                    <div class="metric-value">{len(nodes) if len(nodes) > 0 and nodes[0][0] != 'N/A' else 'Unknown'}</div>
                    <div style="font-size:13px; color:#64748b;">EBS Application Server Distribution</div>
                </div>
            </div>
        </div>

        <div id="issues" class="section">
            <div class="section-header">
                <h2>Potential Issues & Technical Challenges</h2>
            </div>
            <p>Based on the extracted data, the rules engine has identified the following critical roadblocks that must be resolved prior to finalizing the EBS 12.2.15/DB 19c transition architecture.</p>
            
            <div class="challenges-box">
                <ul>
                    {''.join(f'<li>{c}</li>' for c in rules_challenges) if rules_challenges else '<li>No critical rule violations detected from parsed parameter footprint.</li>'}
                </ul>
            </div>
            
            <h3 style="margin-top:20px;">Support Notes & Best Practices</h3>
            <ul style="color: #334155; padding-left: 20px;">
                <li style="margin-bottom: 8px;"><b>Best Practice:</b> Isolate custom database schemas into dedicated tablespaces separate from standard APPS data to simplify Edition-based Redefinition.</li>
                <li style="margin-bottom: 8px;"><b>Best Practice:</b> Convert entirely to <code>txkCreateDirObject.sql</code> database directories before migrating the middle tier (MOS 2552181.1).</li>
                <li style="margin-bottom: 8px;"><b>Best Practice:</b> If utilizing Oracle 23ai targets, thoroughly test bespoke PL/SQL for JSON relational duality interactions mapping against standard EBS tables (MOS 3042045.1).</li>
            </ul>
        </div>

        <div id="roadmap" class="section">
            <div class="section-header">
                <h2>Target State Upgrade Roadmap</h2>
            </div>
            <p>A structured approach is required transitioning your <code>{ebs_version}</code> architecture. The typical critical path for a full DB and App tier replacement on Oracle Linux 9 involves 5 logical sequences.</p>
            {build_roadmap()}
        </div>

        <div id="cemli" class="section">
            <div class="section-header">
                <h2>Application Extension (CEMLI) Impact Analysis</h2>
            </div>
            <p>EBS 12.2 radically changes the Middle-tier. The Oracle 10.1.3 OC4J engine is entirely replaced by WebLogic Server (WLS 10.3.6+). Any custom Application code (Java, OAF, C, Perl) currently deployed on your App server must be rebuilt, recompiled, or heavily remediated.</p>
            
            <div class="cemli-grid">
                <div class="cemli-item">
                    <div class="cemli-num">{forms_count}</div>
                    <div class="cemli-label">Custom Oracle Forms</div>
                </div>
                <div class="cemli-item">
                    <div class="cemli-num">{oaf_count}</div>
                    <div class="cemli-label">OAF Mds Personalizations</div>
                </div>
                <div class="cemli-item" style="border-top: 5px solid var(--warning-amber);">
                    <div class="cemli-num">{safe_get(data, 'APP_CUSTOM_FILES', [['0', '0']])[1][1] if len(safe_get(data, 'APP_CUSTOM_FILES', [])) > 1 else '0'}</div>
                    <div class="cemli-label">Rogue HTML/image Overrides</div>
                </div>
                <div class="cemli-item" style="border-top: 5px solid var(--danger-red);">
                    <div class="cemli-num">{safe_get(data, 'APP_CUSTOM_FILES', [['0', '0']])[3][1] if len(safe_get(data, 'APP_CUSTOM_FILES', [])) > 3 else '0'}</div>
                    <div class="cemli-label">Custom Java Class Drops</div>
                </div>
            </div>

            <h3>Concurrent Program Technical Debt (Grouped by Engine)</h3>
            <p style="color:red; font-size:13px; font-weight:600; margin-top:0;">&#9888; Action Required: All 'Java' and 'Spawned' (C/C++) executables must be recompiled on the target OS.</p>
            {render_table(cemli_cp, ["Execution Tech Stack", "Internal Engine", "Volumes Deployed"])}
        </div>

        <div id="integrations" class="section">
            <div class="section-header">
                <h2>Enterprise Peripheral Integrations</h2>
            </div>
            <p>EBS relies intricately on external software portfolios. Profile values indicate what is actively connected vs unused.</p>
            
            <div class="grid-integrations">
    """
    for integ_name, integ_data in integrations.items():
        color_var = integ_data['color']
        status = integ_data['status']
        desc = integ_data['desc']
        roadmap = integ_data['roadmap']
        html += f"""
                <div class="integ-card" style="border-top-color: var({color_var})">
                    <div class="integ-title">
                        {integ_name}
                        <span class="integ-status" style="background-color: var({color_var})">{status}</span>
                    </div>
                    <p style="font-size:14px; margin:0 0 15px 0; color:#475569;">{desc}</p>
                    <div style="background:#F1F5F9; padding:12px; border-radius:6px; font-size:13px; color:#334155; border-left:3px solid var({color_var})">
                        <b>Upgrade Action:</b> {roadmap}
                    </div>
                </div>
        """

    html += f"""
            </div>
        </div>

        <div id="topology" class="section">
            <div class="section-header">
                <h2>Physical Topology & Contexts</h2>
            </div>
            
            <h3>Application Node Definitions</h3>
            {render_table(nodes, ["Registrar Hostname", "Batch/Concurrent", "Forms Service", "Web Service", "Data Node", "Current State"])}
            
            <h3>Application Context Framework</h3>
            """
    
    if app_context.get('CONTEXT_FILE_FOUND') == 'YES':
        html += render_table([
            ['Web Entry Link (Loadbalancer)', app_context.get('WEB_ENTRY_HOST', '') + '.' + app_context.get('WEB_ENTRY_DOMAIN', '')],
            ['Active External Port', app_context.get('ACTIVE_WEB_PORT', '')],
            ['Admin Server Node', app_context.get('ADMIN_SERVER', '')],
            ['Shared Server Trajectory', app_context.get('SHARED_APPL_TOP', '')]
        ], ["Context Variable", "Detected Value"])
    else:
        html += "<p style='color:var(--danger-red); font-size:14px; font-family:monospace; padding:15px; background:#FEF2F2; border-radius:5px;'>[!] Execution decoupled from Apps Context. Run tool on Web Tier to map physical Autoconfig XMLs.</p>"

    html += f"""
        </div>

        <div id="workload" class="section">
            <div class="section-header">
                <h2>Database Workloads & Process Engineering</h2>
            </div>
            
            <h3>Active Managers & Process Spawning Limits</h3>
            {render_table(safe_get(data, 'EBS_CONCURRENT_MANAGERS', []), ["Queue Routing ID", "Named User Queue", "Manager Standard", "Application Owner", "Internal Cache", "Spawn Target", "Running Now"])}

            <h3>Top 50 Intensive Database Strains (Last 30 Days)</h3>
            {render_table(safe_get(data, 'EBS_TOP_PROGRAMS', []), ["EBS Concurrent Routine Program", "Execution Count (30d)", "Avg Historic DB Time (Hrs)"])}
            
            <h3>Raw Init.ora Parameters Evaluated</h3>
            {render_table(db_params, ["Init Parameter", "Assigned Boundary"])}
        </div>

        <div id="sizing" class="section">
            <div class="section-header">
                <h2>Target Sizing & Capacity Recommendations</h2>
            </div>
            <p>EBS 12.2 and Database 19c introduce new memory structures (specifically WebLogic managed servers and multitenant dictionary cache). The following architecture sizing is dynamically modeled on your extracted usage and hardware metrics:</p>
            {sizing_analytics}
            <h3 style="margin-top:20px;">Infrastructure Sizing Best Practices</h3>
            <ul style="color: #334155; padding-left: 20px;">
                <li style="margin-bottom: 8px;"><b>Weblogic Managed Servers (oacore):</b> Do not exceed 4GB per `oacore` Managed Server footprint due to JVM Garbage Collection pause limits. Scale out horizontally by adding more processes when active user concurrency peaks beyond capacity.</li>
                <li style="margin-bottom: 8px;"><b>Output Post Processor (OPP):</b> For heavy XML Publisher loads (like large invoices), size the `FNDCPOPP` manager correctly per node. The recommended minimum is 2048MB per target process heap size via Context File updates.</li>
                <li style="margin-bottom: 8px;"><b>Oracle Forms Heap:</b> 12.2 shifts Forms to the WLS architecture. Expect +30% server-side memory footprint per active Form session than what was seen under 11g/12.1.</li>
                <li style="margin-bottom: 8px;"><b>Linux Database HugePages:</b> Whenever Target DB Memory (SGA) exceeds 30GB, enabling Linux HugePages is strictly required to prevent catastrophic kernel CPU swapping on Enterprise systems allocating 19c limits.</li>
            </ul>
        </div>
        
        <div id="techstack" class="section">
            <div class="section-header">
                <h2>Application TechStack & Security Profiling</h2>
            </div>
            <p>EBS uses a tightly coupled technology stack containing internal JDKs, OC4J servers, and HTTP listeners. Any custom file deployed locally (outside patching standards) onto the App filesystem must be migrated.</p>
            
            <h3>Base TechStack Context (12.1.3 Baseline)</h3>
            {render_table(safe_get(data, 'APP_TECHSTACK_INFO', []), ["Topology Property", "Discovered Deployment Path / Version"])}
            
            <h3>File-System Rogue Customizations (OS `find` extraction)</h3>
            <p style="font-size:13px; color:#475569;">Includes unmanaged `b64` web logic, rogue custom images missing personalization hooks, and manually dropped `.class` payloads in `$JAVA_TOP` missing standards.</p>
            {render_table(safe_get(data, 'APP_CUSTOM_FILES', []), ["File Search Target", "Discovered Quantity"])}
        </div>
        
        <div id="workflow" class="section">
            <div class="section-header">
                <h2>Oracle Workflow & Output Delivery Integrations</h2>
            </div>
            <p>Critical business transaction flows often stall during upgrades if SMTP/IMAP connections or XML generation templates fail on new Java Virtual Machines.</p>
            
            <h3>Notification Mailer & Network Parameters</h3>
            {render_table(safe_get(data, 'WORKFLOW_MAILER', []), ["Component Parameter", "Network Binding"])}
            
            <h3>Custom EBS Workflow Item Types</h3>
            {render_table(safe_get(data, 'CUSTOM_WORKFLOWS', []), ["Workflow Item Type", "Deplolyment Scope"])}

            <h3>XML Publisher (XDO) Template Demands</h3>
            {render_table(safe_get(data, 'XML_PUBLISHER_DELIVERY', []), ["Engine", "Delivery Format", "Document Volumes"])}
        </div>

    </div>
</body>
</html>
"""
    return html

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_upgrade_report.py <path_to_ebs_upgrade_analyzer_data.txt>")
        sys.exit(1)
        
    file_path = sys.argv[1]
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        sys.exit(1)
        
    data = parse_data(file_path)
    html_content = build_html(data)
    
    output_file = f"EBS_Upgrade_Impact_Analysis_{datetime.now().strftime('%Y%m%d')}.html"
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
        
    print(f"Analysis completely structured and generated: {output_file}")

if __name__ == "__main__":
    main()
