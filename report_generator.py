"""
Report Generator for EBS Upgrade Analysis
Generates formatted reports in various formats
"""

from datetime import datetime
from typing import List, Dict, Any
from tabulate import tabulate
import json


class ReportGenerator:
    """Generates upgrade analysis reports in various formats"""
    
    def __init__(self, analyses: List[Dict[str, Any]], region: str = 'us-east-1'):
        """
        Initialize the report generator
        
        Args:
            analyses: List of analysis results
            region: AWS region analyzed
        """
        self.analyses = analyses
        self.region = region
        self.timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    def generate_text_report(self) -> str:
        """
        Generate a text-based report
        
        Returns:
            Formatted text report
        """
        lines = []
        lines.append("=" * 80)
        lines.append("AWS ELASTIC BEANSTALK UPGRADE ANALYSIS REPORT")
        lines.append("=" * 80)
        lines.append(f"Generated: {self.timestamp}")
        lines.append(f"Region: {self.region}")
        lines.append(f"Total Environments Analyzed: {len(self.analyses)}")
        lines.append("")
        
        # Summary statistics
        risk_counts = self._count_by_risk_level()
        lines.append("RISK LEVEL SUMMARY")
        lines.append("-" * 80)
        for level, count in risk_counts.items():
            lines.append(f"  {level}: {count}")
        lines.append("")
        
        # Detailed analysis for each environment
        lines.append("DETAILED ENVIRONMENT ANALYSIS")
        lines.append("=" * 80)
        
        for i, analysis in enumerate(self.analyses, 1):
            lines.append(f"\n{i}. Environment: {analysis['environment']}")
            lines.append(f"   Application: {analysis.get('application', 'N/A')}")
            lines.append(f"   Current Platform: {analysis['current_platform']}")
            lines.append(f"   Status: {analysis['status']}")
            lines.append(f"   Health: {analysis['health']}")
            lines.append(f"   Risk Level: {analysis['risk_level']}")
            lines.append(f"   Age: {analysis['age_days']} days")
            lines.append(f"   Last Updated: {analysis['last_updated_days']} days ago")
            
            if analysis['recommendations']:
                lines.append(f"\n   Recommendations:")
                for rec in analysis['recommendations']:
                    lines.append(f"     [{rec['type']}] {rec['message']}")
                    lines.append(f"       Action: {rec['action']}")
            else:
                lines.append(f"\n   ✓ No immediate upgrade actions required")
            
            lines.append("-" * 80)
        
        return "\n".join(lines)
    
    def generate_summary_table(self) -> str:
        """
        Generate a summary table of all environments
        
        Returns:
            Formatted table string
        """
        headers = ['Environment', 'Platform', 'Health', 'Risk Level', 'Recommendations']
        rows = []
        
        for analysis in self.analyses:
            rows.append([
                analysis['environment'],
                analysis['current_platform'][:50] + '...' if len(analysis['current_platform']) > 50 else analysis['current_platform'],
                analysis['health'],
                analysis['risk_level'],
                len(analysis['recommendations'])
            ])
        
        return tabulate(rows, headers=headers, tablefmt='grid')
    
    def generate_json_report(self) -> str:
        """
        Generate a JSON report
        
        Returns:
            JSON formatted string
        """
        report = {
            'generated': self.timestamp,
            'region': self.region,
            'summary': {
                'total_environments': len(self.analyses),
                'risk_levels': self._count_by_risk_level(),
            },
            'environments': self.analyses
        }
        
        return json.dumps(report, indent=2, default=str)
    
    def generate_html_report(self) -> str:
        """
        Generate an HTML report
        
        Returns:
            HTML formatted string
        """
        risk_counts = self._count_by_risk_level()
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>EBS Upgrade Analysis Report</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }}
        .header {{
            background-color: #232f3e;
            color: white;
            padding: 20px;
            border-radius: 5px;
        }}
        .summary {{
            background-color: white;
            padding: 20px;
            margin-top: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .environment {{
            background-color: white;
            padding: 15px;
            margin-top: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-left: 4px solid #888;
        }}
        .environment.critical {{
            border-left-color: #d13212;
        }}
        .environment.medium {{
            border-left-color: #ff9900;
        }}
        .environment.low {{
            border-left-color: #1d8102;
        }}
        .risk-badge {{
            display: inline-block;
            padding: 5px 10px;
            border-radius: 3px;
            color: white;
            font-weight: bold;
            font-size: 12px;
        }}
        .risk-critical {{
            background-color: #d13212;
        }}
        .risk-medium {{
            background-color: #ff9900;
        }}
        .risk-low {{
            background-color: #1d8102;
        }}
        .recommendation {{
            margin: 10px 0;
            padding: 10px;
            background-color: #f9f9f9;
            border-left: 3px solid #888;
        }}
        .rec-critical {{
            border-left-color: #d13212;
        }}
        .rec-warning {{
            border-left-color: #ff9900;
        }}
        .rec-info {{
            border-left-color: #0073bb;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }}
        th, td {{
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #f0f0f0;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>AWS Elastic Beanstalk Upgrade Analysis Report</h1>
        <p>Generated: {self.timestamp} | Region: {self.region}</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Environments Analyzed:</strong> {len(self.analyses)}</p>
        <table>
            <tr>
                <th>Risk Level</th>
                <th>Count</th>
            </tr>"""
        
        for level, count in risk_counts.items():
            html += f"""
            <tr>
                <td><span class="risk-badge risk-{level.lower()}">{level}</span></td>
                <td>{count}</td>
            </tr>"""
        
        html += """
        </table>
    </div>
    
    <h2 style="margin-top: 30px;">Environment Details</h2>"""
        
        for analysis in self.analyses:
            risk_class = analysis['risk_level'].lower()
            html += f"""
    <div class="environment {risk_class}">
        <h3>{analysis['environment']}</h3>
        <p><strong>Platform:</strong> {analysis['current_platform']}</p>
        <p>
            <strong>Status:</strong> {analysis['status']} | 
            <strong>Health:</strong> {analysis['health']} | 
            <strong>Risk Level:</strong> <span class="risk-badge risk-{risk_class}">{analysis['risk_level']}</span>
        </p>
        <p>
            <strong>Age:</strong> {analysis['age_days']} days | 
            <strong>Last Updated:</strong> {analysis['last_updated_days']} days ago
        </p>"""
            
            if analysis['recommendations']:
                html += """
        <h4>Recommendations</h4>"""
                for rec in analysis['recommendations']:
                    rec_class = rec['type'].lower()
                    html += f"""
        <div class="recommendation rec-{rec_class}">
            <strong>[{rec['type']}]</strong> {rec['message']}<br>
            <em>Action:</em> {rec['action']}
        </div>"""
            else:
                html += """
        <p style="color: #1d8102;">✓ No immediate upgrade actions required</p>"""
            
            html += """
    </div>"""
        
        html += """
</body>
</html>"""
        
        return html
    
    def _count_by_risk_level(self) -> Dict[str, int]:
        """Count environments by risk level"""
        counts = {'Critical': 0, 'Medium': 0, 'Low': 0}
        for analysis in self.analyses:
            level = analysis.get('risk_level', 'Low')
            if level in counts:
                counts[level] += 1
        return counts
    
    def save_report(self, format: str = 'text', filename: str = None) -> str:
        """
        Save report to file
        
        Args:
            format: Report format (text, json, html)
            filename: Output filename (auto-generated if not provided)
            
        Returns:
            Path to saved file
        """
        if filename is None:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f'ebs_upgrade_report_{timestamp}.{format}'
        
        if format == 'text':
            content = self.generate_text_report()
        elif format == 'json':
            content = self.generate_json_report()
        elif format == 'html':
            content = self.generate_html_report()
        else:
            raise ValueError(f"Unsupported format: {format}")
        
        with open(filename, 'w') as f:
            f.write(content)
        
        return filename
