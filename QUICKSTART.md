# Quick Start Guide

This guide will help you get started with the EBS Upgrade Analyzer quickly.

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/vmuthadi-winfo/ebsupgrade.git
   cd ebsupgrade
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

## Try the Demo

The easiest way to see the tool in action is to use demo mode (no AWS credentials required):

```bash
python ebs_upgrade.py --demo --summary
```

This will display a summary table of sample environments with upgrade recommendations.

## Generate Reports

### Text Report
```bash
python ebs_upgrade.py --demo --format text
```

### HTML Report
```bash
python ebs_upgrade.py --demo --format html --output my_report.html
```

Then open `my_report.html` in your browser to see a professionally formatted report.

### JSON Report
```bash
python ebs_upgrade.py --demo --format json --output my_report.json
```

## Use with Your AWS Account

Once you're ready to analyze your actual Elastic Beanstalk environments:

1. **Configure AWS credentials**
   ```bash
   aws configure
   ```

2. **Run the analyzer**
   ```bash
   python ebs_upgrade.py --region us-east-1 --format html
   ```

3. **Use a specific AWS profile**
   ```bash
   python ebs_upgrade.py --region us-east-1 --profile myprofile --format html
   ```

## Understanding the Report

The report categorizes environments into risk levels:

- **Critical**: Deprecated platforms or critical issues requiring immediate attention
- **Medium**: Older environments that should be reviewed and upgraded
- **Low**: Healthy environments with no immediate concerns

Each environment includes:
- Current platform version
- Health status
- Age and last update information
- Specific recommendations and actions

## Running All Examples

Run the included examples script:

```bash
bash run_examples.sh
```

This will generate all report formats and show various features of the tool.

## Next Steps

- Review the full [README.md](README.md) for detailed documentation
- Check [config.yaml.example](config.yaml.example) for configuration options
- Explore the source code to understand how the analysis works

## Need Help?

- Run `python ebs_upgrade.py --help` for all available options
- Open an issue on GitHub for questions or bug reports
- Check AWS documentation for Elastic Beanstalk best practices
