#!/usr/bin/env python3
"""
EBS Upgrade Analyzer - Command Line Interface
Analyzes AWS Elastic Beanstalk environments and generates upgrade reports
"""

import argparse
import sys
import logging
from analyzer import EBSAnalyzer
from report_generator import ReportGenerator
from sample_data import generate_sample_environments


def setup_logging(verbose: bool = False):
    """Setup logging configuration"""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description='Analyze AWS Elastic Beanstalk environments for upgrade recommendations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate text report for default region
  python ebs_upgrade.py --region us-east-1 --format text
  
  # Generate HTML report with specific AWS profile
  python ebs_upgrade.py --region eu-west-1 --profile myprofile --format html
  
  # Save report to specific file
  python ebs_upgrade.py --region us-west-2 --format json --output my_report.json
  
  # Display summary in console
  python ebs_upgrade.py --region ap-southeast-1 --summary
        """
    )
    
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region to analyze (default: us-east-1)'
    )
    
    parser.add_argument(
        '--profile',
        help='AWS profile to use (optional)'
    )
    
    parser.add_argument(
        '--format',
        choices=['text', 'json', 'html'],
        default='text',
        help='Output format for the report (default: text)'
    )
    
    parser.add_argument(
        '--output',
        '-o',
        help='Output file path (auto-generated if not specified)'
    )
    
    parser.add_argument(
        '--summary',
        action='store_true',
        help='Display summary table in console'
    )
    
    parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    
    parser.add_argument(
        '--demo',
        action='store_true',
        help='Run in demo mode with sample data (no AWS credentials required)'
    )
    
    args = parser.parse_args()
    
    setup_logging(args.verbose)
    logger = logging.getLogger(__name__)
    
    try:
        # Check if demo mode
        if args.demo:
            logger.info("Running in DEMO mode with sample data")
            print("\n" + "="*80)
            print("DEMO MODE - Using sample data (no AWS credentials required)")
            print("="*80 + "\n")
            
            # Use sample data
            from sample_data import generate_sample_environments
            sample_envs = generate_sample_environments()
            
            # Create a mock analyzer and analyze the sample environments
            class MockAnalyzer:
                def analyze_environment(self, env):
                    from analyzer import EBSAnalyzer
                    real_analyzer = object.__new__(EBSAnalyzer)
                    return real_analyzer.analyze_environment(env)
            
            mock_analyzer = MockAnalyzer()
            analyses = [mock_analyzer.analyze_environment(env) for env in sample_envs]
        else:
            # Initialize analyzer
            logger.info(f"Initializing EBS Analyzer for region: {args.region}")
            analyzer = EBSAnalyzer(region_name=args.region, profile_name=args.profile)
            
            # Analyze environments
            logger.info("Analyzing Elastic Beanstalk environments...")
            analyses = analyzer.analyze_all_environments()
        
        if not analyses:
            logger.warning("No Elastic Beanstalk environments found in the specified region")
            print("\nNo Elastic Beanstalk environments found.")
            print(f"Region: {args.region}")
            print("\nPlease verify:")
            print("  1. You have Elastic Beanstalk environments in this region")
            print("  2. Your AWS credentials are configured correctly")
            print("  3. You have permissions to describe Elastic Beanstalk resources")
            return 0
        
        logger.info(f"Found {len(analyses)} environment(s)")
        
        # Generate report
        generator = ReportGenerator(analyses, region=args.region)
        
        if args.summary:
            print("\n" + generator.generate_summary_table())
            print(f"\nTotal Environments: {len(analyses)}")
        
        # Save report
        if args.output or not args.summary:
            output_file = generator.save_report(format=args.format, filename=args.output)
            print(f"\n✓ Report generated successfully: {output_file}")
            
            # Also print text report to console if in text format
            if args.format == 'text' and not args.output:
                print("\n" + generator.generate_text_report())
        
        return 0
        
    except Exception as e:
        logger.error(f"Error during analysis: {e}", exc_info=args.verbose)
        print(f"\n✗ Error: {e}")
        print("\nPlease check:")
        print("  1. AWS credentials are configured (aws configure)")
        print("  2. You have necessary IAM permissions")
        print("  3. The specified region is correct")
        return 1


if __name__ == '__main__':
    sys.exit(main())
