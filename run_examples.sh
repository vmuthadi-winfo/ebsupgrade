#!/bin/bash
# Example script to demonstrate the EBS Upgrade Analyzer

echo "=========================================="
echo "EBS Upgrade Analyzer - Demo Examples"
echo "=========================================="
echo ""

# Example 1: Run in demo mode
echo "Example 1: Running in demo mode (no AWS credentials required)"
echo "Command: python ebs_upgrade.py --demo --summary"
echo ""
python ebs_upgrade.py --demo --summary
echo ""
echo "=========================================="
echo ""

# Example 2: Generate HTML report
echo "Example 2: Generating HTML report"
echo "Command: python ebs_upgrade.py --demo --format html --output example_report.html"
echo ""
python ebs_upgrade.py --demo --format html --output example_report.html
echo ""
echo "HTML report generated: example_report.html"
echo "Open this file in a web browser to view the report"
echo ""
echo "=========================================="
echo ""

# Example 3: Generate JSON report
echo "Example 3: Generating JSON report"
echo "Command: python ebs_upgrade.py --demo --format json --output example_report.json"
echo ""
python ebs_upgrade.py --demo --format json --output example_report.json
echo ""
echo "JSON report generated: example_report.json"
echo ""
echo "=========================================="
echo ""

echo "Demo complete!"
echo ""
echo "To use with your actual AWS account:"
echo "  1. Configure AWS credentials: aws configure"
echo "  2. Run without --demo flag: python ebs_upgrade.py --region us-east-1"
echo ""
