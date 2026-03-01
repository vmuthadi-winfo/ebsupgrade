"""
Demo/Sample data generator for testing the EBS Upgrade Analyzer
without requiring AWS credentials
"""

from datetime import datetime, timedelta
import random


def generate_sample_environments():
    """Generate sample environment data for testing"""
    
    sample_platforms = [
        "64bit Amazon Linux 2 v3.4.10 running Python 3.8",
        "64bit Amazon Linux 2 v5.8.0 running Node.js 16",
        "64bit Amazon Linux 2018.03 v2.9.15 running Python 2.7",  # Deprecated
        "64bit Amazon Linux 2 v3.5.2 running Node.js 18",
        "64bit Amazon Linux 2 v4.2.0 running Java 11 Corretto",
        "64bit Amazon Linux 2 v3.3.0 running Docker",
    ]
    
    health_statuses = ["Green", "Yellow", "Red", "Grey"]
    statuses = ["Ready", "Updating", "Launching"]
    
    environments = []
    
    # Environment 1 - Critical (deprecated platform)
    env1 = {
        'name': 'legacy-python-app',
        'id': 'e-abc123def',
        'application': 'LegacyApp',
        'platform': 'arn:aws:elasticbeanstalk:us-east-1::platform/Python 2.7',
        'solution_stack': sample_platforms[2],
        'status': 'Ready',
        'health': 'Yellow',
        'date_created': datetime.now() - timedelta(days=800),
        'date_updated': datetime.now() - timedelta(days=250),
    }
    environments.append(env1)
    
    # Environment 2 - Medium (old environment)
    env2 = {
        'name': 'production-web-api',
        'id': 'e-def456ghi',
        'application': 'WebAPI',
        'platform': 'arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 16',
        'solution_stack': sample_platforms[1],
        'status': 'Ready',
        'health': 'Green',
        'date_created': datetime.now() - timedelta(days=400),
        'date_updated': datetime.now() - timedelta(days=190),
    }
    environments.append(env2)
    
    # Environment 3 - Low (healthy, recent)
    env3 = {
        'name': 'dev-microservice',
        'id': 'e-ghi789jkl',
        'application': 'Microservices',
        'platform': 'arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 18',
        'solution_stack': sample_platforms[3],
        'status': 'Ready',
        'health': 'Green',
        'date_created': datetime.now() - timedelta(days=120),
        'date_updated': datetime.now() - timedelta(days=15),
    }
    environments.append(env3)
    
    # Environment 4 - Medium (not updated recently)
    env4 = {
        'name': 'staging-backend',
        'id': 'e-jkl012mno',
        'application': 'BackendServices',
        'platform': 'arn:aws:elasticbeanstalk:us-east-1::platform/Python 3.8',
        'solution_stack': sample_platforms[0],
        'status': 'Ready',
        'health': 'Green',
        'date_created': datetime.now() - timedelta(days=500),
        'date_updated': datetime.now() - timedelta(days=200),
    }
    environments.append(env4)
    
    # Environment 5 - Low (Docker, modern)
    env5 = {
        'name': 'container-app',
        'id': 'e-mno345pqr',
        'application': 'ContainerizedApp',
        'platform': 'arn:aws:elasticbeanstalk:us-east-1::platform/Docker',
        'solution_stack': sample_platforms[5],
        'status': 'Ready',
        'health': 'Green',
        'date_created': datetime.now() - timedelta(days=90),
        'date_updated': datetime.now() - timedelta(days=10),
    }
    environments.append(env5)
    
    return environments


def generate_sample_solution_stacks():
    """Generate sample solution stacks"""
    return [
        {'name': '64bit Amazon Linux 2 v3.5.2 running Python 3.11', 'type': 'Python'},
        {'name': '64bit Amazon Linux 2 v5.8.2 running Node.js 18', 'type': 'Node.js'},
        {'name': '64bit Amazon Linux 2 v4.2.5 running Java 17 Corretto', 'type': 'Java'},
        {'name': '64bit Amazon Linux 2 v3.5.0 running Docker', 'type': 'Docker'},
        {'name': '64bit Amazon Linux 2 v2.6.0 running PHP 8.2', 'type': 'PHP'},
        {'name': '64bit Amazon Linux 2 v3.4.0 running Ruby 3.2', 'type': 'Ruby'},
    ]
