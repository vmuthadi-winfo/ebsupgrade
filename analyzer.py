"""
AWS Elastic Beanstalk Upgrade Analyzer
Analyzes EBS environments and provides upgrade recommendations
"""

import boto3
from datetime import datetime
from typing import List, Dict, Any
import logging

logger = logging.getLogger(__name__)


class EBSAnalyzer:
    """Analyzes AWS Elastic Beanstalk environments for upgrade recommendations"""
    
    def __init__(self, region_name: str = 'us-east-1', profile_name: str = None):
        """
        Initialize the EBS Analyzer
        
        Args:
            region_name: AWS region name
            profile_name: AWS profile name (optional)
        """
        session_kwargs = {'region_name': region_name}
        if profile_name:
            session_kwargs['profile_name'] = profile_name
            
        self.session = boto3.Session(**session_kwargs)
        self.eb_client = self.session.client('elasticbeanstalk')
        self.region = region_name
        
    def get_available_solution_stacks(self) -> List[Dict[str, Any]]:
        """
        Get all available solution stacks from AWS
        
        Returns:
            List of solution stack information
        """
        try:
            response = self.eb_client.list_available_solution_stacks()
            stacks = []
            
            for stack in response.get('SolutionStacks', []):
                stacks.append({
                    'name': stack,
                    'type': self._parse_stack_type(stack)
                })
                
            return stacks
        except Exception as e:
            logger.error(f"Error fetching solution stacks: {e}")
            return []
    
    def _parse_stack_type(self, stack_name: str) -> str:
        """Parse the platform type from stack name"""
        stack_lower = stack_name.lower()
        if 'python' in stack_lower:
            return 'Python'
        elif 'node' in stack_lower or 'nodejs' in stack_lower:
            return 'Node.js'
        elif 'java' in stack_lower:
            return 'Java'
        elif 'php' in stack_lower:
            return 'PHP'
        elif 'ruby' in stack_lower:
            return 'Ruby'
        elif 'go' in stack_lower:
            return 'Go'
        elif '.net' in stack_lower or 'dotnet' in stack_lower:
            return '.NET'
        elif 'docker' in stack_lower:
            return 'Docker'
        elif 'tomcat' in stack_lower:
            return 'Tomcat'
        else:
            return 'Other'
    
    def get_all_environments(self) -> List[Dict[str, Any]]:
        """
        Get all Elastic Beanstalk environments in the account
        
        Returns:
            List of environment information
        """
        try:
            response = self.eb_client.describe_environments()
            environments = []
            
            for env in response.get('Environments', []):
                env_info = {
                    'name': env.get('EnvironmentName'),
                    'id': env.get('EnvironmentId'),
                    'application': env.get('ApplicationName'),
                    'platform': env.get('PlatformArn', ''),
                    'solution_stack': env.get('SolutionStackName', ''),
                    'status': env.get('Status'),
                    'health': env.get('Health'),
                    'date_created': env.get('DateCreated'),
                    'date_updated': env.get('DateUpdated'),
                }
                environments.append(env_info)
                
            return environments
        except Exception as e:
            logger.error(f"Error fetching environments: {e}")
            return []
    
    def analyze_environment(self, environment: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze a single environment for upgrade recommendations
        
        Args:
            environment: Environment information dictionary
            
        Returns:
            Analysis results with recommendations
        """
        analysis = {
            'environment': environment['name'],
            'current_platform': environment.get('solution_stack', 'Unknown'),
            'status': environment.get('status'),
            'health': environment.get('health'),
            'age_days': self._calculate_age(environment.get('date_created')),
            'last_updated_days': self._calculate_age(environment.get('date_updated')),
            'recommendations': [],
            'risk_level': 'Low',
        }
        
        # Check for deprecated platforms
        if self._is_platform_deprecated(environment.get('solution_stack', '')):
            analysis['recommendations'].append({
                'type': 'CRITICAL',
                'message': 'Platform is deprecated or approaching end of life',
                'action': 'Upgrade to latest supported platform version'
            })
            analysis['risk_level'] = 'Critical'
        
        # Check age of environment
        if analysis['age_days'] > 365:
            analysis['recommendations'].append({
                'type': 'WARNING',
                'message': f'Environment is {analysis["age_days"]} days old',
                'action': 'Review and consider upgrading to leverage new features'
            })
            if analysis['risk_level'] == 'Low':
                analysis['risk_level'] = 'Medium'
        
        # Check last update
        if analysis['last_updated_days'] > 180:
            analysis['recommendations'].append({
                'type': 'INFO',
                'message': f'Environment not updated in {analysis["last_updated_days"]} days',
                'action': 'Consider updating to latest patch version'
            })
        
        # Check health status
        if environment.get('health') not in ['Green', 'Grey']:
            analysis['recommendations'].append({
                'type': 'WARNING',
                'message': f'Environment health is {environment.get("health")}',
                'action': 'Resolve health issues before upgrading'
            })
        
        return analysis
    
    def _calculate_age(self, date) -> int:
        """Calculate age in days from a date"""
        if not date:
            return 0
        
        if isinstance(date, str):
            date = datetime.fromisoformat(date.replace('Z', '+00:00'))
        
        age = datetime.now(date.tzinfo) - date
        return age.days
    
    def _is_platform_deprecated(self, stack_name: str) -> bool:
        """
        Check if a platform version is deprecated
        This is a simplified check - in production, this would check against AWS announcements
        """
        if not stack_name:
            return False
        
        # Check for very old versions (simplified heuristic)
        deprecated_indicators = [
            '2018', '2019', '2020',  # Old year versions
            'Python 2.7', 'Python 3.6',  # EOL Python versions
            'Node.js 10', 'Node.js 12',  # EOL Node versions
            'Java 7', 'Java 8 running',  # Very old Java
        ]
        
        return any(indicator in stack_name for indicator in deprecated_indicators)
    
    def analyze_all_environments(self) -> List[Dict[str, Any]]:
        """
        Analyze all environments in the account
        
        Returns:
            List of analysis results for all environments
        """
        environments = self.get_all_environments()
        analyses = []
        
        for env in environments:
            analysis = self.analyze_environment(env)
            analyses.append(analysis)
        
        return analyses
