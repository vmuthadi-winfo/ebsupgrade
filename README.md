# EBS Upgrade Analyzer

AWS Elastic Beanstalk Upgrade Analysis Tool - Analyze your EBS environments and get comprehensive upgrade recommendations.

## Overview

The EBS Upgrade Analyzer is a Python-based tool that helps you analyze your AWS Elastic Beanstalk environments and provides detailed recommendations for platform upgrades. It generates comprehensive reports highlighting:

- Deprecated or end-of-life platforms
- Environment age and update history
- Health status concerns
- Risk assessments for each environment
- Actionable upgrade recommendations

## Features

- 🔍 **Automated Analysis**: Scans all Elastic Beanstalk environments in specified AWS regions
- 📊 **Multiple Report Formats**: Generate reports in Text, JSON, or HTML formats
- 🎯 **Risk Assessment**: Categorizes environments by risk level (Critical, Medium, Low)
- 📈 **Detailed Recommendations**: Provides specific upgrade actions for each environment
- 🔐 **AWS Profile Support**: Works with AWS CLI profiles and IAM roles
- 🌍 **Multi-Region**: Analyze environments across multiple AWS regions

## Installation

1. Clone the repository:
```bash
git clone https://github.com/vmuthadi-winfo/ebsupgrade.git
cd ebsupgrade
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure AWS credentials:
```bash
aws configure
```

## Usage

### Basic Usage

Generate a text report for the default region:
```bash
python ebs_upgrade.py --region us-east-1
```

### Advanced Usage

Generate an HTML report:
```bash
python ebs_upgrade.py --region us-east-1 --format html --output my_report.html
```

Use a specific AWS profile:
```bash
python ebs_upgrade.py --region eu-west-1 --profile myprofile --format json
```

Display a summary table in the console:
```bash
python ebs_upgrade.py --region us-west-2 --summary
```

Enable verbose logging:
```bash
python ebs_upgrade.py --region ap-southeast-1 --format html --verbose
```

### Command Line Options

```
--region REGION        AWS region to analyze (default: us-east-1)
--profile PROFILE      AWS profile to use (optional)
--format FORMAT        Output format: text, json, html (default: text)
--output FILE          Output file path (auto-generated if not specified)
--summary              Display summary table in console
--verbose, -v          Enable verbose logging
```

## Report Formats

### Text Report
Plain text format suitable for viewing in terminal or text editors. Includes:
- Executive summary with risk level statistics
- Detailed environment analysis
- Specific recommendations for each environment

### JSON Report
Machine-readable format for integration with other tools. Contains:
- Structured data for all environments
- Complete analysis metadata
- Programmatic access to recommendations

### HTML Report
Visual report with color-coded risk levels and formatted tables. Features:
- Professional styling with AWS color scheme
- Interactive layout with clear visual hierarchy
- Easy to share with stakeholders

## Report Contents

Each report includes:

1. **Summary Section**
   - Total environments analyzed
   - Risk level distribution
   - Generation timestamp and region

2. **Environment Details**
   - Environment name and application
   - Current platform version
   - Status and health information
   - Age and last update information
   - Risk level assessment

3. **Recommendations**
   - Categorized by severity (CRITICAL, WARNING, INFO)
   - Specific upgrade actions
   - Context-aware suggestions

## Example Output

```
AWS ELASTIC BEANSTALK UPGRADE ANALYSIS REPORT
================================================================================
Generated: 2026-02-27 12:00:00
Region: us-east-1
Total Environments Analyzed: 3

RISK LEVEL SUMMARY
--------------------------------------------------------------------------------
  Critical: 1
  Medium: 1
  Low: 1

DETAILED ENVIRONMENT ANALYSIS
================================================================================

1. Environment: my-production-app
   Current Platform: 64bit Amazon Linux 2 v3.4.10 running Python 3.8
   Status: Ready
   Health: Green
   Risk Level: Low
   Age: 245 days
   Last Updated: 30 days ago

   ✓ No immediate upgrade actions required
```

## AWS Permissions Required

The tool requires the following AWS IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:DescribeEnvironments",
        "elasticbeanstalk:ListAvailableSolutionStacks"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuration

You can create a `config.yaml` file for default settings. See `config.yaml.example` for available options.

## Troubleshooting

**No environments found:**
- Verify you have Elastic Beanstalk environments in the specified region
- Check your AWS credentials are configured correctly
- Ensure you have the required IAM permissions

**AWS credential errors:**
- Run `aws configure` to set up credentials
- Verify your AWS profile name if using `--profile`
- Check IAM permissions for Elastic Beanstalk access

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.