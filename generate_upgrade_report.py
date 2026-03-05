# ==============================================================================
# Script Name: generate_upgrade_report.py
# Description: Generates HTML report from EBS upgrade analyzer data
#
# Copyright (c) 2024-2026 Winfo Solutions. All Rights Reserved.
# This tool is Winfo Solutions Proprietary and Confidential.
# Unauthorized copying, distribution, or use of this file is strictly prohibited.
# ==============================================================================

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

def safe_float(value, default=0.0):
    """Safely convert a value to float, extracting digits if needed"""
    if value is None:
        return default
    try:
        return float(value)
    except (ValueError, TypeError):
        # Extract numeric portion from string like "DB_SIZE|12500"
        digits = ''.join(c for c in str(value) if c.isdigit() or c == '.')
        if digits:
            try:
                return float(digits)
            except (ValueError, TypeError):
                pass
        return default

def safe_int(value, default=0):
    """Safely convert a value to int, extracting digits if needed"""
    if value is None:
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        # Extract numeric portion
        digits = ''.join(c for c in str(value) if c.isdigit())
        if digits:
            try:
                return int(digits)
            except (ValueError, TypeError):
                pass
        return default

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

def render_drilldown_table(summary_text, rows, headers):
    if not rows:
         return f"<div style='margin-bottom: 5px; color:#555;'><b>{summary_text}</b> (0 items)</div>"
    
    html = f"""
    <details style="margin-bottom: 10px; background: #fdfdfd; border: 1px solid #eee; border-radius: 6px; padding: 5px 10px;">
        <summary style="cursor: pointer; font-weight: 600; color: #0A3A6B; outline: none;">
            {summary_text} <span style="font-weight: normal; color: #666;">({len(rows)} items)</span>
        </summary>
        <div style="margin-top: 10px;">
            {render_table(rows, headers)}
        </div>
    </details>
    """
    return html

def render_url_profiles_table(url_profiles):
    """Render URL profiles with recommendations for upgrade."""
    if not url_profiles or (len(url_profiles) == 1 and url_profiles[0][0] == 'N/A'):
        return "<p style='color:#777; font-size:14px; font-style:italic;'>No URL profile data found.</p>"
    
    # Define recommendations for each profile
    recommendations = {
        'APPS_FRAMEWORK_AGENT': 'Update to new WebLogic managed server URL format. Must use HTTPS with valid SSL certificate in EBS 12.2.11+.',
        'APPS_AUTH_AGENT': 'Configure for Oracle Access Manager integration or leave blank for standard FND authentication.',
        'FND_APEX_URL': 'Update to APEX 23.x URL after deploying APEX on 19c/23ai database. ORDS must be configured separately.',
        'FND_EXTERNAL_ADF_URL': 'Update ADF URL if external ADF applications are deployed. Validate WebLogic domain configuration.',
        'INV_EBI_SERVER_URL': 'Update ISG (Integrated SOA Gateway) server URL for REST/SOAP service endpoints.',
        'ICX_FORMS_LAUNCHER': 'Forms servlet URL - update to new WebLogic domain URL. Critical for Forms application launch.'
    }
    
    html = '<table><thead><tr><th>Profile Name</th><th>Current Value</th><th style="width:40%;">Upgrade Recommendation</th></tr></thead><tbody>'
    
    for row in url_profiles:
        if len(row) < 2:
            continue
        profile_name = row[0] if row[0] else ''
        profile_value = row[1] if row[1] else 'NOT_DEFINED'
        recommendation = recommendations.get(profile_name, 'Review and update as needed post-upgrade.')
        
        # Determine status color
        if profile_value == 'NOT_DEFINED' or not profile_value.strip():
            status_style = 'background:#FEF3C7; color:#92400E;'
            value_display = '<span style="color:#92400E; font-style:italic;">Not Configured</span>'
        elif 'http://' in profile_value.lower():
            status_style = 'background:#FEE2E2; color:#991B1B;'
            value_display = f'{profile_value} <br/><span style="color:#991B1B; font-size:12px;">⚠️ HTTP - Should use HTTPS</span>'
        else:
            status_style = 'background:#D1FAE5; color:#065F46;'
            value_display = profile_value
        
        html += f'<tr><td style="font-weight:600;">{profile_name}</td><td style="{status_style}">{value_display}</td><td style="font-size:13px;">{recommendation}</td></tr>'
    
    html += '</tbody></table>'
    return html

def determine_integrations(profiles, apex_ords_data):
    integ = {
        'SSO': {'status': 'Disabled', 'desc': 'No Oracle Access Manager or external SSO agents mapping detected. Standard FND login assumed.', 'color': '--border-grey', 'roadmap': 'Standard FND User migration.'},
        'APEX': {'status': 'Disabled', 'desc': 'No APEX listener links found in profiles.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'ECC': {'status': 'Disabled', 'desc': 'Enterprise Command Center not found in fnd profiles.', 'color': '--border-grey', 'roadmap': 'Consider deploying ECC V12 for modern EBS 12.2.14+ reporting.'},
        'SOA_ISG': {'status': 'Disabled', 'desc': 'Integrated SOA Gateway (ISG) or SOA Suite ties are not mapped.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'OBIEE': {'status': 'Disabled', 'desc': 'OAC/OBIEE analytical URL links not found.', 'color': '--border-grey', 'roadmap': 'N/A'},
        'ENDECA': {'status': 'Disabled', 'desc': 'Information Discovery (Endeca) is not wired.', 'color': '--border-grey', 'roadmap': 'Replace with ECC if needed.'}
    }
    
    fwk_agent = ""
    auth_agent = ""
    sso_mode = ""
    endeca_active_count = 0

    for row in profiles:
        if len(row) < 2: continue
        name = row[0].upper() if row[0] else ''
        value = row[1] if row[1] else ''
        if not value.strip(): continue

        if name == 'APPS_FRAMEWORK_AGENT': fwk_agent = value
        if name == 'APPS_AUTH_AGENT': auth_agent = value
        if name == 'APPS_SSO': sso_mode = value.upper() if value else ''  # Track SSO mode - SSWA means standard login
        
        # APEX detection - only FND_APEX_URL with actual URL value
        if name == 'FND_APEX_URL':
            if value == 'NOT_DEFINED':
                integ['APEX'] = {'status': 'Not Configured', 'desc': 'APEX Profile exists but has no value at Site Level.', 'color': '--border-grey', 'roadmap': 'No action required.'}
            else:
                apex_ver = next((row[1] for row in apex_ords_data if len(row) > 1 and row[0] == 'Oracle Application Express'), 'Unknown')
                ords_ver = next((row[1] for row in apex_ords_data if len(row) > 1 and row[0] == 'Oracle REST Data Services'), 'Unknown')
                version_str = f"DB reports APEX v{apex_ver} and ORDS v{ords_ver}." if apex_ords_data and apex_ords_data[0][0] != 'N/A' else "Version data not found in registry."
                integ['APEX'] = {'status': 'Active', 'desc': f'Active via {name}={value}. {version_str} Custom code and APEX Listeners require testing across 19c/23ai.', 'color': '--warning-amber', 'roadmap': 'APEX 23.x must be deployed on the target database, and ORDS configured on a standalone Weblogic/Tomcat server.'}
        
        # ECC detection - specific profiles for Enterprise Command Center
        ecc_profiles = ['FND_ENDECA_PORTAL_URL', 'FND_ENDECA_INTEGRATOR_URL']
        if name in ecc_profiles:
            if value == 'NOT_DEFINED':
                integ['ECC'] = {'status': 'Not Configured', 'desc': 'ECC Command Center Profiles exist but are blank.', 'color': '--border-grey', 'roadmap': 'Consider deploying ECC V12 for modern reporting.'}
            else:
                integ['ECC'] = {'status': 'Active', 'desc': f'Command Center configured via {name}.', 'color': '--primary-blue', 'roadmap': 'Requires upgrading the ECC standalone server to V10+ (V12 Recommended) to certify with EBS 12.2.14/15.'}
        
        # SOA/ISG detection - specific profiles that indicate actual ISG/REST service usage
        isg_profiles = ['FND_SOA_GENERIC_SERVICE_WSDL', 'INV_EBI_SERVER_URL', 'INV_EBI_SOASERVER_USER', 'PA_EBI_SOASERVER_USER']
        if name in isg_profiles:
            if value != 'NOT_DEFINED':
                integ['SOA_ISG'] = {'status': 'Active', 'desc': f'Integrated SOA Gateway detected via {name}. ISG has major architectural shifts in 12.2.', 'color': '--warning-amber', 'roadmap': 'REST services must be migrated to the new EBS Weblogic ISG deployment mechanism. SOAP endpoints must be re-generated.'}
        
        # OBIEE detection - use FND_OBIEE_URL as primary indicator (actual URL)
        # HRI_IMPL_OBIEE alone is not sufficient - it's just an HR profile that can be seeded
        if name == 'FND_OBIEE_URL':
            value_upper = value.upper() if value else ''
            if value != 'NOT_DEFINED' and value_upper not in ['N', 'NO', '']:
                # FND_OBIEE_URL with actual URL value indicates OBIEE is truly configured
                integ['OBIEE'] = {'status': 'Active', 'desc': f'OBIEE/OAC configured via {name}={value}.', 'color': '--primary-blue', 'roadmap': 'No DB structural impact, but EBS Auth integration to OAS/OAC must be tested against new WLS cookies.'}
        
        # HRI_IMPL_OBIEE=Y only indicates OBIEE is available for HR Intelligence, but needs FND_OBIEE_URL
        # to be truly functional. Mark as "Review Required" if HRI_IMPL_OBIEE=Y but no FND_OBIEE_URL found yet
        if name == 'HRI_IMPL_OBIEE':
            value_upper = value.upper() if value else ''
            if value_upper == 'Y' and integ['OBIEE']['status'] == 'Disabled':
                integ['OBIEE'] = {'status': 'Review Required', 'desc': f'HRI_IMPL_OBIEE={value} indicates HR Intelligence may be using OBIEE, but FND_OBIEE_URL is not configured. Review if OBIEE is actually deployed.', 'color': '--warning-amber', 'roadmap': 'Verify if Oracle Business Intelligence (OBIEE/OAC) is installed and being used. If not, consider disabling HRI_IMPL_OBIEE profile.'}
        
        # ENDECA detection - profiles that indicate actual Endeca usage (not just existence of profile)
        # Only count profiles that have real values (not NOT_DEFINED)
        endeca_active_profiles = [
            'HR_EXTENSION_FOR_ENDECA', 'HZ_ENDECA_DISPLAY_CURRENCY', 'CN_ENDECA_VIEW_PERIOD',
            'ONT_ENDECA_DISPLAY_CURRENCY', 'ONT_ENDECA_ADDL_INFO', 'AHL_ENDECA_HISTORICAL_TRANSACTION',
            'CS_ENDECA_SR_LOAD_START_DATE', 'USE_WO_ORG_FOR_EAM_ENDECA_SECURITY'
        ]
        value_upper = value.upper() if value else ''
        if name in endeca_active_profiles and value != 'NOT_DEFINED' and value_upper not in ['N', 'NO', 'NONE']:
            endeca_active_count += 1
        
        # VERTEX detection
        if name in ['HR_US_VERTEX_WEB_SERVICE_HOST', 'HR_US_VERTEX_WEB_SERVICE_PORT']:
            if value != 'NOT_DEFINED':
                integ['VERTEX'] = {'status': 'Active', 'desc': f'Vertex Tax Integration detected via {name}.', 'color': '--danger-red', 'roadmap': 'Verify Vertex O series certification matrix for target OS and EBS 12.2.'}
        
        if 'AVALARA' in name:
            if value != 'NOT_DEFINED':
                integ['AVALARA'] = {'status': 'Active', 'desc': 'Avalara Tax engine detected.', 'color': '--warning-amber', 'roadmap': 'Migration effort required for Avalara integration testing.'}
        
        if 'KBACE' in name:
            if value != 'NOT_DEFINED':
                integ['KBACE'] = {'status': 'Active', 'desc': 'KBACE integration mapping found.', 'color': '--warning-amber', 'roadmap': 'Dependent on modern WebLogic OS architectural dependencies.'}
        
        if 'MARKVIEW' in name:
            if value != 'NOT_DEFINED':
                integ['MARKVIEW'] = {'status': 'Active', 'desc': 'Kofax Markview imaging system.', 'color': '--warning-amber', 'roadmap': 'Highly invasive AP Integration. Exhaustive regression testing required on target WLS tier.'}
        
        if 'GRC' in name:
            if value != 'NOT_DEFINED':
                integ['GRC'] = {'status': 'Active', 'desc': 'Oracle GRC (Governance Risk Compliance).', 'color': '--primary-blue', 'roadmap': 'Ensure AACG connectors map correctly against target OS versions.'}
        
        # SSO detection - specific profiles that indicate OAM/external SSO (not SSWA standard login)
        oam_sso_profiles = ['APPS_OAM_APPL_SERVER_URL', 'FND_SSO_COOKIE_DOMAIN', 'APPS_SSO_COOKIE_DOMAIN', 'APPS_SSO_PROFILE']
        if name in oam_sso_profiles and value != 'NOT_DEFINED':
            integ['SSO'] = {'status': 'Active', 'desc': f'OAM/SSO configurations detected via {name}.', 'color': '--warning-amber', 'roadmap': 'Requires deploying Oracle Access Gate 1.2.3+ on Weblogic 10.3.6 (or OHS 12c Webgates) certified against the new Linux 9 OS.'}
    
    # Set ENDECA status based on count of active profiles
    if endeca_active_count >= 2:
        integ['ENDECA'] = {'status': 'Active', 'desc': f'{endeca_active_count} Endeca-related profiles with values detected. Information Discovery may be in use.', 'color': '--danger-red', 'roadmap': 'Oracle Endeca Information Discovery is functionally replaced by ECC in 12.2. Migration effort to ECC recommended.'}
    elif endeca_active_count == 1:
        integ['ENDECA'] = {'status': 'Partial', 'desc': 'Limited Endeca profile configuration found.', 'color': '--warning-amber', 'roadmap': 'Verify if Endeca Information Discovery is actively used. Consider ECC migration.'}
            
    # Check if agents differ indicating external SSO (only if auth_agent has a real value)
    if auth_agent and auth_agent != 'NOT_DEFINED' and fwk_agent and auth_agent != fwk_agent:
        integ['SSO'] = {'status': 'Active', 'desc': 'External SSO detected via disjointed Auth & Framework Agents.', 'color': '--warning-amber', 'roadmap': 'Verify SSO Trust architecture prior to upgrading.'}
    
    # Set SSO to Standard only if it's still Disabled and APPS_SSO=SSWA (don't override Active or other states)
    if sso_mode == 'SSWA' and integ['SSO']['status'] == 'Disabled':
        integ['SSO'] = {'status': 'Standard', 'desc': 'APPS_SSO=SSWA indicates standard EBS Self-Service login. No external SSO/OAM integration.', 'color': '--border-grey', 'roadmap': 'Standard FND User migration with no SSO dependencies.'}

    return integ

def run_prebuilt_rules(db_version, ebs_version, db_params, os_info, db_size, data):
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
    db_links = 0
    for row in safe_get(data, 'DBA_DB_LINKS', []):
        if row and row[0]:
            try:
                db_links += int(row[0])
            except (ValueError, TypeError):
                pass
                
    invalid_objs_raw = safe_get(data, 'DBA_INVALID_OBJECTS', [['0']])[0]
    # Use safe_int which handles formats like "42" or "INVALID_OBJECTS_COUNT" (extracts digits)
    invalid_objs_num = 0
    for val in invalid_objs_raw:
        num = safe_int(val, 0)
        if num > 0:
            invalid_objs_num = num
            break
    
    if invalid_objs_num > 100:
        challenges.append(f"<b>Database Hygiene</b>: The source database has {invalid_objs_num} invalid objects. The 12.2 Edition-based Redefinition pre-reqs demand a clean compilation state before enablement.")
        
    if db_links > 15:
        challenges.append(f"<b>Integration Sprawl</b>: Detected {db_links} active Database Links. High integration coupling will drastically extend testing cycles during the Multitenant database platform migration.")

    # DB Versions
    if '11' in db_version or '12.1' in db_version:
        challenges.append("<b>Database Container Migration</b>: The Database upgrade to 19c+ mandates converting the non-CDB architecture to the Multitenant (CDB/PDB) architecture required by modern Oracle releases.")

    # Character Set
    challenges.append("<b>AL32UTF8 Mandate</b>: If the Database is not already AL32UTF8, the EBS 12.2 upgrade highly recommends transitioning to Unicode to support modern middle-tier functionality.")

    # Memory Size - use safe_float helper
    db_size_num = safe_float(db_size)
    if db_size_num > 2000:
        challenges.append(f"<b>Downtime Constraints</b>: The database is quite large ({db_size_num} GB). Depending on OS-endianness, the migration/upgrade of the Database file structures might breach typical weekend downtime cutovers without utilizing specialized Data Guard or Oracle GoldenGate syncs.")

    return challenges

def build_roadmap(ebs_version, db_version, is_rac, has_dataguard, tech_stack_info=None):
    """Build dynamic upgrade roadmap based on source environment."""
    
    # Determine source state
    is_ebs_1213 = '12.1' in str(ebs_version) or '1213' in str(ebs_version).replace('.', '')
    is_ebs_122x = '12.2' in str(ebs_version)  # Already on 12.2.x
    is_ebs_1220 = '12.2.0' in str(ebs_version)
    is_db_11g = '11' in str(db_version)
    is_db_12c = '12' in str(db_version)
    is_db_19c = '19' in str(db_version)
    
    # Extract version number for 12.2.x releases
    ebs_minor_version = 0
    if is_ebs_122x:
        try:
            # Extract minor version number (e.g., 12.2.15 -> 15)
            parts = str(ebs_version).split('.')
            if len(parts) >= 3:
                ebs_minor_version = int(parts[2])
        except (ValueError, IndexError):
            ebs_minor_version = 0
    
    # Build complexity indicators
    complexity_factors = []
    if is_ebs_1213:
        complexity_factors.append("EBS 12.1.3 → 12.2 upgrade (Major architectural change)")
    elif is_ebs_122x and ebs_minor_version < 15:
        complexity_factors.append(f"EBS 12.2.{ebs_minor_version} → 12.2.15 upgrade (Continuous Innovation patching)")
    if is_db_11g:
        complexity_factors.append("Database 11g → 19c upgrade (2 major version jumps)")
    elif is_db_12c:
        complexity_factors.append("Database 12c → 19c upgrade (Major version upgrade)")
    if is_rac:
        complexity_factors.append("RAC cluster coordination required")
    if has_dataguard:
        complexity_factors.append("Data Guard standby recreation needed")
    
    complexity_html = ""
    if complexity_factors:
        complexity_html = """
        <div style="background:#FEF3C7; border-left:4px solid #F59E0B; padding:15px; margin-bottom:20px; border-radius:6px;">
            <strong style="color:#92400E;">⚠️ Complexity Factors Identified:</strong>
            <ul style="margin:10px 0 0 20px; color:#92400E;">
        """
        for factor in complexity_factors:
            complexity_html += f"<li>{factor}</li>"
        complexity_html += "</ul></div>"
    
    # RAC-specific considerations
    rac_html = ""
    if is_rac:
        rac_html = """
        <div style="background:#E0F2FE; border-left:4px solid #0284C7; padding:15px; margin:20px 0; border-radius:6px;">
            <strong style="color:#0369A1;">🔄 RAC Cluster Considerations:</strong>
            <ul style="margin:10px 0 0 20px; color:#0369A1;">
                <li>All RAC instances must be shut down during database upgrade</li>
                <li>ASM disk groups require validation post-upgrade</li>
                <li>OCR/Voting disks backup recommended before upgrade</li>
                <li>Grid Infrastructure upgrade may be required (19c GI for 19c RAC)</li>
                <li>SCAN listeners must be reconfigured for new cluster</li>
                <li>Recommend upgrading to RAC with 19c RU latest patch</li>
            </ul>
        </div>
        """
    
    # Data Guard considerations
    dg_html = ""
    if has_dataguard:
        dg_html = """
        <div style="background:#F0FDF4; border-left:4px solid #22C55E; padding:15px; margin:20px 0; border-radius:6px;">
            <strong style="color:#166534;">🛡️ Data Guard Standby Considerations:</strong>
            <ul style="margin:10px 0 0 20px; color:#166534;">
                <li>Standby database must be recreated after primary upgrade</li>
                <li>Physical standby: Use RMAN duplicate or restore from backup</li>
                <li>Logical standby: Requires complete rebuild from upgraded primary</li>
                <li>Data Guard Broker configuration needs reconfiguration</li>
                <li>Consider temporary DR gap during cutover weekend</li>
                <li>Fast-Start Failover should be disabled during upgrade</li>
            </ul>
        </div>
        """
    
    # Tech stack info display for 12.2.x environments
    tech_stack_html = ""
    if tech_stack_info and is_ebs_122x:
        tech_stack_html = """
        <div style="background:#EFF6FF; border-left:4px solid #3B82F6; padding:15px; margin:20px 0; border-radius:6px;">
            <strong style="color:#1E40AF;">📦 Current Technology Stack (EBS 12.2.x):</strong>
            <ul style="margin:10px 0 0 20px; color:#1E40AF;">
        """
        for key, value in tech_stack_info.items():
            if value and value not in ['Unknown', 'N/A', '']:
                tech_stack_html += f"<li><b>{key}:</b> {value}</li>"
        tech_stack_html += "</ul></div>"
    
    # Build different roadmaps based on EBS version
    if is_ebs_122x:
        # Already on 12.2.x - simpler upgrade path to 12.2.15
        db_upgrade_step = ""
        if is_db_11g:
            db_upgrade_step = "Upgrade from 11g to 19c using AutoUpgrade or DBUA. "
        elif is_db_12c:
            db_upgrade_step = "Upgrade from 12c to 19c using AutoUpgrade. "
        elif not is_db_19c:
            db_upgrade_step = "Upgrade database to 19c using AutoUpgrade. "
        else:
            db_upgrade_step = "Database is already at 19c. Apply latest Release Update (RU). "
        
        return f"""
        {complexity_html}
        {tech_stack_html}
        
        <h3>Upgrade Approach Overview (EBS 12.2.x to 12.2.15)</h3>
        <p style="font-size:14px; color:#475569;">Since your environment is already on EBS 12.2.x, the upgrade path is streamlined. Focus is on applying RUPs and updating the technology stack components.</p>
        
        <div class="roadmap-timeline">
            <div class="rm-step">
                <div class="rm-badge">Ph 1</div>
                <div>
                    <strong>Infrastructure Refresh (If Required)</strong><br>
                    Upgrade Oracle Linux to 8/9 (RHEL 8/9) if on older version. Validate storage and compute requirements for new WLS versions.
                    Prepare the target infrastructure with updated hardware requirements.
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 2</div>
                <div>
                    <strong>Database Upgrade</strong><br>
                    {db_upgrade_step}
                    Migrate to PDB architecture if still using non-CDB. Apply latest DB Release Updates.
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 3</div>
                <div>
                    <strong>AD/TXK Delta Patching</strong><br>
                    Apply the latest AD/TXK Delta packs required for 12.2.15. Update WebLogic Server to certified version (12.2.1.4.0).
                    Update Oracle HTTP Server (OHS) to certified version. Apply required technology stack patches.
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 4</div>
                <div>
                    <strong>Apply 12.2.15 Release Update Pack (RUP)</strong><br>
                    Use ADOP to apply the 12.2.15 RUP in preparation, application, finalization phases.
                    Validate Online Patching (EBR) status. Run diagnostics and validation scripts.
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 5</div>
                <div>
                    <strong>Integration & Validation</strong><br>
                    Re-validate SSO, OAC, ISG, and third-party integrations. Test CEMLI customizations against new release.
                    Execute functional test cycles and performance benchmarking.
                </div>
            </div>
        </div>
        
        {rac_html}
        {dg_html}
        
        <h3>High-Level EBS 12.2.x to 12.2.15 Upgrade Steps</h3>
        <p style="font-size:13px; color:#475569;">The following activities represent the critical path for completing an EBS 12.2.15 RUP upgrade project:</p>
        
        <table style="font-size:13px;">
            <thead>
                <tr>
                    <th style="width:50px;">Step</th>
                    <th style="width:150px;">Phase</th>
                    <th>Activity Description</th>
                    <th style="width:100px;">Duration Est.</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td style="text-align:center; font-weight:bold;">1</td>
                    <td>Planning</td>
                    <td><strong>Assess & Plan</strong> - Review current patch levels, verify CEMLI compatibility, identify required pre-requisite patches</td>
                    <td>2-3 days</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">2</td>
                    <td>Infrastructure</td>
                    <td><strong>Clone & Prepare</strong> - Clone production to test environment, validate storage, prepare rollback strategy</td>
                    <td>2-3 days</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">3</td>
                    <td>Database</td>
                    <td><strong>DB Upgrade</strong> - {'Apply 19c upgrade' if not is_db_19c else 'Apply latest DB RU'}, run pre-upgrade fixups, execute AutoUpgrade</td>
                    <td>{'4-8 hours' if is_db_19c else '1-2 days'}</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">4</td>
                    <td>Technology</td>
                    <td><strong>AD/TXK Delta</strong> - Apply AD and TXK delta patches, update WebLogic binaries, update OHS</td>
                    <td>4-8 hours</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">5</td>
                    <td>Application</td>
                    <td><strong>Apply RUP</strong> - Execute ADOP prepare, apply, finalize for 12.2.15 RUP bundle</td>
                    <td>8-16 hours</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">6</td>
                    <td>Validation</td>
                    <td><strong>Post-Upgrade Validation</strong> - Run diagnostics, validate integrations, execute smoke tests</td>
                    <td>1-2 days</td>
                </tr>
                <tr>
                    <td style="text-align:center; font-weight:bold;">7</td>
                    <td>Testing</td>
                    <td><strong>UAT & Functional Testing</strong> - Execute full UAT cycle, validate business processes</td>
                    <td>1-2 weeks</td>
                </tr>
            </tbody>
        </table>
        
        <div style="margin-top: 25px; padding: 15px; background: #F0FDF4; border-radius: 8px; border: 1px solid #BBF7D0;">
            <strong>📋 Timeline Estimate for EBS 12.2.x → 12.2.15:</strong><br>
            <strong>Typical Range:</strong> 2-4 weeks (depending on DB version and testing requirements)<br>
            <strong>Cutover Window:</strong> 8-24 hours depending on database upgrade requirements
        </div>
    """
    else:
        # Original 12.1.3 to 12.2 upgrade path
        return f"""
        {complexity_html}
        
        <h3>Upgrade Approach Overview</h3>
        <p style="font-size:14px; color:#475569;">The following phased approach addresses the transition from your current environment to the target Oracle EBS 12.2.15 on Database 19c architecture.</p>
        
        <div class="roadmap-timeline">
            <div class="rm-step">
                <div class="rm-badge">Ph 1</div>
                <div>
                    <strong>Infrastructure & Technical Stack</strong><br>
                    Deploy Oracle Linux 8/9 (RHEL 8/9). Install Oracle Database 19c binary in Multitenant architecture (CDB). 
                    {'<span style="color:#DC2626;">(Current DB 11g requires direct to 19c upgrade path)</span>' if is_db_11g else ''}
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 2</div>
                <div>
                    <strong>Database Upgrade & Migration</strong><br>
                    {'Upgrade from 11g to 19c using AutoUpgrade or DBUA. ' if is_db_11g else 'Upgrade from 12c to 19c using AutoUpgrade. '}
                    Migrate into 19c PDB. Convert <code>UTL_FILE_DIR</code> to Oracle Directories. Migrate character sets to AL32UTF8 (if needed).
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 3</div>
                <div>
                    <strong>Application Upgrade (12.1.3 → 12.2.0 Base)</strong><br>
                    Major version upgrade from 12.1.3 to 12.2.0 using AD leveling scripts. 
                    Rapid Install the 12.2 File System via DB upgrade mode. Deploy dual-file system and WebLogic Server (WLS 10.3.6). Enable Online Patching (EBR).
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 4</div>
                <div>
                    <strong>CEMLI Remediation (Customizations)</strong><br>
                    Apply Online Patching logical columns to all custom tables. Re-compile Java/C executables natively on target OS. Remediate custom PL/SQL to Edition-based standards. Validate all custom objects.
                </div>
            </div>
            <div class="rm-step">
                <div class="rm-badge">Ph 5</div>
                <div>
                    <strong>Continuous Innovation (12.2.14 / 12.2.15)</strong><br>
                    Apply the latest AD/TXK Delta packs in the run edition. Apply the 12.2.15 Release Update Pack (RUP). Re-integrate SSO, OAC, and ISG endpoints. Validate all integrations.
                </div>
        </div>
    </div>
    
    {rac_html}
    {dg_html}
    
    <h3>High-Level 15-Step Upgrade Activity Summary</h3>
    <p style="font-size:13px; color:#475569;">The following activities represent the critical path for completing a successful EBS upgrade project:</p>
    
    <table style="font-size:13px;">
        <thead>
            <tr>
                <th style="width:50px;">Step</th>
                <th style="width:150px;">Phase</th>
                <th>Activity Description</th>
                <th style="width:100px;">Duration Est.</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td style="text-align:center; font-weight:bold;">1</td>
                <td>Planning</td>
                <td><strong>Discovery & Assessment</strong> - Complete CEMLI inventory, identify customizations, integrations, and technical dependencies</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">2</td>
                <td>Planning</td>
                <td><strong>Environment Sizing</strong> - Define target infrastructure requirements for OL8/9, 19c DB, WLS, and storage needs</td>
                <td>1 week</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">3</td>
                <td>Infrastructure</td>
                <td><strong>Target Environment Build</strong> - Provision new servers with Oracle Linux 8/9, configure network, storage, and prerequisites</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">4</td>
                <td>Infrastructure</td>
                <td><strong>Database Software Installation</strong> - Install Oracle Database 19c software, create CDB container database{'<br><span style="color:#DC2626;">+ Grid Infrastructure for RAC</span>' if is_rac else ''}</td>
                <td>1 week</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">5</td>
                <td>Database</td>
                <td><strong>Database Upgrade/Migration</strong> - Upgrade {'11g' if is_db_11g else '12c'} database to 19c using AutoUpgrade, plug into CDB as PDB</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">6</td>
                <td>Database</td>
                <td><strong>Database Post-Upgrade Tasks</strong> - Apply latest 19c RU patch, validate parameters, configure TDE (if required), test connectivity</td>
                <td>3-5 days</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">7</td>
                <td>Application</td>
                <td><strong>EBS 12.2 Rapid Install</strong> - Install EBS 12.2 application tier file system, configure WebLogic domain, enable dual-filesystem</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">8</td>
                <td>Application</td>
                <td><strong>Online Patching Enablement</strong> - Enable EBR (Edition-Based Redefinition), configure ADOP, validate patching cycle</td>
                <td>3-5 days</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">9</td>
                <td>Application</td>
                <td><strong>Apply Release Update Pack</strong> - Apply AD/TXK Delta packs and 12.2.14/12.2.15 RUP using ADOP patching</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">10</td>
                <td>CEMLI</td>
                <td><strong>Custom Schema Registration</strong> - Register all custom schemas with AD_ZD, apply EBR enablement to custom tables</td>
                <td>1 week</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">11</td>
                <td>CEMLI</td>
                <td><strong>Custom Code Remediation</strong> - Recompile Forms/Reports, remediate PL/SQL for EBR, rebuild Java/OAF components on new JDK</td>
                <td>2-4 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">12</td>
                <td>Integration</td>
                <td><strong>Integration Re-Configuration</strong> - Reconfigure SSO, ISG, APEX, ECC, and third-party integrations on new WLS tier</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">13</td>
                <td>Testing</td>
                <td><strong>Functional Testing</strong> - Execute business process testing across all modules, validate reports and outputs</td>
                <td>2-4 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">14</td>
                <td>Testing</td>
                <td><strong>Performance Testing</strong> - Load testing, concurrent processing validation, Forms/UI response times{'<br><span style="color:#0284C7;">+ RAC workload balancing</span>' if is_rac else ''}</td>
                <td>1-2 weeks</td>
            </tr>
            <tr>
                <td style="text-align:center; font-weight:bold;">15</td>
                <td>Cutover</td>
                <td><strong>Production Cutover</strong> - Final data sync, cutover execution, go-live validation, hypercare support{'<br><span style="color:#22C55E;">+ Data Guard standby rebuild</span>' if has_dataguard else ''}</td>
                <td>1 weekend</td>
            </tr>
        </tbody>
    </table>
    
    <div style="background:#F1F5F9; border-radius:8px; padding:20px; margin-top:20px;">
        <h4 style="margin-top:0; color:#0F172A;">📊 Estimated Total Project Duration</h4>
        <p style="margin:0; font-size:14px;">
            <strong>Typical Range:</strong> 4-6 months (depending on CEMLI complexity and integration scope)<br>
            <strong>Mock Cycles:</strong> 2-3 full upgrade rehearsals recommended before production cutover<br>
            <strong>Cutover Window:</strong> 48-72 hours recommended for production migration
        </p>
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
    if safe_float(db_size) > 1000: cd2_score += 2
    if cd2_score > 5: cd2_score = 5

    # CD-3: EBR Readiness
    cd3_score = 0
    adzd_schemas = safe_int(safe_get(data, 'ADOP_AD_ZD_SCHEMAS', [['0']])[0][0])
    if custom_schemas_cnt > 10 and adzd_schemas == 0: cd3_score = 5
    elif custom_schemas_cnt > 0: cd3_score = 3

    # CD-4: Customization Footprint (CEMLI)
    cd4_score = 0
    if custom_objs > 5000: cd4_score = 5
    elif custom_objs > 1000: cd4_score = 3

    db_links_list = safe_get(data, 'DBA_DB_LINKS', [])
    db_links_count = len(db_links_list) if db_links_list and db_links_list[0][0] != 'N/A' else 0
    cd5_score = 0
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
    users = safe_int(active_users)
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

def calculate_effort_estimation(complexity_payload, custom_objs, db_size, active_users):
    """Calculate effort estimation by workstream based on complexity"""
    base_effort = {
        'Small': {'infra': 2, 'db': 3, 'app': 4, 'cemli': 2, 'sso': 1, 'integrations': 2, 'testing': 4, 'cutover': 1},
        'Medium': {'infra': 4, 'db': 6, 'app': 8, 'cemli': 6, 'sso': 2, 'integrations': 4, 'testing': 8, 'cutover': 2},
        'Large': {'infra': 6, 'db': 10, 'app': 12, 'cemli': 12, 'sso': 4, 'integrations': 8, 'testing': 16, 'cutover': 3},
        'Very Large': {'infra': 10, 'db': 16, 'app': 20, 'cemli': 20, 'sso': 6, 'integrations': 12, 'testing': 24, 'cutover': 4}
    }
    
    size = complexity_payload['size']
    effort = base_effort.get(size, base_effort['Medium']).copy()
    
    # Adjust CEMLI based on actual counts
    if custom_objs > 5000:
        effort['cemli'] = int(effort['cemli'] * 1.5)
    elif custom_objs > 2000:
        effort['cemli'] = int(effort['cemli'] * 1.2)
        
    # Adjust DB based on size
    db_size_gb = safe_float(db_size, 0)
    if db_size_gb > 3000:
        effort['db'] = int(effort['db'] * 1.5)
    elif db_size_gb > 1500:
        effort['db'] = int(effort['db'] * 1.2)
        
    # Adjust testing based on users
    try:
        users = int(active_users)
        if users > 2000:
            effort['testing'] = int(effort['testing'] * 1.3)
    except (ValueError, TypeError):
        pass
    
    total_weeks = sum(effort.values())
    
    return {
        'workstreams': effort,
        'total_weeks': total_weeks,
        'total_months': round(total_weeks / 4, 1)
    }

def generate_risk_register(data, complexity_payload, os_info, db_version, custom_objs, db_links_count):
    """Generate a risk register based on extracted data"""
    risks = []
    
    # OS Related Risks
    os_name = os_info.get('OS_RELEASE', '').lower()
    if 'linux' not in os_name:
        risks.append({'id': 'R01', 'category': 'Infrastructure', 'risk': 'Cross-platform migration required', 'severity': 'Critical', 'impact': 'High', 'mitigation': 'Plan for Transportable Tablespaces or full export/import'})
    elif '6' in os_name or '7' in os_name:
        risks.append({'id': 'R02', 'category': 'Infrastructure', 'risk': 'End-of-Life OS version detected', 'severity': 'High', 'impact': 'Medium', 'mitigation': 'Include OS upgrade in project scope'})
    
    # Database Risks
    if '11' in db_version or '12.1' in db_version:
        risks.append({'id': 'R03', 'category': 'Database', 'risk': 'Major database version upgrade required', 'severity': 'High', 'impact': 'High', 'mitigation': 'Plan for 19c upgrade with CDB/PDB conversion'})
    
    # Customization Risks
    if custom_objs > 5000:
        risks.append({'id': 'R04', 'category': 'CEMLI', 'risk': 'Heavy customization footprint detected', 'severity': 'High', 'impact': 'High', 'mitigation': 'Allocate dedicated CEMLI remediation workstream'})
    elif custom_objs > 1000:
        risks.append({'id': 'R05', 'category': 'CEMLI', 'risk': 'Moderate customization requiring EBR enablement', 'severity': 'Medium', 'impact': 'Medium', 'mitigation': 'Review custom schemas for edition-based readiness'})
    
    # Integration Risks
    if db_links_count > 20:
        risks.append({'id': 'R06', 'category': 'Integration', 'risk': 'High number of database links indicates complex integrations', 'severity': 'High', 'impact': 'High', 'mitigation': 'Map all integration touchpoints and test thoroughly'})
    elif db_links_count > 5:
        risks.append({'id': 'R07', 'category': 'Integration', 'risk': 'External database dependencies identified', 'severity': 'Medium', 'impact': 'Medium', 'mitigation': 'Validate connectivity post-upgrade'})
    
    # Invalid Objects
    invalid_objs = safe_get(data, 'DBA_INVALID_OBJECTS_LIST', [])
    try:
        if len(invalid_objs) > 500:
            risks.append({'id': 'R08', 'category': 'Database', 'risk': f'{len(invalid_objs)} invalid objects require remediation', 'severity': 'High', 'impact': 'Medium', 'mitigation': 'Run utlrp.sql and resolve compilation errors'})
        elif len(invalid_objs) > 100:
            risks.append({'id': 'R09', 'category': 'Database', 'risk': f'{len(invalid_objs)} invalid objects detected', 'severity': 'Medium', 'impact': 'Low', 'mitigation': 'Review and compile before upgrade'})
    except (ValueError, TypeError):
        pass
    
    # Complexity-based risks
    if complexity_payload['total'] >= 25:
        risks.append({'id': 'R10', 'category': 'Project', 'risk': 'Very Large complexity score indicates high project risk', 'severity': 'Critical', 'impact': 'High', 'mitigation': 'Consider phased approach with multiple mock cycles'})
    elif complexity_payload['total'] >= 17:
        risks.append({'id': 'R11', 'category': 'Project', 'risk': 'Large upgrade scope requires careful planning', 'severity': 'High', 'impact': 'Medium', 'mitigation': 'Plan minimum 3 rehearsal cycles'})
    
    # SSO Risk
    if complexity_payload['factors'].get('CD-6 Security/SSO', 0) >= 3:
        risks.append({'id': 'R12', 'category': 'Security', 'risk': 'SSO/OAM integration requires re-implementation', 'severity': 'High', 'impact': 'High', 'mitigation': 'Engage security team early; plan WebGate upgrades'})
    
    # Add default risk if none found
    if not risks:
        risks.append({'id': 'R00', 'category': 'General', 'risk': 'Standard upgrade considerations apply', 'severity': 'Low', 'impact': 'Low', 'mitigation': 'Follow Oracle best practices'})
    
    return risks

def generate_sizing_analytics(db_params, active_users, opp_data, forms_data):
    cpu_count = 8 # Default minimum
    for row in db_params:
        if row[0].lower() == 'cpu_count' and row[1].isdigit():
            cpu_count = int(row[1])
            break
            
    # Calculate recommended Weblogic OAF Managed Servers (assume 1 server per 200 users, min 2)
    users = safe_int(active_users, 500)
    wls_servers = max(users // 200, 2)
    if users < 100: wls_servers = 1
    
    # Calculate Custom Forms 
    forms_sessions = safe_int(forms_data[0][0] if forms_data else '50', 50)
    forms_servers = max(forms_sessions // 150, 1)

    # Calculate OPP
    opp_target = safe_int(opp_data[0][0] if opp_data else '1', 1)
    opp_memory = max(opp_target * 2, 2) # 2 GB per OPP JVM usually
    
    # Database Memory
    db_mem = 16 # Default GB
    for row in db_params:
        if row and len(row) >= 2 and 'sga' in row[0].lower():
            val = safe_int(row[1])
            if val > 0:
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
    ctx_dirs = safe_get(data, 'CTX_DIRECTORIES', [])
    ctx_ports = safe_get(data, 'CTX_PORTS_SECURITY', [])
    ctx_dbnet = safe_get(data, 'CTX_DB_NETWORKING', [])
    ctx_jvm = safe_get(data, 'CTX_JVM_SERVICES', [])
    
    db_params = safe_get(data, 'DB_PARAMETERS', [])
    
    custom_schemas_data = safe_get(data, 'EBS_CUSTOM_SCHEMAS', [])
    custom_schemas = len(custom_schemas_data) if custom_schemas_data and custom_schemas_data[0][0] != 'N/A' else 0
    
    custom_objs_data = safe_get(data, 'EBS_CUSTOM_OBJECTS', [])
    custom_objs = len(custom_objs_data) if custom_objs_data and custom_objs_data[0][0] != 'N/A' else 0
    
    nodes = safe_get(data, 'EBS_NODES', [])
    profiles = safe_get(data, 'EBS_INTEGRATIONS_PROFILES', [])
    apex_ords_info = safe_get(data, 'EBS_APEX_ORDS_VERSION', [])
    integrations = determine_integrations(profiles, apex_ords_info)
    rules_challenges = run_prebuilt_rules(db_version_info[1] if len(db_version_info)>1 else '', ebs_version, db_params, os_info, db_size, data)
    
    # Process New Extracts
    invalid_objs_list = safe_get(data, 'DBA_INVALID_OBJECTS_LIST', [])
    db_links_list = safe_get(data, 'DBA_DB_LINKS', [])
    db_links = len(db_links_list) if db_links_list and db_links_list[0][0] != 'N/A' else 0
    directories = safe_get(data, 'DBA_DIRECTORIES', [['0']])[0][0]

    # Process RAC Database Information
    rac_status = safe_get(data, 'RAC_STATUS', [])
    rac_instances = safe_get(data, 'RAC_INSTANCES', [])
    rac_instance_params = safe_get(data, 'RAC_INSTANCE_PARAMETERS', [])
    rac_interconnect = safe_get(data, 'RAC_INTERCONNECT', [])
    rac_services = safe_get(data, 'RAC_SERVICES', [])
    rac_database_info = safe_get(data, 'RAC_DATABASE_INFO', [])
    rac_asm_diskgroups = safe_get(data, 'RAC_ASM_DISKGROUPS', [])
    rac_gv_sysstat = safe_get(data, 'RAC_GV_SYSSTAT', [])
    rac_thread_redo = safe_get(data, 'RAC_THREAD_REDO', [])
    rac_scan_listeners = safe_get(data, 'RAC_SCAN_LISTENERS', [])
    
    # Determine if database is RAC
    is_rac = False
    rac_instance_count = 1
    for row in rac_status:
        if len(row) >= 2 and row[0] == 'CLUSTER_DATABASE' and row[1].upper() == 'TRUE':
            is_rac = True
        if len(row) >= 2 and row[0] == 'INSTANCE_COUNT':
            try:
                rac_instance_count = int(row[1])
            except (ValueError, TypeError):
                rac_instance_count = 1

    # Process CEMLI Details
    cemli_cp = safe_get(data, 'CEMLI_CONCURRENT_PROGRAMS', [])
    
    forms_data_raw = safe_get(data, 'CEMLI_FORMS_AND_PAGES', [])
    forms_count = len(forms_data_raw) if forms_data_raw and forms_data_raw[0][0] != 'N/A' else 0
    
    oaf_data_raw = safe_get(data, 'CEMLI_OAF_PERSONALIZATIONS', [])
    oaf_count = len(oaf_data_raw) if oaf_data_raw and oaf_data_raw[0][0] != 'N/A' else 0
    
    oracle_alerts_list = safe_get(data, 'ORACLE_ALERTS_LIST', [])
    
    # Process Sizing Details
    opp_data = safe_get(data, 'OPP_SIZING', [['1', '1']])
    forms_data = safe_get(data, 'FORMS_SESSIONS', [['0']])
    sizing_analytics = generate_sizing_analytics(db_params, active_users, opp_data, forms_data)
    
    # Process New Advanced Extractions
    db_dataguard = safe_get(data, 'DB_DATAGUARD', [])
    has_dataguard = len(db_dataguard) > 0 and len(db_dataguard[0]) > 0 and db_dataguard[0][0] != 'N/A'
    db_backups = safe_get(data, 'DB_BACKUP_SUMMARY', [])
    top_10_tables = safe_get(data, 'TOP_10_TABLES', [])
    user_profiles = safe_get(data, 'DB_USER_PROFILES', [])
    role_privs = safe_get(data, 'DB_ROLE_PRIVS', [])
    dmz_nodes = safe_get(data, 'EBS_DMZ_EXTERNAL_NODES', [])
    pcp_managers = safe_get(data, 'EBS_PCP_MANAGERS', [])
    func_volumes = safe_get(data, 'EBS_FUNC_DATA_VOLUMES', [])
    
    # Process Exhaustive Mailers & Security
    workflow_mailer = safe_get(data, 'WORKFLOW_MAILER_DETAILED', [])
    smtp_profiles = safe_get(data, 'FND_SMTP_PROFILES', [])
    users_by_module = safe_get(data, 'ACTIVE_USERS_BY_MODULE', [])
    users_by_resp = safe_get(data, 'ACTIVE_USERS_BY_RESP', [])
    users_schema_connect = safe_get(data, 'EBS_USERS_SCHEMA_CONNECT', [])
    scheduled_jobs = safe_get(data, 'SCHEDULED_CONCURRENT_JOBS', [])
    db_init_params = safe_get(data, 'DB_INIT_PARAMS_FULL', [])
    
    # Process the New Deep-Dive Extractions
    db_internal_state = safe_get(data, 'DB_INTERNAL_STATE', [])
    db_feature_usage = safe_get(data, 'DB_FEATURE_USAGE', [])
    custom_fnd_objects = safe_get(data, 'CUSTOM_FND_OBJECTS', [])
    infra_objects = safe_get(data, 'INFRA_OBJECTS', [])
    workload_statistics = safe_get(data, 'WORKLOAD_STATISTICS', [])
    
    db_usage_free = safe_get(data, 'DB_SIZE_USAGE_FREE', [['0', '0']])[0]
    wf_admin_role = safe_get(data, 'WF_ADMIN_ROLE', [['SYSADMIN']])[0][0] if len(safe_get(data, 'WF_ADMIN_ROLE', [['SYSADMIN']])[0])>0 else 'SYSADMIN'
    ebs_localizations = safe_get(data, 'EBS_LOCALIZATIONS', [])
    top_50_execs = safe_get(data, 'TOP_50_CONC_PROGS_BY_EXEC', [])
    top_50_time = safe_get(data, 'TOP_50_CONC_PROGS_BY_TIME', [])
    conc_mgr_status = safe_get(data, 'CONC_MANAGER_QUEUE_STATUS', [])
    daily_conc_reqs = safe_get(data, 'DAILY_CONC_REQS_LAST_MONTH', [])
    users_created = safe_get(data, 'USERS_CREATED_MONTHLY', [])
    ebs_languages = safe_get(data, 'EBS_LANGUAGES', [])
    
    # EBS URL Profiles for recommendations
    ebs_url_profiles = safe_get(data, 'EBS_URL_PROFILES', [])
    
    # New data extractions from Original Files queries
    active_users_with_resp = safe_get(data, 'ACTIVE_USERS_WITH_RESPONSIBILITIES', [])
    applied_patches_90_days = safe_get(data, 'APPLIED_PATCHES_90_DAYS', [])
    top_100_conc_by_exec = safe_get(data, 'TOP_100_CONC_PROGS_BY_EXEC', [])
    top_100_conc_by_time = safe_get(data, 'TOP_100_CONC_PROGS_BY_AVG_TIME', [])
    
    # Flagged files for upgrade analysis
    flagged_files = safe_get(data, 'FLAGGED_FILES_FOR_UPGRADE', [])
    custom_top_files = safe_get(data, 'CUSTOM_TOP_FILES', [])
    ad_files_by_type = safe_get(data, 'AD_FILES_BY_TYPE', [])
    patched_files_recent = safe_get(data, 'PATCHED_FILES_RECENT', [])
    
    # Extract Tech Stack Versions for EBS 12.2.x environments
    tech_stack_raw = safe_get(data, 'TECH_STACK_VERSIONS', [])
    tech_stack_info = {}
    for row in tech_stack_raw:
        if len(row) >= 2 and row[0] and row[1]:
            tech_stack_info[row[0]] = row[1]
    
    # Also extract AD/TXK versions for tech stack
    ad_txk_versions = safe_get(data, 'AD_TXK_VERSIONS', [])
    for row in ad_txk_versions:
        if len(row) >= 2 and row[0] and row[1]:
            tech_stack_info[row[0]] = row[1]
    
    # CEMLI Extract: Custom Application Objects
    cemli_custom_apps = safe_get(data, 'CEMLI_CUSTOM_APPLICATIONS', [])
    cemli_custom_alerts = safe_get(data, 'CEMLI_CUSTOM_ALERTS', [])
    cemli_conc_host = safe_get(data, 'CEMLI_CONC_PROG_HOST', [])
    cemli_conc_java = safe_get(data, 'CEMLI_CONC_PROG_JAVA', [])
    cemli_conc_reports = safe_get(data, 'CEMLI_CONC_PROG_REPORTS', [])
    cemli_conc_sqlloader = safe_get(data, 'CEMLI_CONC_PROG_SQLLOADER', [])
    cemli_conc_sqlplus = safe_get(data, 'CEMLI_CONC_PROG_SQLPLUS', [])
    
    # CEMLI Extract: Custom OAF and FND Objects
    cemli_oaf_pages = safe_get(data, 'CEMLI_OAF_PAGES', [])
    cemli_oaf_personalizations = safe_get(data, 'CEMLI_OAF_PERSONALIZATIONS', [])
    cemli_lookups = safe_get(data, 'CEMLI_LOOKUPS', [])
    cemli_menus = safe_get(data, 'CEMLI_MENUS', [])
    cemli_messages = safe_get(data, 'CEMLI_MESSAGES', [])
    cemli_profiles = safe_get(data, 'CEMLI_PROFILES', [])
    cemli_request_groups = safe_get(data, 'CEMLI_REQUEST_GROUPS', [])
    cemli_request_sets = safe_get(data, 'CEMLI_REQUEST_SETS', [])
    cemli_value_sets = safe_get(data, 'CEMLI_VALUE_SETS', [])
    
    # CEMLI Extract: Custom Database Objects
    cemli_db_functions = safe_get(data, 'CEMLI_DB_FUNCTIONS', [])
    cemli_db_indexes = safe_get(data, 'CEMLI_DB_INDEXES', [])
    cemli_db_lobs = safe_get(data, 'CEMLI_DB_LOBS', [])
    cemli_db_packages = safe_get(data, 'CEMLI_DB_PACKAGES', [])
    cemli_db_procedures = safe_get(data, 'CEMLI_DB_PROCEDURES', [])
    cemli_db_sequences = safe_get(data, 'CEMLI_DB_SEQUENCES', [])
    cemli_db_synonyms = safe_get(data, 'CEMLI_DB_SYNONYMS', [])
    cemli_db_tables = safe_get(data, 'CEMLI_DB_TABLES', [])
    cemli_db_triggers = safe_get(data, 'CEMLI_DB_TRIGGERS', [])
    cemli_db_types = safe_get(data, 'CEMLI_DB_TYPES', [])
    cemli_db_views = safe_get(data, 'CEMLI_DB_VIEWS', [])
    cemli_db_mviews = safe_get(data, 'CEMLI_DB_MVIEWS', [])
    cemli_db_queues = safe_get(data, 'CEMLI_DB_QUEUES', [])
    cemli_workflows = safe_get(data, 'CEMLI_WORKFLOWS', [])
    
    # CEMLI Extract: Custom Reporting Objects
    cemli_xml_templates = safe_get(data, 'CEMLI_XML_TEMPLATES', [])
    cemli_data_definitions = safe_get(data, 'CEMLI_DATA_DEFINITIONS', [])
    
    # Data Reconciliator: Organization Structure
    data_business_groups = safe_get(data, 'DATA_BUSINESS_GROUPS', [])
    data_set_of_books = safe_get(data, 'DATA_SET_OF_BOOKS', [])
    data_legal_entities = safe_get(data, 'DATA_LEGAL_ENTITIES', [])
    data_operating_units = safe_get(data, 'DATA_OPERATING_UNITS', [])
    data_inventory_orgs = safe_get(data, 'DATA_INVENTORY_ORGS', [])
    
    # Data Reconciliator: Module Data Volumes
    data_ap_volumes = safe_get(data, 'DATA_AP_VOLUMES', [])
    data_ar_volumes = safe_get(data, 'DATA_AR_VOLUMES', [])
    data_gl_volumes = safe_get(data, 'DATA_GL_VOLUMES', [])
    data_po_volumes = safe_get(data, 'DATA_PO_VOLUMES', [])
    data_om_volumes = safe_get(data, 'DATA_OM_VOLUMES', [])
    data_inv_volumes = safe_get(data, 'DATA_INV_VOLUMES', [])
    data_hr_volumes = safe_get(data, 'DATA_HR_VOLUMES', [])
    data_fa_volumes = safe_get(data, 'DATA_FA_VOLUMES', [])
    data_cm_volumes = safe_get(data, 'DATA_CM_VOLUMES', [])
    data_opm_volumes = safe_get(data, 'DATA_OPM_VOLUMES', [])
    data_pricing_volumes = safe_get(data, 'DATA_PRICING_VOLUMES', [])
    
    # Profile and Patch Changes
    profile_changes_48h = safe_get(data, 'PROFILE_OPTIONS_CHANGED_48H', [])
    applied_patches_30d = safe_get(data, 'APPLIED_PATCHES_30_DAYS', [])
    
    # CEMLI Object Data (for drilldowns)
    custom_workflows = safe_get(data, 'CUSTOM_WORKFLOWS', [])
    xml_publisher = safe_get(data, 'XML_PUBLISHER_DELIVERY', [])
    custom_fnd = safe_get(data, 'CUSTOM_FND_OBJECTS', [])
    
    # Generate sizing analytics
    opp_data = safe_get(data, 'OPP_SIZING', [])
    forms_sessions_data = safe_get(data, 'FORMS_SESSIONS', [])
    sizing_analytics = generate_sizing_analytics(db_params, active_users, opp_data, forms_sessions_data)
    
    # Calculate Complexity
    complexity_payload = calculate_complexity_score(data, db_params, active_users, custom_objs, custom_schemas, db_size, os_info, ebs_version, profiles)
    
    # Generate Risk Register
    risk_register = generate_risk_register(data, complexity_payload, os_info, 
                                           db_version_info[1] if len(db_version_info)>1 else '', 
                                           custom_objs, db_links)
    
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
        .section-header {{ display: flex; align-items: center; border-bottom:2px solid var(--light-blue); padding-bottom:15px; margin-bottom: 25px; cursor: pointer; }}
        .section-header h2 {{ color:var(--primary-blue); margin: 0; font-size: 22px; width: 100%; }}
        .section-header::after {{ content: '▼'; font-size: 14px; color: var(--primary-blue); margin-left: auto; transition: transform 0.3s; }}
        .section.collapsed .section-header::after {{ transform: rotate(-90deg); }}
        .section.collapsed .section-content {{ display: none; }}
        
        details {{ background-color: #F8FAFC; border: 1px solid var(--border-grey); padding: 10px 15px; border-radius: 6px; margin-top: 15px; cursor: pointer; transition: all 0.2s; }}
        details:hover {{ border-color: #cbd5e1; }}
        summary {{ font-weight: 600; color: var(--primary-blue); font-size: 15px; outline: none; display: flex; align-items: center; }}
        details[open] summary {{ border-bottom: 1px solid var(--border-grey); padding-bottom: 10px; margin-bottom: 10px; }}
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
        <a href="#topology">4. Physical Architecture</a>
        <a href="#database">5. Database Configurations</a>
        <a href="#wls_sizing">6. Application Configurations</a>
        <a href="#integrations">7. Enterprise Integrations</a>
        <a href="#concurrent">8. Concurrent Programs</a>
        <a href="#workload">9. Admin Specific</a>
        <a href="#cemli">10. CEMLI / Customizations</a>
        <a href="#functional">11. Functional Data Volumes</a>
        <a href="#urlprofiles">12. URL Profiles & Endpoints</a>
        <a href="#workflow">13. Workflow & Middleware</a>
        <a href="#risks">14. Risk Register</a>
    </div>

    <a href="#" id="backToTop" title="Back to Top" style="display:none; position:fixed; bottom:30px; right:30px; background:var(--primary-blue); color:white; padding:15px; border-radius:50%; text-decoration:none; font-weight:bold; z-index:999; box-shadow:0 4px 10px rgba(0,0,0,0.2);">↑</a>

    <div class="main-content">
        <!-- Dashboard Summary -->
        <div id="executive" class="section" style="padding: 0; background: transparent; box-shadow: none; border: none; margin-bottom: 20px;">
            
            <div class="c-engine-section">
                <div class="c-engine-left">
                    <h2 style="margin:0 0 10px 0; font-size: 24px; color: #F8FAFC;">AI Upgrade Complexity Engine</h2>
                    <p style="margin:0; color:#94A3B8; font-size:15px; max-width: 600px;">The assessment engine processed {len(data.keys())} configuration metrics to mathematically compute the complexity of this transition to Oracle EBS 12.2 / 19c.</p>
                    
                    <div class="cd-bars">
                        {''.join(f'''<div class="cd-row">
                            <div class="cd-label">{k}</div>
                            <div class="cd-track"><div class="cd-fill" style="width: {(v/5)*100}%; background: {'#10B981' if v<=2 else '#F59E0B' if v==3 else '#EF4444'};"></div></div>
                            <div class="cd-val">{v}/5</div>
                        </div>''' for k, v in complexity_payload['factors'].items())}
                    </div>
                </div>
                <div class="c-engine-right">
                    <div style="font-size: 13px; color: #94A3B8; text-transform: uppercase; font-weight: 700; letter-spacing: 1px;">Complexity Score</div>
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
            <p>A structured approach is required transitioning your <code>{ebs_version}</code> architecture (Database {db_version_info[1] if len(db_version_info)>1 else 'Unknown'}). The typical critical path for a full DB and App tier replacement on Oracle Linux 8/9 involves multiple phases.</p>
            {build_roadmap(ebs_version, db_version_info[1] if len(db_version_info)>1 else '', is_rac, has_dataguard, tech_stack_info)}
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

            <h3>Concurrent Program Technical Debt</h3>
            <p style="color:red; font-size:13px; font-weight:600; margin-top:0;">&#9888; Action Required: All 'Java' and 'Spawned' (C/C++) executables must be recompiled on the target OS. See <a href="#concurrent">Concurrent Programs & Requests</a> section for full details.</p>
            {render_drilldown_table("Custom Concurrent Programs List", cemli_cp, ["Application Module", "Program Name", "Executable Name", "Execution Method"])}
            
            <h3>Forms & OAF Modifications</h3>
            {render_drilldown_table("Custom Oracle Forms (fmb)", safe_get(data, 'CEMLI_FORMS_AND_PAGES', []), ["Application Module", "Form Name", "User Form Name"])}
            
            <h3>Custom OAF Pages</h3>
            <p style="font-size:13px; color:#475569;">Custom OAF pages with controller classes and AM definitions. These require JDeveloper recompilation for EBS 12.2.</p>
            {render_drilldown_table("Custom OAF Page Components", cemli_oaf_pages, ["Page Name", "Full Path", "Attribute Name", "Attribute Value"])}
            
            <h3>OAF Personalizations / Customizations</h3>
            <p style="font-size:13px; color:#475569;">MDS-based personalizations applied to standard OAF pages. These must be validated post-upgrade.</p>
            {render_drilldown_table("OAF Personalizations", cemli_oaf_personalizations, ["Document Name", "Full Path", "Last Update Date"])}

            <h3>Custom FND Objects (Detailed)</h3>
            <p style="font-size:13px; color:#475569;">Comprehensive breakdown of custom FND objects by type with application ownership.</p>
            
            {render_drilldown_table("Custom Lookups", cemli_lookups, ["App ID", "Lookup Type", "Application Name", "Meaning"])}
            {render_drilldown_table("Custom Menus", cemli_menus, ["Menu ID", "Menu Name", "User Menu Name", "Application Name"])}
            {render_drilldown_table("Custom Messages", cemli_messages, ["App ID", "Message Name", "Application Name", "Message Text"])}
            {render_drilldown_table("Custom Profiles", cemli_profiles, ["Profile ID", "Profile Name", "User Profile Name", "Application Name"])}
            {render_drilldown_table("Custom Request Groups", cemli_request_groups, ["Group ID", "Group Name", "Application Name", "Description"])}
            {render_drilldown_table("Custom Request Sets", cemli_request_sets, ["Set ID", "Set Name", "User Set Name", "Application Name"])}
            {render_drilldown_table("Custom Value Sets", cemli_value_sets, ["Value Set ID", "Value Set Name", "Description", "Validation Type"])}

            <h3>Other Customized Core Components</h3>
            {render_drilldown_table("Custom Workflow Definitions", custom_workflows, ["Item Type", "Display Name"])}
            {render_drilldown_table("BIP / XML Publisher Templates", xml_publisher, ["XML Template Code", "Output Type"])}
            
            <h3>Flagged Files for Upgrade Analysis</h3>
            <p style="font-size:13px; color:#475569;">Custom files tracked in AD schema that require review and potential remediation during upgrade. These include XX-prefixed files and files in custom directories.</p>
            {render_drilldown_table("View Flagged Custom Files (AD_FILES)", flagged_files, ["Application", "Directory", "Filename", "Version", "Translation Level", "Version Date"])}
            
            <h3>Custom Application Tops</h3>
            <p style="font-size:13px; color:#475569;">Registered custom APPL_TOP directories that may contain custom code requiring migration.</p>
            {render_table(custom_top_files, ["APPL_TOP Name", "Base Path", "Applications System"])}
            
            <h3>Custom Files Distribution by Type</h3>
            <p style="font-size:13px; color:#475569;">Breakdown of custom file extensions to identify file types requiring specific remediation (e.g., .fmb, .pll, .class, .java).</p>
            {render_table(ad_files_by_type, ["File Extension", "Count"])}
            
            <h3>Recently Patched Files (Last 90 Days)</h3>
            <p style="font-size:13px; color:#475569;">Files modified by recent patches that may impact custom code dependencies.</p>
            {render_drilldown_table("View Recently Patched Files", patched_files_recent, ["Application", "Filename", "Patch Name", "Applied Date"])}
            
            <h3>CEMLI: Custom Applications</h3>
            <p style="font-size:13px; color:#475569;">Registered custom applications in FND_APPLICATION that require migration.</p>
            {render_drilldown_table("View Custom Applications", cemli_custom_apps, ["App ID", "Application Name", "Short Name", "Base Path", "Created Date"])}
            
            <h3>CEMLI: Custom Alerts</h3>
            {render_drilldown_table("View Custom Alerts", cemli_custom_alerts, ["Alert Name", "Application Name", "Alert Type", "Status"])}
            
            <h3>CEMLI: Custom Database Objects</h3>
            <p style="font-size:13px; color:#475569;">Custom database objects (XX-prefixed or in custom schemas) that require EBR enablement and validation.</p>
            {render_drilldown_table("Custom Functions", cemli_db_functions, ["Object Name", "Type", "Owner", "Status", "Created", "Last DDL"])}
            {render_drilldown_table("Custom Packages", cemli_db_packages, ["Object Name", "Type", "Owner", "Status", "Created", "Last DDL"])}
            {render_drilldown_table("Custom Procedures", cemli_db_procedures, ["Object Name", "Type", "Owner", "Status", "Created", "Last DDL"])}
            {render_drilldown_table("Custom Tables", cemli_db_tables, ["Table Name", "Owner", "Tablespace", "Num Rows", "Partitioned", "Created"])}
            {render_drilldown_table("Custom Views", cemli_db_views, ["View Name", "Owner", "Status", "Created", "Last DDL"])}
            {render_drilldown_table("Custom Indexes", cemli_db_indexes, ["Index Name", "Type", "Owner", "Status", "Table Name", "Uniqueness"])}
            {render_drilldown_table("Custom Sequences", cemli_db_sequences, ["Sequence Name", "Owner", "Min Value", "Max Value", "Increment", "Last Number"])}
            {render_drilldown_table("Custom Synonyms", cemli_db_synonyms, ["Synonym Name", "Owner", "Table Owner", "Table Name", "DB Link"])}
            {render_drilldown_table("Custom Triggers", cemli_db_triggers, ["Trigger Name", "Owner", "Table Owner", "Table Name", "Event", "Status"])}
            {render_drilldown_table("Custom Types", cemli_db_types, ["Object Name", "Type", "Owner", "Status", "Created", "Last DDL"])}
            {render_drilldown_table("Custom Materialized Views", cemli_db_mviews, ["MView Name", "Owner", "Container", "Refresh Mode", "Refresh Method", "Staleness"])}
            {render_drilldown_table("Custom Queues", cemli_db_queues, ["Queue Name", "Owner", "Queue Table", "Type", "Enqueue", "Dequeue"])}
            {render_drilldown_table("Custom LOB Segments", cemli_db_lobs, ["Table Name", "Column Name", "Owner", "Segment Name", "Tablespace", "Chunk Size"])}
            
            <h3>CEMLI: Custom Workflows</h3>
            <p style="font-size:13px; color:#475569;">Custom workflow item types and processes requiring validation post-upgrade.</p>
            {render_drilldown_table("Custom Workflow Definitions", cemli_workflows, ["Item Type", "Display Name", "Persistence Type", "Persistence Days", "Activity Count"])}
            
            <h3>CEMLI: Custom Reporting Objects (XML Publisher / BI Publisher)</h3>
            <p style="font-size:13px; color:#475569;">Custom XML/BI Publisher templates and data definitions requiring migration and testing.</p>
            {render_drilldown_table("XML Publisher Templates", cemli_xml_templates, ["App ID", "Template Code", "Template Name", "Description", "Application", "Type", "Status"])}
            {render_drilldown_table("Data Definitions", cemli_data_definitions, ["App ID", "Data Source Code", "Data Source Name", "Description", "Application", "Status", "Created"])}
        </div>

        <div id="topology" class="section">
            <div class="section-header">
                <h2>Physical Topology & Contexts</h2>
            </div>
            
            <h3>Application Node Definitions</h3>
            {render_table(nodes, ["Registrar Hostname", "Batch/Concurrent", "Forms Service", "Web Service", "Data Node", "Current State"])}
            
        </div>

        <div id="infra" class="section">
            <div class="section-header">
                <h2>Infrastructure Component Counts</h2>
            </div>
            {render_drilldown_table("Scheduler Jobs, Materialized Views & Partitions", safe_get(data, 'INFRA_OBJECTS', []), ["Infrastructure Component", "Definition Count"])}
        </div>
        
        <div id="wls_sizing" class="section">
            <div class="section-header">
                <h2>WLS Architecture Sizing & Java Context Parameters</h2>
            </div>
            <p>Target WebLogic domain deployment footprint extracted deeply from FND_OAM_CONTEXT_FILES across all nodes.</p>
            
            <h3>Application File Systems (Mount Directories)</h3>
            {render_table(ctx_dirs, ["Physical Node", "EBS File System Variable", "Target Mount / Path Location"])}
            
            <h3>Target JVM Services & Memory Allocations</h3>
            <p style="font-size:13px; color:#475569;">Metrics necessary to calculate required Managed Servers and Heap Sizing per Node (oacore, forms, oafm).</p>
            {render_table(ctx_jvm, ["Physical Node", "WebLogic / Form Server Service", "Allocated NPROCS (Processes)", "Java JVM Start Parameters Options"])}
            
            <h3>Ports, Keystores & Security Connectors</h3>
            {render_table(ctx_ports, ["Physical Node", "Configuration Property Name", "Value Resolved"])}
            
            <h3>Database Networking & JDBC Profiles</h3>
            {render_table(ctx_dbnet, ["Physical Node", "Network Property Name", "JDBC Description or URL Profile"])}
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

        <div id="urlprofiles" class="section">
            <div class="section-header">
                <h2>URL Profiles & Endpoints</h2>
            </div>
            <p>Critical URL profiles that define how users and integrations connect to the EBS application. These must be updated during upgrade and SSL/TLS configuration changes.</p>
            
            <h3>EBS URL Configuration Profiles</h3>
            <p style="font-size:13px; color:#475569;">These site-level profile values control application URLs, authentication endpoints, and integration service locations. Review and update these profiles post-upgrade.</p>
            {render_url_profiles_table(ebs_url_profiles)}
        </div>

        <div id="concurrent" class="section">
            <div class="section-header">
                <h2>Concurrent Programs & Requests</h2>
            </div>
            <p>Comprehensive analysis of concurrent processing workloads, custom concurrent programs, and execution patterns critical for upgrade planning.</p>
            
            <h3>Custom Concurrent Programs</h3>
            <p style="font-size:13px; color:#475569;">Custom concurrent programs registered under custom applications (application_id >= 20000) or with XX% naming convention. These require testing and potential remediation during upgrade.</p>
            {render_drilldown_table("View Custom Concurrent Programs", cemli_cp, ["Application", "Program Name", "Executable Name", "Execution Method"])}
            
            <h3>CEMLI: Concurrent Programs by Execution Type</h3>
            <div class="grid-summary">
                <div class="metric-card" style="border-left-color: var(--warning-amber)">
                    <div class="metric-title">Host Programs</div>
                    <div class="metric-value">{len(cemli_conc_host) if cemli_conc_host and cemli_conc_host[0][0] != 'N/A' else 0}</div>
                    <div style="font-size:13px; color:#64748b;">Shell script executables</div>
                </div>
                <div class="metric-card" style="border-left-color: var(--primary-blue)">
                    <div class="metric-title">Java Concurrent</div>
                    <div class="metric-value">{len(cemli_conc_java) if cemli_conc_java and cemli_conc_java[0][0] != 'N/A' else 0}</div>
                    <div style="font-size:13px; color:#64748b;">Java stored procedures</div>
                </div>
                <div class="metric-card" style="border-left-color: var(--danger-red)">
                    <div class="metric-title">Oracle Reports</div>
                    <div class="metric-value">{len(cemli_conc_reports) if cemli_conc_reports and cemli_conc_reports[0][0] != 'N/A' else 0}</div>
                    <div style="font-size:13px; color:#64748b;">Reports executables - CRITICAL</div>
                </div>
                <div class="metric-card" style="border-left-color: var(--success-green)">
                    <div class="metric-title">SQL*Plus Programs</div>
                    <div class="metric-value">{len(cemli_conc_sqlplus) if cemli_conc_sqlplus and cemli_conc_sqlplus[0][0] != 'N/A' else 0}</div>
                    <div style="font-size:13px; color:#64748b;">SQL*Plus scripts</div>
                </div>
            </div>
            
            {render_drilldown_table("Host Programs Detail", cemli_conc_host, ["Application", "Program Name", "Executable", "Description"])}
            {render_drilldown_table("Oracle Reports Detail", cemli_conc_reports, ["Application", "Program Name", "Executable", "Description"])}
            {render_drilldown_table("SQL*Loader Programs Detail", cemli_conc_sqlloader, ["Application", "Program Name", "Executable", "Description"])}
            
            <h3>Concurrent Manager Queue Status</h3>
            <p style="font-size:13px; color:#475569;">Current state of concurrent manager queues showing processing capacity and workload distribution.</p>
            {render_table(conc_mgr_status, ["Queue ID", "Short Name", "Manager Name", "Target Node", "Max Allowed", "Running", "Run Tasks", "Pending Tasks", "Control State"])}
            
            <h3>Daily Concurrent Request Volume (30 Days)</h3>
            <p style="font-size:13px; color:#475569;">Daily concurrent request counts showing workload patterns for capacity planning.</p>
            {render_table(daily_conc_reqs, ["Execution Date", "Total Request Count"])}
            
            <h3>Top 100 Concurrent Programs by Execution Count (30 Days)</h3>
            <p style="font-size:13px; color:#475569;">Most frequently executed programs - prioritize these for upgrade testing.</p>
            {render_drilldown_table("View Top 100 by Execution", top_100_conc_by_exec, ["Program Name", "Total Executions"])}
            
            <h3>Top 100 Concurrent Programs by Average Run Time</h3>
            <p style="font-size:13px; color:#475569;">Longest running programs - monitor for performance regression after upgrade.</p>
            {render_drilldown_table("View Top 100 by Run Time", top_100_conc_by_time, ["Program Name", "Executions", "Avg Hours", "Max Hours", "Min Hours"])}
            
            <h3>Scheduled Concurrent Jobs</h3>
            <p style="font-size:13px; color:#475569;">Currently scheduled jobs that will need validation post-upgrade.</p>
            {render_drilldown_table("View Scheduled Jobs", scheduled_jobs, ["Request ID", "Parent ID", "Program Name", "Status", "Phase", "Schedule Type"])}
        </div>

        <div id="database" class="section">
            <div class="section-header">
                <h2>Database Deep-Dive Analysis</h2>
            </div>
            <p>Comprehensive database analysis including character set, tablespace distribution, and database features usage.</p>
            
            <h3>RAC (Real Application Clusters) Configuration</h3>
            <div class="grid-summary">
                <div class="metric-card" style="border-left-color: {'var(--primary-blue)' if is_rac else 'var(--success-green)'}">
                    <div class="metric-title">Cluster Database</div>
                    <div class="metric-value">{'RAC' if is_rac else 'Single Instance'}</div>
                    <div style="font-size:13px; color:#64748b;">{'Multi-node cluster deployment' if is_rac else 'Standard single-node database'}</div>
                </div>
                <div class="metric-card" style="border-left-color: var(--primary-blue)">
                    <div class="metric-title">Instance Count</div>
                    <div class="metric-value">{rac_instance_count}</div>
                    <div style="font-size:13px; color:#64748b;">{'Active RAC instances' if is_rac else 'Database instance'}</div>
                </div>
            </div>
    """
    
    # Add RAC-specific sections if it's a RAC database
    if is_rac:
        html += f"""
            <h3>RAC Instance Details</h3>
            <p style="font-size:13px; color:#475569;">Details of all RAC instances including host, version, status, and startup time.</p>
            {render_table(rac_instances, ["Instance ID", "Instance Name", "Host Name", "Version", "Status", "Startup Time", "DB Status", "Instance Role"])}
            
            <h3>RAC Database Information</h3>
            {render_table(rac_database_info, ["Property", "Value"])}
            
            <h3>RAC Instance Parameters</h3>
            <p style="font-size:13px; color:#475569;">Critical init parameters per RAC instance. Parameters like SGA, PGA, and undo tablespace may differ between instances.</p>
            {render_drilldown_table("View RAC Instance Parameters", rac_instance_params, ["Instance ID", "Parameter Name", "Value", "Is Default"])}
            
            <h3>Cluster Interconnect Configuration</h3>
            <p style="font-size:13px; color:#475569;">Private interconnect network used for cache fusion and inter-instance communication.</p>
            {render_table(rac_interconnect, ["Instance ID", "Interface Name", "IP Address", "Is Public", "Source"])}
            
            <h3>RAC Services</h3>
            <p style="font-size:13px; color:#475569;">Database services configured for workload management and failover.</p>
            {render_drilldown_table("View RAC Services", rac_services, ["Instance ID", "Service Name", "Network Name", "Enabled", "AQ HA Notifications", "CLB Goal", "Goal"])}
            
            <h3>SCAN & Local Listeners</h3>
            {render_table(rac_scan_listeners, ["Listener Type", "Configuration"])}
            
            <h3>ASM Disk Groups</h3>
            <p style="font-size:13px; color:#475569;">Automatic Storage Management disk groups used for database storage.</p>
            {render_table(rac_asm_diskgroups, ["Disk Group Name", "State", "Type", "Total MB", "Free MB", "% Free"])}
            
            <h3>RAC Redo Log Threads</h3>
            <p style="font-size:13px; color:#475569;">Redo log groups by thread - each RAC instance has its own redo thread.</p>
            {render_table(rac_thread_redo, ["Thread #", "Group #", "Members", "Size (MB)", "Status", "Archived"])}
            
            <h3>Global Cache Statistics</h3>
            <p style="font-size:13px; color:#475569;">Cache fusion statistics for inter-instance block transfers. High values indicate active inter-node communication.</p>
            {render_drilldown_table("View Global Cache Statistics", rac_gv_sysstat, ["Instance ID", "Statistic Name", "Value"])}
        """
    
    html += f"""
            <h3>Database Character Set & NLS Configuration</h3>
            {render_table(safe_get(data, 'DB_CHARACTER_SET', []), ["NLS Parameter", "Current Value"])}
            
            <h3>Tablespace Distribution (GB)</h3>
            {render_table(safe_get(data, 'DB_TABLESPACES', []), ["Tablespace Name", "Size (GB)", "Status"])}
            
            <h3>Redo Log Configuration</h3>
            {render_table(safe_get(data, 'DB_REDO_LOGS', []), ["Group #", "Members", "Size (MB)", "Status"])}
            
            <h3>Archive Mode & Logging</h3>
            {render_table(safe_get(data, 'DB_ARCHIVE_MODE', []), ["Log Mode", "Force Logging", "Supplemental Log"])}
            
            <h3>Total EBS Customization Catalog</h3>
            {render_drilldown_table("View Core Custom Database Extensions", safe_get(data, 'EBS_CUSTOM_OBJECTS', []), ["Custom Schema Owner", "Database Object Type", "Quantity Defined"])}
            
            <h3>Invalid Objects by Owner/Type</h3>
            {render_drilldown_table("View Invalid Schema Objects", safe_get(data, 'INVALID_OBJECTS_DETAIL', []), ["Schema Owner", "Object Name", "Object Type", "Status", "Last DDL Timestamp"])}
            
            <h3>Custom AD Registered Schemas</h3>
            <p style="font-size:13px; color:#475569;">Custom schemas (XX*, CUSTOM*) registered with Oracle AD utilities. These must be properly registered for online patching compatibility.</p>
            {render_table(safe_get(data, 'AD_REGISTERED_SCHEMAS', []), ["Schema Name", "Read Only"])}
            
            <h3>Recently Applied Patches (Last 180 Days)</h3>
            {render_table(safe_get(data, 'AD_APPLIED_PATCHES_RECENT', []), ["Patch Name", "Patch Type", "Applied Date"])}
            
            <h3>Applied Patches (Last 90 Days - Detailed)</h3>
            <p style="font-size:13px; color:#475569;">Comprehensive patch application history extracted from AD schema for recent upgrade activity tracking.</p>
            {render_drilldown_table("View Applied Patches in Last 90 Days", applied_patches_90_days, ["Patch Name", "Last Update Date", "Applied Flag"])}
            
            <h3>Database Links Detail</h3>
            {render_table(safe_get(data, 'DB_LINKS_DETAIL', []), ["Owner", "DB Link Name", "Host"])}
        </div>

        <div id="workload" class="section">
            <div class="section-header">
                <h2>Database Workloads, High Availability & Process Engineering</h2>
            </div>
            
            <h3>PCP (Parallel Concurrent Processing) Distribution</h3>
            {render_table(pcp_managers, ["Queue Routing ID", "Primary Node", "Failover Node"])}
            
            <h3>Top 10 Heaviest Database Segments</h3>
            <p style="font-size:13px; color:#475569;">Storage engineering constraints for tablespace reorganizations.</p>
            {render_table(top_10_tables, ["Database Object Segment", "Segment Type", "Consuming Space (GB)"])}
            
            <h3>Disaster Recovery (Data Guard) Topology</h3>
            {render_table(db_dataguard, ["Archive Dest Name", "Status", "Instance Type", "Remote Address"])}
            
            <h3>Database Internal Configuration Limits</h3>
            {render_table(db_internal_state, ["Internal Architecture Component", "Value limit"])}

            <h3>RMAN Backup Throughput (7 Days)</h3>
            {render_table(db_backups, ["Backup Job Status", "Completion Timestamp", "Output Bytes (GB)"])}
            
            <h3>Oracle Database Enterprise Feature Licensing</h3>
            <p style="font-size:13px; color:#475569;">Flags what native engine plugins are enabled for accurate cloud commercial modeling (e.g. Partitioning, Advanced Compression).</p>
            {render_table(db_feature_usage, ["Feature Module Name", "Active", "First Seen", "Last Known Poll"])}

            <h3>Infrastructure Engine Design</h3>
            <p style="font-size:13px; color:#475569;">Scheduler objects that require careful handling during OS migration and upgrades.</p>
            {render_table(infra_objects, ["Object Classification", "Volumes Configured"])}

            <h3>System Workloads & Footprints</h3>
            {render_table(workload_statistics, ["Performance Category", "Count Output"])}

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
            """
    
    # Use ctx_dirs to build techstack information
    if len(ctx_dirs) > 0 and ctx_dirs[0][0] != 'N/A':
        html += render_table(ctx_dirs, ["Physical Node", "Configuration Property", "Deployment Path / Value"])
    else:
        html += "<p style='color:#777; font-size:14px; font-style:italic;'>TechStack Context not available in Registry.</p>"
        
    html += f"""
            
            <h3>File-System Rogue Customizations (OS `find` extraction)</h3>
            <p style="font-size:13px; color:#475569;">Includes unmanaged `b64` web logic, rogue custom images missing personalization hooks, and manually dropped `.class` payloads in `$JAVA_TOP` missing standards.</p>
            {render_table(safe_get(data, 'APP_CUSTOM_FILES', []), ["File Search Target", "Discovered Quantity"])}
            
            <h3>Database User Password Enforcement (Profiles)</h3>
            {render_table(user_profiles, ["Assigned Profile", "Resource Enforcement", "Boundary"])}
            
            <h3>Database 'APPS' Foundation Privileges</h3>
            {render_table(role_privs, ["Target Account", "Authorized Oracle Role", "Admin Option"])}
            
            <h3>DMZ (External Node) Trust Modeling</h3>
            <p style="font-size:13px; color:#475569;">Validates whether Internet-facing web servers have appropriate NODE_TRUST_LEVEL limitations mapped against restricted responsibilities (e.g. iSupplier, iRecruitment).</p>
            {render_table(dmz_nodes, ["Profile Security Output", "FND System Profile Target", "Physical Node / Responsibility Resolved"])}
        </div>
        
        <div id="workflow" class="section">
            <div class="section-header">
                <h2>Oracle Workflow & Output Delivery Integrations</h2>
            </div>
            <p>Critical business transaction flows often stall during upgrades if SMTP/IMAP connections or XML generation templates fail on new Java Virtual Machines.</p>
            
            <div style="margin:20px 0; padding:15px; background:#F8FAFC; border-left:4px solid var(--primary-blue);">
                <b>Workflow Administrator Role Configuration:</b> <code>{wf_admin_role}</code>
            </div>

            <h3>Notification Mailer & Network Parameters</h3>
            {render_table(safe_get(data, 'WORKFLOW_MAILER', []), ["Component Parameter", "Network Binding"])}
            
            <h3>Custom EBS Workflow Item Types</h3>
            {render_table(safe_get(data, 'CUSTOM_WORKFLOWS', []), ["Workflow Item Type", "Deplolyment Scope"])}

            <h3>XML Publisher (XDO) Template Demands</h3>
            {render_table(safe_get(data, 'XML_PUBLISHER_DELIVERY', []), ["Engine", "Delivery Format", "Document Volumes"])}
        </div>
        
        <div id="functional" class="section">
            <div class="section-header">
                <h2>Functional Application Data Footprint (Volume Syncing)</h2>
            </div>
            <p>Master configuration and Active Transaction scaling sizes mapping Purchasing, HR, GL, Projects, Payables, and Receivables activity.</p>
            
            {render_table(func_volumes, ["Information Tier", "EBS Module", "Functional Object / Document", "Total Deployed Storage", "Open Transactions"])}
            
            <h3>Global Setup: System Languages</h3>
            {render_table(ebs_languages, ["Oracle Language", "Language Tag Code", "Installation Mode"])}
            
            <h3>Global Setup: Active Localizations</h3>
            {render_table(ebs_localizations, ["Short Name", "Regional Extension", "Activation State"])}
            
            <h3>User Base Trajectory (Created Per Month)</h3>
            {render_table(users_created, ["Account Creation Month", "Volume Generated"])}
            
            <h3>Active Users with Responsibilities</h3>
            <p style="font-size:13px; color:#475569;">Mapping of active users to their assigned responsibilities for security and access control analysis during upgrade.</p>
            {render_drilldown_table("View Active Users with Responsibilities (up to 1000)", active_users_with_resp, ["User Name", "Responsibility Name"])}
            
            <h3>Organization Structure: Business Groups</h3>
            {render_table(data_business_groups, ["Business Group Name", "Org ID", "Date From", "Date To", "Legislation Code", "Currency Code"])}
            
            <h3>Organization Structure: Set of Books / Ledgers</h3>
            {render_table(data_set_of_books, ["SOB ID", "Name", "Short Name", "Currency Code", "Period Type", "Latest Opened Period", "Currency Name"])}
            
            <h3>Organization Structure: Legal Entities</h3>
            {render_table(data_legal_entities, ["LE ID", "Legal Entity Name", "LE Identifier", "Country", "Address", "Effective From", "Effective To"])}
            
            <h3>Organization Structure: Operating Units</h3>
            {render_table(data_operating_units, ["Org ID", "Operating Unit Name", "Short Code", "Business Group", "Date From", "Date To"])}
            
            <h3>Organization Structure: Inventory Organizations</h3>
            {render_table(data_inventory_orgs, ["Org ID", "Org Code", "Organization Name", "Operating Unit", "Master Org ID", "Status"])}
            
            <h3>Module Data Volumes: Payables (AP)</h3>
            {render_table(data_ap_volumes, ["AP Object", "Record Count"])}
            
            <h3>Module Data Volumes: Receivables (AR)</h3>
            {render_table(data_ar_volumes, ["AR Object", "Record Count"])}
            
            <h3>Module Data Volumes: General Ledger (GL)</h3>
            {render_table(data_gl_volumes, ["GL Object", "Record Count"])}
            
            <h3>Module Data Volumes: Purchasing (PO)</h3>
            {render_table(data_po_volumes, ["PO Object", "Record Count"])}
            
            <h3>Module Data Volumes: Order Management (OM)</h3>
            {render_table(data_om_volumes, ["OM Object", "Record Count"])}
            
            <h3>Module Data Volumes: Inventory (INV)</h3>
            {render_table(data_inv_volumes, ["INV Object", "Record Count"])}
            
            <h3>Module Data Volumes: Human Resources (HR)</h3>
            {render_table(data_hr_volumes, ["HR Object", "Record Count"])}
            
            <h3>Module Data Volumes: Fixed Assets (FA)</h3>
            {render_table(data_fa_volumes, ["FA Object", "Record Count"])}
            
            <h3>Module Data Volumes: Cost Management (CM)</h3>
            {render_table(data_cm_volumes, ["CM Object", "Record Count"])}
            
            <h3>Module Data Volumes: Process Manufacturing (OPM)</h3>
            {render_table(data_opm_volumes, ["OPM Object", "Record Count"])}
            
            <h3>Module Data Volumes: Pricing (QP)</h3>
            {render_table(data_pricing_volumes, ["Pricing Object", "Record Count"])}
            
            <h3>Profile Options Changed (Last 48 Hours)</h3>
            <p style="font-size:13px; color:#475569;">Recent profile option changes that may indicate active configuration or troubleshooting activities.</p>
            {render_drilldown_table("View Profile Changes", profile_changes_48h, ["Profile Name", "User Profile Name", "Level", "Value", "Changed At", "Changed By"])}
            
            <h3>Applied Patches (Last 30 Days)</h3>
            <p style="font-size:13px; color:#475569;">Recent patch application history for tracking upgrade and maintenance activities.</p>
            {render_drilldown_table("View Applied Patches", applied_patches_30d, ["Patch Name", "Patch Type", "Applied Date", "Applied Flag"])}
        </div>

        <div id="risks" class="section">
            <div class="section-header">
                <h2>Risk Register & Mitigation Plan</h2>
            </div>
            <p>Based on the automated analysis, the following risks have been identified that may impact the upgrade project timeline or success.</p>
            
            <table>
                <thead>
                    <tr>
                        <th>Risk ID</th>
                        <th>Category</th>
                        <th>Risk Description</th>
                        <th>Severity</th>
                        <th>Business Impact</th>
                        <th>Mitigation Strategy</th>
                    </tr>
                </thead>
                <tbody>
                    {''.join(f'''<tr>
                        <td><b>{{r['id']}}</b></td>
                        <td>{{r['category']}}</td>
                        <td>{{r['risk']}}</td>
                        <td><span style="padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600; background: {'#FEE2E2' if r['severity']=='Critical' else '#FEF3C7' if r['severity']=='High' else '#DBEAFE' if r['severity']=='Medium' else '#D1FAE5'}; color: {'#991B1B' if r['severity']=='Critical' else '#92400E' if r['severity']=='High' else '#1E40AF' if r['severity']=='Medium' else '#065F46'};">{{r['severity']}}</span></td>
                        <td>{{r['impact']}}</td>
                        <td>{{r['mitigation']}}</td>
                    </tr>''' for r in risk_register)}
                </tbody>
            </table>
            
            <h3 style="margin-top: 30px;">Recommended Actions Before Upgrade</h3>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin-top: 15px;">
                <div style="background: #F0FDF4; border: 1px solid #86EFAC; padding: 15px; border-radius: 8px;">
                    <b style="color: #166534;">✓ Pre-Upgrade Preparation</b>
                    <ul style="margin: 10px 0 0 0; padding-left: 20px; color: #166534; font-size: 14px;">
                        <li>Run Oracle EBS Upgrade Analyzer (RUP)</li>
                        <li>Run Database Upgrade Analyzer for 19c</li>
                        <li>Generate ETCC compliance report</li>
                        <li>Document all custom code inventory</li>
                    </ul>
                </div>
                <div style="background: #FEF3C7; border: 1px solid #FCD34D; padding: 15px; border-radius: 8px;">
                    <b style="color: #92400E;">⚠ Technical Remediation</b>
                    <ul style="margin: 10px 0 0 0; padding-left: 20px; color: #92400E; font-size: 14px;">
                        <li>Resolve all invalid objects</li>
                        <li>Enable edition-based custom schemas</li>
                        <li>Convert UTL_FILE_DIR to directories</li>
                        <li>Test all database links connectivity</li>
                    </ul>
                </div>
                <div style="background: #DBEAFE; border: 1px solid #93C5FD; padding: 15px; border-radius: 8px;">
                    <b style="color: #1E40AF;">📋 Planning & Governance</b>
                    <ul style="margin: 10px 0 0 0; padding-left: 20px; color: #1E40AF; font-size: 14px;">
                        <li>Define cutover window requirements</li>
                        <li>Plan minimum 3 rehearsal cycles</li>
                        <li>Establish rollback procedures</li>
                        <li>Coordinate with all integration teams</li>
                    </ul>
                </div>
            </div>
        </div>

    </div>
    
    <script>
        // ScrollSpy logic to highlight navigation sidebar
        document.addEventListener('DOMContentLoaded', function() {{
            const sections = document.querySelectorAll('.section');
            const navLinks = document.querySelectorAll('.nav-sidebar a');
            const backToTop = document.getElementById('backToTop');
            
            window.addEventListener('scroll', () => {{
                let current = '';
                sections.forEach(section => {{
                    const sectionTop = section.offsetTop;
                    if (pageYOffset >= sectionTop - 100) {{
                        current = section.getAttribute('id');
                    }}
                }});

                navLinks.forEach(link => {{
                    link.style.backgroundColor = '';
                    link.style.color = '#555';
                    link.style.borderLeftColor = 'transparent';
                    if (link.getAttribute('href').includes(current) && current !== '') {{
                        link.style.backgroundColor = 'var(--light-blue)';
                        link.style.color = 'var(--primary-blue)';
                        link.style.borderLeftColor = 'var(--primary-blue)';
                    }}
                }});
                
                if (window.scrollY > 400) {{
                    backToTop.style.display = 'flex';
                }} else {{
                    backToTop.style.display = 'none';
                }}
            }});

            // Global Subsection Collapsibility
            const subheaders = document.querySelectorAll('.section h3');
            subheaders.forEach(h3 => {{
                h3.style.cursor = 'pointer';
                h3.innerHTML = '▼ ' + h3.innerHTML;
                h3.addEventListener('click', function() {{
                    const isCollapsed = this.innerHTML.startsWith('▶');
                    this.innerHTML = isCollapsed ? this.innerHTML.replace('▶', '▼') : this.innerHTML.replace('▼', '▶');
                    
                    let nextElem = this.nextElementSibling;
                    while(nextElem && !['H3', 'H2'].includes(nextElem.tagName) && !nextElem.classList.contains('section-header')) {{
                        if (isCollapsed) {{
                            nextElem.style.display = '';
                        }} else {{
                            nextElem.style.display = 'none';
                        }}
                        nextElem = nextElem.nextElementSibling;
                    }}
                }});
            }});
        }});
    </script>
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
